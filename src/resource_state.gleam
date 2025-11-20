//// Resource tracking for AGATA time legislation.
//// Tracks budget, time spent, and conceptual allocations across pillars.

import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import time_bill.{type Pillar}

/// Overall resource state for the AGATA project
pub type ResourceState {
  ResourceState(
    /// Available budget in dollars
    available_budget: Float,
    /// Budget allocations by category
    allocations: Dict(String, Float),
    /// Time tracking
    time_tracking: TimeTracking,
    /// Last updated timestamp
    last_updated: String,
  )
}

/// Time tracking across the project
pub type TimeTracking {
  TimeTracking(
    /// Total minutes of work completed
    total_minutes_completed: Int,
    /// Minutes by pillar
    minutes_by_pillar: Dict(String, Int),
    /// Minutes by person
    todd_minutes: Int,
    delaney_minutes: Int,
    /// Number of blocks completed
    blocks_completed: Int,
  )
}

/// Initialize resource state with starting budget
pub fn initial_state(starting_budget: Float) -> ResourceState {
  ResourceState(
    available_budget: starting_budget,
    allocations: dict.new(),
    time_tracking: TimeTracking(
      total_minutes_completed: 0,
      minutes_by_pillar: dict.new(),
      todd_minutes: 0,
      delaney_minutes: 0,
      blocks_completed: 0,
    ),
    last_updated: "",
  )
}

/// Default AGATA starting state ($2000 budget)
pub fn agata_initial() -> ResourceState {
  initial_state(2000.0)
}

/// Record time spent on a block
pub fn record_time(
  state: ResourceState,
  minutes: Int,
  todd_worked: Bool,
  delaney_worked: Bool,
  pillar: Option(Pillar),
) -> ResourceState {
  let tracking = state.time_tracking

  let new_total = tracking.total_minutes_completed + minutes
  let new_todd = case todd_worked {
    True -> tracking.todd_minutes + minutes
    False -> tracking.todd_minutes
  }
  let new_delaney = case delaney_worked {
    True -> tracking.delaney_minutes + minutes
    False -> tracking.delaney_minutes
  }
  let new_blocks = tracking.blocks_completed + 1

  let new_by_pillar = case pillar {
    Some(p) -> {
      let pillar_key = time_bill.pillar_to_string(p)
      let current =
        dict.get(tracking.minutes_by_pillar, pillar_key)
        |> result.unwrap(0)
      dict.insert(tracking.minutes_by_pillar, pillar_key, current + minutes)
    }
    None -> tracking.minutes_by_pillar
  }

  ResourceState(
    ..state,
    time_tracking: TimeTracking(
      total_minutes_completed: new_total,
      minutes_by_pillar: new_by_pillar,
      todd_minutes: new_todd,
      delaney_minutes: new_delaney,
      blocks_completed: new_blocks,
    ),
  )
}

/// Allocate budget to a category
pub fn allocate_budget(
  state: ResourceState,
  category: String,
  amount: Float,
) -> Result(ResourceState, String) {
  let current_allocation =
    dict.get(state.allocations, category)
    |> result.unwrap(0.0)

  let new_allocation = current_allocation +. amount

  case new_allocation <=. state.available_budget {
    True ->
      Ok(
        ResourceState(
          ..state,
          allocations: dict.insert(state.allocations, category, new_allocation),
        ),
      )
    False ->
      Error(
        "Insufficient budget. Available: $"
        <> float.to_string(state.available_budget)
        <> ", Requested: $"
        <> float.to_string(amount),
      )
  }
}

/// Spend from an allocated category
pub fn spend_from_allocation(
  state: ResourceState,
  category: String,
  amount: Float,
) -> Result(ResourceState, String) {
  case dict.get(state.allocations, category) {
    Ok(allocated) ->
      case allocated >=. amount {
        True -> {
          let new_allocated = allocated -. amount
          let new_available = state.available_budget -. amount
          Ok(
            ResourceState(
              ..state,
              available_budget: new_available,
              allocations: dict.insert(
                state.allocations,
                category,
                new_allocated,
              ),
            ),
          )
        }
        False ->
          Error(
            "Insufficient allocation in "
            <> category
            <> ". Allocated: $"
            <> float.to_string(allocated)
            <> ", Requested: $"
            <> float.to_string(amount),
          )
      }
    Error(_) -> Error("No allocation found for category: " <> category)
  }
}

/// Get total allocated budget
pub fn total_allocated(state: ResourceState) -> Float {
  state.allocations
  |> dict.values
  |> list.fold(0.0, float.add)
}

/// Get unallocated budget
pub fn unallocated_budget(state: ResourceState) -> Float {
  state.available_budget -. total_allocated(state)
}

/// Get time spent on a specific pillar
pub fn time_for_pillar(state: ResourceState, pillar: Pillar) -> Int {
  let key = time_bill.pillar_to_string(pillar)
  dict.get(state.time_tracking.minutes_by_pillar, key)
  |> result.unwrap(0)
}

/// Format resource state as a summary string
pub fn summary(state: ResourceState) -> String {
  let tracking = state.time_tracking
  let total_hours = int.to_float(tracking.total_minutes_completed) /. 60.0
  let todd_hours = int.to_float(tracking.todd_minutes) /. 60.0
  let delaney_hours = int.to_float(tracking.delaney_minutes) /. 60.0

  let allocated = total_allocated(state)
  let unallocated = unallocated_budget(state)

  string.join(
    [
      "=== RESOURCE STATE ===",
      "",
      "Budget:",
      "  Available: $" <> float.to_string(state.available_budget),
      "  Allocated: $" <> float.to_string(allocated),
      "  Unallocated: $" <> float.to_string(unallocated),
      "",
      "Time Tracking:",
      "  Total hours: " <> float.to_string(total_hours),
      "  Todd hours: " <> float.to_string(todd_hours),
      "  Delaney hours: " <> float.to_string(delaney_hours),
      "  Blocks completed: " <> int.to_string(tracking.blocks_completed),
      "",
      "Last updated: " <> state.last_updated,
    ],
    "\n",
  )
}

/// Format allocations as a list
pub fn format_allocations(state: ResourceState) -> String {
  case dict.to_list(state.allocations) {
    [] -> "No allocations yet"
    items ->
      items
      |> list.map(fn(pair) {
        let #(category, amount) = pair
        "  " <> category <> ": $" <> float.to_string(amount)
      })
      |> string.join("\n")
  }
}

/// Format time by pillar
pub fn format_time_by_pillar(state: ResourceState) -> String {
  case dict.to_list(state.time_tracking.minutes_by_pillar) {
    [] -> "No time tracked by pillar yet"
    items ->
      items
      |> list.map(fn(pair) {
        let #(pillar, minutes) = pair
        let hours = int.to_float(minutes) /. 60.0
        "  " <> pillar <> ": " <> float.to_string(hours) <> " hours"
      })
      |> string.join("\n")
  }
}
