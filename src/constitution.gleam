//// This module defines the foundational principles and structures for governance.
//// It provides the building blocks and evaluation criteria that the system will
//// use to autonomously generate and assess novel constitutions.

import gleam/list
import gleam/dict
import gleam/int

// A placeholder for a unique identifier for an agent.
pub type AgentId =
  String

/// A high-level principle that a constitution can aim to uphold. These are the
/// fundamental goals the system will optimize for.
pub type Principle {
  MaximizeCollectiveWellbeing
  EnsureFairness
  PromoteLongTermSurvival
  UpholdIndividualLiberty
}

/// A fundamental right granted to an agent under a constitution.
pub type Right {
  RightToVote
  RightToSpeak
  RightToOwnResources
  RightToPrivacy
}

/// A fundamental duty an agent must perform.
pub type Duty {
  DutyToVote
  DutyToContributeToCommonGood
}

/// Represents a single law or rule within the constitution.
/// For now, it's a simple string, but it could become a complex data structure.
pub type Law =
  String

/// The constitution is a collection of principles, rights, duties, and laws.
/// This is the structure that the system will learn to generate and refine.
pub type Constitution {
  Constitution(
    principles: List(Principle),
    rights: List(Right),
    duties: List(Duty),
    laws: List(Law),
    /// Narrative/context string fed to AIs to explain the constitution.
    context_text: String,
    /// High-level decision-making rules that guide agents (e.g., prompts or heuristics).
    decision_rules: List(String),
    /// Desired LLM context window (tokens) when reasoning under this constitution.
    context_window: Int,
    /// Minimum explicit call-vote signals required before ending debate.
    call_vote_support_needed: Int,
    /// Base majority threshold for passing bills (0.0-1.0).
    bill_majority: Float,
    /// Majority threshold for adopting amendments.
    amendment_majority: Float,
    /// Number of turns an objection window stays open after a call_vote.
    objection_window_turns: Int,
  )
}

/// A rich record of a completed session, containing all the data needed to
/// evaluate its performance against a constitution.
pub type SessionHistory {
  SessionHistory(
    events: List(String),
    agent_count: Int,
    final_resource_distribution: dict.Dict(AgentId, Int),
    laws_broken: Int,
  )
}

/// A collection of calculated scores for a session, broken down by principle.
pub type Metrics {
  Metrics(
    wellbeing_score: Float,
    fairness_score: Float,
    survival_score: Float,
    liberty_score: Float,
  )
}

/// Evaluates a session's history against a constitution to see how well it
/// performed. This function is the heart of the "provably fair" dream. It's
/// the fitness function for the genetic algorithm of governance.
pub fn evaluate(
  constitution: Constitution,
  history: SessionHistory,
) -> Metrics {
  // In a real implementation, this would be a series of complex calculations.
  // Here, we simulate those calculations to show how they would work.

  let wellbeing_score =
    history.final_resource_distribution
    |> dict.values
    |> int.sum
    |> int.to_float

  let fairness_score =
    case dict.is_empty(history.final_resource_distribution) {
      True -> 0.0
      False -> 1.0
    }

  let survival_score = {
    // Measures stability. Penalize heavily for breaking laws.
    // A single broken law could mean total system collapse.
    case history.laws_broken > 0 {
      True -> 0.0
      False -> 1.0
    }
  }

  let liberty_score = {
    // Measures how many rights are available to agents.
    let unique_rights = list.unique(constitution.rights)
    int.to_float(list.length(unique_rights)) /. 4.0 // 4 is the total # of possible rights
  }

  // Weigh the final scores based on the principles in this constitution
  let has_principle = fn(p) { list.contains(constitution.principles, p) }

  Metrics(
    wellbeing_score: case has_principle(MaximizeCollectiveWellbeing) {
      True -> wellbeing_score
      False -> 0.0
    },
    fairness_score: case has_principle(EnsureFairness) {
      True -> fairness_score
      False -> 0.0
    },
    survival_score: case has_principle(PromoteLongTermSurvival) {
      True -> survival_score
      False -> 0.0
    },
    liberty_score: case has_principle(UpholdIndividualLiberty) {
      True -> liberty_score
      False -> 0.0
    },
  )
}

/// Creates a basic, foundational constitution. This could be the "seed"
/// constitution from which all others evolve.
pub fn genesis() -> Constitution {
  Constitution(
    principles: [
      MaximizeCollectiveWellbeing,
      EnsureFairness,
      UpholdIndividualLiberty,
    ],
    rights: [RightToVote, RightToSpeak, RightToOwnResources],
    duties: [DutyToVote],
    laws: ["A senator may not harm another senator."],
    context_text:
      "This constitution balances collective wellbeing, fairness, survival, and liberty. "
      <> "Debate is open, transparent, and grounded in cited rights and duties. "
      <> "Votes close when enough senators explicitly request it, after a brief objection window.",
    decision_rules: [
      "Address each proposal with fairness and collective wellbeing in mind.",
      "Cite specific rights and duties when making a decision.",
      "Prefer transparency and explainability over rote authority.",
    ],
    context_window: 2048,
    call_vote_support_needed: 5,
    bill_majority: 0.51,
    amendment_majority: 0.55,
    objection_window_turns: 2,
  )
}
