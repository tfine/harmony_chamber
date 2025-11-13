import chamber
import debate
import gleam/list
import senators

/// Shared helpers for seeding a demonstration chamber until persistent state
/// and orchestrator loops land. Centralising this logic keeps the HTTP layer
/// and API responses perfectly in sync.
pub fn roster() -> List(senators.Senator) {
  senators.all()
}

pub fn seeded_chamber() -> chamber.Chamber {
  let roster_list = roster()
  let base =
    chamber.new(active_bill(), build_queue(roster_list))
    |> chamber.submit_speech(
      "amy_klobuchar",
      "Colleagues, this chamber earned trust by repairing what broke first. The Civic Resilience Act strings together radio towers, spare bridge parts, and rapid training teams so that a washed-out culvert or frozen substation never severs a town from help.\n\nMinnesota’s bridge rebuilding effort taught me that the first few hours after a disaster decide whether families can stay in their homes. This plan puts purchasing power and pre-negotiated contracts into county hands before the storm hits.",
    )
    |> chamber.submit_speech(
      "cory_booker",
      "During the Newark blackout of 2003, neighbors hauled water up twelve flights of stairs because elevators stalled. The Civic Resilience Act honors that spirit by funding multilingual alert systems, backup power trailers, and community stipend programs so the people closest to the crisis have the gear they need.\n\nWhen federal partners braid resources with block captains and pastors, recovery becomes faster, fairer, and more transparent.",
    )

  let requested_vote =
    base
    |> chamber.current_debate
    |> debate.request_vote

  chamber.Chamber(..base, debate: requested_vote)
}

fn active_bill() -> chamber.Bill {
  chamber.Bill(
    id: "HC-001",
    title: "Civic Resilience Act",
    summary: "Modernizes emergency communications, backs redundant public works, and trains rapid response teams so every region can withstand storms, fires, and infrastructure shocks.",
  )
}

fn build_queue(roster: List(senators.Senator)) -> List(String) {
  roster
  |> list.map(fn(senator) { senator.id })
}
