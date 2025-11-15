import autopilot
import gleam/erlang/process
import gleam/http
import gleam/io
import gleam/int
import gleam/string
import gleam/option.{type Option, None, Some}
import html_renderer
import mist
import senators
import session
import session_manager
import session_runner
import session_store
import wisp
import wisp/wisp_mist
import envoy

fn handle_request(
  manager: session_manager.Manager,
  autop: Option(autopilot.Autopilot),
  steps_per_request: Int,
  snapshot_path: String,
  roster: List(senators.Senator),
  request: wisp.Request,
) -> wisp.Response {
  case wisp.path_segments(request) {
    [] ->
      handle_home(
        manager,
        autop,
        steps_per_request,
        snapshot_path,
        roster,
        request,
      )
    ["autopilot", action] ->
      handle_autopilot_action(action, autop, request)
    _ -> wisp.not_found()
  }
}

fn handle_home(
  manager: session_manager.Manager,
  autop: Option(autopilot.Autopilot),
  steps_per_request: Int,
  snapshot_path: String,
  roster: List(senators.Senator),
  request: wisp.Request,
) -> wisp.Response {
  wisp.require_method(request, http.Get, fn() {
    let current_session = session_manager.current(manager)
    let advanced =
      session_runner.run_steps(current_session, roster, steps_per_request)
    session_manager.replace(manager, advanced)
    persist_snapshot(snapshot_path, advanced)
    let page =
      html_renderer.render_session_page(
        advanced,
        roster,
        autopilot_status(autop),
      )
    wisp.html_response(page, 200)
  })
}

fn handle_autopilot_action(
  action: String,
  autop: Option(autopilot.Autopilot),
  request: wisp.Request,
) -> wisp.Response {
  wisp.require_method(request, http.Post, fn() {
    case autop {
      None -> wisp.redirect("/")
      Some(pilot) -> {
        case action {
          "pause" -> autopilot.pause(pilot)
          "resume" -> autopilot.resume(pilot)
          _ -> Nil
        }
        wisp.redirect("/")
      }
    }
  })
}

fn current_bill() -> session.Bill {
  session.Bill(
    id: "HC-001",
    title: "Civic Resilience Act",
    summary: "Modernizes emergency communications, hardens public works, and funds rapid response teams so that every community can withstand storms, fires, and infrastructure shocks.",
  )
}

pub fn main() {
  wisp.configure_logger()

  let roster = senators.all_senators()
  let bill = current_bill()
  let snapshot_path = snapshot_file_path()
  let initial_session = load_or_init_session(bill, snapshot_path)
  let manager = session_manager.start(initial_session)
  let secret_key_base = "dev_secret_key_change_me"
  let steps_per_request = request_step_setting()

  let autop_handle =
    autopilot.start(
      autopilot_settings(snapshot_path),
      manager,
      roster,
    )

  let router = fn(request) {
    handle_request(
      manager,
      autop_handle,
      steps_per_request,
      snapshot_path,
      roster,
      request,
    )
  }

  let assert Ok(_) =
    router
    |> wisp_mist.handler(secret_key_base)
    |> mist.new
    |> mist.bind("0.0.0.0")
    |> mist.port(8080)
    |> mist.start

  process.sleep_forever()
}

fn load_or_init_session(
  bill: session.Bill,
  snapshot_path: String,
) -> session.Session {
  case session_store.load(snapshot_path) {
    Ok(Some(sess)) -> sess
    Ok(None) -> session.initial_session(bill)
    Error(message) -> {
      io.println("Failed to load session snapshot (" <> snapshot_path <> "): " <> message)
      session.initial_session(bill)
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

fn request_step_setting() -> Int {
  env_int("HARMONY_STEPS_PER_REQUEST", 3)
}

fn autopilot_status(autop: Option(autopilot.Autopilot)) -> Option(Bool) {
  case autop {
    None -> None
    Some(pilot) -> Some(autopilot.status(pilot))
  }
}

fn autopilot_settings(snapshot_path: String) -> autopilot.Settings {
  let enabled = env_bool("HARMONY_AUTOPILOT_ENABLED", False)
  let tick_ms = env_int("HARMONY_AUTOPILOT_TICK_MS", 5_000)
  let steps_per_tick = env_int("HARMONY_AUTOPILOT_STEPS", 3)

  autopilot.Settings(
    enabled: enabled,
    tick_ms: tick_ms,
    steps_per_tick: steps_per_tick,
    snapshot_path: snapshot_path,
  )
}

fn snapshot_file_path() -> String {
  case envoy.get("HARMONY_SNAPSHOT_PATH") {
    Ok(path) -> path
    Error(_) -> "session_snapshot.etf"
  }
}

fn env_bool(name: String, default: Bool) -> Bool {
  case envoy.get(name) {
    Ok(value) -> string.lowercase(value) == "true"
    Error(_) -> default
  }
}

fn env_int(name: String, default: Int) -> Int {
  case envoy.get(name) {
    Ok(value) -> {
      case int.parse(value) {
        Ok(parsed) -> parsed
        Error(_) -> default
      }
    }
    Error(_) -> default
  }
}
