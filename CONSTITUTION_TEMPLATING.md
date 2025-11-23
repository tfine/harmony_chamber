# Constitutional Templating System

This repository now ships with a small templating layer so we can experiment with new constitutions without rewriting prompts or core logic. It focuses on clarity and speed: each template is a named, readable constitution with a few knobs that can be overridden at runtime.

## What It Provides
- **Typed constitution model** – Principles, rights, duties, narrative context, decision rules, and procedural knobs are kept together.
- **Prebuilt templates** – `constitution.catalog/0` exposes a few ready-made constitutions (foundation, emergency mandate, consensus lab).
- **Mergeable overrides** – `constitution.materialize/2` applies `TemplateOverrides` to any template, handling list merge or replacement plus procedural tweaks.
- **Renderable summaries** – `constitution.render/1` produces a human/LLM-friendly description that can drop directly into prompts or UI.

## Core API (Gleam)
- `constitution.catalog() -> List(ConstitutionTemplate)` – discover available templates.
- `constitution.find_template(id) -> Option(ConstitutionTemplate)` – helper lookup.
- `constitution.materialize(template, overrides) -> Constitution` – turn a template into a specific constitution instance.
- `constitution.empty_overrides()` / `constitution.default_procedural_overrides()` – start points for targeted overrides.
- `Override` values: `Keep` (no change), `Extend([items])` (append + dedupe), `Replace([items])` (swap out entirely).

## Usage Example
```gleam
import constitution
import gleam/io

pub fn build_experiment() -> constitution.Constitution {
  let base =
    case constitution.find_template("consensus_lab") {
      Some(template) -> template
      None -> constitution.ConstitutionTemplate(
        id: "fallback",
        label: "Fallback",
        description: "Default if catalog changes",
        base: constitution.genesis(),
      )
    }

  let overrides =
    constitution.TemplateOverrides(
      ..constitution.empty_overrides(),
      tagline: Some("Pluralist lab with strong privacy guarantees."),
      rights: constitution.Extend([constitution.RightToPrivacy]),
      procedures: constitution.ProceduralOverrides(
        call_vote_support_needed: Some(6),
        bill_majority: Some(0.62),
        amendment_majority: None,
        objection_window_turns: Some(2),
        automatic_vote_turn_limit: None,
        context_window: Some(2800),
      ),
    )

  let charter = constitution.materialize(base, overrides)
  io.debug(constitution.render(charter))
  charter
}
```

## Suggested Next Steps
- Feed `constitution.render/1` into debate prompts so agents cite their current charter.
- Thread `procedures` into session rules (call-vote threshold, amendment majority, debate turn limit).
- Log the template id + overrides in snapshots so political experiments can be replayed and compared.

## User Senate presets
`src/senate_presets.gleam` exposes ready-made bundles pairing constitution templates with roster sizes and autopilot defaults (e.g., `populus_parliament`, `checks_and_balances`, `rapid_emergency`, `consensus_lab_mini`). These are intended for UI pickers.

Key functions:
- `senate_presets.presets/0` – list all shipped presets.
- `senate_presets.find_preset/1` – lookup by id.
- `senate_presets.roster_for/1` – build a roster recipe (clamped to available senators).
- `senate_presets.constitution_for/1` – resolve the configured constitution (falls back to `genesis` if missing).

New high-impact templates:
- `council_democracy` – polycentric, consensus-first with long objection windows.
- `liquid_proxy` – delegable voting with revocation-friendly norms.
- `swarm_iteration` – rapid LLM-style swarm with rotating leads and bounded dictator fallback.

New presets for quick launch:
- `council_polycentric` (25 seats), `liquid_proxy_30` (30 seats), `swarm_rapid` (12 seats) alongside earlier parliamentary/separation/consensus options.

Runtime hook:
- Set `HARMONY_CONSTITUTION_TEMPLATE` (e.g., `swarm_iteration`, `council_democracy`) to boot the chamber with that charter’s procedural rules. If unset or unknown, the system falls back to the genesis constitution.
