import debate
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import messages
import senators

pub type Bill {
  Bill(id: String, title: String, summary: String)
}

pub type SessionStatus {
  InDebate
  Voting(VoteFocus)
  Closed
}

pub type VoteFocus {
  BillVote
  AmendmentVote(Int)
}

pub type AmendmentStatus {
  Pending
  Adopted
  Rejected
}

pub type Amendment {
  Amendment(
    id: Int,
    proposer: senators.Senator,
    base_summary: String,
    text: String,
    rationale: String,
    status: AmendmentStatus,
    vote_result: Option(VoteResult),
  )
}

pub type CompletedBill {
  CompletedBill(
    bill: Bill,
    amendments: List(Amendment),
    transcript_text: String,
    result: Option(VoteResult),
  )
}

pub type Session {
  Session(
    bill: Bill,
    debate_turns: List(debate.DebateTurn),
    vote_intents: Dict(String, debate.VoteIntent),
    status: SessionStatus,
    final_result: Option(VoteResult),
    next_turn_index: Int,
    next_speaker_index: Int,
    last_error: Option(String),
    llm_calls_used: Int,
    llm_calls_limit: Int,
    messages: List(messages.Message),
    amendments: List(Amendment),
    next_amendment_id: Int,
    upcoming_bills: List(Bill),
    completed_bills: List(CompletedBill),
    vote_queue: List(String),
    vote_reminders_left: Int,
  )
}

pub type VoteTally {
  VoteTally(yea: Int, nay: Int, abstain: Int)
}

pub type VoteResult {
  VoteResult(tally: VoteTally, passed: Bool)
}

// Require at least this many explicit call_vote signals before auto-transitioning.
const call_vote_threshold = 5
const automatic_vote_turn_limit = 16
const default_inbox_limit = 6
const vote_reminder_rounds = 6
const default_llm_calls_limit = 1000
pub fn initial_session(bill: Bill) -> Session {
  Session(
    bill: bill,
    debate_turns: [],
    vote_intents: dict.new(),
    status: InDebate,
    final_result: None,
    next_turn_index: 1,
    next_speaker_index: 0,
    last_error: None,
    llm_calls_used: 0,
    llm_calls_limit: default_llm_calls_limit,
    messages: [],
    amendments: [],
    next_amendment_id: 1,
    upcoming_bills: [],
    completed_bills: [],
    vote_queue: [],
    vote_reminders_left: vote_reminder_rounds,
  )
}

pub fn initial_session_with_docket(
  bill: Bill,
  upcoming: List(Bill),
) -> Session {
  Session(
    ..initial_session(bill),
    upcoming_bills: upcoming,
  )
}

pub fn apply_debate_decision(
  session: Session,
  senator: senators.Senator,
  decision: debate.DebateDecision,
) -> Session {
  let #(safe_decision, warning) = guard_empty_speech(decision, senator)
  let base_session = case warning {
    Some(message) -> record_error(session, message)
    None -> session
  }

  let debate.SpeakDecision(
    will_speak,
    speech,
    vote_intent,
    purpose,
    procedure,
    amendment_summary,
    amendment_rationale,
  ) = safe_decision

  let vote_intents =
    dict.insert(base_session.vote_intents, senator.id, vote_intent)

  let should_record_turn =
    will_speak
      || procedure != debate.NoProcedure
      || purpose != ""

  let #(debate_turns, next_turn_index) =
    case should_record_turn {
      True -> {
        let turn =
          debate.DebateTurn(
            turn_index: base_session.next_turn_index,
            senator: senator,
            speech: speech,
            vote_intent: vote_intent,
            purpose: purpose,
            procedure: procedure,
            amendment_summary: amendment_summary,
            amendment_rationale: amendment_rationale,
          )

        #(
          list.append(base_session.debate_turns, [turn]),
          base_session.next_turn_index + 1,
        )
      }
      False ->
        #(base_session.debate_turns, base_session.next_turn_index)
    }

  let updated =
    Session(
      ..base_session,
      debate_turns: debate_turns,
      vote_intents: vote_intents,
      next_turn_index: next_turn_index,
      last_error: None,
    )

  case procedure {
    debate.ProposeAmendment ->
      case amendment_summary {
        Some(summary) ->
          register_amendment(updated, senator, summary, amendment_rationale)
        None ->
          record_error(updated, "Amendment ignored: summary payload missing for " <> senator.name)
      }
    _ -> updated
  }
}

