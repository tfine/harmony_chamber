import gleam/int
import gleam/string
import session
import gleam/option.{type Option, None}

@external(erlang, "erlang", "unique_integer")
fn unique_integer() -> Int

pub type Status {
  Queued
  Running
  Completed
  Errored(String)
}

pub type Mandate {
  Mandate(
    id: String,
    bill_id: String,
    bill_title: String,
    bill_summary: String,
    constitution_id: String,
    category: String, // "code" or other
    target_repo: String,
    branch_hint: String,
    tags: List(String),
  )
}

pub type Record {
  Record(
    mandate: Mandate,
    status: Status,
    pr_url: Option(String),
    branch: Option(String),
  )
}

pub fn from_completed_bill(
  bill: session.CompletedBill,
  constitution_id: String,
  target_repo: String,
  category: String,
) -> Mandate {
  let branch_hint =
    string.lowercase(bill.bill.id)
    |> string.replace(" ", "-")
    |> string.replace("/", "-")

  Mandate(
    id: generate_id(),
    bill_id: bill.bill.id,
    bill_title: bill.bill.title,
    bill_summary: bill.bill.summary,
    constitution_id: constitution_id,
    category: category,
    target_repo: target_repo,
    branch_hint: branch_hint,
    tags: [],
  )
}

pub fn initial_record(mandate: Mandate) -> Record {
  Record(mandate: mandate, status: Queued, pr_url: None, branch: None)
}

fn generate_id() -> String {
  let id = unique_integer()
  "impl-" <> int.to_string(id)
}
