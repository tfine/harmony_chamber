import envoy
import gleam/dict.{type Dict}
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/string

pub type Note {
  Note(name: String, contact: String, body: String)
}

pub opaque type Office {
  Office(mailbox: process.Subject(Message))
}

type Message {
  Store(String, Note)
  Fetch(String, process.Subject(List(Note)))
}

type State {
  State(notes: Dict(String, List(Note)))
}

pub fn start() -> Office {
  let mailbox = process.new_subject()

  let _pid = process.spawn(fn() { loop(mailbox, State(notes: dict.new())) })

  Office(mailbox: mailbox)
}

pub fn add_note(office: Office, senator_id: String, note: Note) -> Nil {
  process.send(office.mailbox, Store(senator_id, sanitize(note)))
}

pub fn notes_for(office: Office, senator_id: String) -> List(Note) {
  let reply = process.new_subject()
  process.send(office.mailbox, Fetch(senator_id, reply))
  case process.receive(reply, notes_timeout_ms()) {
    Ok(notes) -> notes
    Error(Nil) -> {
      log_timeout(senator_id)
      drain_late_note_reply(reply)
      []
    }
  }
}

fn loop(mailbox: process.Subject(Message), state: State) -> Nil {
  case process.receive_forever(mailbox) {
    Store(senator_id, note) -> {
      let updated = case dict.get(state.notes, senator_id) {
        Ok(notes) -> [note, ..notes]
        Error(_) -> [note]
      }

      let stored = dict.insert(state.notes, senator_id, updated)
      loop(mailbox, State(notes: stored))
    }
    Fetch(senator_id, reply) -> {
      let notes = case dict.get(state.notes, senator_id) {
        Ok(notes) -> notes
        Error(_) -> []
      }
      process.send(reply, notes)
      loop(mailbox, state)
    }
  }
}

fn sanitize(note: Note) -> Note {
  let Note(name:, contact:, body:) = note
  Note(
    name: string.trim(name),
    contact: string.trim(contact),
    body: string.trim(body),
  )
}

fn notes_timeout_ms() -> Int {
  case envoy.get("HARMONY_NOTES_TIMEOUT_MS") {
    Ok(value) ->
      case int.parse(value) {
        Ok(parsed) -> parsed
        Error(_) -> 1000
      }
    Error(_) -> 1000
  }
}

fn log_timeout(senator_id: String) -> Nil {
  io.print_error(
    "WARN [office]: Notes lookup timed out for " <> senator_id <> "\n",
  )
}

fn drain_late_note_reply(subject: process.Subject(List(Note))) -> Nil {
  let _ =
    process.spawn(fn() {
      case process.receive_forever(subject) {
        _ -> Nil
      }
    })
  Nil
}
