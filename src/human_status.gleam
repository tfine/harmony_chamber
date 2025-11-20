//// Human status reporting and parsing for AGATA time legislation.
//// Todd and Delaney report their current state, energy, constraints, and
//// what happened in the last time block.

import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import time_bill.{type EnergyLevel}

/// A status report from Todd and/or Delaney
pub type HumanStatus {
  HumanStatus(
    /// When this status was reported
    timestamp: String,
    /// Preferred block length for next task
    block_preference: Option(Int),
    /// Current location
    location: String,
    /// Todd's current energy
    todd_energy: EnergyLevel,
    /// Delaney's current energy
    delaney_energy: EnergyLevel,
    /// Todd's mood (1-2 words)
    todd_mood: String,
    /// Delaney's mood (1-2 words)
    delaney_mood: String,
    /// Physical state (hungry, tired, driving, etc.)
    physical_state: String,
    /// Available tools/internet
    internet_tools: String,
    /// Todd's immediate needs
    todd_needs: List(String),
    /// Delaney's immediate needs
    delaney_needs: List(String),
    /// Tasks currently on their minds
    current_tasks: List(String),
    /// Hard constraints for next 2-3 hours
    hard_constraints: List(String),
  )
}

/// A report on what happened in the last time block
pub type BlockReport {
  BlockReport(
    /// When this report was submitted
    timestamp: String,
    /// How long the block actually took
    actual_minutes: Int,
    /// Todd's energy after the block
    todd_energy: EnergyLevel,
    /// Delaney's energy after the block
    delaney_energy: EnergyLevel,
    /// What actually got done
    completed: List(String),
    /// Where they got stuck
    stuck_on: List(String),
    /// New needs or tasks that emerged
    new_needs: List(String),
  )
}

/// Parse a status report from markdown-style text
/// Expected format:
/// ## STATUS
/// Time (local): [timestamp]
/// Block length preference: 5 / 10 / 15 / unsure
/// Location: [text]
/// Todd_energy: low / medium / high
/// Delaney_energy: low / medium / high
/// ...
pub fn parse_status(text: String) -> Result(HumanStatus, String) {
  let lines =
    text
    |> string.split("\n")
    |> list.map(string.trim)

  use timestamp <- result.try(extract_field(lines, "Time (local):"))
  use block_pref <- result.try(parse_block_preference(lines))
  use location <- result.try(extract_field(lines, "Location:"))
  use todd_energy <- result.try(parse_energy_field(lines, "Todd_energy:"))
  use delaney_energy <- result.try(parse_energy_field(lines, "Delaney_energy:"))
  use todd_mood <- result.try(extract_field(lines, "Todd_mood:"))
  use delaney_mood <- result.try(extract_field(lines, "Delaney_mood:"))
  use physical <- result.try(extract_field(lines, "Physical_state:"))
  use tools <- result.try(extract_field(lines, "Internet_tools:"))

  let todd_needs = extract_bullets(lines, "Immediate_needs_Todd:")
  let delaney_needs = extract_bullets(lines, "Immediate_needs_Delaney:")
  let current_tasks = extract_bullets(lines, "Current_tasks_on_mind:")
  let constraints = extract_bullets(lines, "Hard_constraints_next_2_3_hours:")

  Ok(HumanStatus(
    timestamp: timestamp,
    block_preference: block_pref,
    location: location,
    todd_energy: todd_energy,
    delaney_energy: delaney_energy,
    todd_mood: todd_mood,
    delaney_mood: delaney_mood,
    physical_state: physical,
    internet_tools: tools,
    todd_needs: todd_needs,
    delaney_needs: delaney_needs,
    current_tasks: current_tasks,
    hard_constraints: constraints,
  ))
}

/// Parse a block report from markdown-style text
pub fn parse_block_report(text: String) -> Result(BlockReport, String) {
  let lines =
    text
    |> string.split("\n")
    |> list.map(string.trim)

  use timestamp <- result.try(extract_field(lines, "Time (local):"))
  use actual_min <- result.try(parse_minutes_field(
    lines,
    "Block actually used:",
  ))
  use todd_energy <- result.try(parse_energy_field(lines, "Todd_energy:"))
  use delaney_energy <- result.try(parse_energy_field(lines, "Delaney_energy:"))

  let completed = extract_bullets(lines, "What_got_done:")
  let stuck = extract_bullets(lines, "Where_got_stuck:")
  let new_needs = extract_bullets(lines, "New_needs_or_tasks:")

  Ok(BlockReport(
    timestamp: timestamp,
    actual_minutes: actual_min,
    todd_energy: todd_energy,
    delaney_energy: delaney_energy,
    completed: completed,
    stuck_on: stuck,
    new_needs: new_needs,
  ))
}

