import autopilot
import debate
import demo
import envoy
import gleam/erlang/process
import gleam/http
import gleam/http/request as http_request
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import html_renderer
import human_status
import llm_client
import memory
import mist
import office
import senator_agents
import senators
import session
import session_manager
import session_store
import speaker_rotation
import theme
import time_bill
import time_session
import time_session_manager
import time_page_renderer
import wisp
import wisp/wisp_mist

fn handle_request(
  manager: session_manager.Manager,
  autop: autopilot.Autopilot,
  agents: senator_agents.Registry,
  roster: List(senators.Senator),
  office: office.Office,
  time_manager: time_session_manager.Manager,
  request: wisp.Request,
) -> wisp.Response {
  case wisp.path_segments(request) {
    [] -> handle_home(manager, autop, roster, request)
    ["senators"] -> handle_senators_index(manager, office, roster, request)
    ["senators", id] ->
      handle_senator_profile(manager, office, agents, roster, id, request)
    ["senators", id, "notes"] ->
      handle_senator_note(manager, office, roster, id, request)
    ["docket"] -> handle_docket(manager, request)
    ["history"] -> handle_history(manager, request)
    ["autopilot", action] -> handle_autopilot_action(action, autop, request)
    ["health"] -> wisp.response(200) |> wisp.string_body("ok")
    ["time"] -> handle_time_page(roster, time_manager, request)
    ["time", "status"] -> handle_time_status(time_manager, request)
    ["time", "report"] -> handle_time_report(time_manager, request)
    ["time", "fragments"] -> handle_time_fragments(roster, time_manager, request)
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
        time_legislation_enabled(),
      )

    case live_refresh_requested(request) {
      True ->
        wisp.json_response(html_renderer.render_live_payload(fragments), 200)
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
      html_renderer.render_senators_index_page(roster, snapshot, current_theme)
    wisp.html_response(page, 200)
  })
}

