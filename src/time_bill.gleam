//// Time legislation data types for AGATA micro-block governance.
//// Designed to work alongside traditional Senate bills while focusing on
//// 5-15 minute time blocks for Todd Fine and Delaney Mills.

import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import senators

/// A time bill governs specific micro-blocks of human work.
/// Unlike traditional bills, these are immediate, actionable, and tied to
/// concrete time commitments and human energy levels.
pub type TimeBill {
  TimeBill(
    /// Unique identifier for this time bill
    id: String,
    /// Short, action-oriented title
    title: String,
    /// Clear purpose statement
    purpose: String,
    /// Which AGATA pillars this connects to
    pillar_links: List(Pillar),
    /// Time horizon for this work
    time_horizon: TimeHorizon,
    /// When this bill was created
    created_at: String,
    /// When this bill becomes active
    effective_at: String,
    /// Which senator(s) proposed this
    proposers: List(senators.Senator),
    /// The actual micro-blocks of work
    micro_blocks: List(MicroBlock),
    /// Current status
    status: TimeBillStatus,
    /// Budget implications (conceptual for now)
    budget_thinking: Option(BudgetThinking),
  )
}

/// A single micro-block: 5-15 minutes of focused work
pub type MicroBlock {
  MicroBlock(
    /// Duration in minutes (typically 5, 10, or 15)
    duration_minutes: Int,
    /// Who is assigned to this block
    assignees: BlockAssignees,
    /// Step-by-step instructions
    instructions: List(String),
    /// What artifacts/outputs are expected
    expected_artifacts: List(String),
    /// Awareness of human limitations
    limitation_note: String,
    /// Prompts for post-block reflection
    reflection_prompts: List(String),
    /// Actual completion report (filled in after)
    completion: Option(BlockCompletion),
  )
}

/// Who does what in a micro-block
pub type BlockAssignees {
  BlockAssignees(
    todd_tasks: List(String),
    delaney_tasks: List(String),
    joint_tasks: List(String),
  )
}

/// Report on what actually happened in a block
pub type BlockCompletion {
  BlockCompletion(
    /// Actual time spent
    actual_minutes: Int,
    /// What got done
    completed_tasks: List(String),
    /// Where things got stuck
    blockers: List(String),
    /// New needs that emerged
    new_needs: List(String),
    /// Energy levels after
    todd_energy_after: EnergyLevel,
    delaney_energy_after: EnergyLevel,
    /// Timestamp of completion
    completed_at: String,
  )
}

/// AGATA project pillars
pub type Pillar {
  Farm
  Film
  Music
  Residency
  DigitalLab
  MeshNetwork
  Institute
  Governance
  Ritual
  History
  Education
}

/// Time horizons for planning
pub type TimeHorizon {
  ThisHour
  Today
  ThisWeek
  ThisMonth
  ThisQuarter
  LongTerm
}

/// Status of a time bill
pub type TimeBillStatus {
  Proposed
  Active
  InProgress
  Completed
  Deferred
  Superseded
}

/// Conceptual budget thinking (not actual accounting yet)
pub type BudgetThinking {
  BudgetThinking(
    /// Estimated cost if any
    estimated_cost: Option(Float),
    /// What budget category this falls under
    category: String,
    /// Notes on financial implications
    notes: String,
  )
}

/// Human energy levels
pub type EnergyLevel {
  Low
  Medium
  High
}

/// Convert energy level to string
pub fn energy_to_string(level: EnergyLevel) -> String {
  case level {
    Low -> "low"
    Medium -> "medium"
    High -> "high"
  }
}

/// Parse energy level from string
pub fn energy_from_string(s: String) -> Result(EnergyLevel, String) {
  case s {
    "low" -> Ok(Low)
    "medium" -> Ok(Medium)
    "high" -> Ok(High)
    _ -> Error("Invalid energy level: " <> s)
  }
}

/// Convert pillar to string
pub fn pillar_to_string(pillar: Pillar) -> String {
  case pillar {
    Farm -> "farm"
    Film -> "film"
    Music -> "music"
    Residency -> "residency"
    DigitalLab -> "digital_lab"
    MeshNetwork -> "mesh_network"
    Institute -> "institute"
    Governance -> "governance"
    Ritual -> "ritual"
    History -> "history"
    Education -> "education"
  }
}

/// Convert time horizon to string
pub fn time_horizon_to_string(horizon: TimeHorizon) -> String {
  case horizon {
    ThisHour -> "this_hour"
    Today -> "today"
    ThisWeek -> "this_week"
    ThisMonth -> "this_month"
    ThisQuarter -> "this_quarter"
    LongTerm -> "long_term"
  }
}

/// Convert status to string
pub fn status_to_string(status: TimeBillStatus) -> String {
  case status {
    Proposed -> "proposed"
    Active -> "active"
    InProgress -> "in_progress"
    Completed -> "completed"
    Deferred -> "deferred"
    Superseded -> "superseded"
  }
}

/// Validate that a micro-block duration is reasonable
pub fn validate_duration(minutes: Int) -> Result(Int, String) {
  case minutes {
    5 | 10 | 15 -> Ok(minutes)
    20 | 25 | 30 -> Ok(minutes)
    // Allowed but should have justification
    _ ->
      Error(
        "Duration must be 5, 10, 15, 20, 25, or 30 minutes. Got: "
        <> int.to_string(minutes),
      )
  }
}

/// Check if a time bill is currently actionable
pub fn is_actionable(bill: TimeBill) -> Bool {
  case bill.status {
    Active | InProgress -> True
    _ -> False
  }
}

/// Get the next incomplete micro-block
pub fn next_block(bill: TimeBill) -> Option(MicroBlock) {
  bill.micro_blocks
  |> list.find(fn(block: MicroBlock) {
    case block.completion {
      None -> True
      Some(_) -> False
    }
  })
  |> result.map(Some)
  |> result.unwrap(None)
}
