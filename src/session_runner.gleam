import chamber
import debate
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import llm_client
import senators
import session

/// Advance the session a fixed number of steps with LLM-driven debate.
/// This centralises the fallback behaviour so both HTTP requests and the
/// background autopilot share identical orchestration.
pub fn run_steps(
  start: session.Session,
  roster: List(senators.Senator),
  steps: Int,
) -> session.Session {
  run_steps_loop(start, roster, 0, steps)
}

fn run_steps_loop(
  current: session.Session,
  roster: List(senators.Senator),
  completed: Int,
  target: Int,
) -> session.Session {
  case completed >= target {
    True -> current
    False -> {
      case chamber.step_session(current, roster) {
        Ok(updated) -> run_steps_loop(updated, roster, completed + 1, target)
        Error(error) -> {
          let fallback_session = apply_fallback_decision(current, roster, error)
          run_steps_loop(fallback_session, roster, completed + 1, target)
        }
      }
    }
  }
}

fn apply_fallback_decision(
  current: session.Session,
  roster: List(senators.Senator),
  error: llm_client.LlmError,
) -> session.Session {
  let total = list.length(roster)
  let message = llm_client.error_to_string(error)

  case senator_at_pointer(current.next_speaker_index, roster) {
    None -> session.record_error(current, message)
    Some(senator) -> {
      io.println("LLM error for " <> senator.name <> ": " <> message)

      let fallback_speech =
        "Unable to retrieve my live remarks because of a temporary communications issue ("
        <> message
        <> "). I remain engaged with the Civic Resilience Act and will revisit my vote soon."

      let decision =
        debate.SpeakDecision(
          True,
          fallback_speech,
          debate.Undecided,
          "message_response",
          debate.NoProcedure,
        )

      current
      |> session.increment_llm_calls()
      |> session.apply_debate_decision(senator, decision)
      |> session.advance_speaker(total)
      |> session.record_error(message)
    }
  }
}

fn senator_at_pointer(
  index: Int,
  roster: List(senators.Senator),
) -> Option(senators.Senator) {
  case roster {
    [] -> None
    [head, ..tail] ->
      case index {
        0 -> Some(head)
        _ -> senator_at_pointer(index - 1, tail)
      }
  }
}
