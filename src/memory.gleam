// Vector-backed recall layer for debate context. Stores embeddings of past
// turns and retrieves them to ground future LLM calls.
import debate
import envoy
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/result
import gleam/string
import llm_client
import senators
import session
import vector_store

type AlertHook =
  fn(String) -> Nil

pub type Memory {
  Memory(
    vector_index: vector_store.Pinecone,
    worker: process.Subject(StoreMessage),
    alert_hook: AlertHook,
  )
  Disabled(reason: String)
}

pub type MemoryError {
  EmbeddingError(llm_client.LlmError)
  VectorError(vector_store.Error)
  DecodeError(String)
}

pub type MemoryHit {
  MemoryHit(
    summary: String,
    content: String,
    bill_id: String,
    bill_title: String,
    senator_id: String,
    kind: String,
    score: Float,
    turn_index: Int,
    vote_intent: String,
    purpose: String,
  )
}

const max_memory_retries = 3

const initial_memory_backoff_ms = 200

pub fn init() -> Memory {
  let mode = memory_mode()
  case string.lowercase(mode) == "production" {
    False -> Disabled("Memory disabled in mode: " <> mode)
    True ->
      case vector_store.connect() {
        Ok(index) -> {
          let hook = default_alert_hook()
          Memory(
            vector_index: index,
            worker: start_worker(index, hook),
            alert_hook: hook,
          )
        }
        Error(error) -> Disabled(vector_error_to_string(error))
      }
  }
}

// Future: tie Memory to agent intentions/plans so retrieval uses both role and goal.

pub fn enabled(memory: Memory) -> Bool {
  case memory {
    Memory(..) -> True
    Disabled(_) -> False
  }
}

pub fn add_debate_turn(
  memory: Memory,
  senator: senators.Senator,
  bill: session.Bill,
  turn_index: Int,
  speech: String,
  intent: debate.VoteIntent,
  purpose: String,
  procedure: debate.Procedure,
) -> Result(Nil, MemoryError) {
  let cleaned = string.trim(speech)

  case cleaned == "" {
    True -> Ok(Nil)
    False ->
      case memory {
        Disabled(reason) -> {
          log_info(
            "Memory disabled ("
            <> reason
            <> "); skipping store for "
            <> senator.id,
          )
          Ok(Nil)
        }
        Memory(vector_index: _, worker: worker, ..) -> {
          log_info(
            "Sending debate turn to memory worker for "
            <> senator.id
            <> " #"
            <> int.to_string(turn_index),
          )
          process.send(
            worker,
            StoreTurn(
              senator: senator,
              bill: bill,
              turn_index: turn_index,
              speech: cleaned,
              intent: intent,
              purpose: purpose,
              procedure: procedure,
            ),
          )
          Ok(Nil)
        }
      }
  }
}

pub fn add_intentions_snapshot(
  memory: Memory,
  senator: senators.Senator,
  bill: session.Bill,
  turn_index: Int,
  intentions: List(String),
) -> Result(Nil, MemoryError) {
  let cleaned =
    intentions
    |> list.map(fn(line) { string.trim(line) })
    |> list.filter(fn(line) { line != "" })

  case cleaned {
    [] -> Ok(Nil)
    _ ->
      case memory {
        Disabled(reason) -> {
          log_info(
            "Memory disabled ("
            <> reason
            <> "); skipping intentions store for "
            <> senator.id,
          )
          Ok(Nil)
        }
        Memory(vector_index: _, worker: worker, ..) -> {
          log_info(
            "Sending intentions snapshot to memory worker for "
            <> senator.id
            <> " #"
            <> int.to_string(turn_index),
          )
          process.send(
            worker,
            StoreIntentions(
              senator: senator,
              bill: bill,
              turn_index: turn_index,
              lines: cleaned,
            ),
          )
          Ok(Nil)
        }
      }
  }
}

