import gleeunit
import gleam/list
import gleam/option.{Some}
import senate_presets
import senators

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn roster_clamps_to_available_test() {
  let limited = senate_presets.roster_for(senate_presets.FirstN(10))
  let full = senate_presets.roster_for(senate_presets.FirstN(200))

  assert list.length(limited) == 10
  assert list.length(full) == list.length(senators.all_senators())
}

pub fn preset_lookup_and_constitution_test() {
  let assert Some(preset) = senate_presets.find_preset("populus_parliament")
  let charter = senate_presets.constitution_for(preset)

  assert charter.id == "parliamentary_majority"
  assert charter.procedures.call_vote_support_needed == 3
  assert charter.procedures.objection_window_turns == 1
}

pub fn preset_catalog_size_test() {
  let ids = senate_presets.presets() |> list.map(fn(p) { p.id })

  assert list.length(ids) >= 7
  assert list.contains(ids, "consensus_lab_mini")
  assert list.contains(ids, "swarm_rapid")
}
