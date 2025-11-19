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
import gleam/result
import gleam/string

pub type LlmError {
  MissingApiKey
  HttpFailure(String)
  DecodeFailure(String)
}

type Config {
  Config(api_key: String, model: String, api_base: String)
}

type RawDecision {
  RawDecision(
    will_speak: Bool,
    speech: String,
    vote_intent: String,
    purpose: String,
    procedure: String,
  )
}

const default_model = "gpt-4.1-mini"
const default_api_base = "https://api.openai.com/v1"
const default_embedding_model = "text-embedding-3-small"

pub fn embed(text: String) -> Result(List(Float), LlmError) {
  use config <- result.try(load_config())

  let model = case envoy.get("HARMONY_EMBEDDING_MODEL") {
    Ok(value) -> value
    Error(_) -> default_embedding_model
  }

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
    True -> decode_embedding(body)
    False ->
      Error(HttpFailure(
        "OpenAI status " <> int.to_string(resp.status) <> ": " <> body,
      ))
  }
}

/// Spawn an LLM request in a worker process and enforce a timeout so callers
/// don't block indefinitely if the upstream model is slow.
pub fn call_llm_with_timeout(prompt: String, timeout_ms: Int) -> Result(String, LlmError) {
  let reply = process.new_subject()

  let _worker =
    process.spawn(fn() {
      let result = call_llm(prompt)
      process.send(reply, result)
    })

  case process.receive(reply, timeout_ms) {
    Ok(result) -> result
    Error(Nil) ->
      Error(HttpFailure("LLM call timed out after " <> int.to_string(timeout_ms) <> "ms"))
  }
}

pub fn call_llm(prompt: String) -> Result(String, LlmError) {
  use config <- result.try(load_config())

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
    True -> decode_completion(body)
    False ->
      Error(HttpFailure(
        "OpenAI status " <> int.to_string(resp.status) <> ": " <> body,
      ))
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
  ))
}

pub fn error_to_string(error: LlmError) -> String {
  case error {
    MissingApiKey -> "Missing OPENAI_API_KEY environment variable"
    HttpFailure(message) -> message
    DecodeFailure(message) -> message
  }
}

fn load_config() -> Result(Config, LlmError) {
  case envoy.get("OPENAI_API_KEY") {
    Ok(api_key) -> {
      let model = case envoy.get("HARMONY_MODEL") {
        Ok(value) -> value
        Error(_) -> default_model
      }

      let api_base = case envoy.get("HARMONY_API_BASE") {
        Ok(value) -> value
        Error(_) -> default_api_base
      }

      Ok(Config(api_key:, model:, api_base:))
    }
    Error(_) -> Error(MissingApiKey)
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
            "You are a sitting United States Senator giving speeches and preparing and voting on legislation. "
            <> "Respond in polished speech paragraphs, cite concrete considerations, and avoid meta commentary.",
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

fn decode_completion(body: String) -> Result(String, LlmError) {
  json.parse(body, completion_decoder())
  |> result.map(fn(content) { string.trim(content) })
  |> result.map_error(fn(error) { DecodeFailure(format_decode_error(error)) })
}

fn decode_embedding(body: String) -> Result(List(Float), LlmError) {
  json.parse(body, embedding_decoder())
  |> result.map_error(fn(error) { DecodeFailure(format_decode_error(error)) })
}

fn completion_decoder() -> decode.Decoder(String) {
  use choices <- decode.field("choices", decode.list(choice_decoder()))
  case choices {
    [first, ..] -> decode.success(first)
    [] -> decode.failure("", "NonEmptyChoices")
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
  decode.success(RawDecision(
    will_speak: will_speak,
    speech: speech,
    vote_intent: vote_intent,
    purpose: purpose,
    procedure: procedure,
  ))
}

fn embedding_decoder() -> decode.Decoder(List(Float)) {
  use data <- decode.field("data", decode.list(embedding_item_decoder()))
  case data {
    [first, ..] -> decode.success(first)
    [] -> decode.failure([], "NonEmptyEmbeddings")
  }
}

fn embedding_item_decoder() -> decode.Decoder(List(Float)) {
  use embedding <- decode.field("embedding", decode.list(decode.float))
  decode.success(embedding)
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
