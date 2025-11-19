import gleeunit
import session

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn llm_limit_update_test() {
  let bill = session.Bill(id: "T-1", title: "Test Bill", summary: "Demo")
  let base = session.initial_session(bill)
  let updated = session.set_llm_calls_limit(base, 42)

  assert base.llm_calls_limit == session.default_llm_limit()
  assert updated.llm_calls_limit == 42
}

pub fn advance_to_next_bill_keeps_budget_test() {
  let first = session.Bill(id: "T-1", title: "First", summary: "One")
  let second = session.Bill(id: "T-2", title: "Second", summary: "Two")
  let with_docket = session.initial_session_with_docket(first, [second])
  let closed = session.Session(
    ..with_docket,
    status: session.Closed,
    llm_calls_used: 5,
  )

  let advanced = session.advance_to_next_bill(closed)

  assert advanced.bill.id == second.id
  assert advanced.llm_calls_used == 5
  assert advanced.status == session.InDebate
}