/// Extract a field value from lines
fn extract_field(lines: List(String), prefix: String) -> Result(String, String) {
  lines
  |> list.find(fn(line) { string.starts_with(line, prefix) })
  |> result.map(fn(line) {
    line
    |> string.replace(prefix, "")
    |> string.trim
  })
  |> result.replace_error("Missing field: " <> prefix)
}

/// Parse energy level from a field
fn parse_energy_field(
  lines: List(String),
  prefix: String,
) -> Result(EnergyLevel, String) {
  use value <- result.try(extract_field(lines, prefix))
  time_bill.energy_from_string(string.lowercase(value))
}

/// Parse block preference (can be a number or "unsure")
fn parse_block_preference(lines: List(String)) -> Result(Option(Int), String) {
  case extract_field(lines, "Block length preference:") {
    Ok(value) -> {
      let cleaned = string.lowercase(string.trim(value))
      case cleaned {
        "unsure" | "none" | "" -> Ok(None)
        _ ->
          case int.parse(cleaned) {
            Ok(minutes) -> Ok(Some(minutes))
            Error(_) ->
              // Try to extract first number from "5 / 10 / 15" format
              case string.split(cleaned, "/") {
                [first, ..] ->
                  case int.parse(string.trim(first)) {
                    Ok(minutes) -> Ok(Some(minutes))
                    Error(_) -> Ok(None)
                  }
                [] -> Ok(None)
              }
          }
      }
    }
    Error(_) -> Ok(None)
  }
}

/// Parse minutes from a field
fn parse_minutes_field(
  lines: List(String),
  prefix: String,
) -> Result(Int, String) {
  use value <- result.try(extract_field(lines, prefix))
  int.parse(string.trim(value))
  |> result.replace_error("Invalid minutes value: " <> value)
}

/// Extract bullet points after a header
fn extract_bullets(lines: List(String), header: String) -> List(String) {
  let after_header = drop_until_header(lines, header)

  after_header
  |> list.take_while(fn(line) {
    string.starts_with(line, "-") || string.starts_with(line, "*")
  })
  |> list.map(fn(line) {
    line
    |> string.replace("-", "")
    |> string.replace("*", "")
    |> string.trim
  })
  |> list.filter(fn(line) { line != "" && line != "none" })
}

/// Drop lines until we find the header, then return remaining lines
fn drop_until_header(lines: List(String), header: String) -> List(String) {
  case lines {
    [] -> []
    [first, ..rest] ->
      case string.starts_with(first, header) {
        True -> rest
        False -> drop_until_header(rest, header)
      }
  }
}

/// Format a status report as markdown
pub fn format_status(status: HumanStatus) -> String {
  let todd_needs_text = format_bullets(status.todd_needs)
  let delaney_needs_text = format_bullets(status.delaney_needs)
  let tasks_text = format_bullets(status.current_tasks)
  let constraints_text = case status.hard_constraints {
    [] -> "- none"
    items -> format_bullets(items)
  }

  let block_pref = case status.block_preference {
    Some(minutes) -> int.to_string(minutes)
    None -> "unsure"
  }

  string.join(
    [
      "## STATUS",
      "Time (local): " <> status.timestamp,
      "Block length preference: " <> block_pref,
      "Location: " <> status.location,
      "Todd_energy: " <> time_bill.energy_to_string(status.todd_energy),
      "Delaney_energy: " <> time_bill.energy_to_string(status.delaney_energy),
      "Todd_mood: " <> status.todd_mood,
      "Delaney_mood: " <> status.delaney_mood,
      "Physical_state: " <> status.physical_state,
      "Internet_tools: " <> status.internet_tools,
      "",
      "Immediate_needs_Todd:",
      todd_needs_text,
      "",
      "Immediate_needs_Delaney:",
      delaney_needs_text,
      "",
      "Current_tasks_on_mind:",
      tasks_text,
      "",
      "Hard_constraints_next_2_3_hours:",
      constraints_text,
    ],
    "\n",
  )
}

/// Format a block report as markdown
pub fn format_block_report(report: BlockReport) -> String {
  let completed_text = format_bullets(report.completed)
  let stuck_text = case report.stuck_on {
    [] -> "- none"
    items -> format_bullets(items)
  }
  let needs_text = format_bullets(report.new_needs)

  string.join(
    [
      "## BLOCK REPORT",
      "Time (local): " <> report.timestamp,
      "Block actually used: " <> int.to_string(report.actual_minutes),
      "Todd_energy: " <> time_bill.energy_to_string(report.todd_energy),
      "Delaney_energy: " <> time_bill.energy_to_string(report.delaney_energy),
      "",
      "What_got_done:",
      completed_text,
      "",
      "Where_got_stuck:",
      stuck_text,
      "",
      "New_needs_or_tasks:",
      needs_text,
    ],
    "\n",
  )
}

fn format_bullets(items: List(String)) -> String {
  case items {
    [] -> "- (none)"
    _ ->
      items
      |> list.map(fn(item) { "- " <> item })
      |> string.join("\n")
  }
}
