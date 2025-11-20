import envoy
import gleam/bit_array
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/result
import gleam/string
import gleam/option.{type Option, None, Some}

pub type Pinecone {
  Pinecone(
    api_key: String,
    environment: String,
    project_id: String,
    index: String,
  )
}

pub type Error {
  MissingApiKey
  MissingEnvironment
  MissingIndexName
  HttpFailure(String)
  DecodeFailure(String)
}

pub type UpsertVector {
  UpsertVector(id: String, values: List(Float), metadata: json.Json)
}

pub type QueryMatch {
  QueryMatch(
    id: String,
    score: Float,
    senator_id: String,
    bill_id: String,
    bill_title: String,
    summary: String,
    content: String,
    kind: String,
    turn_index: Int,
    vote_intent: String,
    purpose: String,
    // Time legislation specific fields
    time_horizon: Option(String),
    status: Option(String),
    timestamp: Option(String),
    todd_energy: Option(String),
    delaney_energy: Option(String),
    actual_minutes: Option(Int),
  )
}

// Connect to Pinecone, verifying credentials via /actions/whoami.
pub fn connect() -> Result(Pinecone, Error) {
  let api_key =
    envoy.get("PINECONE_API_KEY")
    |> result.map_error(fn(_) { MissingApiKey })

  let environment =
    envoy.get("PINECONE_ENVIRONMENT")
    |> result.map_error(fn(_) { MissingEnvironment })

  let index =
    envoy.get("PINECONE_INDEX")
    |> result.map_error(fn(_) { MissingIndexName })

  use api_key <- result.try(api_key)
  use environment <- result.try(environment)
  use index <- result.try(index)

  // Pinecone whoami now lives under /actions (old /whoami returns 404)
  // Pinecone whoami is under /actions; /whoami returns 404.
  let url = "https://api.pinecone.io/actions/whoami"
  let request = build_request(url, http.Get, api_key, "")

  use req <- result.try(request)
  use resp <- result.try(send(req))
  use body <- result.try(body_as_string(resp.body))

  case resp.status {
    status if status >= 200 && status < 300 ->
      case json.parse(body, using: project_id_decoder()) {
        Ok(project_id) -> {
          log_info(
            "Connected to Pinecone project="
              <> project_id
              <> " index="
              <> index,
          )
          Ok(Pinecone(
            api_key: api_key,
            environment: environment,
            project_id: project_id,
            index: index,
          ))
        }
        Error(error) -> Error(DecodeFailure(format_decode_error(error)))
      }

    _ ->
      Error(HttpFailure(
        "Pinecone whoami returned status "
          <> int.to_string(resp.status)
          <> ": "
          <> body,
      ))
  }
}

