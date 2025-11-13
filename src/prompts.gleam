import chamber
import debate
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import senators

pub fn compose_senator_prompt(
  senator: senators.Senator,
  chamber: chamber.Chamber,
  recent_turns: List(debate.DebateTurn),
) -> String {
  let roster = senators.all()
  let bill = chamber.bill
  let transcript_digest = format_turns(recent_turns, roster)
  let queue_digest = describe_queue(chamber.debate.queue, roster)

  string.join(
    [
      "Harmony Chamber — Senatorial Briefing",
      "",
      "Bill " <> bill.id <> ": " <> bill.title,
      "Summary: " <> bill.summary,
      "Phase: " <> phase_label(chamber.debate.phase),
      "",
      "You are " <> senator.name <> " of " <> senator.state <> ".",
      "Biography refresher:",
      senator.biography,
      "",
      "Recent transcript excerpts:",
      transcript_digest,
      "",
      "Queue outlook: " <> queue_digest,
      "",
      "Instruction:",
      "Craft the next floor speech in the first person, with calm but persuasive energy.",
      "Respond with the speech text only—no headers, JSON, or meta commentary.",
    ],
    "\n",
  )
}

pub fn compose_orchestrator_prompt(
  chamber: chamber.Chamber,
  recent_turns: List(debate.DebateTurn),
) -> String {
  let roster = senators.all()
  let transcript_digest = format_turns(recent_turns, roster)
  let bill = chamber.bill

  string.join(
    [
      "Harmony Chamber — Procedural Briefing",
      "",
      "Bill " <> bill.id <> ": " <> bill.title,
      "Phase: " <> phase_label(chamber.debate.phase),
      "",
      "Recent turns under review:",
      transcript_digest,
      "",
      "Decide whether to keep debate open or call a vote.",
      "Return ONLY a JSON object with fields {\"action\":\"call_vote\" | \"continue_debate\"} and optionally \"notes\".",
    ],
    "\n",
  )
}

pub fn phase_slug(phase: debate.Phase) -> String {
  case phase {
    debate.Ongoing -> "ongoing"
    debate.VoteRequested -> "vote_requested"
    debate.Voting -> "voting"
    debate.Completed -> "completed"
  }
}

fn phase_label(phase: debate.Phase) -> String {
  case phase {
    debate.Ongoing -> "Open Debate"
    debate.VoteRequested -> "Vote Requested"
    debate.Voting -> "Voting In Progress"
    debate.Completed -> "Completed"
  }
}

fn format_turns(
  turns: List(debate.DebateTurn),
  roster: List(senators.Senator),
) -> String {
  case turns {
    [] -> "No speeches logged yet. You will open the floor."
    _ ->
      turns
      |> list.map(fn(turn) {
        "- Turn #"
        <> int.to_string(turn.id)
        <> " — "
        <> senator_display_name(turn.senator_id, roster)
        <> ": "
        <> turn.text
      })
      |> string.join("\n")
  }
}

fn describe_queue(queue: List(String), roster: List(senators.Senator)) -> String {
  case queue {
    [] -> "No senators currently queued."
    [next, ..rest] -> {
      let rest_line =
        rest
        |> list.map(fn(id) { senator_display_name(id, roster) })
        |> string.join(" → ")

      case rest_line {
        "" ->
          senator_display_name(next, roster)
          <> " speaks now; queue recycles after."
        _ -> senator_display_name(next, roster) <> " speaks now → " <> rest_line
      }
    }
  }
}

fn senator_display_name(id: String, roster: List(senators.Senator)) -> String {
  case find_senator(id, roster) {
    Some(senator) -> senator.name <> " (" <> senator.state <> ")"
    None -> id
  }
}

fn find_senator(
  id: String,
  roster: List(senators.Senator),
) -> Option(senators.Senator) {
  case roster {
    [] -> None
    [head, ..tail] ->
      case head.id == id {
        True -> Some(head)
        False -> find_senator(id, tail)
      }
  }
}
