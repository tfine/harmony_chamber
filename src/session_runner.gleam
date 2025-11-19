import chamber
import debate
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import llm_client
import memory
import senators
import session

/// Advance the session a fixed number of steps with LLM-driven debate.
/// This centralises the fallback behaviour so both HTTP requests and the
/// background autopilot share identical orchestration.
pub fn run_steps(
  start: session.Session,
  roster: List(senators.Senator),
  steps: Int,
  mem: memory.Memory,
) -> session.Session {
  run_steps_loop(start, roster, 0, steps, mem)
}

fn run_steps_loop(
  current: session.Session,
  roster: List(senators.Senator),
  completed: Int,
  target: Int,
  mem: memory.Memory,
) -> session.Session {
  case completed >= target {
    True -> current
    False -> {
      case chamber.step_session(current, roster, mem) {
        Ok(updated) -> run_steps_loop(updated, roster, completed + 1, target, mem)
        Error(error) -> {
          let fallback_session = apply_fallback_decision(current, roster, error, mem)
          run_steps_loop(fallback_session, roster, completed + 1, target, mem)
        }
      }
    }
  }
}

fn apply_fallback_decision(
  current: session.Session,
  roster: List(senators.Senator),
  error: llm_client.LlmError,
  mem: memory.Memory,
) -> session.Session {
  let total = list.length(roster)
  let message = llm_client.error_to_string(error)

  case senator_at_pointer(current.next_speaker_index, roster) {
    None -> session.record_error(current, message)
    Some(senator) -> {
      io.println("LLM error for " <> senator.name <> ": " <> message)

      let bill_title = current.bill.title
      let fallback_speech =
        "Unable to retrieve my live remarks on "
        <> bill_title
        <> " because of a temporary communications issue ("
        <> message
        <> "). I remain engaged and will revisit my vote soon."

      let decision =
        debate.SpeakDecision(
          True,
          fallback_speech,
          debate.Undecided,
          "message_response",
          debate.NoProcedure,
        )

      let updated =
        current
        |> session.increment_llm_calls()
        |> session.apply_debate_decision(senator, decision)
        |> session.advance_speaker(total)
        |> session.record_error(message)

      case decision {
        debate.SpeakDecision(
          will_speak: True,
          speech: speech,
          vote_intent: intent,
          purpose: _,
          procedure: _,
        ) -> {
          let _ =
            memory.add_debate_turn(
              mem,
              senator,
              updated.bill,
              updated.next_turn_index - 1,
              speech,
              intent,
            )
          updated
        }
        _ -> updated
      }
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
