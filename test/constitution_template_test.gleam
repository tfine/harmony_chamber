import constitution
import gleam/list
import gleam/option.{None, Some}
import gleam/string

pub fn extend_and_dedup_lists_test() {
  let template =
    constitution.ConstitutionTemplate(
      id: "tmp",
      label: "Tmp",
      description: "Temporary template for test",
      base: constitution.genesis(),
    )

  let overrides =
    constitution.TemplateOverrides(
      ..constitution.empty_overrides(),
      principles: constitution.Extend([constitution.PromoteLongTermSurvival]),
      rights: constitution.Extend([constitution.RightToVote]),
      context_append: ["Appended context."],
      procedures: constitution.ProceduralOverrides(
        call_vote_support_needed: Some(3),
        bill_majority: None,
        amendment_majority: None,
        objection_window_turns: Some(1),
        automatic_vote_turn_limit: Some(8),
        context_window: Some(1024),
      ),
    )

  let result = constitution.materialize(template, overrides)

  assert list.contains(result.principles, constitution.PromoteLongTermSurvival)
  assert list.length(result.rights) == 3 // deduplicates RightToVote
  assert result.procedures.call_vote_support_needed == 3
  assert result.procedures.automatic_vote_turn_limit == 8
  assert result.procedures.objection_window_turns == 1
  assert result.context_window == 1024
  assert string.contains(result.context_text, "Appended context.")
}

pub fn replace_rules_and_labels_test() {
  let template =
    constitution.ConstitutionTemplate(
      id: "tmp",
      label: "Tmp",
      description: "Temporary template for test",
      base: constitution.genesis(),
    )

  let overrides =
    constitution.TemplateOverrides(
      ..constitution.empty_overrides(),
      id: Some("localist_charter"),
      label: Some("Localist Charter"),
      tagline: Some("Local stewardship first."),
      principles: constitution.Replace([constitution.EnsureFairness]),
      decision_rules: constitution.Replace([
        "Protect local autonomy.",
        "Document consent in writing.",
      ]),
      procedures: constitution.ProceduralOverrides(
        call_vote_support_needed: None,
        bill_majority: Some(0.75),
        amendment_majority: Some(0.67),
        objection_window_turns: None,
        automatic_vote_turn_limit: None,
        context_window: None,
      ),
    )

  let result = constitution.materialize(template, overrides)

  assert result.id == "localist_charter"
  assert result.label == "Localist Charter"
  assert result.tagline == "Local stewardship first."
  assert result.principles == [constitution.EnsureFairness]
  assert result.decision_rules == [
    "Protect local autonomy.",
    "Document consent in writing.",
  ]
  assert result.procedures.bill_majority == 0.75
  assert result.procedures.amendment_majority == 0.67
}

pub fn catalog_has_foundation_test() {
  let ids = constitution.catalog() |> list.map(fn(template) { template.id })

  assert list.contains(ids, "deliberative_foundation")
  assert list.length(ids) >= 3
}