fn handle_senator_profile(
  manager: session_manager.Manager,
  office: office.Office,
  agents: senator_agents.Registry,
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
        let intentions = senator_agents.intentions_for(agents, senator.id)
        let posts = senator_blog_posts(snapshot, senator)
        let page =
          html_renderer.render_senator_profile_page(
            senator,
            snapshot,
            intentions,
            posts,
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
      html_renderer.render_history_page(snapshot.completed_bills, current_theme)
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

fn handle_time_page(
  roster: List(senators.Senator),
  time_manager: time_session_manager.Manager,
  request: wisp.Request,
) -> wisp.Response {
  wisp.require_method(request, http.Get, fn() {
    let current_theme = theme.from_request(request)

    let time_session_state = time_session_manager.current(time_manager)
    let current_status = time_session_state.current_human_status
    let active_bill = time_session_state.active_time_bill
    let recent_reports = time_session_state.recent_block_reports
    let resources = time_session_state.resources
    let all_bills = time_session_state.all_time_bills

    let page =
      time_page_renderer.render_time_page(
        current_status,
        active_bill,
        recent_reports,
        resources,
        all_bills,
        roster,
        current_theme,
      )

    wisp.html_response(page, 200)
  })
}

fn handle_time_status(
  time_manager: time_session_manager.Manager,
  request: wisp.Request,
) -> wisp.Response {
  let current_theme = theme.from_request(request)
  wisp.require_method(request, http.Post, fn() {
    wisp.require_form(request, fn(form) {
      let timestamp = field_value(form.values, "timestamp")
      let block_pref = parse_block_preference(field_value(form.values, "block_preference"))
      let location = field_value(form.values, "location")
      let todd_energy = parse_energy_level(field_value(form.values, "todd_energy"))
      let delaney_energy = parse_energy_level(field_value(form.values, "delaney_energy"))
      let todd_mood = field_value(form.values, "todd_mood")
      let delaney_mood = field_value(form.values, "delaney_mood")
      let physical_state = field_value(form.values, "physical_state")
      let internet_tools = field_value(form.values, "internet_tools")
      let todd_needs = split_lines(field_value(form.values, "todd_needs"))
      let delaney_needs = split_lines(field_value(form.values, "delaney_needs"))
      let current_tasks = split_lines(field_value(form.values, "tasks"))
      let hard_constraints = split_lines(field_value(form.values, "constraints"))

      let status = human_status.HumanStatus(
        timestamp: timestamp,
        block_preference: block_pref,
        location: location,
        todd_energy: todd_energy,
        delaney_energy: delaney_energy,
        todd_mood: todd_mood,
        delaney_mood: delaney_mood,
        physical_state: physical_state,
        internet_tools: internet_tools,
        todd_needs: todd_needs,
        delaney_needs: delaney_needs,
        current_tasks: current_tasks,
        hard_constraints: hard_constraints,
      )

      let updated_session =
        time_session_manager.record_human_status(time_manager, status)
      let _ = ensure_time_bill_for_status(time_manager, updated_session, status)
      let target = "/time" <> theme.query_suffix(current_theme)
      wisp.redirect(target)
    })
  })
}

fn handle_time_report(
  time_manager: time_session_manager.Manager,
  request: wisp.Request,
) -> wisp.Response {
  let current_theme = theme.from_request(request)
  wisp.require_method(request, http.Post, fn() {
    wisp.require_form(request, fn(form) {
      let timestamp = field_value(form.values, "timestamp")
      let actual_minutes = parse_int(field_value(form.values, "actual_minutes"))
      let todd_energy = parse_energy_level(field_value(form.values, "todd_energy_after"))
      let delaney_energy = parse_energy_level(field_value(form.values, "delaney_energy_after"))
      let completed = split_lines(field_value(form.values, "completed"))
      let stuck = split_lines(field_value(form.values, "stuck"))
      let new_needs = split_lines(field_value(form.values, "new_needs"))

      let report = human_status.BlockReport(
        timestamp: timestamp,
        actual_minutes: actual_minutes,
        todd_energy: todd_energy,
        delaney_energy: delaney_energy,
        completed: completed,
        stuck_on: stuck,
        new_needs: new_needs,
      )

      let _ = time_session_manager.record_block_report(time_manager, report)
      let target = "/time" <> theme.query_suffix(current_theme)
      wisp.redirect(target)
    })
  })
}

fn handle_time_fragments(
  roster: List(senators.Senator),
  time_manager: time_session_manager.Manager,
  request: wisp.Request,
) -> wisp.Response {
  let current_theme = theme.from_request(request)
  wisp.require_method(request, http.Get, fn() {
    let time_session_state = time_session_manager.current(time_manager)
    let fragments =
      time_page_renderer.render_time_fragments(
        time_session_state.current_human_status,
        time_session_state.active_time_bill,
        time_session_state.recent_block_reports,
        time_session_state.resources,
        time_session_state.all_time_bills,
        roster,
        current_theme,
      )

    let payload =
      json.object([
        #("order_banner", json.string(fragments.order_banner)),
        #("timeline", json.string(fragments.timeline)),
        #("resources", json.string(fragments.resources)),
        #("senate_status", json.string(fragments.senate_status)),
        #("active_block", json.string(fragments.active_block)),
      ])
      |> json.to_string

    wisp.json_response(payload, 200)
  })
}

fn ensure_time_bill_for_status(
  manager: time_session_manager.Manager,
  session: time_session.TimeSession,
  status: human_status.HumanStatus,
) -> Nil {
  case session.active_time_bill {
    Some(_) -> Nil
    None -> {
      let bill = build_immediate_time_bill(session, status)
      let _ = time_session_manager.add_time_bill(manager, bill)
      let _ = time_session_manager.set_active_time_bill(manager, bill)
      Nil
    }
  }
}

fn build_immediate_time_bill(
  session: time_session.TimeSession,
  status: human_status.HumanStatus,
) -> time_bill.TimeBill {
  let title = "Immediate response for " <> status.timestamp
  let purpose =
    case status.current_tasks {
      [] -> "Reactivate the rhythm with a quick check-in and priority refresh."
      [first, .._] -> "Advance the next step: " <> first
    }
  let micro_block = build_micro_block_from_status(status)

  time_bill.TimeBill(
    id: time_session.next_time_bill_id(session),
    title: title,
    purpose: purpose,
    pillar_links: [time_bill.Governance],
    time_horizon: time_bill.ThisHour,
    created_at: status.timestamp,
    effective_at: status.timestamp,
    proposers: [],
    micro_blocks: [micro_block],
    status: time_bill.Active,
    budget_thinking: None,
  )
}

fn build_micro_block_from_status(status: human_status.HumanStatus) -> time_bill.MicroBlock {
  let duration = case status.block_preference {
    Some(value) -> value
    None -> 10
  }

  let todd_tasks = ensure_nonempty(status.todd_needs, "Todd: revisit the status inputs.")
  let delaney_tasks = ensure_nonempty(status.delaney_needs, "Delaney: review your notes.")
  let joint_tasks = ensure_nonempty(status.current_tasks, "Sync on immediate priorities.")

  let instructions =
    joint_tasks
    |> list.map(fn(task) { "Execute: " <> task })

  let expected_artifacts = [
    "Notes on how the block unfolded",
    "Updated status summary keyed to the reflection prompts",
  ]

  let limitation_note =
    case status.hard_constraints {
      [] -> "No new hard constraints beyond the status note."
      constraints -> string.join(constraints, "; ")
    }

  let reflection_prompts = [
    "What completed tasks can we mark done?",
    "What blockers emerged and how can the Senate help?",
    "What should the next block focus on?",
  ]

  time_bill.MicroBlock(
    duration_minutes: duration,
    assignees: time_bill.BlockAssignees(
      todd_tasks: todd_tasks,
      delaney_tasks: delaney_tasks,
      joint_tasks: joint_tasks,
    ),
    instructions: instructions,
    expected_artifacts: expected_artifacts,
    limitation_note: limitation_note,
    reflection_prompts: reflection_prompts,
    completion: None,
  )
}

fn ensure_nonempty(list: List(String), fallback: String) -> List(String) {
  case list {
    [] -> [fallback]
    items -> items
  }
}


pub fn main() {
  wisp.configure_logger()

  let roster = senators.all_senators()
  let speaking_roster = speaker_rotation.prioritized_roster(roster)
  let snapshot_path = snapshot_file_path()
  let docket = bill_docket()
  let mem = memory.init()
  let agents = senator_agents.start(roster, mem)
  let office_handle = office.start()
  let initial_session = load_or_init_session(snapshot_path, docket)
  let manager = session_manager.start(initial_session)
  let initial_time_session = time_session.initial_time_session()
  let time_manager = time_session_manager.start(initial_time_session)
  let secret_key_base = "dev_secret_key_change_me"
  boot_probe_llm()

  let autop_handle =
    autopilot.start(
      autopilot_settings(snapshot_path),
      manager,
      speaking_roster,
      mem,
      agents,
    )

  let router = fn(request) {
    handle_request(
      manager,
      autop_handle,
      agents,
      roster,
      office_handle,
      time_manager,
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

fn boot_probe_llm() {
  case demo.demo_senator_llm() {
    Ok(_) -> io.println("LLM probe succeeded")
    Error(error) ->
      io.println("LLM probe failed: " <> llm_client.error_to_string(error))
  }
}

fn load_or_init_session(
  snapshot_path: String,
  docket: List(session.Bill),
) -> session.Session {
  let llm_limit = env_int("HARMONY_MAX_LLM_CALLS", session.default_llm_limit())

  let base_session = case session_store.load(snapshot_path) {
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
        id: "AGATA-TIME-001",
        title: "Todd and Delaney Time Arrangements Legislation",
        summary:
          "Orchestrates the next set of micro-blocks for Todd and Delaney, keeping the AGATA shorelines alive with regenerative art, land, and tech.",
      ))
    [first, ..rest] -> session.initial_session_with_docket(first, rest)
  }
}

fn bill_docket() -> List(session.Bill) {
  [
    session.Bill(
      id: "AGATA-TIME-PRI-001",
      title: "AGATA Time Priorities Charter",
      summary:
        "A living manifesto that names AGATA's core priorities for the time legislation stream. "
        <> "Every senator should debate it as a priority-setting vehicle, propose sweeping amendments, "
        <> "and leave a record of why the Senate settles on each pillar and practice before issuing further time bills. "
        <> "Treat amendment proposals as instruments for clarifying what AGATA must do next and what principles will govern every subsequent micro-block.",
    ),
  ]
}

fn autopilot_status(autop: autopilot.Autopilot) -> Bool {
  autopilot.status(autop)
}

fn autopilot_mode() -> String {
  case envoy.get("HARMONY_AUTOPILOT_MODE") {
    Ok(value) -> value
    Error(_) -> "both"
  }
}

fn time_legislation_enabled() -> Bool {
  case string.lowercase(string.trim(autopilot_mode())) {
    "time" -> True
    "both" -> True
    _ -> False
  }
}

fn autopilot_settings(snapshot_path: String) -> autopilot.Settings {
  let enabled_env = env_bool("HARMONY_AUTOPILOT_ENABLED", True)
  let tick_ms = env_int("HARMONY_AUTOPILOT_TICK_MS", 300)
  let steps_per_tick = env_int("HARMONY_AUTOPILOT_STEPS", 3)
  let enabled = case envoy.get("OPENAI_API_KEY") {
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
    mode: autopilot_mode(),
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

fn senator_blog_posts(
  sess: session.Session,
  senator: senators.Senator,
) -> List(debate.DebateTurn) {
  sess.debate_turns
  |> list.filter(fn(turn) { turn.senator.id == senator.id })
  |> list.reverse
  |> list.take(5)
}

fn split_lines(value: String) -> List(String) {
  value
  |> string.split("\n")
  |> list.map(string.trim)
  |> list.filter(fn(line) { line != "" })
}

fn parse_block_preference(value: String) -> Option(Int) {
  let cleaned = string.lowercase(string.trim(value))
  case cleaned {
    "" | "unsure" | "none" -> None
    other ->
      case int.parse(other) {
        Ok(minutes) -> Some(minutes)
        Error(_) -> None
      }
  }
}

fn parse_energy_level(value: String) -> time_bill.EnergyLevel {
  let normalized = string.lowercase(string.trim(value))
  case time_bill.energy_from_string(normalized) {
    Ok(level) -> level
    Error(_) -> time_bill.Medium
  }
}

fn parse_int(value: String) -> Int {
  case int.parse(string.trim(value)) {
    Ok(parsed) -> parsed
    Error(_) -> 0
  }
}

fn field_value(fields: List(#(String, String)), key: String) -> String {
  case list.key_find(fields, key) {
    Ok(value) -> value
    Error(_) -> ""
  }
}

fn live_refresh_requested(request: wisp.Request) -> Bool {
  let header_value = case
    http_request.get_header(request, "x-harmony-refresh")
  {
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
