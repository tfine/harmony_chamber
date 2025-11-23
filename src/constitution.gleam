//// This module defines the foundational principles and structures for governance.
//// It now includes a templating system so we can rapidly experiment with
//// different constitutions without rewriting prompts or core logic.

import gleam/dict
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

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

/// Procedural knobs that downstream systems (debate flow, vote handling, prompt
/// shapers) can pull from a constitution template.
pub type ProceduralRules {
  ProceduralRules(
    /// Minimum explicit call-vote signals required before ending debate.
    call_vote_support_needed: Int,
    /// Base majority threshold for passing bills (0.0-1.0).
    bill_majority: Float,
    /// Majority threshold for adopting amendments.
    amendment_majority: Float,
    /// Number of turns an objection window stays open after a call_vote.
    objection_window_turns: Int,
    /// Hard ceiling on debate turns before forcing a vote.
    automatic_vote_turn_limit: Int,
  )
}

/// The constitution is a collection of principles, rights, duties, and laws.
/// This is the structure that the system will learn to generate and refine.
pub type Constitution {
  Constitution(
    id: String,
    label: String,
    tagline: String,
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
    /// Procedural knobs for debate and voting.
    procedures: ProceduralRules,
  )
}

/// Discoverable template container. The `base` field holds a ready-to-use
/// constitution while the metadata makes it easy to present choices to humans.
pub type ConstitutionTemplate {
  ConstitutionTemplate(
    id: String,
    label: String,
    description: String,
    base: Constitution,
  )
}

/// How to merge list-like fields when applying overrides.
pub type Override(a) {
  Keep
  Replace(List(a))
  Extend(List(a))
}

/// Optional override slots for procedural rules.
pub type ProceduralOverrides {
  ProceduralOverrides(
    call_vote_support_needed: Option(Int),
    bill_majority: Option(Float),
    amendment_majority: Option(Float),
    objection_window_turns: Option(Int),
    automatic_vote_turn_limit: Option(Int),
    context_window: Option(Int),
  )
}

