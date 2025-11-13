import envoy
import gleam/bit_array
import gleam/dynamic/decode
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

const default_model = "gpt-4.1-mini"

const default_api_base = "https://api.openai.com/v1"

// High-level entrypoint: send a prompt string, get either the LLM text or an LlmError.
pub fn call_llm(prompt: String) -> Result(String, LlmError) {
  // Load environment-driven configuration (API key, model, base URL).
  use config <- result.try(load_config())

  // Build JSON body for OpenAI chat/completions.
  let payload = build_payload(prompt, config.model)
  let url = normalise_base(config.api_base) <> "/chat/completions"

  // Construct an HTTP request to the OpenAI API.
  let prepared_request =
    request.to(url)
    |> result.map_error(fn(_) { HttpFailure("Invalid API base URL: " <> url) })

  use base_request <- result.try(prepared_request)

  let req =
    base_request
    // Use POST for chat/completions.
    |> request.set_method(http.Post)
    // Auth header with bearer token.
    |> request.set_header("authorization", "Bearer " <> config.api_key)
    // JSON content type.
    |> request.set_header("content-type", "application/json")
    // Attach body as bits built from the JSON payload string.
    |> request.map(fn(_) { bit_array.from_string(payload) })

  // Execute the HTTP request and map network errors into our LlmError type.
  let sent =
    httpc.send_bits(req)
    |> result.map_error(fn(error) { HttpFailure(http_error_to_string(error)) })

  use resp <- result.try(sent)

  // Convert response body bits into a UTF-8 string.
  let body_bits =
    resp.body
    |> bit_array.to_string
    |> result.map_error(fn(_) { DecodeFailure("Response body is not UTF-8") })

  use body <- result.try(body_bits)

  // Check status code range. 2xx = success, otherwise treat as HTTP failure.
  case resp.status >= 200 && resp.status < 300 {
    True -> decode_completion(body)
    False ->
      Error(HttpFailure(
        "OpenAI status " <> int.to_string(resp.status) <> ": " <> body,
      ))
  }
}

// Read configuration from environment variables.
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

// Build JSON payload for the chat/completions endpoint.
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

// Parse the JSON response body to extract the assistant's message content.
fn decode_completion(body: String) -> Result(String, LlmError) {
  json.parse(body, completion_decoder())
  |> result.map(fn(content) { string.trim(content) })
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

// Turn a JSON DecodeError into a readable string for logging / debugging.
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

// Map low-level httpc.HttpError to a friendly String.
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

// Map ConnectError into a concise description.
fn format_connect_error(error: httpc.ConnectError) -> String {
  case error {
    httpc.Posix(code) -> code
    httpc.TlsAlert(code, detail) -> code <> " " <> detail
  }
}

// Strip any trailing slash from the base URL so we can safely append paths.
fn normalise_base(base: String) -> String {
  case string.ends_with(base, "/") {
    True -> string.drop_end(base, 1)
    False -> base
  }
}
// /// Future: call a local Agent SDK sidecar instead of direct OpenAI access.
// /// This function will proxy the same prompt payload to a trusted in-cluster
// /// orchestrator service once that component exists.
// // pub fn call_agent_sdk(input: String) -> Result(String, LlmError) {
// //   todo
// // }
