import debate
import envoy
import gleam/bit_array
import gleam/dynamic/decode
import gleam/erlang/process
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import gleam/float
import gleam/io

pub type LlmError {
  MissingApiKey
  HttpFailure(String)
  DecodeFailure(String)
}

type Config {
  Config(api_key: String, model: String, api_base: String)
}

type Usage {
  Usage(
    prompt_tokens: Int,
    completion_tokens: Int,
    total_tokens: Int,
  )
}

type RawDecision {
  RawDecision(
    will_speak: Bool,
    speech: String,
    vote_intent: String,
    purpose: String,
    procedure: String,
    amendment_summary: String,
    amendment_rationale: String,
  )
}

const default_model = "gpt-4.1-mini"
const default_api_base = "https://api.openai.com/v1"
const default_embedding_model = "text-embedding-3-small"

const default_retry_attempts = 3
const default_retry_backoff_ms = 250

type WorkerEvent {
  WorkerReply(Result(String, LlmError))
  WorkerDown(String)
}

fn resolve_model(model_override: Option(String)) -> String {
  case model_override {
    Some(value) -> value
    None ->
      case envoy.get("HARMONY_MODEL") {
        Ok(value) -> value
        Error(_) -> default_model
      }
  }
}

fn load_config(model_override: Option(String)) -> Result(Config, LlmError) {
  case envoy.get("OPENAI_API_KEY") {
    Ok(api_key) -> {
      let model = resolve_model(model_override)
      let api_base = case envoy.get("HARMONY_API_BASE") {
        Ok(value) -> value
        Error(_) -> default_api_base
      }

      Ok(Config(api_key:, model:, api_base:))
    }
    Error(_) -> Error(MissingApiKey)
  }
}

pub fn embed(text: String) -> Result(List(Float), LlmError) {
  use config <- result.try(load_config(None))

  let model = case envoy.get("HARMONY_EMBEDDING_MODEL") {
    Ok(value) -> value
    Error(_) -> default_embedding_model
  }

  retry(
    fn() { embed_once(text, config, model) },
    max_retry_attempts(),
    retry_backoff_ms(),
  )
}

/// Spawn an LLM request in a worker process and enforce a timeout so callers
/// don't block indefinitely if the upstream model is slow.
pub fn call_llm_with_timeout(prompt: String, timeout_ms: Int) -> Result(String, LlmError) {
  call_llm_with_timeout_internal(prompt, timeout_ms, None)
}

pub fn call_llm_with_timeout_using_model(
  prompt: String,
  timeout_ms: Int,
  model_override: Option(String),
) -> Result(String, LlmError) {
  call_llm_with_timeout_internal(prompt, timeout_ms, model_override)
}

pub fn call_llm(prompt: String) -> Result(String, LlmError) {
  call_llm_internal(prompt, None)
}

pub fn call_llm_with_model(prompt: String, model_override: String) -> Result(String, LlmError) {
  call_llm_internal(prompt, Some(model_override))
}

fn call_llm_internal(
  prompt: String,
  model_override: Option(String),
) -> Result(String, LlmError) {
  use config <- result.try(load_config(model_override))

  retry(
    fn() { completion_once(prompt, config) },
    max_retry_attempts(),
    retry_backoff_ms(),
  )
}

fn call_llm_with_timeout_internal(
  prompt: String,
  timeout_ms: Int,
  model_override: Option(String),
) -> Result(String, LlmError) {
  let reply = process.new_subject()

  let worker =
    process.spawn_unlinked(fn() {
      let result = call_llm_internal(prompt, model_override)
      process.send(reply, result)
    })

  let monitor = process.monitor(worker)

  let selector =
    process.select_specific_monitor(
      process.select_map(
        process.new_selector(),
        reply,
        fn(result) { WorkerReply(result) },
      ),
      monitor,
      fn(down) { WorkerDown(string.inspect(down)) },
    )

  case process.selector_receive(selector, timeout_ms) {
    Ok(event) -> {
      process.demonitor_process(monitor)
      case event {
        WorkerReply(result) -> result
        WorkerDown(reason) ->
          Error(HttpFailure("LLM worker terminated: " <> reason))
      }
    }
    Error(Nil) -> {
      process.kill(worker)
      process.demonitor_process(monitor)
      Error(HttpFailure("LLM call timed out after " <> int.to_string(timeout_ms) <> "ms"))
    }
  }
}