fn guard_empty_speech(
  decision: debate.DebateDecision,
  senator: senators.Senator,
) -> #(debate.DebateDecision, Option(String)) {
  let debate.SpeakDecision(
    will_speak,
    speech,
    vote_intent,
    purpose,
    procedure,
    amendment_summary,
    amendment_rationale,
  ) = decision

  let trimmed = string.trim(speech)

  case will_speak && trimmed == "" {
    False -> #(decision, None)
    True -> {
      let fallback =
        "Apologies — my prepared remarks did not transmit correctly. I'll rejoin shortly with a full statement after I verify the feed."

      #(
        debate.SpeakDecision(
          True,
          fallback,
          vote_intent,
          purpose,
          procedure,
          amendment_summary,
          amendment_rationale,
        ),
        Some("Recovered placeholder speech for " <> senator.name),
      )
    }
  }
}

pub fn advance_speaker(session: Session, cycle_length: Int) -> Session {
  case cycle_length <= 0 {
    True -> session
    False -> {
      let next_index = case
        int.modulo(session.next_speaker_index + 1, cycle_length)
      {
        Ok(value) -> value
        Error(Nil) -> 0
      }
      Session(..session, next_speaker_index: next_index)
    }
  }
}

pub fn vote_intent_for(
  session: Session,
  senator_id: String,
) -> Option(debate.VoteIntent) {
  case dict.get(session.vote_intents, senator_id) {
    Ok(intent) -> Some(intent)
    Error(Nil) -> None
  }
}

pub fn recent_turns(session: Session, count: Int) -> List(debate.DebateTurn) {
  session.debate_turns
  |> list.reverse
  |> list.take(count)
  |> list.reverse
}

pub fn record_error(session: Session, message: String) -> Session {
  Session(..session, last_error: Some(message))
}

pub fn increment_llm_calls(session: Session) -> Session {
  Session(..session, llm_calls_used: session.llm_calls_used + 1)
}

pub fn set_llm_calls_limit(session: Session, limit: Int) -> Session {
  Session(..session, llm_calls_limit: limit)
}

pub fn default_llm_limit() -> Int {
  default_llm_calls_limit
}

pub fn add_message(session: Session, message: messages.Message) -> Session {
  Session(..session, messages: [message, ..session.messages])
}

pub fn inbox_for(
  session: Session,
  senator_id: String,
  limit: Int,
) -> List(messages.Message) {
  session.messages
  |> list.filter(fn(msg) { messages.is_relevant_for(msg, senator_id) })
  |> list.take(limit)
  |> list.reverse
}

pub fn inbox_slice(session: Session, senator_id: String) -> List(messages.Message) {
  inbox_for(session, senator_id, default_inbox_limit)
}

pub fn vote_focus_for_transition(
  session: Session,
  decision: debate.DebateDecision,
) -> Option(VoteFocus) {
  case session.status {
    InDebate -> {
      let call_vote_signals =
        session.debate_turns
        |> list.filter(fn(turn) { turn.procedure == debate.CallVote })
        |> list.length

      let decision_requests_vote = case decision {
        debate.SpeakDecision(_, _, _, _, debate.CallVote, _, _) -> True
        _ -> False
      }

      let limit_reached =
        list.length(session.debate_turns) >= automatic_vote_turn_limit

      case decision_requests_vote
        || call_vote_signals >= call_vote_threshold
        || limit_reached
      {
        True -> Some(select_vote_focus(session))
        False -> None
      }
    }
    _ -> None
  }
}

pub fn begin_vote(
  session: Session,
  focus: VoteFocus,
  order: List(senators.Senator),
) -> Session {
  Session(
    ..session,
    status: Voting(focus),
    vote_queue: senator_ids(order),
    vote_reminders_left: vote_reminder_rounds,
  )
}

pub fn tally_votes(session: Session) -> VoteTally {
  dict.fold(session.vote_intents, VoteTally(0, 0, 0), fn(tally, _id, intent) {
    let VoteTally(yea: yea, nay: nay, abstain: abstain) = tally
    case intent {
      debate.Yea -> VoteTally(yea + 1, nay, abstain)
      debate.Nay -> VoteTally(yea, nay + 1, abstain)
      debate.Abstain -> VoteTally(yea, nay, abstain + 1)
      debate.Undecided -> tally
    }
  })
}

