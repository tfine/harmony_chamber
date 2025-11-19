import gleam/float
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/result
import vector_store

/// Minimal storage drills to prove Pinecone connectivity end-to-end.
///
/// - Grabs live index dimension from Pinecone
/// - Upserts two synthetic vectors with metadata matching our schema
/// - Queries back the first vector so we can see a hit in-line
///
/// Call `print_smoke_demo()` from `gleam run -m pinecone_scripts` or
/// directly invoke `smoke_seed_and_query()` from elsewhere.
pub fn smoke_seed_and_query() -> Result(List(vector_store.QueryMatch), vector_store.Error) {
  use pinecone <- result.try(vector_store.connect())
  use dimension <- result.try(vector_store.describe_index_stats(pinecone))

  let vector_a = ramp_vector(dimension, 0.01)
  let vector_b = ramp_vector(dimension, 0.02)

  let metadata_a =
    json.object([
      #("senator_id", json.string("S-TST-001")),
      #("bill_id", json.string("BILL-TEST-001")),
      #("summary", json.string("Synthetic debate summary A")),
      #("content", json.string("Calm opening statement from the storage smoke test.")),
      #("kind", json.string("debate_speech")),
      #("turn_index", json.int(0)),
    ])

  let metadata_b =
    json.object([
      #("senator_id", json.string("S-TST-002")),
      #("bill_id", json.string("BILL-TEST-001")),
      #("summary", json.string("Synthetic rebuttal B")),
      #("content", json.string("Counterpoint from the smoke test to exercise recall.")),
      #("kind", json.string("debate_speech")),
      #("turn_index", json.int(1)),
    ])

  let vectors = [
    vector_store.UpsertVector(id: "smoke-A", values: vector_a, metadata: metadata_a),
    vector_store.UpsertVector(id: "smoke-B", values: vector_b, metadata: metadata_b),
  ]

  use _ <- result.try(vector_store.upsert(pinecone, vectors))

  // Query against the first vector looking for the best 3 hits.
  vector_store.query(pinecone, vector_a, json.null(), 3)
}

/// Convenience entrypoint for quick CLI runs.
pub fn print_smoke_demo() -> Nil {
  case smoke_seed_and_query() {
    Ok(matches) -> {
      io.println("Pinecone smoke test succeeded; top matches:")
      matches
      |> list.each(fn(match) {
        io.println(
          match.id
            <> " score="
            <> float.to_string(match.score)
            <> " senator="
            <> match.senator_id
            <> " turn="
            <> int.to_string(match.turn_index),
        )
      })
    }
    Error(error) ->
      io.println("Pinecone smoke test failed: " <> vector_error_to_string(error))
  }
}

/// Default entrypoint so `gleam run -m pinecone_scripts` works.
pub fn main() {
  print_smoke_demo()
}

fn ramp_vector(dimension: Int, step: Float) -> List(Float) {
  list.range(0, dimension - 1)
  |> list.map(fn(i) { int.to_float(i) *. step })
}

fn vector_error_to_string(error: vector_store.Error) -> String {
  case error {
    vector_store.MissingApiKey -> "Missing PINECONE_API_KEY"
    vector_store.MissingEnvironment -> "Missing PINECONE_ENVIRONMENT"
    vector_store.MissingIndexName -> "Missing PINECONE_INDEX"
    vector_store.DecodeFailure(msg) -> "Decode failure: " <> msg
    vector_store.HttpFailure(msg) -> "HTTP failure: " <> msg
  }
}
