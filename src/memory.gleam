
import debate
import gleam/int
import gleam/json
import gleam/list
import gleam/result
import gleam/string
import llm_client
import senators
import session
import vector_store

pub type Memory {
  Memory(vector_index: vector_store.Pinecone)
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
    senator_id: String,
    kind: String,
    score: Float,
    turn_index: Int,
  )
}

pub fn init() -> Memory {
  case vector_store.connect() {
    Ok(index) -> Memory(vector_index: index)
    Error(error) -> Disabled(vector_error_to_string(error))
  }
}

pub fn enabled(memory: Memory) -> Bool {
  case memory {
    Memory(_) -> True
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
) -> Result(Nil, MemoryError) {
  let cleaned = string.trim(speech)

  case cleaned == "" {
    True -> Ok(Nil)
    False ->
      case memory {
        Disabled(_) -> Ok(Nil)
        Memory(vector_index) -> {
          use embedding <- result.try(
            llm_client.embed(cleaned)
            |> result.map_error(EmbeddingError)
          )

          let metadata =
            json.object([
              #("senator_id", json.string(senator.id)),
              #("senator_name", json.string(senator.name)),
              #("bill_id", json.string(bill.id)),
              #("bill_title", json.string(bill.title)),
              #("content", json.string(cleaned)),
              #("summary", json.string(summarise(cleaned))),
              #("kind", json.string("debate_speech")),
              #("turn_index", json.int(turn_index)),
              #("vote_intent", json.string(debate.vote_intent_label(intent))),
            ])

          let vector =
            vector_store.UpsertVector(
              id: vector_id(senator.id, bill.id, turn_index),
              values: embedding,
              metadata: metadata,
            )

          vector_store.upsert(vector_index, [vector])
          |> result.map_error(VectorError)
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
    Memory(vector_index) -> {
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
      summary: summary,
      content: content,
      kind: kind,
      turn_index: turn_index,
    ) = match

    MemoryHit(
      summary: summary,
      content: content,
      bill_id: bill_id,
      senator_id: senator_id,
      kind: kind,
      score: score,
      turn_index: turn_index,
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
