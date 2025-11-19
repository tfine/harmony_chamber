import chamber
import debate
import gleam/io
import gleam/list
import gleam/int
import gleam/option.{type Option, None, Some}
import llm_client
import memory
import senators
import senator_agents
import session
import simplifile
import gleam/bit_array
import gleam/string
import gleam/result

/// Advance the session a fixed number of steps with LLM-driven debate.
/// This centralises the fallback behaviour so both HTTP requests and the
/// background autopilot share identical orchestration.
pub fn run_steps(
  start: session.Session,
  roster: List(senators.Senator),
  steps: Int,
  mem: memory.Memory,
  agents: senator_agents.Registry,
) -> session.Session {
  run_steps_loop(start, roster, 0, steps, mem, agents)
}

fn run_steps_loop(
  current: session.Session,
  roster: List(senators.Senator),
  completed: Int,
  target: Int,
  mem: memory.Memory,
  agents: senator_agents.Registry,
) -> session.Session {
  case completed >= target {
    True -> current
    False -> {
      case chamber.step_session(current, roster, agents, mem) {
        Ok(updated) -> run_steps_loop(updated, roster, completed + 1, target, mem, agents)
        Error(error) -> {
          let fallback_session = apply_fallback_decision(current, roster, error, mem)
          run_steps_loop(fallback_session, roster, completed + 1, target, mem, agents)
        }
      }
    }
  }
}

/// Render the full proceedings as text and write to `path`.
/// Downstream callers should ignore failures (e.g. out-of-disk).
pub fn publish_proceedings(
  sess: session.Session,
  path: String,
) -> Result(Nil, String) {
  render_proceedings(sess)
  |> bit_array.from_string
  |> fn(bits) { simplifile.write_bits(to: path, bits: bits) }
  |> result.map_error(file_error_to_string)
}

/// Suggest a filename for proceedings based on the bill id.
pub fn default_proceedings_path(sess: session.Session) -> String {
  let bill_id =
    sess.bill.id
    |> string.lowercase
    |> string.replace(" ", "_")
  "proceedings_" <> bill_id <> ".txt"
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
          None,
          None,
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
          purpose: purpose,
          procedure: procedure,
          amendment_summary: _,
          amendment_rationale: _,
        ) -> {
          let _ =
            memory.add_debate_turn(
              mem,
              senator,
              updated.bill,
              updated.next_turn_index - 1,
              speech,
              intent,
              purpose,
              procedure,
            )
          updated
        }
        _ -> updated
      }
    }
  }
}

fn render_proceedings(sess: session.Session) -> String {
  let bill = sess.bill
  let result_line = case sess.final_result {
    None -> "Final vote: Not taken"
    Some(result) -> format_vote_result(result)
  }

  let turns =
    sess.debate_turns
    |> list.map(fn(turn) { format_turn(turn) })
    |> string.join("\n\n")

  string.join(
    [
      "Proceedings for bill " <> bill.id <> ": " <> bill.title,
      bill.summary,
      "Status: " <> format_status(sess.status),
      result_line,
      "LLM calls: "
        <> int.to_string(sess.llm_calls_used)
        <> " / "
        <> int.to_string(sess.llm_calls_limit),
      "Turn transcript:",
      turns,
    ],
    "\n\n",
  )
}

fn format_turn(turn: debate.DebateTurn) -> String {
  let label =
    "Turn "
      <> int.to_string(turn.turn_index)
      <> " — "
      <> turn.senator.name
      <> " ("
      <> turn.senator.state
      <> ")"

  let intent = debate.vote_intent_label(turn.vote_intent)
  let procedure = debate.procedure_label(turn.procedure)

  string.join(
    [
      label,
      "Intent: " <> intent <> "; Procedure: " <> procedure <> "; Purpose: " <> turn.purpose,
      turn.speech,
    ],
    "\n",
  )
}

fn format_status(status: session.SessionStatus) -> String {
  case status {
    session.InDebate -> "In debate"
    session.Voting(_) -> "Voting"
    session.Closed -> "Closed"
  }
}

fn format_vote_result(result: session.VoteResult) -> String {
  let session.VoteResult(tally: tally, passed: passed) = result
  let session.VoteTally(yea: yea, nay: nay, abstain: abstain) = tally

  "Yea "
    <> int.to_string(yea)
    <> ", Nay "
    <> int.to_string(nay)
    <> ", Abstain "
    <> int.to_string(abstain)
    <> " — Passed: "
    <> case passed {
      True -> "Yes"
      False -> "No"
    }
}

fn file_error_to_string(error: simplifile.FileError) -> String {
  case error {
    simplifile.Enoent -> "not_found"
    _ -> string.inspect(error)
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
