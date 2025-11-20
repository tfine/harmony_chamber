import debate
import gleam/float
import gleam/int
import gleam/list
import gleam/string
import gleam/option.{None, Some}
import memory
import messages
import senators
import session

pub fn senator_debate_prompt(
  senator: senators.Senator,
  sess: session.Session,
  recall: List(memory.MemoryHit),
  intentions: List(String),
) -> String {
  let bill = sess.bill
  let history = sess.debate_turns
  let inbox = session.inbox_slice(sess, senator.id)

  let history_section =
    case history {
      [] ->
        "No one has spoken yet. Open the floor with a detailed framing that establishes the full context before saying why you are waiting."
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
  let memory_section = format_memory_section(recall)
  let intentions_section = format_intentions_section(intentions)
  let procedure_context = format_procedure_context(sess.status)
  let vote_section = format_vote_section(sess)

  string.join(
    [
      "You are a member of the AGATA Senate: administrators of a 70-acre art collaborative, cooperative farm, and cultural lab in Coward, South Carolina.",
      "Base your decisions on the needs of the project, the neighbors, and the evolving priorities already described in the time law charter.",
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
      "This bill is intentionally framed as a living priorities charter for the AGATA time legislation stream.",
      "You must interrogate each clause, argue over the principles it elevates, and use amendments to revise the priorities before asking the Senate to move on.",
      "Think in terms of heavy amendments and long debate: identify what should stay, what must change, and how it should guide Todd and Delaney's immediate blocks and long-term rhythm.",
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
      "=== PERSONAL INTENTIONS ===",
      intentions_section,
      "",
      "=== PRIOR MEMORY ===",
      memory_section,
      "",
      "=== VOTE STATUS ===",
      vote_section,
      "",
      "=== INCOMING MESSAGES ===",
      "You may react to constituents, press, archivists, or other senators. Provide whatever level of detail is needed for clarity; length is fine when it conveys the facts.",
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
      "  \"procedure\": \"none\" | \"call_vote\" | \"propose_amendment\",",
      "  \"amendment_summary\": \"if proposing, the complete replacement bill summary text; otherwise empty string\",",
      "  \"amendment_rationale\": \"brief justification for the amendment or empty string\"",
      "}",
      "",
      "Rules:",
      "- Output ONLY the JSON object. No markdown, code fences, or commentary.",
      "- If will_speak is false, set speech to \"\" but still provide purpose and vote_intent.",
      "- \"vote_intent\" must be one of: yea, nay, abstain, undecided.",
      "- Proposing an amendment requires `procedure` = \"propose_amendment\" plus a complete replacement bill summary in `amendment_summary`. Use `speech` to justify or explain, not to carry the formal text.",
      "- All votes are simple majorities. Amendments are voted on before the final bill and replace the bill text if adopted.",
      "- Use `procedure` = \"call_vote\" when debate has surfaced the necessary considerations and you want to move to a vote.",
      "- Reference specific prior arguments or messages when speaking; avoid generic filler.",
      "- Your speech and amendments may be as long as necessary—provide fully drafted, precise legislation rather than shorthand notes.",
      "- If you've spoken before, acknowledge how your stance has evolved or respond directly to prior remarks before adding something new.",
    ],
    "\n",
  )
}

pub fn memory_query_text(sess: session.Session) -> String {
  sess.bill.title <> " — " <> sess.bill.summary
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
    <> case turn.amendment_summary {
      None -> ""
      Some(summary) ->
        " | Amendment summary proposed: " <> trim_speech(summary)
    }
}

fn trim_speech(text: String) -> String {
  let cleaned = string.trim(text)

  case string.length(cleaned) > 220 {
    True -> string.slice(cleaned, 0, 217) <> "..."
    False -> cleaned
  }
}

pub fn speaker_rotation_prompt(
  roster: List(senators.Senator),
) -> String {
  let roster_lines =
    roster
    |> list.map(fn(senator) {
      "- id: "
        <> senator.id
        <> "\n  name: "
        <> senator.name
        <> " ("
        <> senator.state
        <> ")\n  focus: "
        <> biography_excerpt(senator.biography)
    })
    |> string.join("\n")

  string.join(
    [
      "You are scheduling the opening speaking order for a high-stakes Senate debate.",
      "Consider regional diversity, committee expertise, and contrasting perspectives to keep the debate lively.",
      "Return a JSON array of senator `id` strings ordered from first speaker to last. Include every id exactly once.",
      "",
      roster_lines,
    ],
    "\n",
  )
}

fn biography_excerpt(text: String) -> String {
  let trimmed = string.trim(text)
  let paragraphs = string.split(trimmed, "\n\n")
  let base = case paragraphs {
    [] -> trimmed
    [first, ..] -> first
  }

  case string.length(base) > 220 {
    True -> string.slice(base, 0, 217) <> "..."
    False -> base
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
          <> ". Proposed summary: "
          <> trim_speech(amendment.text)
          <> case string.trim(amendment.rationale) {
            "" -> ""
            other -> " (Rationale: " <> other <> ")"
          }
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

fn format_memory_section(recall: List(memory.MemoryHit)) -> String {
  case recall {
    [] ->
      "No retrieved long-term memories for this bill and senator. You may propose new arguments or reference transcripts directly."
    _ ->
      recall
      |> list.take(6)
      |> list.map(fn(hit) {
        "- Turn "
          <> int.to_string(hit.turn_index)
          <> " on "
          <> hit.bill_title
          <> " — intent "
          <> string.lowercase(hit.vote_intent)
          <> ", purpose "
          <> hit.purpose
          <> ": "
          <> hit.summary
          <> " (relevance "
          <> float.to_string(hit.score)
          <> ")"
      })
      |> string.join("\n")
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

fn format_vote_section(sess: session.Session) -> String {
  case sess.status {
    session.Voting(_focus) -> {
      let tally = session.vote_progress(sess)
      let session.VoteTally(yea: yea, nay: nay, abstain: abstain) = tally
      "Voting underway — current totals: Yea "
        <> int.to_string(yea)
        <> ", Nay "
        <> int.to_string(nay)
        <> ", Abstain "
        <> int.to_string(abstain)
        <> ". Senators without a recorded vote may wait, but will be reminded every 20 seconds until the 2-minute vote window closes."
    }
    _ ->
      "No vote is active. Focus on substantive debate, amendments, or procedural motions."
  }
}

fn format_intentions_section(intentions: List(String)) -> String {
  case intentions {
    [] ->
      "- No persistent goals or commitments recorded. If you have an ongoing initiative, state it explicitly so future turns can reference it."
    _ ->
      intentions
      |> list.map(fn(line) { "- " <> line })
      |> string.join("\n")
  }
}