pub fn resolve_vote(session: Session) -> Session {
  case session.status {
    Voting(BillVote) -> close_with_result(session)
    Voting(AmendmentVote(id)) -> resolve_amendment_vote(session, id)
    Closed -> session
    InDebate -> session
  }
}

fn close_with_result(session: Session) -> Session {
  let tally = tally_votes(session)
  let VoteTally(yea: yea, nay: nay, abstain: _abstain) = tally
  let passed = yea > nay
  let result = VoteResult(tally: tally, passed: passed)

  Session(
    ..session,
    status: Closed,
    final_result: Some(result),
    last_error: None,
  )
  |> record_completion(result)
  |> advance_to_next_bill()
}

fn resolve_amendment_vote(session: Session, amendment_id: Int) -> Session {
  case find_amendment(session.amendments, amendment_id) {
    None -> Session(..session, status: InDebate)
    Some(amendment) -> {
      let tally = tally_votes(session)
      let VoteTally(yea: yea, nay: nay, abstain: _abstain) = tally
      let passed = yea > nay
      let result = VoteResult(tally: tally, passed: passed)

      let updated_amendments =
        session.amendments
        |> list.map(fn(item) {
          case item.id == amendment.id {
            True -> Amendment(
              ..item,
              status: case passed {
                True -> Adopted
                False -> Rejected
              },
              vote_result: Some(result),
            )
            False -> item
          }
        })

      let updated_bill = case passed {
        True -> Bill(..session.bill, summary: amendment.text)
        False -> session.bill
      }

      let #(rebased_amendments, revision_notices) =
        case passed {
          True ->
            rebase_pending_amendments(
              updated_amendments,
              amendment.text,
              amendment.id,
            )
          False -> #(updated_amendments, [])
        }

      let message_log =
        revision_notices
        |> list.fold(session.messages, fn(acc, notice) { [notice, ..acc] })

      Session(
        ..session,
        amendments: rebased_amendments,
        bill: updated_bill,
        status: InDebate,
        vote_intents: dict.new(),
        vote_queue: [],
        vote_reminders_left: vote_reminder_rounds,
        messages: message_log,
      )
    }
  }
}

fn register_amendment(
  session: Session,
  senator: senators.Senator,
  submitted_summary: String,
  rationale: Option(String),
) -> Session {
  let text = normalized_amendment_summary(submitted_summary, session.bill.summary)
  let rationale_text = case rationale {
    Some(value) -> string.trim(value)
    None -> ""
  }

  let amendment =
    Amendment(
      id: session.next_amendment_id,
      proposer: senator,
      base_summary: session.bill.summary,
      text: text,
      rationale: rationale_text,
      status: Pending,
      vote_result: None,
    )

  Session(
    ..session,
    amendments: list.append(session.amendments, [amendment]),
    next_amendment_id: session.next_amendment_id + 1,
  )
}

fn normalized_amendment_summary(proposed: String, current_summary: String) -> String {
  let cleaned = string.trim(proposed)
  case string.length(cleaned) < 120 {
    True -> current_summary
    False -> cleaned
  }
}

fn rebase_pending_amendments(
  amendments: List(Amendment),
  new_summary: String,
  adopted_id: Int,
) -> #(List(Amendment), List(messages.Message)) {
  let #(updated, notices) =
    amendments
    |> list.fold(#([], []), fn(acc, amendment) {
      let #(amendments_acc, notices_acc) = acc
      let #(rebased, notice) =
        rebase_amendment(amendment, new_summary, adopted_id)
      let next_notices = case notice {
        Some(message) -> [message, ..notices_acc]
        None -> notices_acc
      }
      #([rebased, ..amendments_acc], next_notices)
    })

  #(list.reverse(updated), list.reverse(notices))
}

fn rebase_amendment(
  amendment: Amendment,
  new_summary: String,
  adopted_id: Int,
) -> #(Amendment, Option(messages.Message)) {
  case amendment.id == adopted_id {
    True -> #(amendment, None)
    False ->
      case amendment.status {
        Pending -> {
          let note = append_rebase_note(amendment.rationale, adopted_id)
          let updated =
            Amendment(
              ..amendment,
              base_summary: new_summary,
              rationale: note,
            )
          let notice =
            messages.DirectMessage(
              from: "Parliamentarian",
              to: amendment.proposer.id,
              body:
                "Amendment "
                  <> int.to_string(amendment.id)
                  <> " now references updated bill language because amendment "
                  <> int.to_string(adopted_id)
                  <> " passed. Please revise it to align with the new summary.",
            )
          #(updated, Some(notice))
        }
        _ -> #(amendment, None)
      }
  }
}

