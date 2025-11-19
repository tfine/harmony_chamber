import gleam/dynamic/decode
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import llm_client
import prompts
import senators

/// Request a custom roster order from the LLM and fall back to a deterministic
/// shuffle when the call fails.
pub fn prioritized_roster(
  roster: List(senators.Senator),
) -> List(senators.Senator) {
  case request_rotation(roster) {
    Ok(ids) -> apply_order(roster, ids)
    Error(error) -> {
      io.println(
        "Speaker ordering request failed: " <> llm_client.error_to_string(error),
      )
      deterministic_shuffle(roster)
    }
  }
}

fn request_rotation(
  roster: List(senators.Senator),
) -> Result(List(String), llm_client.LlmError) {
  let prompt = prompts.speaker_rotation_prompt(roster)
  use body <- result.try(llm_client.call_llm_with_timeout(prompt, 2500))
  parse_id_list(body)
}

fn parse_id_list(body: String) -> Result(List(String), llm_client.LlmError) {
  let cleaned = strip_fences(string.trim(body))

  case json.parse(cleaned, decode.list(decode.string)) {
    Ok(ids) -> Ok(ids)
    Error(error) -> {
      // Some models wrap output in prose; attempt a lenient CSV-ish fallback.
      case fallback_ids(cleaned) {
        Some(ids) -> Ok(ids)
        None -> Error(llm_client.DecodeFailure(json_error_to_string(error)))
      }
    }
  }
}

fn json_error_to_string(error: json.DecodeError) -> String {
  case error {
    json.UnexpectedEndOfInput -> "Unexpected end of input"
    json.UnexpectedByte(detail) -> "Unexpected byte: " <> detail
    json.UnexpectedSequence(detail) -> "Unexpected sequence: " <> detail
    json.UnableToDecode(errors) ->
      errors
      |> list.map(fn(err) {
        format_path(err.path)
          <> ": expected "
          <> err.expected
          <> ", found "
          <> err.found
      })
      |> string.join("; ")
  }
}

fn format_path(path: List(String)) -> String {
  case path {
    [] -> "(root)"
    _ -> string.join(path, ".")
  }
}

fn apply_order(
  roster: List(senators.Senator),
  ids: List(String),
) -> List(senators.Senator) {
  let prioritized =
    ids
    |> list.fold([], fn(acc, target) {
      case find_senator(roster, target) {
        None -> acc
        Some(senator) -> {
          case list.any(acc, fn(entry: senators.Senator) { entry.id == senator.id }) {
            True -> acc
            False -> [senator, ..acc]
          }
        }
      }
    })
    |> list.reverse

  let prioritized_ids =
    prioritized
    |> list.map(fn(senator) { senator.id })

  let remainder =
    roster
    |> list.filter(fn(senator) {
      list.contains(prioritized_ids, senator.id) == False
    })

  list.append(prioritized, deterministic_shuffle(remainder))
}

fn find_senator(
  roster: List(senators.Senator),
  target: String,
) -> Option(senators.Senator) {
  case roster {
    [] -> None
    [head, ..tail] ->
      case head.id == target {
        True -> Some(head)
        False -> find_senator(tail, target)
      }
  }
}

fn deterministic_shuffle(
  roster: List(senators.Senator),
) -> List(senators.Senator) {
  roster
  |> list.sort(fn(a, b) {
    int.compare(speaker_weight(a.id), speaker_weight(b.id))
  })
}

fn strip_fences(text: String) -> String {
  case string.starts_with(text, "```") {
    False -> text
    True -> {
      let without_prefix =
        text
        |> string.split("```")
        |> list.filter(fn(part) { string.length(string.trim(part)) > 0 })
      case without_prefix {
        [inner, ..] -> string.trim(inner)
        [] -> text
      }
    }
  }
}

fn fallback_ids(text: String) -> Option(List(String)) {
  let cleaned =
    text
    |> string.replace("\n", ",")
    |> string.replace("[", "")
    |> string.replace("]", "")
    |> string.split(",")
    |> list.map(string.trim)
    |> list.map(strip_quotes)
    |> list.filter(fn(part) { string.length(part) > 0 })

  case cleaned {
    [] -> None
    _ -> Some(cleaned)
  }
}

fn strip_quotes(text: String) -> String {
  let len = string.length(text)
  case len >= 2 && string.starts_with(text, "\"") && string.ends_with(text, "\"") {
    True -> string.slice(text, 1, len - 1)
    False -> text
  }
}

fn speaker_weight(identifier: String) -> Int {
  identifier
  |> string.to_utf_codepoints
  |> list.fold(17, fn(weight, codepoint) {
    let value = string.utf_codepoint_to_int(codepoint)
    weight * 1_103_515 + value + 97_183
  })
}
