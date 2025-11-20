//// Manages the state of the AGATA time legislation session in a separate process.
//// This allows for concurrent access and updates to the TimeSession data.
//// The single-process mailbox keeps writes serialized so the Senate cannot
//// double-apply reports or bills and ensures updates remain predictable.

import gleam/erlang/process
import gleam/io
import human_status
import time_bill
import time_session

/// Opaque handle to the time session manager process.
pub opaque type Manager {
  Manager(mailbox: process.Subject(Message))
}

/// Messages understood by the manager process.
type Message {
  Fetch(process.Subject(time_session.TimeSession))
  Replace(time_session.TimeSession, process.Subject(Nil))
  UpdateHumanStatus(human_status.HumanStatus, process.Subject(time_session.TimeSession))
  UpdateBlockReport(human_status.BlockReport, process.Subject(time_session.TimeSession))
  SetActiveTimeBill(time_bill.TimeBill, process.Subject(time_session.TimeSession))
  AddTimeBill(time_bill.TimeBill, process.Subject(time_session.TimeSession))
  UpdateTimeBill(time_bill.TimeBill, process.Subject(time_session.TimeSession))
}

/// Start the manager with an initial `TimeSession`. Call this exactly once during
/// application boot and hold on to the returned `Manager` handle.
pub fn start(initial_session: time_session.TimeSession) -> Manager {
  let handshake: process.Subject(process.Subject(Message)) = process.new_subject()

  let _pid =
    process.spawn(fn() {
      let mailbox = process.new_subject()
      process.send(handshake, mailbox)
      loop(mailbox, initial_session)
    })

  let subject = process.receive_forever(handshake)
  Manager(mailbox: subject)
}

/// Retrieve the current `TimeSession` snapshot synchronously.
pub fn current(manager: Manager) -> time_session.TimeSession {
  let reply = process.new_subject()
  process.send(manager.mailbox, Fetch(reply))
  process.receive_forever(reply)
}

/// Replace the stored session with a new value.
pub fn replace(manager: Manager, new_session: time_session.TimeSession) -> Nil {
  let ack = process.new_subject()
  process.send(manager.mailbox, Replace(new_session, ack))
  let _ = process.receive_forever(ack)
  Nil
}

/// Records a new human status report and returns the updated session.
pub fn record_human_status(
  manager: Manager,
  status: human_status.HumanStatus,
) -> time_session.TimeSession {
  let reply = process.new_subject()
  process.send(manager.mailbox, UpdateHumanStatus(status, reply))
  process.receive_forever(reply)
}

/// Records a new block report and returns the updated session.
pub fn record_block_report(
  manager: Manager,
  report: human_status.BlockReport,
) -> time_session.TimeSession {
  let reply = process.new_subject()
  process.send(manager.mailbox, UpdateBlockReport(report, reply))
  process.receive_forever(reply)
}

/// Sets a time bill as active and returns the updated session.
pub fn set_active_time_bill(
  manager: Manager,
  bill: time_bill.TimeBill,
) -> time_session.TimeSession {
  let reply = process.new_subject()
  process.send(manager.mailbox, SetActiveTimeBill(bill, reply))
  process.receive_forever(reply)
}

/// Adds a new time bill to the list of all time bills and returns the updated session.
pub fn add_time_bill(
  manager: Manager,
  bill: time_bill.TimeBill,
) -> time_session.TimeSession {
  let reply = process.new_subject()
  process.send(manager.mailbox, AddTimeBill(bill, reply))
  process.receive_forever(reply)
}

/// Updates an existing time bill in the session and returns the updated session.
pub fn update_time_bill(
  manager: Manager,
  bill: time_bill.TimeBill,
) -> time_session.TimeSession {
  let reply = process.new_subject()
  process.send(manager.mailbox, UpdateTimeBill(bill, reply))
  process.receive_forever(reply)
}

fn loop(
  mailbox: process.Subject(Message),
  current: time_session.TimeSession,
) -> Nil {
  case process.receive_forever(mailbox) {
    Fetch(reply) -> {
      process.send(reply, current)
      loop(mailbox, current)
    }
    Replace(new_session, ack) -> {
      process.send(ack, Nil)
      loop(mailbox, new_session)
    }
    UpdateHumanStatus(status, reply) -> {
      let new_session = time_session.record_human_status(current, status)
      process.send(reply, new_session)
      loop(mailbox, new_session)
    }
    UpdateBlockReport(report, reply) -> {
      let new_session = time_session.record_block_report(current, report)
      process.send(reply, new_session)
      loop(mailbox, new_session)
    }
    SetActiveTimeBill(bill, reply) -> {
      let new_session = time_session.set_active_time_bill(current, bill)
      process.send(reply, new_session)
      loop(mailbox, new_session)
    }
    AddTimeBill(bill, reply) -> {
      let new_session = time_session.add_time_bill(current, bill)
      io.println(
        "[time senate] Passed time bill "
        <> bill.id
        <> " — "
        <> bill.title,
      )
      process.send(reply, new_session)
      loop(mailbox, new_session)
    }
    UpdateTimeBill(bill, reply) -> {
      let new_session = time_session.update_time_bill(current, bill)
      process.send(reply, new_session)
      loop(mailbox, new_session)
    }
  }
}
