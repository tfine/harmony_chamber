import gleam/erlang/process
import gleam/io
import gleam/option.{type Option, None, Some}
import session
import session_manager
import session_runner
import session_store
import senators

pub type Settings {
  Settings(
    enabled: Bool,
    tick_ms: Int,
    steps_per_tick: Int,
    snapshot_path: String,
  )
}

pub opaque type Autopilot {
  Autopilot(mailbox: process.Subject(Message))
}

type Message {
  Pause
  Resume
  Stop
  Query(process.Subject(Bool))
}

type State {
  State(
    manager: session_manager.Manager,
    roster: List(senators.Senator),
    tick_ms: Int,
    steps_per_tick: Int,
    snapshot_path: String,
    running: Bool,
  )
}

pub fn start(
  settings: Settings,
  manager: session_manager.Manager,
  roster: List(senators.Senator),
) -> Option(Autopilot) {
  case settings.enabled {
    False -> None
    True -> {
      let handshake = process.new_subject()
      let state = State(
        manager: manager,
        roster: roster,
        tick_ms: settings.tick_ms,
        steps_per_tick: settings.steps_per_tick,
        snapshot_path: settings.snapshot_path,
        running: True,
      )

      let _pid =
        process.spawn(fn() {
          let mailbox = process.new_subject()
          process.send(handshake, mailbox)
          loop(mailbox, state)
        })

      let mailbox = process.receive_forever(handshake)
      Some(Autopilot(mailbox: mailbox))
    }
  }
}

pub fn pause(pilot: Autopilot) -> Nil {
  process.send(pilot.mailbox, Pause)
}

pub fn resume(pilot: Autopilot) -> Nil {
  process.send(pilot.mailbox, Resume)
}

pub fn stop(pilot: Autopilot) -> Nil {
  process.send(pilot.mailbox, Stop)
}

pub fn status(pilot: Autopilot) -> Bool {
  let reply = process.new_subject()
  process.send(pilot.mailbox, Query(reply))
  process.receive_forever(reply)
}

fn loop(mailbox: process.Subject(Message), state: State) -> Nil {
  case process.receive(mailbox, state.tick_ms) {
    Ok(Stop) -> Nil
    Ok(message) ->
      case handle_message(state, message) {
        #(next_state, continue) ->
          case continue {
            False -> Nil
            True -> loop(mailbox, next_state)
          }
      }
    Error(Nil) -> {
      let next_state = maybe_tick(state)
      loop(mailbox, next_state)
    }
  }
}

fn handle_message(state: State, message: Message) -> #(State, Bool) {
  case message {
    Pause -> #(State(..state, running: False), True)
    Resume -> #(State(..state, running: True), True)
    Stop -> #(state, False)
    Query(reply) -> {
      process.send(reply, state.running)
      #(state, True)
    }
  }
}

fn maybe_tick(state: State) -> State {
  case state.running {
    False -> state
    True -> {
      let current = session_manager.current(state.manager)
      let advanced =
        session_runner.run_steps(current, state.roster, state.steps_per_tick)

      session_manager.replace(state.manager, advanced)
      persist_snapshot(state.snapshot_path, advanced)
      state
    }
  }
}

fn persist_snapshot(path: String, sess: session.Session) {
  case session_store.persist(sess, path) {
    Ok(_) -> Nil
    Error(message) ->
      io.println("Snapshot write failed (" <> path <> "): " <> message)
  }
}
