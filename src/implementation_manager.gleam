import gleam/erlang/process
import gleam/list
import gleam/option.{type Option}
import implementation

pub opaque type Manager {
  Manager(mailbox: process.Subject(Message))
}

type Message {
  Fetch(process.Subject(List(implementation.Record)))
  Enqueue(implementation.Mandate)
  UpdateStatus(String, implementation.Status, Option(String), Option(String))
}

pub fn start() -> Manager {
  let handshake = process.new_subject()

  let _pid =
    process.spawn(fn() {
      let mailbox = process.new_subject()
      process.send(handshake, mailbox)
      loop(mailbox, [])
    })

  let subject = process.receive_forever(handshake)
  Manager(mailbox: subject)
}

pub fn all(manager: Manager) -> List(implementation.Record) {
  let reply = process.new_subject()
  process.send(manager.mailbox, Fetch(reply))
  process.receive_forever(reply)
}

pub fn enqueue(manager: Manager, mandate: implementation.Mandate) -> Nil {
  process.send(manager.mailbox, Enqueue(mandate))
}

pub fn update_status(
  manager: Manager,
  id: String,
  status: implementation.Status,
  pr_url: Option(String),
  branch: Option(String),
) -> Nil {
  process.send(manager.mailbox, UpdateStatus(id, status, pr_url, branch))
}

fn loop(
  mailbox: process.Subject(Message),
  records: List(implementation.Record),
) -> Nil {
  case process.receive_forever(mailbox) {
    Fetch(reply) -> {
      process.send(reply, records)
      loop(mailbox, records)
    }
    Enqueue(mandate) -> {
      let updated = [implementation.initial_record(mandate), ..records]
      loop(mailbox, updated)
    }
    UpdateStatus(id, status, pr_url, branch) -> {
      let updated =
        records
        |> list.map(fn(record) {
          case record.mandate.id == id {
            True -> implementation.Record(
              ..record,
              status: status,
              pr_url: pr_url,
              branch: branch,
            )
            False -> record
          }
        })
      loop(mailbox, updated)
    }
  }
}