fn append_rebase_note(existing: String, adopted_id: Int) -> String {
  let marker = "[Rebased"
  case string.contains(existing, marker) {
    True -> existing
    False -> {
      let note =
        "[Rebased after amendment "
          <> int.to_string(adopted_id)
          <> " updated the bill summary. Review and adjust.]"
      case string.trim(existing) == "" {
        True -> note
        False -> existing <> "\n\n" <> note
      }
    }
  }
}

fn select_vote_focus(session: Session) -> VoteFocus {
  case next_pending_amendment(session.amendments) {
    Some(amendment) -> AmendmentVote(amendment.id)
    None -> BillVote
  }
}

fn next_pending_amendment(amendments: List(Amendment)) -> Option(Amendment) {
  case amendments {
    [] -> None
    [head, ..tail] ->
      case head.status {
        Pending -> Some(head)
        _ -> next_pending_amendment(tail)
      }
  }
}

fn find_amendment(
  amendments: List(Amendment),
  id: Int,
) -> Option(Amendment) {
  case amendments {
    [] -> None
    [head, ..tail] ->
      case head.id == id {
        True -> Some(head)
        False -> find_amendment(tail, id)
      }
  }
}

fn senator_ids(senators_list: List(senators.Senator)) -> List(String) {
  senators_list
  |> list.map(fn(senator) { senator.id })
}

pub fn next_vote_target(session: Session) -> Option(String) {
  case session.vote_queue {
    [] -> None
    [head, .._] -> Some(head)
  }
}

pub fn drop_vote_target(session: Session) -> Session {
  case session.vote_queue {
    [] -> session
    [_head, ..tail] -> Session(..session, vote_queue: tail)
  }
}

pub fn outstanding_voters(
  session: Session,
  roster: List(senators.Senator),
) -> List(String) {
  roster
  |> list.fold([], fn(acc, senator) {
    case vote_intent_for(session, senator.id) {
      None -> [senator.id, ..acc]
      Some(debate.Undecided) -> [senator.id, ..acc]
      _ -> acc
    }
  })
  |> list.reverse
}

pub fn requeue_outstanding(
  session: Session,
  outstanding: List(String),
) -> Session {
  Session(
    ..session,
    vote_queue: outstanding,
    vote_reminders_left: session.vote_reminders_left - 1,
  )
}

pub fn force_vote_completion(
  session: Session,
  outstanding: List(String),
) -> Session {
  let updated =
    outstanding
    |> list.fold(session.vote_intents, fn(dict, senator_id) {
      dict.insert(dict, senator_id, debate.Abstain)
    })

  Session(
    ..session,
    vote_intents: updated,
    vote_queue: [],
  )
}

fn record_completion(session: Session, result: VoteResult) -> Session {
  let completed =
    CompletedBill(
      bill: session.bill,
      amendments: session.amendments,
      transcript_text: format_transcript(session.debate_turns),
      result: Some(result),
    )

  Session(
    ..session,
    completed_bills: [completed, ..session.completed_bills],
  )
}

pub fn advance_to_next_bill(session: Session) -> Session {
  case session.upcoming_bills {
    [] -> session
    [next, ..rest] ->
      Session(
        bill: next,
        debate_turns: [],
        vote_intents: dict.new(),
        status: InDebate,
        final_result: None,
        next_turn_index: 1,
        next_speaker_index: 0,
        last_error: None,
        llm_calls_used: session.llm_calls_used,
        llm_calls_limit: session.llm_calls_limit,
        messages: [],
        amendments: [],
        next_amendment_id: 1,
        upcoming_bills: rest,
        completed_bills: session.completed_bills,
        vote_queue: [],
        vote_reminders_left: vote_reminder_rounds,
      )
  }
}

pub fn vote_progress(session: Session) -> VoteTally {
  tally_votes(session)
}

pub fn ensure_active(session: Session) -> Session {
  case session.status {
    Closed -> advance_to_next_bill(session)
    _ -> session
  }
}

fn format_transcript(turns: List(debate.DebateTurn)) -> String {
  turns
  |> list.map(fn(turn) {
    "Turn "
      <> int.to_string(turn.turn_index)
      <> " — "
      <> turn.senator.name
      <> " ("
      <> turn.senator.state
      <> "):\n"
      <> turn.speech
  })
  |> string.join("\n\n")
}
