import autopilot
import envoy
import gleam/erlang/process
import gleam/http
import gleam/http/request as http_request
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import html_renderer
import mist
import memory
import office
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
  office: office.Office,
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
    ["senators"] -> handle_senators_index(manager, office, roster, request)
    ["senators", id] ->
      handle_senator_profile(manager, office, roster, id, request)
    ["senators", id, "notes"] ->
      handle_senator_note(manager, office, roster, id, request)
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
    let query_params = wisp.get_query(request)
    let current_theme = theme.from_query_params(query_params)
    let current_session = session_manager.current(manager)
    let fragments =
      html_renderer.live_fragments(
        current_session,
        roster,
        autopilot_status(autop),
        current_theme,
        query_params,
      )

    case live_refresh_requested(request) {
      True ->
        wisp.json_response(
          html_renderer.render_live_payload(fragments),
          200,
        )
      False -> {
        let page =
          html_renderer.render_session_page_from_fragments(
            fragments,
            current_theme,
          )

        wisp.html_response(page, 200)
      }
    }
  })
}

fn handle_senators_index(
  manager: session_manager.Manager,
  _office: office.Office,
  roster: List(senators.Senator),
  request: wisp.Request,
) -> wisp.Response {
  wisp.require_method(request, http.Get, fn() {
    let current_theme = theme.from_request(request)
    let snapshot = session_manager.current(manager)
    let page =
      html_renderer.render_senators_index_page(
        roster,
        snapshot,
        current_theme,
      )
    wisp.html_response(page, 200)
  })
}

fn handle_senator_profile(
  manager: session_manager.Manager,
  office: office.Office,
  roster: List(senators.Senator),
  id: String,
  request: wisp.Request,
) -> wisp.Response {
  wisp.require_method(request, http.Get, fn() {
    let current_theme = theme.from_request(request)
    let snapshot = session_manager.current(manager)

    case find_senator(roster, id) {
      None -> wisp.not_found()
      Some(senator) -> {
        let notes = office.notes_for(office, id)
        let page =
          html_renderer.render_senator_profile_page(
            senator,
            snapshot,
            notes,
            current_theme,
          )
        wisp.html_response(page, 200)
      }
    }
  })
}

fn handle_senator_note(
  _manager: session_manager.Manager,
  office: office.Office,
  roster: List(senators.Senator),
  id: String,
  request: wisp.Request,
) -> wisp.Response {
  let current_theme = theme.from_request(request)
  wisp.require_method(request, http.Post, fn() {
    case find_senator(roster, id) {
      None -> wisp.not_found()
      Some(_senator) ->
        wisp.require_form(request, fn(form) {
          let name = field_value(form.values, "name")
          let contact = field_value(form.values, "contact")
          let body = field_value(form.values, "body")
          let note = office.Note(name:, contact:, body:)
          office.add_note(office, id, note)
          let target = "/senators/" <> id <> theme.query_suffix(current_theme)
          wisp.redirect(target)
        })
    }
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
  let mem = memory.init()
  let office_handle = office.start()
  let initial_session = load_or_init_session(snapshot_path, docket)
  let manager = session_manager.start(initial_session)
  let secret_key_base = "dev_secret_key_change_me"

  let autop_handle =
    autopilot.start(
      autopilot_settings(snapshot_path),
      manager,
      speaking_roster,
      mem,
    )

  let router =
    fn(request) { handle_request(manager, autop_handle, roster, office_handle, request) }

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
  let llm_limit = env_int("HARMONY_MAX_LLM_CALLS", session.default_llm_limit())

  let base_session =
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

  session.set_llm_calls_limit(base_session, llm_limit)
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
  let enabled_env = env_bool("HARMONY_AUTOPILOT_ENABLED", True)
  let tick_ms = env_int("HARMONY_AUTOPILOT_TICK_MS", 1666)
  let steps_per_tick = env_int("HARMONY_AUTOPILOT_STEPS", 3)
  let enabled =
    case envoy.get("OPENAI_API_KEY") {
      Ok(_) -> enabled_env
      Error(_) -> {
        io.println("Autopilot disabled: missing OPENAI_API_KEY")
        False
      }
    }

  autopilot.Settings(
    enabled: enabled,
    tick_ms: tick_ms,
    steps_per_tick: steps_per_tick,
    snapshot_path: snapshot_path,
    export_proceedings: env_bool("HARMONY_EXPORT_PROCEEDINGS", False),
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

fn find_senator(
  roster: List(senators.Senator),
  id: String,
) -> Option(senators.Senator) {
  case roster {
    [] -> None
    [head, ..tail] ->
      case head.id == id {
        True -> Some(head)
        False -> find_senator(tail, id)
      }
  }
}

fn field_value(fields: List(#(String, String)), key: String) -> String {
  case list.key_find(fields, key) {
    Ok(value) -> value
    Error(_) -> ""
  }
}

fn live_refresh_requested(request: wisp.Request) -> Bool {
  let header_value =
    case http_request.get_header(request, "x-harmony-refresh") {
      Ok(value) -> Ok(value)
      Error(_) -> http_request.get_header(request, "X-Harmony-Refresh")
    }

  case header_value {
    Ok(value) -> {
      let trimmed = string.lowercase(string.trim(value))
      trimmed == "1" || trimmed == "true" || trimmed == "yes"
    }
    Error(_) -> False
  }
}