pub fn parse_debate_decision(
  body: String,
) -> Result(debate.DebateDecision, LlmError) {
  use raw <- result.try(
    json.parse(body, decision_decoder())
    |> result.map_error(fn(error) { DecodeFailure(format_decode_error(error)) })
  )

  use intent <- result.try(
    debate.vote_intent_from_label(raw.vote_intent)
    |> result.map_error(fn(message) { DecodeFailure(message) })
  )

  let procedure = debate.procedure_from_label(raw.procedure)

  Ok(debate.SpeakDecision(
    raw.will_speak,
    raw.speech,
    intent,
    raw.purpose,
    procedure,
    blank_to_option(raw.amendment_summary),
    blank_to_option(raw.amendment_rationale),
  ))
}

pub fn error_to_string(error: LlmError) -> String {
  case error {
    MissingApiKey -> "Missing OPENAI_API_KEY environment variable"
    HttpFailure(message) -> message
    DecodeFailure(message) -> message
  }
}

fn log_info(message: String) -> Nil {
  io.println("INFO [llm_client]: " <> message)
}

fn completion_once(prompt: String, config: Config) -> Result(String, LlmError) {
  maybe_rate_limit()
  io.println("call_llm: sending system/user prompt with length=" <> int.to_string(string.length(prompt)))

  let payload = build_payload(prompt, config.model)
  let url = normalise_base(config.api_base) <> "/chat/completions"

  let prepared_request =
    request.to(url)
    |> result.map_error(fn(_) { HttpFailure("Invalid API base URL: " <> url) })

  use base_request <- result.try(prepared_request)

  let req =
    base_request
    |> request.set_method(http.Post)
    |> request.set_header("authorization", "Bearer " <> config.api_key)
    |> request.set_header("content-type", "application/json")
    |> request.map(fn(_) { bit_array.from_string(payload) })

  let sent =
    httpc.send_bits(req)
    |> result.map_error(fn(error) { HttpFailure(http_error_to_string(error)) })

  use resp <- result.try(sent)

  let body_bits =
    resp.body
    |> bit_array.to_string
    |> result.map_error(fn(_) { DecodeFailure("Response body is not UTF-8") })

  use body <- result.try(body_bits)

  case resp.status >= 200 && resp.status < 300 {
    True -> {
      use #(content, usage) <- result.try(decode_completion(body))
      log_completion_usage(usage)
      io.println("call_llm: success")
      Ok(content)
    }
    False ->
      Error(HttpFailure(
        "OpenAI status " <> int.to_string(resp.status) <> ": " <> body,
      ))
  }
}

fn embed_once(text: String, config: Config, model: String) -> Result(List(Float), LlmError) {
  maybe_rate_limit()
  io.println("embed call len=" <> int.to_string(string.length(text)))

  let payload = embedding_payload(text, model)
  let url = normalise_base(config.api_base) <> "/embeddings"

  let prepared_request =
    request.to(url)
    |> result.map_error(fn(_) { HttpFailure("Invalid API base URL: " <> url) })

  use base_request <- result.try(prepared_request)

  let req =
    base_request
    |> request.set_method(http.Post)
    |> request.set_header("authorization", "Bearer " <> config.api_key)
    |> request.set_header("content-type", "application/json")
    |> request.map(fn(_) { bit_array.from_string(payload) })

  let sent =
    httpc.send_bits(req)
    |> result.map_error(fn(error) { HttpFailure(http_error_to_string(error)) })

  use resp <- result.try(sent)

  let body_bits =
    resp.body
    |> bit_array.to_string
    |> result.map_error(fn(_) { DecodeFailure("Response body is not UTF-8") })

  use body <- result.try(body_bits)

  case resp.status >= 200 && resp.status < 300 {
    True -> {
      use #(vector, usage) <- result.try(decode_embedding(body))
      log_embedding_usage(usage)
      io.println("embed call success")
      Ok(vector)
    }
    False ->
      Error(HttpFailure(
        "OpenAI status " <> int.to_string(resp.status) <> ": " <> body,
      ))
  }
}

fn build_payload(prompt: String, model: String) -> String {
  let messages =
    json.preprocessed_array([
      json.object([
        #("role", json.string("system")),
        #(
          "content",
          json.string(
            "You are a member of the AGATA Senate: caretakers of a 70-acre art collaborative and regenerative farm at Coward, South Carolina. "
            <> "Speak with the urgency of those running the farm, reference AGATA's priorities, and avoid meta commentary.",
          ),
        ),
      ]),
      json.object([
        #("role", json.string("user")),
        #("content", json.string(prompt)),
      ]),
    ])

  json.object([
    #("model", json.string(model)),
    #("messages", messages),
  ])
  |> json.to_string
}

