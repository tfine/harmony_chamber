import constitution
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import senators

/// Describes how to assemble a roster for a user-generated Senate.
pub type RosterConfig {
  FullRoster
  FirstN(Int)
}

/// High-level preset combining a roster recipe with a constitutional template id.
/// These are meant to be listed in a UI so users can launch a Senate quickly.
pub type SenatePreset {
  SenatePreset(
    id: String,
    label: String,
    description: String,
    constitution_id: String,
    roster: RosterConfig,
    autopilot_enabled: Bool,
    autopilot_mode: String, // "debate", "time", or "both"
    steps_per_tick: Int,
  )
}

/// All shipped presets. Safe to extend without breaking existing callers.
pub fn presets() -> List(SenatePreset) {
  [
    SenatePreset(
      id: "populus_parliament",
      label: "Populus Parliament",
      description: "30-seat fast agenda with parliamentary-style confidence rules.",
      constitution_id: "parliamentary_majority",
      roster: FirstN(30),
      autopilot_enabled: True,
      autopilot_mode: "debate",
      steps_per_tick: 2,
    ),
    SenatePreset(
      id: "checks_and_balances",
      label: "Checks & Balances",
      description: "40-seat separation-of-powers simulation with longer objections.",
      constitution_id: "separation_checks",
      roster: FirstN(40),
      autopilot_enabled: True,
      autopilot_mode: "debate",
      steps_per_tick: 1,
    ),
    SenatePreset(
      id: "rapid_emergency",
      label: "Rapid Emergency Council",
      description: "20-seat crisis council using the emergency mandate template.",
      constitution_id: "emergency_mandate",
      roster: FirstN(20),
      autopilot_enabled: True,
      autopilot_mode: "both",
      steps_per_tick: 3,
    ),
    SenatePreset(
      id: "consensus_lab_mini",
      label: "Consensus Lab Mini",
      description: "15-seat consensus experiment with supermajority expectations.",
      constitution_id: "consensus_lab",
      roster: FirstN(15),
      autopilot_enabled: False,
      autopilot_mode: "debate",
      steps_per_tick: 1,
    ),
    SenatePreset(
      id: "council_polycentric",
      label: "Council Polycentric",
      description: "25-seat council democracy with long objections and consensus-first flow.",
      constitution_id: "council_democracy",
      roster: FirstN(25),
      autopilot_enabled: False,
      autopilot_mode: "debate",
      steps_per_tick: 1,
    ),
    SenatePreset(
      id: "liquid_proxy_30",
      label: "Liquid Proxy 30",
      description: "30-seat chamber experimenting with delegation-heavy decision making.",
      constitution_id: "liquid_proxy",
      roster: FirstN(30),
      autopilot_enabled: True,
      autopilot_mode: "debate",
      steps_per_tick: 2,
    ),
    SenatePreset(
      id: "swarm_rapid",
      label: "Swarm Rapid",
      description: "12-seat rapid-iteration swarm with rotating lead and dictator safety valve.",
      constitution_id: "swarm_iteration",
      roster: FirstN(12),
      autopilot_enabled: True,
      autopilot_mode: "debate",
      steps_per_tick: 3,
    ),
  ]
}

/// Find a preset by id.
pub fn find_preset(id: String) -> Option(SenatePreset) {
  case list.find(presets(), fn(preset) { preset.id == id }) {
    Ok(preset) -> Some(preset)
    Error(Nil) -> None
  }
}

/// Build a roster for a preset. Guards against requesting more than available.
pub fn roster_for(config: RosterConfig) -> List(senators.Senator) {
  let all = senators.all_senators()
  case config {
    FullRoster -> all
    FirstN(count) -> {
      let safe = int.min(count, list.length(all))
      all |> list.take(safe)
    }
  }
}

/// Resolve the constitution for a preset, falling back to the genesis charter
/// if an unknown id is provided.
pub fn constitution_for(preset: SenatePreset) -> constitution.Constitution {
  case constitution.find_template(preset.constitution_id) {
    Some(template) -> template.base
    None -> constitution.genesis()
  }
}
