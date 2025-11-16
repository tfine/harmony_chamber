import gleam/result
import gleam/string
import gleam/option.{type Option, None, Some}
import session
import simplifile

const snapshot_tag = "harmony_snapshot_v4"

@external(erlang, "erlang", "term_to_binary")
fn term_to_binary(value: a) -> BitArray

@external(erlang, "session_store_ffi", "safe_binary_to_term")
fn safe_binary_to_term(binary: BitArray) -> Result(session.Session, String)

/// Persist the current session to disk using Erlang's external term format.
pub fn persist(sess: session.Session, path: String) -> Result(Nil, String) {
  let payload = #(snapshot_tag, sess)
  simplifile.write_bits(to: path, bits: term_to_binary(payload))
  |> result.map_error(file_error_to_string)
}

/// Attempt to load a session snapshot from disk. Returns `Ok(None)` when the
/// file does not exist so callers can fall back to a fresh session.
pub fn load(path: String) -> Result(Option(session.Session), String) {
  case simplifile.read_bits(from: path) {
    Ok(bits) ->
      case safe_binary_to_term(bits) {
        Ok(sess) -> Ok(Some(sess))
        Error(message) -> {
          case message {
            "invalid_snapshot" -> Ok(None)
            _ -> Error(message)
          }
        }
      }
    Error(error) -> {
      case file_error_to_string(error) {
        "not_found" -> Ok(None)
        message -> Error(message)
      }
    }
  }
}

fn file_error_to_string(error: simplifile.FileError) -> String {
  case error {
    simplifile.Enoent -> "not_found"
    _ -> string.inspect(error)
  }
}
