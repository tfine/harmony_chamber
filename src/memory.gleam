
// Vector-backed recall layer for debate context. Stores embeddings of past
// turns and retrieves them to ground future LLM calls.
import debate
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/result
import gleam/string
import envoy
import llm_client
import senators
import session
import vector_store

type AlertHook = fn(String) -> Nil

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
        Disabled(_) -> Ok(Nil)
        Memory(vector_index: _, worker: worker, ..) -> {
          process.send(worker, StoreTurn(
            senator: senator,
            bill: bill,
            turn_index: turn_index,
            speech: cleaned,
            intent: intent,
            purpose: purpose,
            procedure: procedure,
          ))
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
        |> result.map_error(EmbeddingError)
      )

      let filter =
        json.object([
          #(
            "senator_id",
            json.object([#("$eq", json.string(senator_id))]),
          ),
          #(
            "bill_id",
            json.object([#("$eq", json.string(bill_id))]),
          ),
        ])

      vector_store.query(vector_index, embedding, filter, limit)
      |> result.map(from_matches)
      |> result.map_error(VectorError)
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
  let mailbox = process.new_subject()

  let _pid =
    process.spawn(fn() {
      worker_loop(mailbox, index, alert_hook)
    })

  mailbox
}

fn worker_loop(
  mailbox: process.Subject(StoreMessage),
  index: vector_store.Pinecone,
  alert_hook: AlertHook,
) -> Nil {
  case process.receive_forever(mailbox) {
    StoreTurn(senator, bill, turn_index, speech, intent, purpose, procedure) -> {
      case persist_with_retry(
        index,
        senator,
        bill,
        turn_index,
        speech,
        intent,
        purpose,
        procedure,
        0,
      ) {
        Ok(_) -> Nil
        Error(error) ->
          alert_hook(
            "Persistent memory failure after retries: "
              <> memory_error_to_string(error),
          )
      }
      worker_loop(mailbox, index, alert_hook)
    }
  }
}

fn default_alert_hook() -> AlertHook {
  fn(message: String) {
    log_error("ALERT: " <> message)
  }
}

fn log_error(message: String) -> Nil {
  io.print_error("ERROR [memory]: " <> message <> "\n")
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
  case persist_turn(
    index,
    senator,
    bill,
    turn_index,
    speech,
    intent,
    purpose,
    procedure,
  ) {
    Ok(_) -> Ok(Nil)
    Error(error) ->
      case attempt < max_memory_retries && is_transient(error) {
        True -> {
          let delay =
            initial_memory_backoff_ms
            * power_of_two(attempt)

          log_error(
            "Transient memory error (attempt "
              <> int.to_string(attempt + 1)
              <> "): "
              <> memory_error_to_string(error)
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
  use embedding <- result.try(
    llm_client.embed(speech)
    |> result.map_error(EmbeddingError)
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

  vector_store.upsert(index, [vector])
  |> result.map_error(VectorError)
}

fn memory_error_to_string(error: MemoryError) -> String {
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
}

fn power_of_two(exponent: Int) -> Int {
  case exponent <= 0 {
    True -> 1
    False -> 2 * power_of_two(exponent - 1)
  }
}
