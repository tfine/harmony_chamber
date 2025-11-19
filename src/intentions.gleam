import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

pub type SenatorIntentions {
  SenatorIntentions(
    primary_goal: Option(String),
    commitments: List(String),
    constituent_pressures: List(String),
  )
}

pub fn empty() -> SenatorIntentions {
  SenatorIntentions(
    primary_goal: None,
    commitments: [],
    constituent_pressures: [],
  )
}

pub fn set_primary_goal(
  intentions: SenatorIntentions,
  goal: String,
) -> SenatorIntentions {
  SenatorIntentions(..intentions, primary_goal: Some(string.trim(goal)))
}

pub fn add_commitment(
  intentions: SenatorIntentions,
  commitment: String,
) -> SenatorIntentions {
  case string.trim(commitment) {
    "" -> intentions
    trimmed ->
      SenatorIntentions(
        ..intentions,
        commitments: [trimmed, ..intentions.commitments]
        |> list.take(8),
      )
  }
}

pub fn add_constituent_pressure(
  intentions: SenatorIntentions,
  note: String,
) -> SenatorIntentions {
  case string.trim(note) {
    "" -> intentions
    trimmed ->
      SenatorIntentions(
        ..intentions,
        constituent_pressures: [trimmed, ..intentions.constituent_pressures]
        |> list.take(8),
      )
  }
}

pub fn clear_commitments(intentions: SenatorIntentions) -> SenatorIntentions {
  SenatorIntentions(..intentions, commitments: [])
}

pub fn summary_lines(intentions: SenatorIntentions) -> List(String) {
  let goal_line =
    case intentions.primary_goal {
      None -> []
      Some(goal) -> ["Primary goal: " <> goal]
    }

  let commitments =
    intentions.commitments
    |> list.map(fn(entry) { "Commitment: " <> entry })

  let pressures =
    intentions.constituent_pressures
    |> list.map(fn(entry) { "Constituent pressure: " <> entry })

  goal_line
  |> list.append(commitments)
  |> list.append(pressures)
}
