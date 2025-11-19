import debate
import gleeunit
import gleam/dict
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import messages
import senators
import session

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn llm_limit_update_test() {
  let bill = session.Bill(id: "T-1", title: "Test Bill", summary: "Demo")
  let base = session.initial_session(bill)
  let updated = session.set_llm_calls_limit(base, 42)

  assert base.llm_calls_limit == session.default_llm_limit()
  assert updated.llm_calls_limit == 42
}

pub fn advance_to_next_bill_keeps_budget_test() {
  let first = session.Bill(id: "T-1", title: "First", summary: "One")
  let second = session.Bill(id: "T-2", title: "Second", summary: "Two")
  let with_docket = session.initial_session_with_docket(first, [second])
  let closed = session.Session(
    ..with_docket,
    status: session.Closed,
    llm_calls_used: 5,
  )

  let advanced = session.advance_to_next_bill(closed)

  assert advanced.bill.id == second.id
  assert advanced.llm_calls_used == 5
  assert advanced.status == session.InDebate
}

pub fn amendment_proposal_records_turn_test() {
  let bill = session.Bill(
    id: "A-1",
    title: "Resilience Act",
    summary: "Invests in coastal infrastructure upgrades and emergency preparedness.",
  )
  let senator = senators.Senator(
    id: "sen_test",
    name: "Test Senator",
    state: "Test State",
    biography: "A veteran legislator focused on emergency preparedness.",
  )
  let session0 = session.initial_session(bill)
  let replacement_text =
    "This comprehensive resilience package directs federal, state, and regional partners to fund levee modernization, "
    <> "deploy resilient microgrids, and stage medical logistics hubs so coastal counties withstand repeated climate shocks."
  let decision =
    debate.SpeakDecision(
      True,
      "Colleagues, I offer a full rewrite to prioritize resilience corridors.",
      debate.Yea,
      "amendment",
      debate.ProposeAmendment,
      Some(replacement_text),
      Some("Clarifies that the core bill summary becomes a full resilience plan."),
    )

  let session1 = session.apply_debate_decision(session0, senator, decision)
  let assert [turn, .._] = session1.debate_turns
  let assert [amendment, .._] = session1.amendments

  assert turn.procedure == debate.ProposeAmendment
  assert turn.amendment_summary == Some(replacement_text)
  assert amendment.text == replacement_text
  assert amendment.proposer.id == senator.id
  assert amendment.rationale == "Clarifies that the core bill summary becomes a full resilience plan."
}

pub fn amendment_vote_focus_before_bill_vote_test() {
  let bill = session.Bill(
    id: "A-2",
    title: "Transit Equity Act",
    summary: "Expands rail and bus investments in underserved regions.",
  )
  let senator = senators.Senator(
    id: "sen_focus",
    name: "Focus Builder",
    state: "Metro",
    biography: "Transit-focused policymaker.",
  )
  let base = session.initial_session(bill)
  let long_summary =
    "The amendment requires DOT to channel 60% of funding into corridor coalitions that pair electrified intercity rail, "
    <> "dedicated bus rapid transit lanes, and zero-fare pilot programs for townships with unemployment above the national average."
  let propose =
    debate.SpeakDecision(
      False,
      "",
      debate.Undecided,
      "amendment",
      debate.ProposeAmendment,
      Some(long_summary),
      Some("Redirects resources to regions with persistent disinvestment."),
    )
  let with_amendment = session.apply_debate_decision(base, senator, propose)
  let call_vote =
    debate.SpeakDecision(
      True,
      "The chamber should now vote, beginning with the pending amendment.",
      debate.Undecided,
      "procedural",
      debate.CallVote,
      None,
      None,
    )

  let focus = session.vote_focus_for_transition(with_amendment, call_vote)

  assert focus == Some(session.AmendmentVote(1))
  assert list.length(with_amendment.debate_turns) == 1
}

