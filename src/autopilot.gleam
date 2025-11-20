import gleam/erlang/process
import gleam/io
import memory
import session
import session_manager
import session_runner
import session_store
import senator_agents
import senators

pub type Settings {
  Settings(
    enabled: Bool,
    tick_ms: Int,
    steps_per_tick: Int,
    snapshot_path: String,
    export_proceedings: Bool,
  )
}

const status_timeout_ms = 50

pub opaque type Autopilot {
  Autopilot(mailbox: process.Subject(Message))
}

type Message {
  Pause
  Resume
  Stop
  Query(process.Subject(Bool))
  TickCompleted(session.Session)
}

type State {
  State(
    manager: session_manager.Manager,
    roster: List(senators.Senator),
    tick_ms: Int,
    steps_per_tick: Int,
    snapshot_path: String,
    memory: memory.Memory,
    running: Bool,
    export_proceedings: Bool,
    agents: senator_agents.Registry,
    tick_inflight: Bool,
  )
}

/// Starts a background process that periodically advances the session and
/// persists snapshots. Controlled via pause/resume/stop messages.
pub fn start(
  settings: Settings,
  manager: session_manager.Manager,
  roster: List(senators.Senator),
  mem: memory.Memory,
  agents: senator_agents.Registry,
) -> Autopilot {
  let handshake = process.new_subject()
  let state = State(
    manager: manager,
    roster: roster,
    tick_ms: settings.tick_ms,
    steps_per_tick: settings.steps_per_tick,
    snapshot_path: settings.snapshot_path,
    memory: mem,
    running: settings.enabled,
    export_proceedings: settings.export_proceedings,
    agents: agents,
    tick_inflight: False,
  )

  let _pid =
    process.spawn(fn() {
      let mailbox = process.new_subject()
      process.send(handshake, mailbox)
      loop(mailbox, state)
    })

  let mailbox = process.receive_forever(handshake)
  Autopilot(mailbox: mailbox)
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
  case process.receive(reply, status_timeout_ms) {
    Ok(running) -> running
    Error(Nil) -> {
      drain_late_status(reply)
      True
    }
  }
}

fn loop(mailbox: process.Subject(Message), state: State) -> Nil {
  case process.receive(mailbox, state.tick_ms) {
    Ok(Stop) -> Nil
    Ok(TickCompleted(sess)) -> {
      let next_state = handle_tick_completion(state, sess)
      loop(mailbox, next_state)
    }
    Ok(message) ->
      case handle_message(state, message) {
        #(next_state, continue) ->
          case continue {
            False -> Nil
            True -> loop(mailbox, next_state)
          }
      }
    Error(Nil) -> {
      let next_state = maybe_tick(mailbox, state)
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
    TickCompleted(_) -> #(state, True)
  }
}

fn maybe_tick(mailbox: process.Subject(Message), state: State) -> State {
  case state.running && !state.tick_inflight {
    False -> state
    True -> {
      spawn_tick_job(mailbox, state)
      State(..state, tick_inflight: True)
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

fn drain_late_status(subject: process.Subject(Bool)) -> Nil {
  let _ =
    process.spawn(fn() {
      case process.receive_forever(subject) {
        _ -> Nil
      }
    })
  Nil
}

fn spawn_tick_job(
  mailbox: process.Subject(Message),
  state: State,
) -> Nil {
  let manager = state.manager
  let roster = state.roster
  let steps = state.steps_per_tick
  let mem = state.memory
  let agents = state.agents

  let _ =
    process.spawn(fn() {
      let current = session_manager.current(manager)
      let advanced =
        session_runner.run_steps(
          current,
          roster,
          steps,
          mem,
          agents,
        )
      process.send(mailbox, TickCompleted(advanced))
    })

  Nil
}

fn handle_tick_completion(state: State, sess: session.Session) -> State {
  let _ =
    case sess.status {
      session.Closed -> {
        case state.export_proceedings {
          True -> {
            let path = session_runner.default_proceedings_path(sess)
            let _ = session_runner.publish_proceedings(sess, path)
            Nil
          }
          False -> Nil
        }
      }
      _ -> Nil
    }

  session_manager.replace(state.manager, sess)
  persist_snapshot(state.snapshot_path, sess)
  State(..state, tick_inflight: False)
}
