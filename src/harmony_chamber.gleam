import autopilot
import envoy
import gleam/erlang/process
import gleam/http
import gleam/int
import gleam/io
import gleam/option.{None, Some}
import gleam/string
import html_renderer
import mist
import senators
import session
import session_manager
import session_store
import speaker_rotation
import theme
import wisp
import wisp/wisp_mist

fn handle_request(
  manager: session_manager.Manager,
  autop: autopilot.Autopilot,
  roster: List(senators.Senator),
  request: wisp.Request,
) -> wisp.Response {
  case wisp.path_segments(request) {
    [] ->
      handle_home(
        manager,
        autop,
        roster,
        request,
      )
    ["docket"] -> handle_docket(manager, request)
    ["history"] -> handle_history(manager, request)
    ["autopilot", action] -> handle_autopilot_action(action, autop, request)
    _ -> wisp.not_found()
  }
}

fn handle_home(
  manager: session_manager.Manager,
  autop: autopilot.Autopilot,
  roster: List(senators.Senator),
  request: wisp.Request,
) -> wisp.Response {
  wisp.require_method(request, http.Get, fn() {
    let current_theme = theme.from_request(request)
    let current_session = session_manager.current(manager)
    let page =
      html_renderer.render_session_page(
        current_session,
        roster,
        autopilot_status(autop),
        current_theme,
      )
    wisp.html_response(page, 200)
  })
}

fn handle_docket(
  manager: session_manager.Manager,
  request: wisp.Request,
) -> wisp.Response {
  wisp.require_method(request, http.Get, fn() {
    let current_theme = theme.from_request(request)
    let snapshot = session_manager.current(manager)
    let page =
      html_renderer.render_docket_page(
        snapshot.bill,
        snapshot.completed_bills,
        snapshot.upcoming_bills,
        current_theme,
      )
    wisp.html_response(page, 200)
  })
}

fn handle_history(
  manager: session_manager.Manager,
  request: wisp.Request,
) -> wisp.Response {
  wisp.require_method(request, http.Get, fn() {
    let current_theme = theme.from_request(request)
    let snapshot = session_manager.current(manager)
    let page =
      html_renderer.render_history_page(
        snapshot.completed_bills,
        current_theme,
      )
    wisp.html_response(page, 200)
  })
}

fn handle_autopilot_action(
  action: String,
  autop: autopilot.Autopilot,
  request: wisp.Request,
) -> wisp.Response {
  let current_theme = theme.from_request(request)
  wisp.require_method(request, http.Post, fn() {
    case action {
      "pause" -> autopilot.pause(autop)
      "resume" -> autopilot.resume(autop)
      _ -> Nil
    }
    let target = "/" <> theme.query_suffix(current_theme)
    wisp.redirect(target)
  })
}

pub fn main() {
  wisp.configure_logger()

  let roster = senators.all_senators()
  let speaking_roster = speaker_rotation.prioritized_roster(roster)
  let snapshot_path = snapshot_file_path()
  let docket = bill_docket()
  let initial_session = load_or_init_session(snapshot_path, docket)
  let manager = session_manager.start(initial_session)
  let secret_key_base = "dev_secret_key_change_me"

  let autop_handle =
    autopilot.start(autopilot_settings(snapshot_path), manager, speaking_roster)

  let router = fn(request) {
    handle_request(manager, autop_handle, roster, request)
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
  snapshot_path: String,
  docket: List(session.Bill),
) -> session.Session {
  case session_store.load(snapshot_path) {
    Ok(Some(sess)) -> session.ensure_active(sess)
    Ok(None) -> start_from_docket(docket)
    Error(message) -> {
      io.println(
        "Failed to load session snapshot (" <> snapshot_path <> "): " <> message,
      )
      start_from_docket(docket)
    }
  }
}

fn start_from_docket(docket: List(session.Bill)) -> session.Session {
  case docket {
    [] ->
      session.initial_session(session.Bill(
        id: "HC-000",
        title: "Placeholder Resolution",
        summary: "Fallback bill used when no docket is supplied.",
      ))
    [first, ..rest] -> session.initial_session_with_docket(first, rest)
  }
}

fn bill_docket() -> List(session.Bill) {
  [
    session.Bill(
      id: "HC-001",
      title: "Civic Resilience Act",
      summary: "Modernizes emergency communications, hardens public works, and funds rapid response teams so that every community can withstand storms, fires, and infrastructure shocks.",
    ),
    session.Bill(
      id: "HC-002",
      title: "Rural Innovation Grants",
      summary: "Launches a rural innovation trust fund that backs broadband fiber loops, remote health hubs, and agricultural robotics cooperatives across all 50 states.",
    ),
    session.Bill(
      id: "HC-003",
      title: "Clean Grid Compact",
      summary: "Coordinates interstate transmission permitting, workforce training, and resilience funding to accelerate deployment of clean power lines and microgrids.",
    ),
  ]
}

fn autopilot_status(autop: autopilot.Autopilot) -> Bool {
  autopilot.status(autop)
}

fn autopilot_settings(snapshot_path: String) -> autopilot.Settings {
  let enabled = env_bool("HARMONY_AUTOPILOT_ENABLED", True)
  let tick_ms = env_int("HARMONY_AUTOPILOT_TICK_MS", 5000)
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
