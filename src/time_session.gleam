//// State management for AGATA time legislation sessions.
//// This module defines the TimeSession type and functions for managing
//// the state of micro-block governance.
//// It is intentionally lightweight: the time session lives alongside the
//// traditional chamber session so the Senate can direct human time without
//// blocking on heavier debate flows.

import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import human_status
import resource_state
import time_bill

/// The complete state of a time legislation session.
pub type TimeSession {
  TimeSession(
    /// The most recently reported human status.
    current_human_status: Option(human_status.HumanStatus),
    /// The currently active time bill being worked on.
    active_time_bill: Option(time_bill.TimeBill),
    /// A list of recently completed block reports.
    recent_block_reports: List(human_status.BlockReport),
    /// The current state of resources (budget, time tracking).
    resources: resource_state.ResourceState,
    /// All time bills that have been proposed or completed.
    all_time_bills: List(time_bill.TimeBill),
    /// The next ID to use for a new time bill.
    next_bill_id_num: Int,
    /// Last error encountered during a time session operation.
    last_error: Option(String),
  )
}

/// Initializes a new TimeSession with default values.
pub fn initial_time_session() -> TimeSession {
  TimeSession(
    current_human_status: None,
    active_time_bill: None,
    recent_block_reports: [],
    resources: resource_state.agata_initial(),
    all_time_bills: [],
    next_bill_id_num: 1,
    last_error: None,
  )
}

/// Generates a new unique ID for a time bill.
pub fn next_time_bill_id(session: TimeSession) -> String {
  "TB-" <> int.to_string(session.next_bill_id_num)
}

/// Records a new human status report.
pub fn record_human_status(
  session: TimeSession,
  status: human_status.HumanStatus,
) -> TimeSession {
  TimeSession(
    ..session,
    current_human_status: Some(status),
    last_error: None,
  )
}

/// Records a new block report, marks the current micro-block complete,
/// and refreshes resource tracking. This is the main checkpoint that
/// promotes a bill into `Completed` when all blocks are done.
pub fn record_block_report(
  session: TimeSession,
  report: human_status.BlockReport,
) -> TimeSession {
  let updated_reports = [report, ..session.recent_block_reports]
  case session.active_time_bill {
    None ->
      TimeSession(
        ..session,
        recent_block_reports: updated_reports,
        last_error: Some("No active time bill when recording block report"),
      )
    Some(bill) -> {
      case time_bill.next_block(bill) {
        None ->
          TimeSession(
            ..session,
            recent_block_reports: updated_reports,
            last_error: Some("Active time bill has no pending micro-block"),
          )
        Some(block) -> {
          let completion = time_bill.BlockCompletion(
            actual_minutes: report.actual_minutes,
            completed_tasks: report.completed,
            blockers: report.stuck_on,
            new_needs: report.new_needs,
            todd_energy_after: report.todd_energy,
            delaney_energy_after: report.delaney_energy,
            completed_at: report.timestamp,
          )

          let updated_blocks = mark_block_completed(bill.micro_blocks, completion)

          let next_after = time_bill.next_block(
            time_bill.TimeBill(..bill, micro_blocks: updated_blocks),
          )

          let status_after = case next_after {
            None -> time_bill.Completed
            Some(_) ->
              case bill.status {
                time_bill.Completed -> time_bill.Completed
                _ -> time_bill.InProgress
              }
          }

          let updated_bill =
            time_bill.TimeBill(
              ..bill,
              micro_blocks: updated_blocks,
              status: status_after,
            )

          let tod_worked = block.assignees.todd_tasks != []
          let dela_worked = block.assignees.delaney_tasks != []
          let pillar =
            case bill.pillar_links {
              [] -> None
              [first, .._] -> Some(first)
            }

          let updated_resources =
            resource_state.record_time(
              session.resources,
              report.actual_minutes,
              tod_worked,
              dela_worked,
              pillar,
            )

          let updated_resources =
            resource_state.ResourceState(
              ..updated_resources,
              last_updated: report.timestamp,
            )

          let updated_all_bills =
            session.all_time_bills
            |> list.map(fn(existing) {
              case existing.id == updated_bill.id {
                True -> updated_bill
                False -> existing
              }
            })

          let new_active_bill = case updated_bill.status {
            time_bill.Completed -> None
            _ -> Some(updated_bill)
          }

          TimeSession(
            ..session,
            recent_block_reports: updated_reports,
            resources: updated_resources,
            active_time_bill: new_active_bill,
            all_time_bills: updated_all_bills,
            last_error: None,
          )
        }
      }
    }
  }
}

/// Sets a time bill as active.
pub fn set_active_time_bill(
  session: TimeSession,
  bill: time_bill.TimeBill,
) -> TimeSession {
  let filtered_bills =
    session.all_time_bills
    |> list.filter(fn(b) { b.id != bill.id })

  let updated_all_bills = [bill, ..filtered_bills]

  TimeSession(
    ..session,
    active_time_bill: Some(bill),
    all_time_bills: updated_all_bills,
    last_error: None,
  )
}

/// Adds a new time bill to the list of all time bills.
pub fn add_time_bill(
  session: TimeSession,
  bill: time_bill.TimeBill,
) -> TimeSession {
  TimeSession(
    ..session,
    all_time_bills: [bill, ..session.all_time_bills],
    next_bill_id_num: session.next_bill_id_num + 1,
    last_error: None,
  )
}

fn mark_block_completed(
  blocks: List(time_bill.MicroBlock),
  completion: time_bill.BlockCompletion,
) -> List(time_bill.MicroBlock) {
  case blocks {
    [] -> []
    [head, ..tail] ->
      case head.completion {
        None -> complete_first_block(head, tail, completion)
        Some(_) -> [head, ..mark_block_completed(tail, completion)]
      }
  }
}

fn complete_first_block(
  block: time_bill.MicroBlock,
  remaining: List(time_bill.MicroBlock),
  completion: time_bill.BlockCompletion,
) -> List(time_bill.MicroBlock) {
  let updated_block =
    time_bill.MicroBlock(..block, completion: Some(completion))

  [updated_block, ..remaining]
}

/// Records an error in the time session.
pub fn record_error(session: TimeSession, message: String) -> TimeSession {
  TimeSession(..session, last_error: Some(message))
}

/// Finds a time bill by its ID.
pub fn find_time_bill(
  session: TimeSession,
  bill_id: String,
) -> Option(time_bill.TimeBill) {
  session.all_time_bills
  |> list.find(fn(bill) { bill.id == bill_id })
  |> result.map(Some)
  |> result.unwrap(None)
}

/// Updates an existing time bill in the session.
pub fn update_time_bill(
  session: TimeSession,
  updated_bill: time_bill.TimeBill,
) -> TimeSession {
  let new_all_bills =
    session.all_time_bills
    |> list.map(fn(bill) {
      case bill.id == updated_bill.id {
        True -> updated_bill
        False -> bill
      }
    })

  let new_active_bill = case session.active_time_bill {
    Some(active) if active.id == updated_bill.id -> Some(updated_bill)
    _ -> session.active_time_bill
  }

  TimeSession(
    ..session,
    all_time_bills: new_all_bills,
    active_time_bill: new_active_bill,
    last_error: None,
  )
}
