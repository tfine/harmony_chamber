import debate
import gleam/int
import gleam/list
import gleam/string
import messages
import senators
import session

const max_history = 6

pub fn senator_debate_prompt(
  senator: senators.Senator,
  sess: session.Session,
) -> String {
  let bill = sess.bill
  let history = session.recent_turns(sess, max_history)
  let inbox = session.inbox_slice(sess, senator.id)

  let history_section =
    case history {
      [] ->
        "No one has spoken yet. Open the floor with a concise framing or state why you are waiting."
      _ ->
        history
        |> list.map(format_history_entry)
        |> string.join("\n")
    }

  let messages_section =
    case inbox {
      [] ->
        "- No direct messages, public comments, or press inquiries currently require your reaction."
      _ ->
        inbox
        |> list.map(messages.short_summary)
        |> list.map(fn(line) { "- " <> line })
        |> string.join("\n")
    }

  let amendment_section = format_amendment_section(sess.amendments)
  let procedure_context = format_procedure_context(sess.status)

  string.join(
    [
      "You are a United States Senator. There is no predefined party alignment;",
      "base your decisions entirely on your biography, your state, and the needs of the bill described below.",
      "",
      "=== SENATOR PROFILE ===",
      "Name: " <> senator.name <> " (" <> senator.state <> ")",
      "Biography:",
      senator.biography,
      "",
      "=== CURRENT BILL ===",
      "Bill " <> bill.id <> ": " <> bill.title,
      bill.summary,
      "",
      "Identify key tensions and trade-offs in this bill summary. Consider competing priorities (costs vs preparedness,",
      "federal vs local control, timelines, labor impact, civil liberties, and regional inequities).",
      "",
      "=== PROCEDURAL CONTEXT ===",
      procedure_context,
      "",
      "=== RECENT DEBATE TURNS ===",
      history_section,
      "",
      "=== AMENDMENTS ===",
      amendment_section,
      "",
      "=== INCOMING MESSAGES ===",
      "You may react to constituents, press, archivists, or other senators. Keep references concise.",
      messages_section,
      "",
      "=== TASK ===",
      "Decide whether you will speak on this turn. Speak only if you can rebut, add a new argument, propose a full amendment,",
      "advance procedure, or clearly explain a vote intent shift. Acknowledge or act on relevant messages when helpful.",
      "",
      "=== RESPONSE FORMAT ===",
      "Respond with a single JSON object matching exactly this schema:",
      "{",
      "  \"will_speak\": true|false,",
      "  \"purpose\": \"rebuttal\" | \"new_argument\" | \"amendment\" | \"procedural\" | \"vote_explanation\" | \"message_response\" | \"pass\",",
      "  \"speech\": \"full speech text if will_speak is true, otherwise an empty string\",",
      "  \"vote_intent\": \"yea\" | \"nay\" | \"abstain\" | \"undecided\",",
      "  \"procedure\": \"none\" | \"call_vote\" | \"propose_amendment\"",
      "}",
      "",
      "Rules:",
      "- Output ONLY the JSON object. No markdown, code fences, or commentary.",
      "- If will_speak is false, set speech to \"\" but still provide purpose and vote_intent.",
      "- \"vote_intent\" must be one of: yea, nay, abstain, undecided.",
      "- Proposing an amendment requires `procedure` = \"propose_amendment\" and your `speech` must contain the full replacement text for the bill summary.",
      "- All votes are simple majorities. Amendments are voted on before the final bill and replace the bill text if adopted.",
      "- Use `procedure` = \"call_vote\" when debate has surfaced the necessary considerations and you want to move to a vote.",
      "- Reference specific prior arguments or messages when speaking; avoid generic filler.",
    ],
    "\n",
  )
}

fn format_history_entry(turn: debate.DebateTurn) -> String {
  "- Turn "
    <> int.to_string(turn.turn_index)
    <> ": "
    <> turn.senator.name
    <> " ("
    <> turn.senator.state
    <> ") — vote intent: "
    <> debate.vote_intent_label(turn.vote_intent)
    <> "; purpose: "
    <> turn.purpose
    <> "; procedure: "
    <> debate.procedure_label(turn.procedure)
    <> ". Summary: "
    <> trim_speech(turn.speech)
}

fn trim_speech(text: String) -> String {
  let cleaned = string.trim(text)

  case string.length(cleaned) > 220 {
    True -> string.slice(cleaned, 0, 217) <> "..."
    False -> cleaned
  }
}

fn format_amendment_section(amendments: List(session.Amendment)) -> String {
  case amendments {
    [] ->
      "No amendments have been proposed. You may introduce one by supplying the complete replacement text for the bill."
    _ ->
      amendments
      |> list.map(fn(amendment) {
        "- Amendment "
          <> int.to_string(amendment.id)
          <> " by "
          <> amendment.proposer.name
          <> " — status: "
          <> format_amendment_status(amendment)
          <> ". Text: "
          <> trim_speech(amendment.text)
      })
      |> string.join("\n")
  }
}

fn format_amendment_status(amendment: session.Amendment) -> String {
  case amendment.status {
    session.Pending -> "Pending"
    session.Adopted -> "Adopted"
    session.Rejected -> "Rejected"
  }
}

fn format_procedure_context(status: session.SessionStatus) -> String {
  case status {
    session.InDebate ->
      "Debate is open. Propose amendments or arguments, and request votes when ready."
    session.Voting(session.BillVote) ->
      "A final vote on the bill is underway."
    session.Voting(session.AmendmentVote(id)) ->
      "A vote is underway on Amendment " <> int.to_string(id) <> "."
    session.Closed ->
      "The session is closed and the final result has been recorded."
  }
}