pub fn recall(
  memory: Memory,
  senator_id: String,
  bill_id: String,
  query_text: String,
  limit: Int,
) -> Result(List(MemoryHit), MemoryError) {
  case memory {
    Disabled(_) -> Ok([])
    Memory(vector_index: vector_index, ..) -> {
      use embedding <- result.try(
        llm_client.embed(query_text)
        |> result.map_error(EmbeddingError),
      )

      let filters = recall_filters(senator_id, bill_id)
      query_with_fallback(vector_index, embedding, filters, limit)
    }
  }
}

fn from_matches(matches: List(vector_store.QueryMatch)) -> List(MemoryHit) {
  matches
  |> list.map(fn(match) {
    let vector_store.QueryMatch(
      id: _,
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
    ) = match

    MemoryHit(
      summary: summary,
      content: content,
      bill_id: bill_id,
      bill_title: bill_title,
      senator_id: senator_id,
      kind: kind,
      score: score,
      turn_index: turn_index,
      vote_intent: vote_intent,
      purpose: purpose,
    )
  })
}

fn vector_id(senator_id: String, bill_id: String, turn_index: Int) -> String {
  senator_id <> "-" <> bill_id <> "-" <> int.to_string(turn_index)
}

fn summarise(text: String) -> String {
  let cleaned = string.trim(text)
  case string.length(cleaned) > 240 {
    True -> string.slice(cleaned, 0, 237) <> "..."
    False -> cleaned
  }
}

fn vector_error_to_string(error: vector_store.Error) -> String {
  case error {
    vector_store.MissingApiKey -> "Missing PINECONE_API_KEY"
    vector_store.MissingEnvironment -> "Missing PINECONE_ENVIRONMENT"
    vector_store.MissingIndexName -> "Missing PINECONE_INDEX"
    vector_store.HttpFailure(message) -> message
    vector_store.DecodeFailure(message) -> message
  }
}

fn start_worker(
  index: vector_store.Pinecone,
  alert_hook: AlertHook,
) -> process.Subject(StoreMessage) {
  let handshake: process.Subject(process.Subject(StoreMessage)) =
    process.new_subject()

  let _pid =
    process.spawn(fn() {
      let mailbox = process.new_subject()
      process.send(handshake, mailbox)
      log_info("Memory worker started")
      worker_loop(mailbox, index, alert_hook)
    })

  process.receive_forever(handshake)
}

fn worker_loop(
  mailbox: process.Subject(StoreMessage),
  index: vector_store.Pinecone,
  alert_hook: AlertHook,
) -> Nil {
  let message = process.receive_forever(mailbox)
  log_info("Memory worker: Message received, processing...")

  case message {
    StoreTurn(senator, bill, turn_index, speech, intent, purpose, procedure) -> {
      log_info(
        "Memory worker received StoreTurn for "
        <> senator.id
        <> " #"
        <> int.to_string(turn_index),
      )
      case
        persist_with_retry(
          index,
          senator,
          bill,
          turn_index,
          speech,
          intent,
          purpose,
          procedure,
          0,
        )
      {
        Ok(_) -> {
          log_info(
            "Stored memory turn "
            <> senator.id
            <> " #"
            <> int.to_string(turn_index)
            <> " ("
            <> bill.id
            <> ")",
          )
          Nil
        }
        Error(error) ->
          alert_hook(
            "Persistent memory failure after retries: "
            <> error_to_string(error),
          )
      }
      worker_loop(mailbox, index, alert_hook)
    }
    StoreIntentions(senator, bill, turn_index, lines) -> {
      log_info(
        "Memory worker received StoreIntentions for "
        <> senator.id
        <> " #"
        <> int.to_string(turn_index),
      )
      case
        persist_intentions_with_retry(
          index,
          senator,
          bill,
          turn_index,
          lines,
          0,
        )
      {
        Ok(_) -> {
          log_info(
            "Stored intentions snapshot for "
            <> senator.id
            <> " ("
            <> bill.id
            <> ")",
          )
          Nil
        }
        Error(error) ->
          alert_hook(
            "Intentions store failed after retries: " <> error_to_string(error),
          )
      }
      worker_loop(mailbox, index, alert_hook)
    }
  }
}

fn default_alert_hook() -> AlertHook {
  fn(message: String) { log_error("ALERT: " <> message) }
}

