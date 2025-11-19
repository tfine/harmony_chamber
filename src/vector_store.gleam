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
    summary: String,
    content: String,
    kind: String,
    turn_index: Int,
  )
}

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

  let url = "https://api.pinecone.io/whoami"
  let request = build_request(url, http.Get, api_key, "")

  use req <- result.try(request)
  use resp <- result.try(send(req))
  use body <- result.try(body_as_string(resp.body))

  case resp.status {
    status if status >= 200 && status < 300 ->
      case json.parse(body, using: project_id_decoder()) {
        Ok(project_id) ->
          Ok(Pinecone(
            api_key: api_key,
            environment: environment,
            project_id: project_id,
            index: index,
          ))
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
        True -> Ok(Nil)
        False -> {
          use body <- result.try(body_as_string(resp.body))
          Error(HttpFailure("Pinecone upsert status " <> int.to_string(resp.status) <> ": " <> body))
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
    False ->
      Error(HttpFailure(
        "Pinecone query status "
          <> int.to_string(resp.status)
          <> ": "
          <> body,
      ))

    True ->
      case json.parse(body, using: match_list_decoder()) {
        Ok(matches) -> Ok(matches)
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

  let #(senator_id, bill_id, summary, content, kind, turn_index) = meta

  decode.success(QueryMatch(
    id: id,
    score: score,
    senator_id: senator_id,
    bill_id: bill_id,
    summary: summary,
    content: content,
    kind: kind,
    turn_index: turn_index,
  ))
}

fn metadata_decoder() -> decode.Decoder(#(String, String, String, String, String, Int)) {
  use senator_id <- decode.field("senator_id", decode.string)
  use bill_id <- decode.field("bill_id", decode.string)
  use summary <- decode.field("summary", decode.string)
  use content <- decode.optional_field("content", summary, decode.string)
  use kind <- decode.optional_field("kind", "debate_speech", decode.string)
  use turn_index <- decode.optional_field("turn_index", 0, decode.int)

  decode.success(#(senator_id, bill_id, summary, content, kind, turn_index))
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