pub fn amendment_rejection_restores_bill_summary_test() {
  let bill = session.Bill(
    id: "A-3",
    title: "Clean Energy Act",
    summary: "Funds clean grids and workforce transitions.",
  )
  let senator = senators.Senator(
    id: "sen_reject",
    name: "Cautious Member",
    state: "Heartland",
    biography: "Skeptical of abrupt transitions.",
  )
  let proposed =
    "Requires DOE to replace all fossil fuels in five years without exceptions, "
    <> "mandating immediate shutdowns of every refinery, pipeline, and port facility across the United States regardless of regional readiness."
  let propose =
    debate.SpeakDecision(
      True,
      "I table a radical overhaul to test rejection handling.",
      debate.Nay,
      "amendment",
      debate.ProposeAmendment,
      Some(proposed),
      Some("Demonstrates that a failing amendment should keep the original summary."),
    )
  let with_amendment = session.apply_debate_decision(session.initial_session(bill), senator, propose)
  let to_vote = session.Session(
    ..with_amendment,
    status: session.Voting(session.AmendmentVote(1)),
    vote_intents: dict.from_list([
      #("alpha", debate.Nay),
      #("beta", debate.Nay),
      #("gamma", debate.Yea),
    ]),
  )

  let resolved = session.resolve_vote(to_vote)
  let assert [amendment, .._] = resolved.amendments

  assert resolved.status == session.InDebate
  assert resolved.bill.summary == bill.summary
  assert amendment.status == session.Rejected
  assert amendment.vote_result == Some(session.VoteResult(
    tally: session.VoteTally(yea: 1, nay: 2, abstain: 0),
    passed: False,
  ))
}

pub fn amendment_adoption_updates_bill_summary_test() {
  let bill = session.Bill(
    id: "A-4",
    title: "Broadband Expansion",
    summary: "Deploys middle-mile fiber.",
  )
  let senator = senators.Senator(
    id: "sen_adopt",
    name: "Connectivity Hawk",
    state: "Mountain",
    biography: "Tech-forward planner.",
  )
  let new_summary =
    "Guarantees universal fiber-to-the-home by 2030, funds tribal spectrum cooperatives, "
    <> "and ties grants to apprenticeships so every county can maintain resilient networks."
  let propose =
    debate.SpeakDecision(
      True,
      "This amendment expands scope to universal service.",
      debate.Yea,
      "amendment",
      debate.ProposeAmendment,
      Some(new_summary),
      Some("Focuses debate on the stronger universal build."),
    )
  let with_amendment = session.apply_debate_decision(session.initial_session(bill), senator, propose)
  let to_vote = session.Session(
    ..with_amendment,
    status: session.Voting(session.AmendmentVote(1)),
    vote_intents: dict.from_list([
      #("alpha", debate.Yea),
      #("beta", debate.Yea),
      #("gamma", debate.Nay),
    ]),
  )

  let resolved = session.resolve_vote(to_vote)
  let assert [amendment, .._] = resolved.amendments

  assert resolved.bill.summary == new_summary
  assert amendment.status == session.Adopted
  assert resolved.status == session.InDebate
}

pub fn amendment_rebase_notifies_proposer_test() {
  let bill = session.Bill(
    id: "A-5",
    title: "Harbor Safety Act",
    summary: "Upgrades port security systems.",
  )
  let author = senators.Senator(
    id: "sen_adopt_chain",
    name: "Port Chair",
    state: "Coastal",
    biography: "Chairs a harbor committee.",
  )
  let seconder = senators.Senator(
    id: "sen_second",
    name: "River Delegate",
    state: "Inland",
    biography: "Focuses on river infrastructure.",
  )
  let adopted_text =
    "Orders DHS to install interoperable port security nodes, pilot rapid-response tug fleets, and publish quarterly harbor readiness scorecards."
  let follow_text =
    "Mandates that every inland port immediately mirror the old requirements regardless of capacity, overriding state-run authorities."

  let base = session.initial_session(bill)
  let with_first =
    session.apply_debate_decision(
      base,
      author,
      debate.SpeakDecision(
        True,
        "My amendment defines a comprehensive upgrade path.",
        debate.Yea,
        "amendment",
        debate.ProposeAmendment,
        Some(adopted_text),
        Some("Strengthens the bill summary to match the work ahead."),
      ),
    )
  let with_second =
    session.apply_debate_decision(
      with_first,
      seconder,
      debate.SpeakDecision(
        True,
        "I propose mirroring the prior summary for inland operations.",
        debate.Nay,
        "amendment",
        debate.ProposeAmendment,
        Some(follow_text),
        Some("Extends requirements inland."),
      ),
    )
  let to_vote = session.Session(
    ..with_second,
    status: session.Voting(session.AmendmentVote(1)),
    vote_intents: dict.from_list([
      #("alpha", debate.Yea),
      #("beta", debate.Yea),
      #("gamma", debate.Nay),
    ]),
  )

  let resolved = session.resolve_vote(to_vote)
  let assert [first, second] = resolved.amendments
  let notices =
    resolved.messages
    |> list.filter(fn(message) {
      case message {
        messages.DirectMessage(_, to, _) -> to == seconder.id
        _ -> False
      }
    })

  assert first.status == session.Adopted
  assert second.base_summary == adopted_text
  assert string.contains(second.rationale, "[Rebased after amendment 1")
  assert list.length(notices) == 1
}
