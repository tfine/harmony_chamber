import gleam/erlang/process
import session

/// Opaque handle to the session manager process.
pub opaque type Manager {
  Manager(mailbox: process.Subject(Message))
}

/// Messages understood by the manager process. Kept private so we can extend
/// the protocol later (e.g., applying functions or spawning sub-agents).
type Message {
  Fetch(process.Subject(session.Session))
  Store(session.Session, process.Subject(Nil))
}

/// Start the manager with an initial `Session`. Call this exactly once during
/// application boot and hold on to the returned `Manager` handle.
pub fn start(initial_session: session.Session) -> Manager {
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

/// Retrieve the current `Session` snapshot synchronously.
pub fn current(manager: Manager) -> session.Session {
  let reply = process.new_subject()
  process.send(manager.mailbox, Fetch(reply))
  process.receive_forever(reply)
}

/// Replace the stored session with a new value (used after running debate steps).
pub fn replace(manager: Manager, new_session: session.Session) -> Nil {
  let ack = process.new_subject()
  process.send(manager.mailbox, Store(new_session, ack))
  let _ = process.receive_forever(ack)
  Nil
}

fn loop(
  mailbox: process.Subject(Message),
  current: session.Session,
) -> Nil {
  case process.receive_forever(mailbox) {
    Fetch(reply) -> {
      process.send(reply, current)
      loop(mailbox, current)
    }
    Store(new_session, ack) -> {
      process.send(ack, Nil)
      loop(mailbox, new_session)
    }
  }
}
