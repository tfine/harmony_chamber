import agent_bridge
import debate
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import llm_client
import senators
import session

pub fn step_session(
  current_session: session.Session,
  senator_cycle: List(senators.Senator),
) -> Result(session.Session, llm_client.LlmError) {
  case current_session.status {
    session.Closed -> Ok(current_session)
    session.Voting(_) -> Ok(session.resolve_vote(current_session))
    session.InDebate ->
      step_debate_round(current_session, senator_cycle)
  }
}

fn step_debate_round(
  current_session: session.Session,
  senator_cycle: List(senators.Senator),
) -> Result(session.Session, llm_client.LlmError) {
  case current_session.llm_calls_used >= current_session.llm_calls_limit {
    True ->
      // Budget spent — do nothing this tick.
      Ok(current_session)

    False -> {
      let total = list.length(senator_cycle)

      case next_senator(current_session.next_speaker_index, senator_cycle) {
        None -> Ok(current_session)

        Some(senator) -> {
          use decision <- result.try(agent_bridge.request_debate_decision(
            senator,
            current_session,
          ))

          let updated =
            current_session
            |> session.apply_debate_decision(senator, decision)
            |> maybe_move_to_voting(decision)
            |> session.advance_speaker(total)
            |> session.increment_llm_calls()

          Ok(updated)
        }
      }
    }
  }
}

fn next_senator(
  index: Int,
  cycle: List(senators.Senator),
) -> Option(senators.Senator) {
  case cycle {
    [] -> None
    [head, ..tail] ->
      case index {
        0 -> Some(head)
        _ -> next_senator(index - 1, tail)
      }
  }
}

fn maybe_move_to_voting(
  sess: session.Session,
  decision: debate.DebateDecision,
) -> session.Session {
  case session.vote_focus_for_transition(sess, decision) {
    Some(focus) -> session.begin_vote(sess, focus)
    None -> sess
  }
}