fn log_error(message: String) -> Nil {
  io.print_error("ERROR [memory]: " <> message <> "\n")
}

fn log_info(message: String) -> Nil {
  io.print("INFO [memory]: " <> message <> "\n")
}

fn persist_with_retry(
  index: vector_store.Pinecone,
  senator: senators.Senator,
  bill: session.Bill,
  turn_index: Int,
  speech: String,
  intent: debate.VoteIntent,
  purpose: String,
  procedure: debate.Procedure,
  attempt: Int,
) -> Result(Nil, MemoryError) {
  case
    persist_turn(
      index,
      senator,
      bill,
      turn_index,
      speech,
      intent,
      purpose,
      procedure,
    )
  {
    Ok(_) -> Ok(Nil)
    Error(error) ->
      case attempt < max_memory_retries && is_transient(error) {
        True -> {
          let delay = initial_memory_backoff_ms * power_of_two(attempt)

          log_error(
            "Transient memory error (attempt "
            <> int.to_string(attempt + 1)
            <> "): "
            <> error_to_string(error)
            <> " — retrying in "
            <> int.to_string(delay)
            <> "ms",
          )
          process.sleep(delay)
          persist_with_retry(
            index,
            senator,
            bill,
            turn_index,
            speech,
            intent,
            purpose,
            procedure,
            attempt + 1,
          )
        }
        False -> Error(error)
      }
  }
}

fn persist_intentions_with_retry(
  index: vector_store.Pinecone,
  senator: senators.Senator,
  bill: session.Bill,
  turn_index: Int,
  lines: List(String),
  attempt: Int,
) -> Result(Nil, MemoryError) {
  case persist_intentions(index, senator, bill, turn_index, lines) {
    Ok(_) -> Ok(Nil)
    Error(error) ->
      case attempt < max_memory_retries && is_transient(error) {
        True -> {
          let delay = initial_memory_backoff_ms * power_of_two(attempt)

          log_error(
            "Transient intentions store error (attempt "
            <> int.to_string(attempt + 1)
            <> "): "
            <> error_to_string(error)
            <> " — retrying in "
            <> int.to_string(delay)
            <> "ms",
          )
          process.sleep(delay)
          persist_intentions_with_retry(
            index,
            senator,
            bill,
            turn_index,
            lines,
            attempt + 1,
          )
        }
        False -> Error(error)
      }
  }
}

fn is_transient(error: MemoryError) -> Bool {
  case error {
    EmbeddingError(llm_client.HttpFailure(_)) -> True
    VectorError(vector_store.HttpFailure(_)) -> True
    _ -> False
  }
}

fn persist_turn(
  index: vector_store.Pinecone,
  senator: senators.Senator,
  bill: session.Bill,
  turn_index: Int,
  speech: String,
  intent: debate.VoteIntent,
  purpose: String,
  procedure: debate.Procedure,
) -> Result(Nil, MemoryError) {
  log_info(
    "persist_turn: Embedding speech for "
    <> senator.id
    <> " #"
    <> int.to_string(turn_index),
  )

  use embedding <- result.try(
    llm_client.embed(speech)
    |> result.map_error(EmbeddingError),
  )

  log_info(
    "persist_turn: Creating vector for "
    <> senator.id
    <> " #"
    <> int.to_string(turn_index),
  )

  let metadata =
    json.object([
      #("senator_id", json.string(senator.id)),
      #("senator_name", json.string(senator.name)),
      #("bill_id", json.string(bill.id)),
      #("bill_title", json.string(bill.title)),
      #("bill_summary", json.string(bill.summary)),
      #("content", json.string(speech)),
      #("summary", json.string(summarise(speech))),
      #("kind", json.string("debate_speech")),
      #("turn_index", json.int(turn_index)),
      #("vote_intent", json.string(debate.vote_intent_label(intent))),
      #("purpose", json.string(purpose)),
      #("procedure", json.string(debate.procedure_label(procedure))),
    ])

  let vector =
    vector_store.UpsertVector(
      id: vector_id(senator.id, bill.id, turn_index),
      values: embedding,
      metadata: metadata,
    )

  log_info(
    "persist_turn: Upserting to Pinecone for "
    <> senator.id
    <> " #"
    <> int.to_string(turn_index),
  )

  let result =
    vector_store.upsert(index, [vector])
    |> result.map_error(VectorError)

  case result {
    Ok(_) ->
      log_info(
        "persist_turn: Successfully upserted "
        <> senator.id
        <> " #"
        <> int.to_string(turn_index),
      )
    Error(error) ->
      log_error(
        "persist_turn: Failed to upsert "
        <> senator.id
        <> " #"
        <> int.to_string(turn_index)
        <> ": "
        <> error_to_string(error),
      )
  }

  result
}