fn embedding_payload(text: String, model: String) -> String {
  json.object([
    #("model", json.string(model)),
    #("input", json.string(text)),
  ])
  |> json.to_string
}

fn decode_completion(body: String) -> Result(#(String, Option(Usage)), LlmError) {
  json.parse(body, using: completion_response_decoder())
  |> result.map(fn(result_pair) {
    let #(content, usage) = result_pair
    #(string.trim(content), usage)
  })
  |> result.map_error(fn(error) { DecodeFailure(format_decode_error(error)) })
}

fn decode_embedding(body: String) -> Result(#(List(Float), Option(Usage)), LlmError) {
  json.parse(body, using: embedding_response_decoder())
  |> result.map_error(fn(error) { DecodeFailure(format_decode_error(error)) })
}

fn completion_response_decoder() -> decode.Decoder(#(String, Option(Usage))) {
  use choices <- decode.field("choices", decode.list(choice_decoder()))
  use usage <- decode.optional_field(
    "usage",
    None,
    decode.map(usage_decoder(), fn(u) { Some(u) }),
  )
  case choices {
    [first, ..] -> decode.success(#(first, usage))
    [] -> decode.failure(#("", usage), "NonEmptyChoices")
  }
}

fn embedding_response_decoder() -> decode.Decoder(#(List(Float), Option(Usage))) {
  use vectors <- decode.field("data", decode.list(embedding_item_decoder()))
  use usage <- decode.optional_field(
    "usage",
    None,
    decode.map(usage_decoder(), fn(u) { Some(u) }),
  )
  case vectors {
    [first, ..] -> decode.success(#(first, usage))
    [] -> decode.failure(#([], usage), "NonEmptyEmbeddings")
  }
}

fn choice_decoder() -> decode.Decoder(String) {
  use message <- decode.field("message", message_decoder())
  decode.success(message)
}

fn message_decoder() -> decode.Decoder(String) {
  use content <- decode.field("content", decode.string)
  decode.success(content)
}

fn decision_decoder() -> decode.Decoder(RawDecision) {
  use will_speak <- decode.field("will_speak", decode.bool)
  use speech <- decode.field("speech", decode.string)
  use vote_intent <- decode.field("vote_intent", decode.string)
  use purpose <- decode.optional_field("purpose", "new_argument", decode.string)
  use procedure <- decode.optional_field("procedure", "none", decode.string)
  use amendment_summary <- decode.optional_field("amendment_summary", "", decode.string)
  use amendment_rationale <- decode.optional_field("amendment_rationale", "", decode.string)
  decode.success(RawDecision(
    will_speak: will_speak,
    speech: speech,
    vote_intent: vote_intent,
    purpose: purpose,
    procedure: procedure,
    amendment_summary: amendment_summary,
    amendment_rationale: amendment_rationale,
  ))
}

fn embedding_item_decoder() -> decode.Decoder(List(Float)) {
  use embedding <- decode.field("embedding", decode.list(decode.float))
  decode.success(embedding)
}

fn usage_decoder() -> decode.Decoder(Usage) {
  use prompt_tokens <- decode.field("prompt_tokens", decode.int)
  use completion_tokens <- decode.optional_field("completion_tokens", 0, decode.int)
  use total_tokens <- decode.field("total_tokens", decode.int)
  decode.success(Usage(
    prompt_tokens: prompt_tokens,
    completion_tokens: completion_tokens,
    total_tokens: total_tokens,
  ))
}

fn format_decode_error(error: json.DecodeError) -> String {
  case error {
    json.UnexpectedEndOfInput -> "Unexpected end of input"
    json.UnexpectedByte(detail) -> "Unexpected byte: " <> detail
    json.UnexpectedSequence(detail) -> "Unexpected sequence: " <> detail
    json.UnableToDecode(errors) ->
      errors
      |> list.map(fn(err) {
        let decode.DecodeError(expected:, found:, path:) = err
        let location = case path {
          [] -> ""
          _ -> " at " <> string.join(path, with: ".")
        }
        "Expected " <> expected <> " but found " <> found <> location
      })
      |> string.join(", ")
  }
}

fn http_error_to_string(error: httpc.HttpError) -> String {
  case error {
    httpc.InvalidUtf8Response -> "Invalid UTF-8 in response"
    httpc.ResponseTimeout -> "Timed out waiting for response"
    httpc.FailedToConnect(ip4, ip6) ->
      "Failed to connect (IPv4: "
      <> format_connect_error(ip4)
      <> ", IPv6: "
      <> format_connect_error(ip6)
      <> ")"
  }
}

fn format_connect_error(error: httpc.ConnectError) -> String {
  case error {
    httpc.Posix(code) -> code
    httpc.TlsAlert(code, detail) -> code <> " " <> detail
  }
}

fn normalise_base(base: String) -> String {
  case string.ends_with(base, "/") {
    True -> string.drop_end(base, 1)
    False -> base
  }
}

fn maybe_rate_limit() -> Nil {
  let delay = rate_limit_delay_ms()
  case delay > 0 {
    True -> process.sleep(delay)
    False -> Nil
  }
}

fn blank_to_option(value: String) -> Option(String) {
  let trimmed = string.trim(value)
  case trimmed == "" {
    True -> None
    False -> Some(trimmed)
  }
}

fn retry(
  operation: fn() -> Result(a, LlmError),
  max_retries: Int,
  delay_ms: Int,
) -> Result(a, LlmError) {
  retry_loop(operation, 0, max_retries, delay_ms)
}

fn retry_loop(
  operation: fn() -> Result(a, LlmError),
  attempt: Int,
  max_retries: Int,
  base_delay_ms: Int,
) -> Result(a, LlmError) {
  case operation() {
    Ok(value) -> Ok(value)
    Error(error) ->
      case attempt < max_retries && should_retry(error) {
        True -> {
          let delay = base_delay_ms * power_of_two(attempt)
          process.sleep(delay)
          retry_loop(operation, attempt + 1, max_retries, base_delay_ms)
        }
        False -> Error(error)
      }
  }
}

fn should_retry(error: LlmError) -> Bool {
  case error {
    HttpFailure(message) -> {
      let lower = string.lowercase(message)
      string.contains(lower, "429")
        || string.contains(lower, "timeout")
        || string.contains(lower, "temporarily unavailable")
        || string.contains(lower, "502")
    }
    _ -> False
  }
}

fn rate_limit_delay_ms() -> Int {
  env_int("HARMONY_LLM_MIN_DELAY_MS", 0)
}

fn max_retry_attempts() -> Int {
  env_int("HARMONY_LLM_MAX_RETRIES", default_retry_attempts)
}

fn retry_backoff_ms() -> Int {
  env_int("HARMONY_LLM_RETRY_BACKOFF_MS", default_retry_backoff_ms)
}

fn env_int(name: String, default: Int) -> Int {
  case envoy.get(name) {
    Ok(value) ->
      case int.parse(value) {
        Ok(parsed) -> parsed
        Error(_) -> default
      }
    Error(_) -> default
  }
}

fn env_float(name: String, default: Float) -> Float {
  case envoy.get(name) {
    Ok(value) ->
      case float.parse(value) {
        Ok(parsed) -> parsed
        Error(_) -> default
      }
    Error(_) -> default
  }
}

fn completion_cost_rate() -> Float {
  env_float("HARMONY_LLM_COST_PER_1K_TOKENS", 0.0)
}

fn embedding_cost_rate() -> Float {
  env_float("HARMONY_EMBED_COST_PER_1K_TOKENS", 0.0)
}

fn log_completion_usage(usage: Option(Usage)) -> Nil {
  case usage {
    Some(info) -> log_usage("completion", info, completion_cost_rate())
    None -> log_info("Completion call succeeded (usage unavailable)")
  }
}

fn log_embedding_usage(usage: Option(Usage)) -> Nil {
  case usage {
    Some(info) -> log_usage("embedding", info, embedding_cost_rate())
    None -> log_info("Embedding call succeeded (usage unavailable)")
  }
}

fn log_usage(label: String, usage: Usage, rate: Float) -> Nil {
  let cost =
    int.to_float(usage.total_tokens) /. 1000.0 *. rate

  log_info(
    "LLM "
      <> label
      <> " usage prompt="
      <> int.to_string(usage.prompt_tokens)
      <> " completion="
      <> int.to_string(usage.completion_tokens)
      <> " total="
      <> int.to_string(usage.total_tokens)
      <> " cost=$"
      <> float.to_string(cost),
  )
}

fn power_of_two(exponent: Int) -> Int {
  case exponent <= 0 {
    True -> 1
    False -> 2 * power_of_two(exponent - 1)
  }
}