/// Optional override slots for turning a template into a new constitution.
pub type TemplateOverrides {
  TemplateOverrides(
    id: Option(String),
    label: Option(String),
    tagline: Option(String),
    context_text: Option(String),
    context_append: List(String),
    principles: Override(Principle),
    rights: Override(Right),
    duties: Override(Duty),
    laws: Override(Law),
    decision_rules: Override(String),
    procedures: ProceduralOverrides,
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

/// Creates a basic, foundational constitution. This can be used directly or as
/// the seed for new templates.
pub fn genesis() -> Constitution {
  base_foundation()
}

/// Quickly describe a constitution in prose, suitable for prompts or UI.
pub fn render(constitution: Constitution) -> String {
  let procedures = constitution.procedures
  let procedure_lines = [
    "- Call vote support: " <> int.to_string(procedures.call_vote_support_needed),
    "- Bill majority: " <> float.to_string(procedures.bill_majority),
    "- Amendment majority: " <> float.to_string(procedures.amendment_majority),
    "- Objection window (turns): " <> int.to_string(procedures.objection_window_turns),
    "- Auto vote turn limit: " <> int.to_string(procedures.automatic_vote_turn_limit),
  ]

  string.join(
    [
      constitution.label <> " (" <> constitution.id <> ")",
      constitution.tagline,
      "",
      "Principles:",
      bullet_lines(list.map(constitution.principles, principle_label)),
      "",
      "Rights:",
      bullet_lines(list.map(constitution.rights, right_label)),
      "",
      "Duties:",
      bullet_lines(list.map(constitution.duties, duty_label)),
      "",
      "Laws:",
      bullet_lines(constitution.laws),
      "",
      "Decision rules:",
      bullet_lines(constitution.decision_rules),
      "",
      "Procedures:",
      bullet_lines(procedure_lines),
      "",
      "Context:",
      constitution.context_text,
      "",
      "LLM context window (tokens): " <> int.to_string(constitution.context_window),
    ],
    "\n",
  )
}

/// Return a set of ready-made constitutional templates for experiments.
pub fn catalog() -> List(ConstitutionTemplate) {
  [
    base_template(),
    emergency_mandate_template(),
    consensus_lab_template(),
    parliamentary_template(),
    separation_checks_template(),
    council_template(),
    liquid_proxy_template(),
    swarm_template(),
  ]
}

/// Apply optional overrides to a template to produce a new constitution. This
/// is the primary way to experiment with different political setups without
/// rewriting every list by hand.
pub fn materialize(
  template: ConstitutionTemplate,
  overrides: TemplateOverrides,
) -> Constitution {
  let base = template.base
  Constitution(
    id: or_default(overrides.id, base.id),
    label: or_default(overrides.label, base.label),
    tagline: or_default(overrides.tagline, base.tagline),
    principles: merge_collection(base.principles, overrides.principles),
    rights: merge_collection(base.rights, overrides.rights),
    duties: merge_collection(base.duties, overrides.duties),
    laws: merge_collection(base.laws, overrides.laws),
    context_text: merge_context(base.context_text, overrides.context_text, overrides.context_append),
    decision_rules: merge_collection(base.decision_rules, overrides.decision_rules),
    context_window:
      or_default(overrides.procedures.context_window, base.context_window),
    procedures: merge_procedural_rules(base.procedures, overrides.procedures),
  )
}

/// Default "no-op" overrides for callers that want to modify a few fields.
pub fn empty_overrides() -> TemplateOverrides {
  TemplateOverrides(
    id: None,
    label: None,
    tagline: None,
    context_text: None,
    context_append: [],
    principles: Keep,
    rights: Keep,
    duties: Keep,
    laws: Keep,
    decision_rules: Keep,
    procedures: default_procedural_overrides(),
  )
}

/// Default "no-op" procedural overrides for callers.
pub fn default_procedural_overrides() -> ProceduralOverrides {
  ProceduralOverrides(
    call_vote_support_needed: None,
    bill_majority: None,
    amendment_majority: None,
    objection_window_turns: None,
    automatic_vote_turn_limit: None,
    context_window: None,
  )
}

/// Look up a template by id if present in the catalog.
pub fn find_template(id: String) -> Option(ConstitutionTemplate) {
  case list.find(catalog(), fn(template) { template.id == id }) {
    Ok(template) -> Some(template)
    Error(Nil) -> None
  }
}

fn base_template() -> ConstitutionTemplate {
  ConstitutionTemplate(
    id: "deliberative_foundation",
    label: "Deliberative Foundation",
    description: "Balanced wellbeing/fairness/liberty baseline with transparent debate and simple majorities.",
    base: base_foundation(),
  )
}

fn emergency_mandate_template() -> ConstitutionTemplate {
  let overrides =
    TemplateOverrides(
      ..empty_overrides(),
      id: Some("emergency_mandate"),
      label: Some("Emergency Mandate"),
      tagline: Some("Survival-first charter for short crises where rapid consensus is needed."),
      context_append: [
        "This template prioritizes long-term survival and rapid hazard response over deliberative pacing.",
      ],
      principles: Extend([PromoteLongTermSurvival]),
      duties: Extend([DutyToContributeToCommonGood]),
      decision_rules: Extend([
        "Default to decisive action when survival risks are non-trivial.",
        "Accept temporary rights friction if doing so clearly improves resilience.",
      ]),
      procedures: ProceduralOverrides(
        call_vote_support_needed: Some(3),
        bill_majority: Some(0.5),
        amendment_majority: Some(0.5),
        objection_window_turns: Some(1),
        automatic_vote_turn_limit: Some(10),
        context_window: Some(3072),
      ),
    )

  let constitution = materialize(base_template(), overrides)

  ConstitutionTemplate(
    id: constitution.id,
    label: constitution.label,
    description: "Fast-track rules, survival principle added, and shorter objection windows.",
    base: constitution,
  )
}

fn consensus_lab_template() -> ConstitutionTemplate {
  let overrides =
    TemplateOverrides(
      ..empty_overrides(),
      id: Some("consensus_lab"),
      label: Some("Consensus Lab"),
      tagline: Some("Supermajority governance that rewards cross-faction collaboration."),
      context_append: [
        "Designed for experiments in broad coalition building. Forces higher agreement before closing debate.",
      ],
      principles: Extend([EnsureFairness, UpholdIndividualLiberty]),
      rights: Extend([RightToPrivacy]),
      decision_rules: Extend([
        "Explicitly cite how proposals balance minority protections with majoritarian legitimacy.",
        "Hold the floor until opposing factions acknowledge trade-offs in writing.",
      ]),
      procedures: ProceduralOverrides(
        call_vote_support_needed: Some(7),
        bill_majority: Some(0.66),
        amendment_majority: Some(0.6),
        objection_window_turns: Some(3),
        automatic_vote_turn_limit: Some(20),
        context_window: Some(3072),
      ),
    )

  let constitution = materialize(base_template(), overrides)

  ConstitutionTemplate(
    id: constitution.id,
    label: constitution.label,
    description: "Supermajority experiment with extended objection windows and privacy protections.",
    base: constitution,
  )
}

fn parliamentary_template() -> ConstitutionTemplate {
  let overrides =
    TemplateOverrides(
      ..empty_overrides(),
      id: Some("parliamentary_majority"),
      label: Some("Parliamentary Majority"),
      tagline: Some("Government-led agenda with confidence votes and fast closure."),
      principles: Extend([MaximizeCollectiveWellbeing, EnsureFairness]),
      duties: Extend([DutyToContributeToCommonGood]),
      decision_rules: Extend([
        "Treat call-vote motions on government bills as confidence matters unless otherwise stated.",
        "Use closure/guillotine when debate stalls and a working majority is intact.",
        "Balance speed with fairness by guaranteeing minority response time before closure.",
      ]),
      context_append: [
        "This template models a fused executive-legislature: agenda control is centralized, and government defeat on key bills signals loss of confidence.",
      ],
      procedures: ProceduralOverrides(
        call_vote_support_needed: Some(3),
        bill_majority: Some(0.5),
        amendment_majority: Some(0.5),
        objection_window_turns: Some(1),
        automatic_vote_turn_limit: Some(10),
        context_window: Some(2800),
      ),
    )

  let constitution = materialize(base_template(), overrides)

  ConstitutionTemplate(
    id: constitution.id,
    label: constitution.label,
    description: "Fast parliamentary-style workflow with confidence signaling and short objection windows.",
    base: constitution,
  )
}

fn separation_checks_template() -> ConstitutionTemplate {
  let overrides =
    TemplateOverrides(
      ..empty_overrides(),
      id: Some("separation_checks"),
      label: Some("Separation of Powers"),
      tagline: Some("Higher thresholds, longer objections, and veto/override minded rules."),
      principles: Extend([UpholdIndividualLiberty, EnsureFairness]),
      rights: Extend([RightToPrivacy]),
      decision_rules: Extend([
        "Assume independent executive review; craft bills to survive a veto or explain override rationale.",
        "Use extended objection windows to surface minority protections before closure.",
        "Expect decentralized agenda setting; justify why this bill deserves floor time versus committee work.",
      ]),
      context_append: [
        "This template mimics a separated-powers legislature: slower flow, distributed agenda control, and explicit expectation of veto/override dynamics.",
      ],
      procedures: ProceduralOverrides(
        call_vote_support_needed: Some(7),
        bill_majority: Some(0.6),
        amendment_majority: Some(0.6),
        objection_window_turns: Some(3),
        automatic_vote_turn_limit: Some(22),
        context_window: Some(3200),
      ),
    )

  let constitution = materialize(base_template(), overrides)

  ConstitutionTemplate(
    id: constitution.id,
    label: constitution.label,
    description: "Checks-and-balances model with higher thresholds and longer deliberation.",
    base: constitution,
  )
}

fn council_template() -> ConstitutionTemplate {
  let overrides =
    TemplateOverrides(
      ..empty_overrides(),
      id: Some("council_democracy"),
      label: Some("Council Democracy"),
      tagline: Some("Polycentric, sortition-friendly chamber with strong minority protections."),
      principles: Extend([EnsureFairness, UpholdIndividualLiberty]),
      rights: Extend([RightToPrivacy]),
      decision_rules: Extend([
        "Guarantee minority response time before any closure or call-vote.",
        "Prioritize consensus; move to supermajority only after two objection-resolution rounds.",
        "Surface written steelman statements from opposing blocs before final passage.",
      ]),
      context_append: [
        "Designed for polycentric council-style governance with rotating facilitation and explicit minority protections.",
      ],
      procedures: ProceduralOverrides(
        call_vote_support_needed: Some(6),
        bill_majority: Some(0.65),
        amendment_majority: Some(0.6),
        objection_window_turns: Some(4),
        automatic_vote_turn_limit: Some(24),
        context_window: Some(3200),
      ),
    )

  let constitution = materialize(base_template(), overrides)

  ConstitutionTemplate(
    id: constitution.id,
    label: constitution.label,
    description: "Consensus-first council model with supermajority fallbacks and long objection windows.",
    base: constitution,
  )
}

fn liquid_proxy_template() -> ConstitutionTemplate {
  let overrides =
    TemplateOverrides(
      ..empty_overrides(),
      id: Some("liquid_proxy"),
      label: Some("Liquid Proxy"),
      tagline: Some("Delegable voting with transparency and quick revocation."),
      principles: Extend([MaximizeCollectiveWellbeing, EnsureFairness]),
      decision_rules: Extend([
        "When claiming delegated authority, cite the chain of delegation and its scope.",
        "Respect rapid revocation: assume proxies can be withdrawn between turns.",
        "Document intensity: note when delegated mandates express strong preferences.",
      ]),
      context_append: [
        "This template assumes delegates can temporarily carry others' votes; chains should stay short, visible, and easily revoked.",
      ],
      procedures: ProceduralOverrides(
        call_vote_support_needed: Some(5),
        bill_majority: Some(0.55),
        amendment_majority: Some(0.55),
        objection_window_turns: Some(2),
        automatic_vote_turn_limit: Some(18),
        context_window: Some(3000),
      ),
    )

  let constitution = materialize(base_template(), overrides)

  ConstitutionTemplate(
    id: constitution.id,
    label: constitution.label,
    description: "Liquid-democracy flavored rules with moderate thresholds and delegation-aware norms.",
    base: constitution,
  )
}

fn swarm_template() -> ConstitutionTemplate {
  let overrides =
    TemplateOverrides(
      ..empty_overrides(),
      id: Some("swarm_iteration"),
      label: Some("Swarm Iteration"),
      tagline: Some("Fast iterative LLM swarm with rotating lead and emergency dictator fallback."),
      principles: Extend([PromoteLongTermSurvival, MaximizeCollectiveWellbeing]),
      duties: Extend([DutyToContributeToCommonGood]),
      decision_rules: Extend([
        "Run rapid short-form rounds; each turn must add or refine concrete edits.",
        "Rotate lead every round; the lead must summarize swarm consensus and propose the next draft.",
        "If stalled after N rounds, authorize a temporary 'dictator' to synthesize a decision, subject to post-hoc review.",
      ]),
      context_append: [
        "Optimized for many short LLM calls: quick iterations, rotating lead, and a time-boxed dictatorship as a safety valve when consensus fails.",
      ],
      procedures: ProceduralOverrides(
        call_vote_support_needed: Some(2),
        bill_majority: Some(0.5),
        amendment_majority: Some(0.5),
        objection_window_turns: Some(1),
        automatic_vote_turn_limit: Some(8),
        context_window: Some(2400),
      ),
    )

  let constitution = materialize(base_template(), overrides)

  ConstitutionTemplate(
    id: constitution.id,
    label: constitution.label,
    description: "Swarm-style rapid iteration with rotating leads and a bounded dictator fallback.",
    base: constitution,
  )
}

fn base_foundation() -> Constitution {
  Constitution(
    id: "deliberative_foundation",
    label: "Deliberative Foundation",
    tagline: "Balances collective wellbeing, fairness, and liberty through transparent debate.",
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
    procedures: ProceduralRules(
      call_vote_support_needed: 5,
      bill_majority: 0.51,
      amendment_majority: 0.55,
      objection_window_turns: 2,
      automatic_vote_turn_limit: 16,
    ),
  )
}

fn merge_collection(base: List(a), override: Override(a)) -> List(a) {
  let merged =
    case override {
      Keep -> base
      Replace(values) -> values
      Extend(values) -> list.append(base, values)
    }

  list.unique(merged)
}

fn merge_procedural_rules(
  base: ProceduralRules,
  override: ProceduralOverrides,
) -> ProceduralRules {
  let ProceduralRules(
    call_vote_support_needed: call_vote_support_needed,
    bill_majority: bill_majority,
    amendment_majority: amendment_majority,
    objection_window_turns: objection_window_turns,
    automatic_vote_turn_limit: automatic_vote_turn_limit,
  ) = base

  ProceduralRules(
    call_vote_support_needed:
      or_default(override.call_vote_support_needed, call_vote_support_needed),
    bill_majority: or_default(override.bill_majority, bill_majority),
    amendment_majority: or_default(override.amendment_majority, amendment_majority),
    objection_window_turns:
      or_default(override.objection_window_turns, objection_window_turns),
    automatic_vote_turn_limit:
      or_default(override.automatic_vote_turn_limit, automatic_vote_turn_limit),
  )
}

fn merge_context(
  base: String,
  replacement: Option(String),
  append: List(String),
) -> String {
  let text = or_default(replacement, base)
  case append {
    [] -> text
    _ -> text <> "\n\n" <> string.join(append, "\n")
  }
}

fn bullet_lines(lines: List(String)) -> String {
  case lines {
    [] -> "- None"
    _ -> lines |> list.map(fn(line) { "- " <> line }) |> string.join("\n")
  }
}

fn principle_label(principle: Principle) -> String {
  case principle {
    MaximizeCollectiveWellbeing -> "Maximize collective wellbeing"
    EnsureFairness -> "Ensure fairness"
    PromoteLongTermSurvival -> "Promote long-term survival"
    UpholdIndividualLiberty -> "Uphold individual liberty"
  }
}

fn right_label(right: Right) -> String {
  case right {
    RightToVote -> "Right to vote"
    RightToSpeak -> "Right to speak"
    RightToOwnResources -> "Right to own resources"
    RightToPrivacy -> "Right to privacy"
  }
}

fn duty_label(duty: Duty) -> String {
  case duty {
    DutyToVote -> "Duty to vote"
    DutyToContributeToCommonGood -> "Duty to contribute to common good"
  }
}

fn or_default(value: Option(a), fallback: a) -> a {
  case value {
    Some(val) -> val
    None -> fallback
  }
}