fn persist_intentions(
  index: vector_store.Pinecone,
  senator: senators.Senator,
  bill: session.Bill,
  turn_index: Int,
  lines: List(String),
) -> Result(Nil, MemoryError) {
  let body = intentions_body(lines)

  use embedding <- result.try(
    llm_client.embed(body)
    |> result.map_error(EmbeddingError),
  )

  let metadata =
    json.object([
      #("senator_id", json.string(senator.id)),
      #("senator_name", json.string(senator.name)),
      #("bill_id", json.string(bill.id)),
      #("bill_title", json.string(bill.title)),
      #("content", json.string(body)),
      #("summary", json.string(summarise(body))),
      #("kind", json.string("senator_intentions")),
      #("turn_index", json.int(turn_index)),
      #(
        "intentions",
        lines
          |> json.array(fn(line) { json.string(line) }),
      ),
    ])

  let vector =
    vector_store.UpsertVector(
      id: intentions_vector_id(senator.id, bill.id, turn_index),
      values: embedding,
      metadata: metadata,
    )

  vector_store.upsert(index, [vector])
  |> result.map_error(VectorError)
}

fn query_with_fallback(
  index: vector_store.Pinecone,
  embedding: List(Float),
  filters: List(json.Json),
  limit: Int,
) -> Result(List(MemoryHit), MemoryError) {
  case filters {
    [] -> Ok([])
    [filter, ..rest] ->
      case
        vector_store.query(index, embedding, filter, limit)
        |> result.map(from_matches)
        |> result.map_error(VectorError)
      {
        Ok([]) -> query_with_fallback(index, embedding, rest, limit)
        other -> other
      }
  }
}

fn recall_filters(senator_id: String, bill_id: String) -> List(json.Json) {
  let senator_clause = equality_filter(senator_id)
  let bill_clause = equality_filter(bill_id)

  [
    json.object([#("senator_id", senator_clause), #("bill_id", bill_clause)]),
    json.object([#("senator_id", senator_clause)]),
    json.object([#("bill_id", bill_clause)]),
    json.null(),
  ]
}

fn equality_filter(value: String) -> json.Json {
  json.object([#("$eq", json.string(value))])
}

pub fn error_to_string(error: MemoryError) -> String {
  case error {
    EmbeddingError(inner) -> llm_client.error_to_string(inner)
    VectorError(inner) -> vector_error_to_string(inner)
    DecodeError(message) -> message
  }
}

fn memory_mode() -> String {
  case envoy.get("HARMONY_MEMORY_MODE") {
    Ok(value) -> value
    Error(_) -> "development"
  }
}

pub type StoreMessage {
  StoreTurn(
    senator: senators.Senator,
    bill: session.Bill,
    turn_index: Int,
    speech: String,
    intent: debate.VoteIntent,
    purpose: String,
    procedure: debate.Procedure,
  )
  StoreIntentions(
    senator: senators.Senator,
    bill: session.Bill,
    turn_index: Int,
    lines: List(String),
  )
}

fn power_of_two(exponent: Int) -> Int {
  case exponent <= 0 {
    True -> 1
    False -> 2 * power_of_two(exponent - 1)
  }
}

fn intentions_body(lines: List(String)) -> String {
  string.join(lines, "\n")
}

fn intentions_vector_id(
  senator_id: String,
  bill_id: String,
  turn_index: Int,
) -> String {
  senator_id <> "-" <> bill_id <> "-intentions-" <> int.to_string(turn_index)
}