pub fn upsert(index: Pinecone, vectors: List(UpsertVector)) -> Result(Nil, Error) {
  case vectors {
    [] -> Ok(Nil)
    _ -> {
      let url = index_host(index) <> "/vectors/upsert"
      let payload =
        vectors
        |> list.map(fn(vector) {
          let UpsertVector(id:, values:, metadata:) = vector
          json.object([
            #("id", json.string(id)),
            #("values", json.array(values, json.float)),
            #("metadata", metadata),
          ])
        })
        |> json.array(fn(item) { item })
        |> fn(items) { json.object([#("vectors", items)]) }
        |> json.to_string

      let request = build_request(url, http.Post, index.api_key, payload)

      use req <- result.try(request)
      use resp <- result.try(send(req))
      case resp.status >= 200 && resp.status < 300 {
        True -> {
          log_info(
            "Upserted "
              <> int.to_string(list.length(vectors))
              <> " vectors",
          )
          Ok(Nil)
        }
        False -> {
          use body <- result.try(body_as_string(resp.body))
          let message =
            "Pinecone upsert status "
              <> int.to_string(resp.status)
              <> ": "
              <> body
          log_error(message)
          Error(HttpFailure(message))
        }
      }
    }
  }
}

pub fn query(
  index: Pinecone,
  vector: List(Float),
  filter: json.Json,
  top_k: Int,
) -> Result(List(QueryMatch), Error) {
  let url = index_host(index) <> "/query"

  let payload =
    json.object([
      #("vector", json.array(vector, json.float)),
      #("filter", filter),
      #("topK", json.int(top_k)),
      #("includeMetadata", json.bool(True)),
    ])
    |> json.to_string

  let request = build_request(url, http.Post, index.api_key, payload)

  use req <- result.try(request)
  use resp <- result.try(send(req))
  use body <- result.try(body_as_string(resp.body))

  case resp.status >= 200 && resp.status < 300 {
    False -> {
      let message =
        "Pinecone query status "
          <> int.to_string(resp.status)
          <> ": "
          <> body
      log_error(message)
      Error(HttpFailure(message))
    }

    True ->
      case json.parse(body, using: match_list_decoder()) {
        Ok(matches) -> {
          log_info(
            "Query returned "
              <> int.to_string(list.length(matches))
              <> " matches (top_k="
              <> int.to_string(top_k)
              <> ")",
          )
          Ok(matches)
        }
        Error(error) -> Error(DecodeFailure(format_decode_error(error)))
      }
  }
}

/// Fetch index stats to discover attributes like the embedding dimension.
pub fn describe_index_stats(index: Pinecone) -> Result(Int, Error) {
  let url = index_host(index) <> "/describe_index_stats"
  let request = build_request(url, http.Post, index.api_key, "{}")

  use req <- result.try(request)
  use resp <- result.try(send(req))
  use body <- result.try(body_as_string(resp.body))

  case resp.status >= 200 && resp.status < 300 {
    False -> {
      let message =
        "Pinecone describe_index_stats status "
          <> int.to_string(resp.status)
          <> ": "
          <> body
      log_error(message)
      Error(HttpFailure(message))
    }

    True ->
      case json.parse(body, using: index_stats_decoder()) {
        Ok(dimension) -> {
          log_info("Index dimension=" <> int.to_string(dimension))
          Ok(dimension)
        }
        Error(error) -> Error(DecodeFailure(format_decode_error(error)))
      }
  }
}

fn index_host(index: Pinecone) -> String {
  "https://"
    <> index.index
    <> "-"
    <> index.project_id
    <> ".svc."
    <> index.environment
    <> ".pinecone.io"
}

fn build_request(
  url: String,
  method: http.Method,
  api_key: String,
  body: String,
) -> Result(request.Request(BitArray), Error) {
  let prepared =
    request.to(url)
    |> result.map_error(fn(_) { HttpFailure("Invalid Pinecone URL: " <> url) })

  use base <- result.try(prepared)

  Ok(
    base
    |> request.set_method(method)
    |> request.set_header("Api-Key", api_key)
    |> request.set_header("content-type", "application/json")
    |> request.map(fn(_) { bit_array.from_string(body) }),
  )
}

fn send(req: request.Request(BitArray)) {
  httpc.send_bits(req)
  |> result.map_error(fn(error) { HttpFailure(http_error_to_string(error)) })
}

fn body_as_string(body: BitArray) -> Result(String, Error) {
  body
  |> bit_array.to_string
  |> result.map_error(fn(_) { DecodeFailure("Response body is not UTF-8") })
}

fn project_id_decoder() -> decode.Decoder(String) {
  use project <- decode.field("project_name", decode.string)
  decode.success(project)
}

fn match_list_decoder() -> decode.Decoder(List(QueryMatch)) {
  use matches <- decode.field("matches", decode.list(match_decoder()))
  decode.success(matches)
}

fn match_decoder() -> decode.Decoder(QueryMatch) {
  use id <- decode.field("id", decode.string)
  use score <- decode.field("score", decode.float)
  use meta <- decode.field("metadata", metadata_decoder())

  let #(
    senator_id,
    bill_id,
    bill_title,
    summary,
    content,
    kind,
    turn_index,
    vote_intent,
    purpose,
    time_horizon,
    status,
    timestamp,
    todd_energy,
    delaney_energy,
    actual_minutes,
  ) = meta

  decode.success(QueryMatch(
    id: id,
    score: score,
    senator_id: senator_id,
    bill_id: bill_id,
    bill_title: bill_title,
    summary: summary,
    content: content,
    kind: kind,
    turn_index: turn_index,
    vote_intent: vote_intent,
    purpose: purpose,
    time_horizon: time_horizon,
    status: status,
    timestamp: timestamp,
    todd_energy: todd_energy,
    delaney_energy: delaney_energy,
    actual_minutes: actual_minutes,
  ))
}

fn metadata_decoder() -> decode.Decoder(
  #(
    String,
    String,
    String,
    String,
    String,
    String,
    Int,
    String,
    String,
    Option(String),
    Option(String),
    Option(String),
    Option(String),
    Option(String),
    Option(Int),
  ),
) {
  use senator_id <- decode.optional_field("senator_id", "", decode.string)
  use bill_id <- decode.optional_field("bill_id", "", decode.string)
  use bill_title <- decode.optional_field("bill_title", "", decode.string)
  use summary <- decode.field("summary", decode.string)
  use content <- decode.optional_field("content", summary, decode.string)
  use kind <- decode.optional_field("kind", "debate_speech", decode.string)
  use turn_index <- decode.optional_field("turn_index", 0, decode.int)
  use vote_intent <- decode.optional_field("vote_intent", "undecided", decode.string)
  use purpose <- decode.optional_field("purpose", "new_argument", decode.string)
  // Time legislation specific fields
  use time_horizon_value <- decode.optional_field("time_horizon", "", decode.string)
  use status_value <- decode.optional_field("status", "", decode.string)
  use timestamp_value <- decode.optional_field("timestamp", "", decode.string)
  use todd_energy_value <- decode.optional_field("todd_energy", "", decode.string)
  use delaney_energy_value <- decode.optional_field("delaney_energy", "", decode.string)
  use actual_minutes_value <- decode.optional_field("actual_minutes", 0, decode.int)

  let time_horizon = optional_string(time_horizon_value)
  let status = optional_string(status_value)
  let timestamp = optional_string(timestamp_value)
  let todd_energy = optional_string(todd_energy_value)
  let delaney_energy = optional_string(delaney_energy_value)
  let actual_minutes = optional_positive_int(actual_minutes_value)

  decode.success(#(
    senator_id,
    bill_id,
    bill_title,
    summary,
    content,
    kind,
    turn_index,
    vote_intent,
    purpose,
    time_horizon,
    status,
    timestamp,
    todd_energy,
    delaney_energy,
    actual_minutes,
  ))
}

fn optional_string(value: String) -> Option(String) {
  case string.trim(value) {
    "" -> None
    _ -> Some(value)
  }
}

fn optional_positive_int(value: Int) -> Option(Int) {
  case value <= 0 {
    True -> None
    False -> Some(value)
  }
}

fn index_stats_decoder() -> decode.Decoder(Int) {
  use dimension <- decode.field("dimension", decode.int)
  decode.success(dimension)
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

fn log_info(message: String) -> Nil {
  io.println("INFO [pinecone]: " <> message)
}

fn log_error(message: String) -> Nil {
  io.print_error("ERROR [pinecone]: " <> message <> "\n")
}

fn format_connect_error(error: httpc.ConnectError) -> String {
  case error {
    httpc.Posix(code) -> code
    httpc.TlsAlert(code, detail) -> code <> " " <> detail
  }
}
