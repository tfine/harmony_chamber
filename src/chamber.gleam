import agent_bridge
import debate
import gleam/int
import gleam/list
import gleam/order
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
    session.Voting(_) -> step_vote_round(current_session, senator_cycle)
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
      let ordered = speaking_order(current_session, senator_cycle)
      let total = list.length(ordered)

      case next_senator(current_session.next_speaker_index, ordered) {
        None -> Ok(current_session)

        Some(senator) -> {
          use decision <- result.try(agent_bridge.request_debate_decision(
            senator,
            current_session,
          ))

          let updated =
            current_session
            |> session.apply_debate_decision(senator, decision)
            |> maybe_move_to_voting(decision, ordered)
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
  order: List(senators.Senator),
) -> session.Session {
  case session.vote_focus_for_transition(sess, decision) {
    Some(focus) -> session.begin_vote(sess, focus, order)
    None -> sess
  }
}

fn step_vote_round(
  current_session: session.Session,
  senator_cycle: List(senators.Senator),
) -> Result(session.Session, llm_client.LlmError) {
  case current_session.llm_calls_used >= current_session.llm_calls_limit {
    True -> Ok(current_session)
    False ->
      case session.next_vote_target(current_session) {
        Some(senator_id) ->
          case find_senator(senator_cycle, senator_id) {
            None ->
              Ok(session.drop_vote_target(current_session))
            Some(senator) -> {
              use decision <- result.try(agent_bridge.request_debate_decision(
                senator,
                current_session,
              ))

              let updated =
                current_session
                |> session.apply_debate_decision(senator, decision)
                |> session.drop_vote_target()
                |> session.increment_llm_calls()

              Ok(updated)
            }
          }

        None -> {
          let outstanding = session.outstanding_voters(current_session, senator_cycle)

          case outstanding {
            [] -> Ok(session.resolve_vote(current_session))

            _ -> {
              case current_session.vote_reminders_left > 0 {
                True ->
                  Ok(session.requeue_outstanding(current_session, outstanding))
                False -> {
                  let forced =
                    current_session
                    |> session.force_vote_completion(outstanding)
                  Ok(session.resolve_vote(forced))
                }
              }
            }
          }
        }
      }
  }
}

fn find_senator(
  roster: List(senators.Senator),
  target_id: String,
) -> Option(senators.Senator) {
  case roster {
    [] -> None
    [head, ..tail] ->
      case head.id == target_id {
        True -> Some(head)
        False -> find_senator(tail, target_id)
      }
  }
}

fn speaking_order(
  sess: session.Session,
  cycle: List(senators.Senator),
) -> List(senators.Senator) {
  cycle
  |> enumerate(0)
  |> list.sort(fn(a, b) {
    let #(index_a, senator_a) = a
    let #(index_b, senator_b) = b
    let priority_a = reaction_priority(sess, senator_a)
    let priority_b = reaction_priority(sess, senator_b)

    case int.compare(priority_a, priority_b) {
      order.Eq ->
        int.compare(index_a, index_b)
      other -> other
    }
  })
  |> list.map(fn(entry) {
    let #(_, senator) = entry
    senator
  })
}

fn reaction_priority(
  sess: session.Session,
  senator: senators.Senator,
) -> Int {
  case session.vote_intent_for(sess, senator.id) {
    None -> 0
    Some(debate.Undecided) -> 0
    Some(debate.Nay) -> 1
    Some(debate.Yea) -> 2
    Some(debate.Abstain) -> 3
  }
}

fn enumerate(
  cycle: List(senators.Senator),
  index: Int,
) -> List(#(Int, senators.Senator)) {
  case cycle {
    [] -> []
    [head, ..tail] -> [#(index, head), ..enumerate(tail, index + 1)]
  }
}
