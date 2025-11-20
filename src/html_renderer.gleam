import debate
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some, unwrap}
import gleam/string
import office
import senators
import session
import theme

const debate_turns_per_page = 10

const transcript_page_shortcuts = [
  1,
  2,
  3,
  4,
  5,
  6,
  7,
  8,
  9,
  10,
  20,
  30,
  40,
  50,
]

type DebatePagination {
  DebatePagination(
    turns: List(debate.DebateTurn),
    current_page: Int,
    total_pages: Int,
    per_page: Int,
    total_turns: Int,
  )
}

pub type LiveFragments {
  LiveFragments(
    hero: String,
    bill: String,
    vote: String,
    debate: String,
    amendment: String,
    roster: String,
    alert: String,
    vote_active: Bool,
    amendment_considered: Bool,
  )
}

pub fn render_session_page(
  sess: session.Session,
  senators_list: List(senators.Senator),
  autopilot_running: Bool,
  current_theme: theme.Theme,
  query_params: List(#(String, String)),
  time_legislation_enabled: Bool,
) -> String {
  live_fragments(
    sess,
    senators_list,
    autopilot_running,
    current_theme,
    query_params,
    time_legislation_enabled,
  )
  |> render_session_page_from_fragments(current_theme)
}

pub fn render_session_page_from_fragments(
  fragments: LiveFragments,
  current_theme: theme.Theme,
) -> String {
  let body_class = theme.body_class(current_theme)
  let refresh_script = live_update_script()
  let vote_block = fragments.vote
  let debate_block = fragments.debate
  let vote_debate_block = case fragments.vote_active {
    True -> vote_block <> debate_block
    False -> debate_block <> vote_block
  }
  let ordered_panels = case fragments.amendment_considered {
    True -> [fragments.bill, fragments.amendment, vote_debate_block]
    False -> [fragments.bill, vote_debate_block, fragments.amendment]
  }
  let main_section = ordered_panels |> string.join("\n          ")

  "<!doctype html>
   <html lang=\"en\">
     <head>
       <meta charset=\"utf-8\" />
       <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />
       <title>Harmony Chamber</title>
       <style>" <> stylesheet() <> "</style>
     </head>
     <body class=\"" <> body_class <> "\">
      <div class=\"page\">
       " <> fragments.hero <> "
       " <> fragments.alert <> "
       <main class=\"grid\">
          " <> main_section <> "
         </main>
         " <> fragments.roster <> "
       </div>
     " <> refresh_script <> "
     </body>
   </html>"
}

pub fn live_fragments(
  sess: session.Session,
  senators_list: List(senators.Senator),
  autopilot_running: Bool,
  current_theme: theme.Theme,
  query_params: List(#(String, String)),
  time_legislation_enabled: Bool,
) -> LiveFragments {
  let hero = render_hero(sess, autopilot_running, current_theme, time_legislation_enabled)
  let bill_section = render_bill(sess.bill)
  let vote_section = render_live_vote_panel(sess, senators_list, query_params)
  let pagination = debate_pagination(sess.debate_turns, query_params)
  let debate_section =
    render_debate_log(pagination, current_theme, query_params)
  let amendment_section = render_amendments(sess.amendments)
  let roster_section = render_roster(sess, senators_list)
  let error_section = render_error_banner(sess.last_error)
  let pending_amendment =
    sess.amendments
    |> list.any(fn(amendment) { amendment.status == session.Pending })
  let amendment_considered = case sess.status {
    session.Voting(session.AmendmentVote(_)) -> True
    session.InDebate -> pending_amendment
    _ -> False
  }

  LiveFragments(
    hero: hero,
    bill: bill_section,
    vote: vote_section,
    debate: debate_section,
    amendment: amendment_section,
    roster: roster_section,
    alert: error_section,
    vote_active: case sess.status {
      session.Voting(_) -> True
      _ -> False
    },
    amendment_considered: amendment_considered,
  )
}

pub fn render_live_payload(fragments: LiveFragments) -> String {
  json.object([
    #("hero", json.string(fragments.hero)),
    #("bill", json.string(fragments.bill)),
    #("vote", json.string(fragments.vote)),
    #("debate", json.string(fragments.debate)),
    #("amendment", json.string(fragments.amendment)),
    #("roster", json.string(fragments.roster)),
    #("alert", json.string(fragments.alert)),
    #("amendment_considered", json.bool(fragments.amendment_considered)),
  ])
  |> json.to_string()
}

pub fn render_docket_page(
  current: session.Bill,
  completed: List(session.CompletedBill),
  upcoming: List(session.Bill),
  current_theme: theme.Theme,
) -> String {
  let completed_section = render_completed_bills(completed)
  let upcoming_section = render_upcoming_bills(current, upcoming)
  let nav_links = render_nav_links(current_theme)
  let theme_switcher = render_theme_switcher(current_theme, "/docket")
  let body_class = theme.body_class(current_theme)

  "<!doctype html>
   <html lang=\"en\">
     <head>
       <meta charset=\"utf-8\" />
       <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />
       <title>Harmony Chamber Docket</title>
       <style>" <> stylesheet() <> "</style>
     </head>
     <body class=\"" <> body_class <> "\">
       <div class=\"page\">
         <header class=\"hero\">
           <div>
             <p class=\"eyebrow\">Harmony Chamber</p>
             <h1>Legislative Docket</h1>
             <nav class=\"nav-links\">
               " <> nav_links <> "
             </nav>
             <p class=\"hero-summary\">
               Completed votes and upcoming legislation.
             </p>
             " <> theme_switcher <> "
           </div>
         </header>
         <main class=\"grid\">
           " <> completed_section <> "
           " <> upcoming_section <> "
         </main>
       </div>
     </body>
   </html>"
}

pub fn render_history_page(
  completed: List(session.CompletedBill),
  current_theme: theme.Theme,
) -> String {
  let body = case completed {
    [] -> "<p>No completed votes yet.</p>"
    _ ->
      completed
      |> list.map(render_history_card)
      |> string.join("")
  }
  let nav_links = render_nav_links(current_theme)
  let theme_switcher = render_theme_switcher(current_theme, "/history")
  let body_class = theme.body_class(current_theme)

  "<!doctype html>
   <html lang=\"en\">
     <head>
       <meta charset=\"utf-8\" />
       <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />
       <title>Harmony Chamber Vote History</title>
       <style>" <> stylesheet() <> "</style>
     </head>
     <body class=\"" <> body_class <> "\">
       <div class=\"page\">
         <header class=\"hero\">
           <div>
             <p class=\"eyebrow\">Harmony Chamber</p>
             <h1>Vote History</h1>
             <nav class=\"nav-links\">
               " <> nav_links <> "
             </nav>
             <p class=\"hero-summary\">
               Full record of completed bills, amendments, and transcripts.
             </p>
             " <> theme_switcher <> "
           </div>
         </header>
         <section class=\"panel docket-panel\">
           <div class=\"panel-header\">
             <h2>Completed votes</h2>
             <p>Includes raw debate text for archival access.</p>
           </div>
           <div class=\"docket-list\">" <> body <> "</div>
         </section>
       </div>
     </body>
   </html>"
}

pub fn render_senators_index_page(
  senators_list: List(senators.Senator),
  current_session: session.Session,
  current_theme: theme.Theme,
) -> String {
  let cards =
    senators_list
    |> list.map(fn(senator) { render_senator_card(senator, current_session) })
    |> string.join("")

  let nav_links = render_nav_links(current_theme)
  let theme_switcher = render_theme_switcher(current_theme, "/senators")
  let body_class = theme.body_class(current_theme)

  "<!doctype html>
   <html lang=\"en\">
     <head>
       <meta charset=\"utf-8\" />
       <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />
       <title>Senators | Harmony Chamber</title>
       <style>" <> stylesheet() <> "</style>
     </head>
     <body class=\"" <> body_class <> "\">
       <div class=\"page\">
         <header class=\"hero\">
           <div>
             <p class=\"eyebrow\">Harmony Chamber</p>
             <h1>Senators</h1>
             <nav class=\"nav-links\">
               " <> nav_links <> "
             </nav>
             <p class=\"hero-summary\">
               Explore each senator’s priorities, most recent remarks, and constituent notes.
             </p>
             " <> theme_switcher <> "
           </div>
         </header>
         <main class=\"grid\">
           " <> cards <> "
         </main>
       </div>
     </body>
   </html>"
}

pub fn render_senator_profile_page(
  senator: senators.Senator,
  sess: session.Session,
  intentions: List(String),
  posts: List(debate.DebateTurn),
  notes: List(office.Note),
  current_theme: theme.Theme,
) -> String {
  let body_class = theme.body_class(current_theme)
  let nav_links = render_nav_links(current_theme)
  let theme_switcher =
    render_theme_switcher(current_theme, "/senators/" <> senator.id)
  let intentions_panel = render_intentions_panel(intentions)
  let mailbox_panel = render_mailbox_panel(senator, notes)
  let blog_panel = render_statement_blog(posts, sess.bill)
  let bill_panel = "<section class=\"panel\">
       <h2>Current Bill</h2>
       <p class=\"eyebrow\">" <> sess.bill.id <> "</p>
       <h3>" <> escape_html(sess.bill.title) <> "</h3>
       <p>" <> escape_html(sess.bill.summary) <> "</p>
     </section>"

  "<!doctype html>
   <html lang=\"en\">
     <head>
       <meta charset=\"utf-8\" />
       <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />
       <title>" <> senator.name <> " | Harmony Chamber</title>
       <style>" <> stylesheet() <> "</style>
     </head>
     <body class=\"" <> body_class <> "\">
       <div class=\"page\">
         <header class=\"hero\">
           <div>
             <p class=\"eyebrow\">Senator Profile</p>
             <h1>" <> senator.name <> " (" <> senator.state <> ")</h1>
             <nav class=\"nav-links\">" <> nav_links <> "</nav>
             <p class=\"hero-summary\">" <> senator.biography <> "</p>
             " <> theme_switcher <> "
           </div>
         </header>
         <main class=\"grid\">
           " <> intentions_panel <> "
           " <> mailbox_panel <> "
           " <> bill_panel <> "
           " <> blog_panel <> "
         </main>
       </div>
     </body>
   </html>"
}

fn render_hero(
  sess: session.Session,
  autopilot_running: Bool,
  current_theme: theme.Theme,
  time_legislation_enabled: Bool,
) -> String {
  let nav_links = render_nav_links(current_theme)
  let theme_switcher = render_theme_switcher(current_theme, "/")
  let status_line = render_status_line(sess)
  let autopilot_controls =
    render_autopilot_controls(sess, autopilot_running, current_theme)
  let time_nav = case time_legislation_enabled {
    True -> nav_link("/time", "Time Legislation", current_theme)
    False -> ""
  }

  "<header class=\"hero\" id=\"hero-header\">\n     <div>\n       <p class=\"eyebrow\">Harmony Chamber</p>\n       <div class=\"hero-top\">\n         <h1>Live Senate Simulation</h1>\n         <span class=\"pill live-pill\" id=\"live-badge\">Live</span>\n       </div>\n       <nav class=\"nav-links\">\n         "
  <> nav_links
  <> time_nav
  <> "\n       </nav>\n       <p class=\"hero-summary\">\n         Live session generated by Gleam/BEAM + OpenAI agents.\n       </p>\n       <p>\n         LLM calls used: "
  <> int.to_string(sess.llm_calls_used)
  <> " / "
  <> int.to_string(sess.llm_calls_limit)
  <> "\n       </p>\n       "
  <> status_line
  <> "\n       <div class=\"live-meta\">\n         <span class=\"pill ghost-pill\">Server-rendered updates</span>\n         <span class=\"pill ghost-pill\">Auto-sync ~3s</span>\n       </div>\n       "
  <> autopilot_controls
  <> "\n       "
  <> theme_switcher
  <> "\n     </div>\n   </header>"
}

fn render_bill(bill: session.Bill) -> String {
  "<section class=\"panel bill-panel\" id=\"bill-panel\">
     <div class=\"panel-header\">
       <h2>" <> escape_html(bill.title) <> "</h2>
       <p class=\"bill-id\">Bill " <> escape_html(bill.id) <> "</p>
     </div>
     <p class=\"bill-summary\">" <> escape_html(bill.summary) <> "</p>
   </section>"
}

fn render_live_vote_panel(
  sess: session.Session,
  senators_list: List(senators.Senator),
  query_params: List(#(String, String)),
) -> String {
  let active_vote = case sess.status {
    session.Voting(focus) -> Some(focus)
    _ -> None
  }

  let tally = session.vote_progress(sess)
  let total_members = list.length(senators_list)
  let outstanding = session.outstanding_voters(sess, senators_list)
  let focus_label = vote_focus_label(active_vote)
  let summary = vote_summary_line(sess, tally, total_members, outstanding)
  let bars = render_vote_bars(tally, total_members)
  let drama_enabled = query_flag(query_params, "drama")
  let drama_toggle = render_drama_toggle(query_params, drama_enabled)
  let stats = render_vote_stats(tally, total_members, outstanding)

  let senator_vote_cards =
    senators_list
    |> list.map(fn(senator) {
      let intent = case session.vote_intent_for(sess, senator.id) {
        Some(value) -> value
        None -> debate.Undecided
      }
      render_senator_vote_card(senator, intent)
    })
    |> string.join("")

  let spotlights = case drama_enabled {
    True -> "<div class=\"vote-spotlights\">" <> senator_vote_cards <> "</div>"
    False -> ""
  }

  "<section class=\"panel vote-panel\" id=\"vote-panel\">
     <div class=\"panel-header\">
       <div>
         <h2>Live Vote Watch</h2>
         <p>" <> focus_label <> "</p>
       </div>
       <div class=\"control-bar\">
         " <> drama_toggle <> "
         <span class=\"pill\">" <> vote_status_pill(sess.status) <> "</span>
       </div>
     </div>
     " <> bars <> "
     <p class=\"vote-summary\">" <> summary <> "</p>
    " <> stats <> "
    " <> spotlights <> "
   </section>"
}

fn vote_focus_label(focus: Option(session.VoteFocus)) -> String {
  case focus {
    None -> "No vote is open. Watch for motions or amendments."
    Some(session.BillVote) ->
      "Final vote on the bill text. Simple majority decides."
    Some(session.AmendmentVote(id)) ->
      "Vote on amendment "
      <> int.to_string(id)
      <> " — winner rewrites the bill summary."
  }
}

fn vote_status_pill(status: session.SessionStatus) -> String {
  case status {
    session.InDebate -> "Debate pacing"
    session.Voting(session.BillVote) -> "Live vote"
    session.Voting(session.AmendmentVote(_)) -> "Amendment vote"
    session.Closed -> "Result locked"
  }
}

fn vote_summary_line(
  sess: session.Session,
  tally: session.VoteTally,
  total_members: Int,
  outstanding: List(String),
) -> String {
  let session.VoteTally(yea: yea, nay: nay, abstain: abstain) = tally
  let decided = yea + nay + abstain
  let remaining = total_members - decided
  let remaining_floor = case remaining < 0 {
    True -> 0
    False -> remaining
  }

  case sess.status {
    session.Voting(_) ->
      "Called votes: "
      <> int.to_string(yea)
      <> " yea / "
      <> int.to_string(nay)
      <> " nay / "
      <> int.to_string(abstain)
      <> " abstain. "
      <> int.to_string(remaining_floor)
      <> " still on the board, including "
      <> int.to_string(list.length(outstanding))
      <> " without any intent on record."
    session.Closed ->
      "Vote closed. "
      <> format_result_summary(unwrap(
        sess.final_result,
        session.VoteResult(tally: tally, passed: yea > nay),
      ))
    session.InDebate ->
      "Debate in play — no ballots yet. Signals and procedures shape the next move."
  }
}

fn render_vote_stats(
  tally: session.VoteTally,
  total_members: Int,
  outstanding: List(String),
) -> String {
  let session.VoteTally(yea: yea, nay: nay, abstain: abstain) = tally
  let decided = yea + nay + abstain
  let remaining = non_negative(total_members - decided)
  let outstanding_count = list.length(outstanding)
  let needed = majority_threshold(total_members)

  "<div class=\"vote-stats\">\n     "
  <> stat_pill("Needed to pass", int.to_string(needed) <> " yea")
  <> "\n     "
  <> stat_pill("Outstanding", int.to_string(remaining) <> " senators")
  <> "\n     "
  <> stat_pill("No intent logged", int.to_string(outstanding_count))
  <> "\n   </div>"
}

fn stat_pill(label: String, value: String) -> String {
  "<span class=\"pill stat-pill\"><strong>"
  <> escape_html(label)
  <> ":</strong> "
  <> escape_html(value)
  <> "</span>"
}

fn render_senator_vote_card(
  senator: senators.Senator,
  intent: debate.VoteIntent,
) -> String {
  let intent_label = debate.vote_intent_label(intent)
  let intent_class = case intent {
    debate.Yea -> "is-yea"
    debate.Nay -> "is-nay"
    debate.Abstain -> "is-abstain"
    debate.Undecided -> "is-undecided"
  }
  let anchor_id = senator_anchor_id(senator)

  "<article class=\"card vote-card "
  <> intent_class
  <> "\" id=\""
  <> anchor_id
  <> "\">
     <div class=\"vote-card-header\">
       <h3>"
  <> escape_html(senator.name)
  <> "</h3>
       <span class=\"pill intent-pill "
  <> intent_class
  <> "\">"
  <> intent_label
  <> "</span>
     </div>
     <p class=\"vote-card-sub\">"
  <> escape_html(senator.state)
  <> "</p>
   </article>"
}

fn majority_threshold(total_members: Int) -> Int {
  case total_members <= 0 {
    True -> 0
    False -> {
      let half = case int.divide(total_members, by: 2) {
        Ok(value) -> value
        Error(Nil) -> 0
      }
      half + 1
    }
  }
}

fn non_negative(value: Int) -> Int {
  case value < 0 {
    True -> 0
    False -> value
  }
}

fn render_vote_bars(tally: session.VoteTally, total_members: Int) -> String {
  let session.VoteTally(yea: yea, nay: nay, abstain: abstain) = tally

  let bar_total = case total_members <= 0 {
    True -> 1
    False -> total_members
  }

  let yea_width = vote_percent(yea, bar_total)
  let nay_width = vote_percent(nay, bar_total)
  let abstain_width = vote_percent(abstain, bar_total)

  "<div class=\"vote-bars\">
     " <> vote_bar("Yea", yea, yea_width, "is-yea") <> "
     " <> vote_bar("Nay", nay, nay_width, "is-nay") <> "
     " <> vote_bar("Abstain", abstain, abstain_width, "is-abstain") <> "
   </div>"
}

fn vote_bar(label: String, count: Int, width: Int, class_name: String) -> String {
  "<div class=\"vote-bar\">
     <div class=\"vote-bar-label\">
       <span>" <> label <> "</span>
       <strong>" <> int.to_string(count) <> "</strong>
     </div>
     <div class=\"vote-bar-track\">
       <span class=\"vote-bar-fill " <> class_name <> "\" style=\"width: " <> int.to_string(
    width,
  ) <> "%\"></span>
     </div>
   </div>"
}

fn vote_percent(part: Int, total: Int) -> Int {
  case total <= 0 {
    True -> 0
    False -> {
      let percent = part * 100
      case int.divide(percent, by: total) {
        Ok(value) -> value
        Error(Nil) -> 0
      }
    }
  }
}

fn render_drama_toggle(params: List(#(String, String)), enabled: Bool) -> String {
  let toggled_params = case enabled {
    True -> remove_query_param(params, "drama")
    False -> set_query_param(params, "drama", "1")
  }

  let href = "/" <> render_query_string(toggled_params)
  let label = case enabled {
    True -> "Drama mode on"
    False -> "Enable drama mode"
  }

  "<a class=\"button secondary\" href=\"" <> href <> "\">" <> label <> "</a>"
}

fn render_debate_log(
  pagination: DebatePagination,
  current_theme: theme.Theme,
  query_params: List(#(String, String)),
) -> String {
  let body = case pagination.turns {
    [] ->
      "<div class=\"empty-transcript\">
         <p>No speeches logged yet. Senators are still reviewing the bill.</p>
       </div>"
    _ ->
      pagination.turns
      |> list.map(render_turn_card)
      |> string.join("")
  }

  let base_query = ensure_theme_query(query_params, current_theme)

  let note =
    "Newest speeches first. Page "
    <> int.to_string(pagination.current_page)
    <> " of "
    <> int.to_string(pagination.total_pages)
    <> ". Speeches are presented in full-width blocks for emphasis."

  let top_controls =
    render_pagination_controls(pagination, base_query, False, False)

  let bottom_controls =
    render_pagination_controls(pagination, base_query, True, True)

  "<section class=\"panel transcript-panel\" id=\"debate-panel\">
     <div class=\"panel-header\">
       <h2>Debate Floor</h2>
       <p>" <> note <> "</p>
     </div>
     " <> top_controls <> "
     <div class=\"transcript-grid\">" <> body <> "</div>
     " <> bottom_controls <> "
   </section>"
}

fn render_pagination_controls(
  pagination: DebatePagination,
  base_query: List(#(String, String)),
  include_numbers: Bool,
  include_summary: Bool,
) -> String {
  case pagination.total_turns {
    0 -> ""
    _ -> {
      let targets = case include_numbers {
        True ->
          pagination_targets(pagination.total_pages, pagination.current_page)
        False -> []
      }

      let previous =
        render_page_nav_link(
          "Newer",
          pagination.current_page - 1,
          pagination.current_page > 1,
          base_query,
        )

      let next =
        render_page_nav_link(
          "Older",
          pagination.current_page + 1,
          pagination.current_page < pagination.total_pages,
          base_query,
        )

      let numbered =
        targets
        |> list.map(fn(page) {
          render_page_link(page, pagination.current_page, base_query)
        })
        |> string.join("")

      let #(start_turn, end_turn) = page_turn_range(pagination)

      let summary = case include_summary {
        False -> ""
        True ->
          "<p class=\"pagination-summary\">Showing "
          <> int.to_string(start_turn)
          <> "–"
          <> int.to_string(end_turn)
          <> " of "
          <> int.to_string(pagination.total_turns)
          <> " speeches</p>"
      }

      let compact_class = case include_numbers {
        True -> ""
        False -> " is-compact"
      }

      "<div class=\"pagination"
      <> compact_class
      <> "\" aria-label=\"Debate transcript pages\">
         <div class=\"pagination-links\">"
      <> previous
      <> numbered
      <> next
      <> "</div>
         "
      <> summary
      <> "
       </div>"
    }
  }
}

fn pagination_targets(total_pages: Int, current_page: Int) -> List(Int) {
  let shortcuts =
    transcript_page_shortcuts
    |> list.filter(fn(page) { page <= total_pages })

  let with_current = case list.contains(shortcuts, current_page) {
    True -> shortcuts
    False -> [current_page, ..shortcuts]
  }

  let with_last = case list.contains(with_current, total_pages) {
    True -> with_current
    False -> [total_pages, ..with_current]
  }

  with_last |> list.sort(int.compare)
}

fn render_page_link(
  page: Int,
  current_page: Int,
  query_params: List(#(String, String)),
) -> String {
  let href = page_href(page, query_params)
  let class_name = case page == current_page {
    True -> "page-link is-active"
    False -> "page-link"
  }

  "<a class=\""
  <> class_name
  <> "\" href=\""
  <> href
  <> "\">"
  <> int.to_string(page)
  <> "</a>"
}

fn render_page_nav_link(
  label: String,
  target_page: Int,
  enabled: Bool,
  query_params: List(#(String, String)),
) -> String {
  case enabled {
    False -> "<span class=\"page-link is-disabled\">" <> label <> "</span>"
    True ->
      "<a class=\"page-link\" href=\""
      <> page_href(target_page, query_params)
      <> "\">"
      <> label
      <> "</a>"
  }
}

fn page_href(page: Int, query_params: List(#(String, String))) -> String {
  let params = set_query_param(query_params, "page", int.to_string(page))
  "/" <> render_query_string(params)
}

fn render_query_string(params: List(#(String, String))) -> String {
  case params {
    [] -> ""
    _ -> {
      let query =
        params
        |> list.map(fn(param) {
          let #(key, value) = param
          key <> "=" <> value
        })
        |> string.join("&")
      "?" <> query
    }
  }
}

fn set_query_param(
  params: List(#(String, String)),
  key: String,
  value: String,
) -> List(#(String, String)) {
  let filtered =
    params
    |> list.filter(fn(param) {
      let #(existing, _) = param
      existing != key
    })
  [#(key, value), ..filtered]
}

fn remove_query_param(
  params: List(#(String, String)),
  key: String,
) -> List(#(String, String)) {
  params
  |> list.filter(fn(param) {
    let #(existing, _) = param
    existing != key
  })
}

fn query_flag(params: List(#(String, String)), key: String) -> Bool {
  case params {
    [] -> False
    [#(k, value), ..tail] ->
      case string.lowercase(k) == string.lowercase(key) {
        False -> query_flag(tail, key)
        True ->
          case string.lowercase(value) {
            "1" -> True
            "true" -> True
            "yes" -> True
            _ -> False
          }
      }
  }
}

fn ensure_theme_query(
  params: List(#(String, String)),
  current_theme: theme.Theme,
) -> List(#(String, String)) {
  case current_theme {
    theme.Classic -> params
    _ -> {
      let has_theme =
        list.any(params, fn(param) {
          let #(key, _) = param
          key == "theme"
        })

      case has_theme {
        True -> params
        False -> [#("theme", theme.slug(current_theme)), ..params]
      }
    }
  }
}

fn debate_pagination(
  turns: List(debate.DebateTurn),
  query_params: List(#(String, String)),
) -> DebatePagination {
  let total_turns = list.length(turns)
  let total_pages = case total_turns {
    0 -> 1
    _ -> {
      let numerator = total_turns + debate_turns_per_page - 1
      case int.divide(numerator, by: debate_turns_per_page) {
        Ok(value) -> value
        Error(Nil) -> 1
      }
    }
  }

  let requested_page = query_page_param(query_params)
  let current_page = clamp_page(requested_page, total_pages)
  let start_index = {
    let offset = current_page - 1
    offset * debate_turns_per_page
  }

  let visible_turns =
    turns
    |> list.reverse
    |> list.drop(start_index)
    |> list.take(debate_turns_per_page)

  DebatePagination(
    turns: visible_turns,
    current_page: current_page,
    total_pages: total_pages,
    per_page: debate_turns_per_page,
    total_turns: total_turns,
  )
}

fn query_page_param(params: List(#(String, String))) -> Int {
  case find_query_int(params, "page") {
    Some(value) -> value
    None -> 1
  }
}

fn find_query_int(params: List(#(String, String)), key: String) -> Option(Int) {
  case params {
    [] -> None
    [#(k, value), ..rest] ->
      case k == key {
        False -> find_query_int(rest, key)
        True ->
          case int.parse(value) {
            Ok(number) -> Some(number)
            Error(Nil) -> None
          }
      }
  }
}

fn clamp_page(requested: Int, total_pages: Int) -> Int {
  let at_least_one = case requested < 1 {
    True -> 1
    False -> requested
  }

  case at_least_one > total_pages {
    True -> total_pages
    False -> at_least_one
  }
}

fn page_turn_range(pagination: DebatePagination) -> #(Int, Int) {
  let offset = pagination.current_page - 1
  let start_index = offset * pagination.per_page + 1
  let count = list.length(pagination.turns)

  case count <= 0 {
    True -> #(0, 0)
    False -> #(start_index, start_index + count - 1)
  }
}

fn render_turn_card(turn: debate.DebateTurn) -> String {
  let senator_link = senator_inline_link(turn.senator)

  "<article class=\"turn-card\">
     <div class=\"turn-meta\">
       <span class=\"turn-index\">Turn #" <> int.to_string(turn.turn_index) <> "</span>
       <span class=\"turn-senator\">" <> senator_link <> "</span>
        <span class=\"turn-vote\">Intent: " <> escape_html(
    debate.vote_intent_label(turn.vote_intent),
  ) <> "</span>
     </div>
     " <> render_turn_tags(turn) <> "
     <div class=\"turn-text full-width\">" <> format_speech(turn.speech) <> "</div>
   </article>"
}

fn render_turn_tags(turn: debate.DebateTurn) -> String {
  let purpose = string.trim(turn.purpose)

  let purpose_tag = case purpose {
    "" -> ""
    _ ->
      "<span class=\"pill tag\">Purpose: " <> escape_html(purpose) <> "</span>"
  }

  let procedure_tag = case turn.procedure {
    debate.NoProcedure -> ""
    _ ->
      "<span class=\"pill tag\">Procedure: "
      <> escape_html(debate.procedure_label(turn.procedure))
      <> "</span>"
  }

  let tags =
    [purpose_tag, procedure_tag]
    |> list.filter(fn(tag) { tag != "" })
    |> string.join("")

  case tags {
    "" -> ""
    _ -> "<div class=\"turn-tags\">" <> tags <> "</div>"
  }
}

fn render_amendments(amendments: List(session.Amendment)) -> String {
  let content = case amendments {
    [] ->
      "<div class=\"empty-transcript\">
         <p>No amendments proposed yet. Senators may submit a full replacement text.</p>
       </div>"
    _ ->
      amendments
      |> list.map(render_amendment_card)
      |> string.join("")
  }

  "<section class=\"panel amendment-panel\" id=\"amendment-panel\">
     <div class=\"panel-header\">
       <h2>Amendments</h2>
       <p>Each amendment replaces the bill text if adopted.</p>
     </div>
     <div class=\"amendment-list\">" <> content <> "</div>
   </section>"
}

fn render_amendment_card(amendment: session.Amendment) -> String {
  let vote_summary = case amendment.vote_result {
    None -> ""
    Some(result) ->
      "<p class=\"amendment-vote\">Vote: "
      <> escape_html(format_result_summary(result))
      <> "</p>"
  }

  "<article class=\"card amendment-card\">
     <div class=\"amendment-meta\">
       <h3>Amendment " <> int.to_string(amendment.id) <> "</h3>
       <p>Proposed by " <> senator_inline_link(amendment.proposer) <> "</p>
       <p>Status: " <> escape_html(format_amendment_status(amendment.status)) <> "</p>
       " <> vote_summary <> "
     </div>
     <div class=\"amendment-text\">" <> format_speech(amendment.text) <> "</div>
   </article>"
}

fn render_roster(
  sess: session.Session,
  senators_list: List(senators.Senator),
) -> String {
  let cards =
    senators_list
    |> list.map(fn(senator) {
      let anchor_id = senator_anchor_id(senator)
      let intent = case session.vote_intent_for(sess, senator.id) {
        Some(value) -> value
        None -> debate.Undecided
      }

      "<article class=\"card senator-card\" id=\"" <> anchor_id <> "\">
         <h3><a href=\"" <> escape_html(senator_profile_href(senator)) <> "\" target=\"_blank\" rel=\"noopener\">" <> escape_html(
        senator.name,
      ) <> "</a></h3>
         <p class=\"senator-meta\">" <> escape_html(senator.state) <> " &middot; Vote intent: " <> escape_html(
        debate.vote_intent_label(intent),
      ) <> "</p>
         <p class=\"senator-bio\">" <> escape_html(biography_snippet(
        senator.biography,
      )) <> "</p>
       </article>"
    })
    |> string.join("")

  "<section class=\"panel senator-panel\" id=\"senator-panel\">
     <div class=\"panel-header\">
       <h2>Senatorial Ledger</h2>
       <p>Background summaries and current vote intentions.</p>
     </div>
     <div class=\"senator-grid\">" <> cards <> "</div>
   </section>"
}

fn render_error_banner(error: Option(String)) -> String {
  let content = case error {
    None -> ""
    Some(message) -> "<div class=\"alert\">
         <p>LLM decision error: " <> escape_html(message) <> "</p>
       </div>"
  }

  "<div id=\"alert-banner\">" <> content <> "</div>"
}

fn render_status_line(sess: session.Session) -> String {
  let label = status_label(sess.status)

  let result_text = case sess.final_result {
    None -> ""
    Some(result) -> "Result: " <> format_result_summary(result)
  }

  let note = case sess.status {
    session.Closed ->
      "Deliberations closed. No further LLM calls will be made for this bill."
    session.Voting(session.BillVote) ->
      "Voting on the bill text is in progress. Tallies will finalize shortly."
    session.Voting(session.AmendmentVote(id)) ->
      "Voting on amendment " <> int.to_string(id) <> " is underway."
    session.InDebate ->
      "Debate in progress. Senators speak selectively with purpose."
  }

  let details =
    [result_text, note]
    |> list.filter(fn(text) { string.trim(text) != "" })
    |> list.map(escape_html)
    |> string.join(" · ")

  "<p class=\"status-line\"><span class=\"pill status-pill\">"
  <> escape_html(label)
  <> "</span> <span class=\"status-detail\">"
  <> details
  <> "</span></p>"
}

fn status_label(status: session.SessionStatus) -> String {
  case status {
    session.InDebate -> "In debate"
    session.Voting(session.BillVote) -> "Voting on bill"
    session.Voting(session.AmendmentVote(id)) ->
      "Voting on amendment " <> int.to_string(id)
    session.Closed -> "Closed"
  }
}

fn render_nav_links(current_theme: theme.Theme) -> String {
  [
    nav_link("/", "Current session", current_theme),
    nav_link("/docket", "Bill docket", current_theme),
    nav_link("/history", "Vote history", current_theme),
  ]
  |> string.join("")
}

fn nav_link(path: String, label: String, current_theme: theme.Theme) -> String {
  "<a href=\""
  <> path
  <> theme.query_suffix(current_theme)
  <> "\">"
  <> label
  <> "</a>"
}

fn render_theme_switcher(
  current_theme: theme.Theme,
  base_path: String,
) -> String {
  let buttons =
    theme.available()
    |> list.map(fn(option) {
      let active = option == current_theme
      let href = case theme.query_suffix(option) {
        "" -> base_path
        suffix -> base_path <> suffix
      }

      "<a class=\""
      <> theme_button_class(active)
      <> "\" href=\""
      <> href
      <> "\">"
      <> theme.label(option)
      <> "</a>"
    })
    |> string.join("")

  "<div class=\"theme-switcher\">
     <span class=\"theme-label\">Theme:</span>
     " <> buttons <> "
   </div>"
}

fn theme_button_class(active: Bool) -> String {
  case active {
    True -> "theme-button is-active"
    False -> "theme-button"
  }
}

fn senator_inline_link(senator: senators.Senator) -> String {
  let href = escape_html(senator_profile_href(senator))
  let label =
    escape_html(senator.name) <> " (" <> escape_html(senator.state) <> ")"

  "<a class=\"senator-link\" href=\""
  <> href
  <> "\" target=\"_blank\" rel=\"noopener\">"
  <> label
  <> "</a>"
}

fn senator_profile_href(senator: senators.Senator) -> String {
  "/senators/" <> senator.id
}

fn senator_anchor_id(senator: senators.Senator) -> String {
  "senator-" <> clean_anchor_fragment(senator.id)
}

fn clean_anchor_fragment(raw: String) -> String {
  raw
  |> string.to_utf_codepoints
  |> list.fold("", fn(acc, cp) {
    let value = string.utf_codepoint_to_int(cp)
    case is_anchor_char(value) {
      True -> acc <> string.from_utf_codepoints([cp])
      False -> acc <> "-"
    }
  })
}

fn is_anchor_char(code: Int) -> Bool {
  code >= 48
  && code <= 57
  || code >= 65
  && code <= 90
  || code >= 97
  && code <= 122
  || code == 45
  || code == 95
}

fn render_autopilot_controls(
  sess: session.Session,
  running: Bool,
  current_theme: theme.Theme,
) -> String {
  let #(action, label, note) = case running {
    True -> #(
      "pause",
      "Pause Simulation",
      "Simulation is advancing automatically. Pause if you need a moment to review.",
    )
    False -> {
      let started = session_has_started(sess)
      #(
        "resume",
        case started {
          True -> "Resume Simulation"
          False -> "Start Simulation"
        },
        case started {
          True -> "Simulation paused — resume when you're ready for more turns."
          False ->
            "Simulation is staged. Start it to generate the first speeches."
        },
      )
    }
  }
  let suffix = theme.query_suffix(current_theme)

  "<div class=\"control-bar\" id=\"autopilot-controls\">
     <form action=\"/autopilot/" <> action <> suffix <> "\" method=\"post\">
       <button class=\"pill-button\" type=\"submit\">" <> label <> "</button>
     </form>
     <p class=\"autopilot-note\">" <> note <> "</p>
   </div>"
}

fn session_has_started(sess: session.Session) -> Bool {
  sess.debate_turns != [] || sess.llm_calls_used > 0
}

fn live_update_script() -> String {
  "<script>
     const harmonyUpdateTargets = {
       hero: \"#hero-header\",
       bill: \"#bill-panel\",
       vote: \"#vote-panel\",
       debate: \"#debate-panel\",
       amendment: \"#amendment-panel\",
       roster: \"#senator-panel\",
       alert: \"#alert-banner\",
     };

     async function harmonyRefreshPanels() {
       if (document.hidden) return;
       try {
         const response = await fetch(window.location.href, { headers: { \"X-Harmony-Refresh\": \"1\" } });
         if (!response.ok) return;
         const payload = await response.json();
         Object.entries(harmonyUpdateTargets).forEach(([key, selector]) => {
           const html = payload[key];
           if (!html) return;
           const current = document.querySelector(selector);
           if (current) {
             current.outerHTML = html;
           }
         });

         const liveBadge = document.querySelector('#live-badge');
         if (liveBadge) {
           liveBadge.classList.add('is-pulsing');
           setTimeout(() => liveBadge.classList.remove('is-pulsing'), 420);
         }
       } catch (_error) {
         // Ignore transient network issues
       }
     }

     setInterval(harmonyRefreshPanels, 2800);
     window.addEventListener('visibilitychange', () => {
       if (!document.hidden) harmonyRefreshPanels();
     });
     setTimeout(harmonyRefreshPanels, 900);
   </script>"
}

fn format_amendment_status(status: session.AmendmentStatus) -> String {
  case status {
    session.Pending -> "Pending"
    session.Adopted -> "Adopted"
    session.Rejected -> "Rejected"
  }
}

fn render_completed_bills(bills: List(session.CompletedBill)) -> String {
  let body = case bills {
    [] -> "<p>No completed votes yet. The first bill is still in progress.</p>"
    _ ->
      bills
      |> list.map(render_completed_card)
      |> string.join("")
  }

  "<section class=\"panel docket-panel\">
     <div class=\"panel-header\">
       <h2>Completed Legislation</h2>
       <p>Vote totals for every bill and amendment finished so far.</p>
     </div>
     <div class=\"docket-list\">" <> body <> "</div>
   </section>"
}

fn render_completed_card(record: session.CompletedBill) -> String {
  let summary = case record.result {
    None -> "Awaiting final vote"
    Some(result) -> format_result_summary(result)
  }

  let amendment_list = render_amendment_history(record.amendments)

  "<article class=\"card amendment-card\">
     <h3>" <> escape_html(record.bill.title) <> "</h3>
     <p class=\"amendment-vote\">Final vote: " <> escape_html(summary) <> "</p>
     <div class=\"amendment-text\">
       <h4>Amendments</h4>
       " <> amendment_list <> "
     </div>
   </article>"
}

fn render_history_card(record: session.CompletedBill) -> String {
  let summary = case record.result {
    None -> "No final vote recorded"
    Some(result) -> format_result_summary(result)
  }

  let amendment_list = render_amendment_history(record.amendments)

  "<article class=\"card amendment-card\">
     <h3>" <> escape_html(record.bill.title) <> "</h3>
     <p class=\"amendment-vote\">Final vote: " <> escape_html(summary) <> "</p>
     <div class=\"amendment-text\">
       <h4>Amendments</h4>
       " <> amendment_list <> "
     </div>
     <details class=\"transcript-block\">
       <summary>View full debate transcript</summary>
       <pre>" <> escape_html(record.transcript_text) <> "</pre>
     </div>
   </article>"
}

fn render_amendment_history(amendments: List(session.Amendment)) -> String {
  case amendments {
    [] -> "<p>No amendments were proposed.</p>"
    _ ->
      amendments
      |> list.map(fn(amendment) {
        "<li><strong>"
        <> senator_inline_link(amendment.proposer)
        <> "</strong>: "
        <> escape_html(format_amendment_status(amendment.status))
        <> case amendment.vote_result {
          None -> ""
          Some(result) -> " — " <> escape_html(format_result_summary(result))
        }
        <> "</li>"
      })
      |> string.join("")
      |> fn(items) { "<ul>" <> items <> "</ul>" }
  }
}

fn render_upcoming_bills(
  current: session.Bill,
  upcoming: List(session.Bill),
) -> String {
  let upcoming_cards =
    upcoming
    |> list.map(fn(bill) { "<article class=\"card senator-card\">
         <h3>" <> escape_html(bill.title) <> "</h3>
         <p class=\"bill-id\">Bill " <> escape_html(bill.id) <> "</p>
         <p>" <> escape_html(bill.summary) <> "</p>
       </article>" })
    |> string.join("")

  "<section class=\"panel bill-panel\">
     <div class=\"panel-header\">
       <h2>On Deck</h2>
       <p>Currently debating: " <> escape_html(current.title) <> "</p>
     </div>
     <div class=\"senator-grid\">" <> upcoming_cards <> "</div>
   </section>"
}

fn format_result_summary(result: session.VoteResult) -> String {
  let session.VoteResult(tally: tally, passed: passed) = result
  let session.VoteTally(yea: yea, nay: nay, abstain: abstain) = tally
  let verdict = case passed {
    True -> "Passed"
    False -> "Failed"
  }

  let abstain_suffix = case abstain > 0 {
    True -> " (" <> int.to_string(abstain) <> " abstaining)"
    False -> ""
  }

  verdict
  <> " "
  <> int.to_string(yea)
  <> "-"
  <> int.to_string(nay)
  <> abstain_suffix
}

fn render_senator_card(
  senator: senators.Senator,
  sess: session.Session,
) -> String {
  let intent = case session.vote_intent_for(sess, senator.id) {
    Some(value) -> value
    None -> debate.Undecided
  }
  let justification = case latest_turn_for(senator.id, sess.debate_turns) {
    None -> ""
    Some(turn) ->
      "<p class=\"senator-meta\"><strong>Latest speech:</strong> "
      <> escape_html(trim_text(turn.speech))
      <> "</p>"
  }

  "<section class=\"panel senator-card\">
     <p class=\"eyebrow\">" <> escape_html(senator.state) <> "</p>
     <h3><a href=\"/senators/" <> escape_html(senator.id) <> "\" target=\"_blank\" rel=\"noopener\">" <> escape_html(
    senator.name,
  ) <> "</a></h3>
     <p class=\"senator-meta\">Intent: " <> escape_html(
    debate.vote_intent_label(intent),
  ) <> "</p>
     " <> justification <> "
  </section>"
}

fn latest_turn_for(
  senator_id: String,
  turns: List(debate.DebateTurn),
) -> Option(debate.DebateTurn) {
  turns
  |> list.filter(fn(turn) { turn.senator.id == senator_id })
  |> list.reverse
  |> list.first
  |> result_to_option
}

fn result_to_option(a: Result(a, b)) -> Option(a) {
  case a {
    Ok(value) -> Some(value)
    Error(_) -> None
  }
}

fn render_notes(notes: List(office.Note)) -> String {
  case notes {
    [] -> "<p>No constituent notes yet. Be the first to share a priority.</p>"
    _ ->
      notes
      |> list.map(fn(note) {
        let office.Note(name:, contact:, body:) = note
        let author = case string.trim(name) {
          "" -> "Anonymous"
          other -> escape_html(other)
        }
        let contact_text = case string.trim(contact) {
          "" -> ""
          other -> " — " <> escape_html(other)
        }

        "<article class=\"note\"><p><strong>"
        <> author
        <> "</strong>"
        <> contact_text
        <> "</p><p>"
        <> escape_html(trim_text(body))
        <> "</p></article>"
      })
      |> string.join("")
  }
}

fn biography_snippet(bio: String) -> String {
  let paragraphs = string.split(bio, "\n\n")
  let snippet = case paragraphs {
    [] -> bio
    [first, ..] -> first
  }

  case string.length(snippet) > 280 {
    True -> string.slice(snippet, 0, 277) <> "..."
    False -> snippet
  }
}

fn trim_text(text: String) -> String {
  let cleaned = string.trim(text)
  case string.length(cleaned) > 220 {
    True -> string.slice(cleaned, 0, 217) <> "..."
    False -> cleaned
  }
}

fn format_speech(text: String) -> String {
  case string.trim(text) {
    "" -> "<p>(No speech recorded this turn.)</p>"
    cleaned ->
      cleaned
      |> string.split("\n\n")
      |> list.map(fn(paragraph) { "<p>" <> escape_html(paragraph) <> "</p>" })
      |> string.join("")
  }
}

fn escape_html(text: String) -> String {
  text
  |> string.replace("&", "&amp;")
  |> string.replace("<", "&lt;")
  |> string.replace(">", "&gt;")
  |> string.replace("\"", "&quot;")
  |> string.replace("'", "&#39;")
}

fn stylesheet() -> String {
  "
  :root {
    --parchment: #f3efe2;
    --ink: #2d2a24;
    --accent: #c1a364;
    --shadow: rgba(0, 0, 0, 0.08);
  }

  * { box-sizing: border-box; }

  body {
    margin: 0;
    font-family: 'Georgia', 'Garamond', serif;
    background: var(--parchment);
    color: var(--ink);
  }

  .page {
    max-width: 1200px;
    margin: 0 auto;
    padding: 2rem 1.5rem 4rem;
  }

  .hero {
    background: #f9f5ea;
    border: 2px solid var(--accent);
    border-radius: 1rem;
    padding: 1.5rem 2rem;
    box-shadow: 0 10px 30px var(--shadow);
    margin-bottom: 1.5rem;
  }

  .hero-top {
    display: flex;
    align-items: center;
    gap: 0.65rem;
    flex-wrap: wrap;
  }

  .live-meta {
    display: flex;
    flex-wrap: wrap;
    gap: 0.5rem;
    margin: 0.35rem 0 0.6rem;
  }

  .live-pill {
    background: linear-gradient(135deg, #ff6b4a, #d23a2c);
    color: #fff;
    border-color: #b3312b;
    box-shadow: 0 0 0 0 rgba(210, 58, 44, 0.4);
  }

  .live-pill.is-pulsing {
    animation: liveFlash 0.5s ease;
  }

  @keyframes liveFlash {
    0% { box-shadow: 0 0 0 0 rgba(210, 58, 44, 0.45); transform: translateY(0); }
    60% { box-shadow: 0 0 0 12px rgba(210, 58, 44, 0); transform: translateY(-1px); }
    100% { box-shadow: 0 0 0 0 rgba(210, 58, 44, 0); transform: translateY(0); }
  }

  .ghost-pill {
    background: #fff4d9;
    border-color: #d1b676;
    color: #6b5634;
  }

  .eyebrow {
    text-transform: uppercase;
    letter-spacing: 0.2em;
    font-size: 0.8rem;
    margin: 0 0 0.4rem;
    color: #8c6a2f;
  }

  .hero-summary {
    margin: 0.4rem 0 0;
    max-width: 40rem;
  }

  .nav-links {
    display: flex;
    gap: 0.75rem;
    margin: 0.5rem 0 0.5rem;
    font-size: 0.9rem;
  }

  .nav-links a {
    color: #2d2a24;
    text-decoration: none;
    border-bottom: 1px solid transparent;
    padding-bottom: 0.1rem;
  }

  .nav-links a:hover {
    border-color: #2d2a24;
  }

  .senator-link {
    color: inherit;
    text-decoration: underline dotted;
    transition: color 0.15s ease;
  }

  .senator-link:hover {
    text-decoration: underline;
  }

  .status-line {
    margin: 0.5rem 0 0;
    font-weight: 600;
    color: #5a4a30;
  }

  .status-detail {
    font-weight: 400;
    margin-left: 0.5rem;
  }

  .pill {
    display: inline-flex;
    align-items: center;
    gap: 0.35rem;
    padding: 0.25rem 0.75rem;
    border-radius: 999px;
    background: #e8dcc0;
    border: 1px solid #c1a364;
    font-size: 0.85rem;
    letter-spacing: 0.02em;
  }

  .status-pill {
    background: #d9c28d;
  }

  .control-bar {
    display: flex;
    flex-wrap: wrap;
    gap: 0.75rem;
    align-items: center;
    margin-top: 0.75rem;
  }

  .button {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 0.4rem;
    padding: 0.5rem 0.85rem;
    border-radius: 0.65rem;
    border: 1px solid #b4882f;
    background: linear-gradient(180deg, #f6e7c9, #e7d6b2);
    color: #3f3217;
    text-decoration: none;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.08em;
    transition: transform 0.12s ease, box-shadow 0.12s ease;
  }

  .button:hover {
    transform: translateY(-1px);
    box-shadow: 0 6px 16px var(--shadow);
  }

  .button.secondary {
    background: #fffaf0;
    border-color: #c1a364;
  }

  .theme-switcher {
    margin-top: 0.75rem;
    display: flex;
    flex-wrap: wrap;
    gap: 0.5rem;
    align-items: center;
  }

  .theme-label {
    font-size: 0.75rem;
    text-transform: uppercase;
    letter-spacing: 0.18em;
    color: #6b5634;
  }

  .theme-button {
    text-decoration: none;
    font-size: 0.75rem;
    text-transform: uppercase;
    letter-spacing: 0.12em;
    border: 1px solid #c1a364;
    padding: 0.2rem 0.6rem;
    border-radius: 0.6rem;
    color: #2d2a24;
    background: rgba(255, 255, 255, 0.6);
    transition: background 0.2s ease, color 0.2s ease;
  }

  .theme-button.is-active {
    background: #2d2a24;
    color: #fff;
  }

  .pill-button {
    border: none;
    background: #2d2a24;
    color: #fff;
    padding: 0.45rem 1.1rem;
    border-radius: 999px;
    font-size: 0.9rem;
    cursor: pointer;
    transition: opacity 0.15s ease;
  }

  .pill-button:hover {
    opacity: 0.85;
  }

  .autopilot-note {
    margin: 0;
    color: #5a4a30;
    font-size: 0.9rem;
  }

  .alert {
    background: #fff2e4;
    border: 1px solid #d27c35;
    border-radius: 0.5rem;
    padding: 0.75rem 1rem;
    margin-bottom: 1rem;
  }

  .grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
    gap: 1.5rem;
    margin-bottom: 2rem;
  }

  .vote-panel {
    grid-column: 1 / -1;
    border: 2px solid #af8c3a;
    box-shadow: 0 12px 30px var(--shadow);
    position: relative;
    overflow: hidden;
  }

  .bill-panel,
  .amendment-panel {
    grid-column: 1 / -1;
  }

  .transcript-panel {
    grid-column: 1 / -1;
  }

  .vote-bars {
    display: grid;
    gap: 0.75rem;
    margin: 0.5rem 0 1rem;
  }

  .vote-bar {
    display: flex;
    flex-direction: column;
    gap: 0.35rem;
  }

  .vote-bar-label {
    display: flex;
    justify-content: space-between;
    font-weight: 600;
  }

  .vote-bar-track {
    height: 14px;
    background: #efe7d2;
    border-radius: 999px;
    overflow: hidden;
    border: 1px solid #d1b77a;
  }

  .vote-bar-fill {
    display: block;
    height: 100%;
    border-radius: 999px;
    transition: width 0.4s ease-in-out;
  }

  .vote-bar-fill.is-yea {
    background: linear-gradient(90deg, #4caf50, #74c174);
  }

  .vote-bar-fill.is-nay {
    background: linear-gradient(90deg, #c62828, #e35151);
  }

  .vote-bar-fill.is-abstain {
    background: linear-gradient(90deg, #8d6e63, #b99f93);
  }

  .vote-summary {
    margin: 0 0 1rem;
    font-weight: 600;
    color: #5a4a30;
  }

  .vote-stats {
    display: flex;
    flex-wrap: wrap;
    gap: 0.5rem;
    margin: 0.1rem 0 0.9rem;
  }

  .stat-pill {
    background: #f3e7d0;
    border-color: #c1a364;
    font-weight: 600;
  }

  .vote-spotlights {
    display: grid;
    gap: 0.5rem;
    grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
    margin-top: 1rem;
  }

  .vote-card {
    border: 1px solid #d9c28d;
    background: #fdf9ef;
    transition: transform 0.2s ease, box-shadow 0.2s ease;
    padding: 0.75rem;
    border-radius: 0.75rem;
  }

  .vote-card:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 20px var(--shadow);
  }

  .vote-card.is-yea { border-color: #4caf50; }
  .vote-card.is-nay { border-color: #c62828; }
  .vote-card.is-abstain { border-color: #8d6e63; }
  .vote-card.is-undecided { border-color: #b7a06b; }

  .vote-card.is-spotlight {
    animation: vote-pulse 1.6s infinite;
    border-width: 2px;
  }

  @keyframes vote-pulse {
    0% { box-shadow: 0 0 0 0 rgba(161, 124, 52, 0.35); }
    70% { box-shadow: 0 0 0 12px rgba(161, 124, 52, 0); }
    100% { box-shadow: 0 0 0 0 rgba(161, 124, 52, 0); }
  }

  .vote-card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 0.3rem;
    margin-bottom: 0.2rem;
  }

  .vote-card-header h3 {
    margin: 0;
    font-size: 1rem;
    line-height: 1.2;
  }

  .intent-pill {
    font-size: 0.7rem;
    padding: 0.15rem 0.5rem;
    text-transform: uppercase;
    letter-spacing: 0.06em;
  }
  
  .intent-pill.is-yea {
    background: #e8f5e9;
    border-color: #4caf50;
    color: #285e28;
  }

  .intent-pill.is-nay {
    background: #ffebee;
    border-color: #c62828;
    color: #7b1f1f;
  }

  .intent-pill.is-abstain {
    background: #efebe9;
    border-color: #8d6e63;
    color: #4e342e;
  }

  .intent-pill.is-undecided {
    background: #fff8e1;
    border-color: #b59b61;
    color: #5d4a1f;
  }

  .vote-card-sub {
    margin: 0;
    color: #6f5c38;
    font-weight: 600;
    font-size: 0.85rem;
  }

  .vote-card-bio {
    margin-top: 0.4rem;
    color: #4b3f2b;
    line-height: 1.45;
  }

  .vote-pill {
    display: inline-block;
    background: #f0e5cf;
    padding: 0.25rem 0.65rem;
    border-radius: 999px;
    border: 1px dashed #b39655;
    margin: 0.35rem 0;
    font-size: 0.85rem;
  }

  .panel {
    background: #fffdf8;
    border: 2px solid #dac6a3;
    border-radius: 1rem;
    padding: 1.5rem;
    box-shadow: 0 8px 24px var(--shadow);
  }

  .panel-header h2 {
    margin: 0;
    font-size: 1.4rem;
  }

  .panel-header p {
    margin: 0.3rem 0 0;
    color: #5a4a30;
  }

  .bill-summary {
    line-height: 1.6;
  }

  .transcript-grid {
    display: flex;
    flex-direction: column;
    gap: 1rem;
  }

  .pagination {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    justify-content: space-between;
    gap: 0.5rem;
    margin-top: 1rem;
  }

  .pagination.is-compact {
    justify-content: flex-end;
    margin-top: 0;
    margin-bottom: 0.75rem;
  }

  .pagination-links {
    display: flex;
    flex-wrap: wrap;
    gap: 0.4rem;
  }

  .page-link {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    min-width: 2.25rem;
    padding: 0.35rem 0.65rem;
    border-radius: 0.55rem;
    border: 1px solid rgba(149, 115, 60, 0.35);
    background: #fffaf0;
    color: inherit;
    text-decoration: none;
    font-weight: 600;
    transition: background 0.15s ease, transform 0.1s ease, color 0.15s ease;
  }

  .page-link:hover {
    background: #f1e6d0;
    transform: translateY(-1px);
  }

  .page-link.is-active {
    background: #c1a364;
    color: #fff;
    border-color: #c1a364;
  }

  .page-link.is-disabled {
    opacity: 0.5;
    pointer-events: none;
  }

  .pagination-summary {
    margin: 0;
    color: #5a4a30;
    font-size: 0.9rem;
  }

  .turn-card {
    background: #fffaf0;
    border: 1px solid rgba(151, 121, 70, 0.4);
    border-radius: 0.75rem;
    padding: 1rem;
    box-shadow: 0 6px 20px var(--shadow);
  }

  .turn-meta {
    display: flex;
    flex-wrap: wrap;
    gap: 0.5rem 1rem;
    font-size: 0.9rem;
    margin-bottom: 0.75rem;
    text-transform: uppercase;
    letter-spacing: 0.04em;
    color: #6f5632;
  }

  .turn-text p {
    margin: 0 0 0.6rem;
    line-height: 1.55;
  }

  .turn-text.full-width {
    width: 100%;
    display: block;
    padding: 1rem 0.25rem;
  }

  .turn-text.full-width p {
    font-size: 1.05rem;
    line-height: 1.7;
  }

  .turn-tags {
    display: flex;
    flex-wrap: wrap;
    gap: 0.4rem;
    margin: 0 0 0.5rem;
  }

  .tag {
    background: #f1e6d0;
  }

  .empty-transcript {
    border: 1px dashed #c5ab78;
    border-radius: 0.75rem;
    padding: 1rem;
    font-style: italic;
    color: #6b5a37;
  }

  .senator-panel {
    margin-top: 2rem;
  }

  .senator-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
    gap: 1rem;
    margin-top: 1rem;
  }

  .card {
    background: #fffef9;
    border: 1px solid rgba(149, 115, 60, 0.35);
    border-radius: 0.75rem;
    padding: 1rem;
    box-shadow: 0 4px 16px var(--shadow);
  }

  .senator-card h3 {
    margin: 0;
  }

  .senator-meta {
    margin: 0.35rem 0;
    font-size: 0.95rem;
    color: #6a5533;
  }

  .senator-bio {
    margin: 0;
    line-height: 1.4;
  }

  .amendment-panel .amendment-list {
    display: flex;
    flex-direction: column;
    gap: 1rem;
    margin-top: 1rem;
  }

  .amendment-panel .empty-transcript {
    margin: 0;
  }

  .amendment-card h3 {
    margin: 0 0 0.25rem 0;
  }

  .amendment-meta p {
    margin: 0.1rem 0;
    font-size: 0.9rem;
    color: #5b4a33;
  }

  .amendment-text {
    margin-top: 0.5rem;
  }

  .amendment-text p {
    margin: 0 0 0.6rem;
  }

  .amendment-vote {
    font-weight: 600;
  }

  .docket-panel .docket-list {
    display: flex;
    flex-direction: column;
    gap: 1rem;
    margin-top: 1rem;
  }

  .transcript-block {
    margin-top: 0.75rem;
  }

  .transcript-block pre {
    background: #f4efe0;
    padding: 0.75rem;
    border-radius: 0.5rem;
    white-space: pre-wrap;
    max-height: 20rem;
    overflow-y: auto;
  }

  body.theme-terminal {
    background-color: #020b04;
    color: #d4ffe0;
    font-family: 'Share Tech Mono', 'IBM Plex Mono', 'SFMono-Regular', 'Liberation Mono', monospace;
    text-shadow: 0 0 8px rgba(13, 244, 106, 0.18);
    background-image:
      radial-gradient(circle at 15% 20%, rgba(13, 244, 106, 0.12), transparent 45%),
      repeating-linear-gradient(0deg, rgba(13, 244, 106, 0.04) 0px, rgba(13, 244, 106, 0.04) 1px, transparent 1px, transparent 4px);
    background-attachment: fixed;
  }

  body.theme-terminal .page {
    background: rgba(0, 0, 0, 0.55);
  }

  body.theme-terminal .hero {
    background: rgba(3, 18, 11, 0.95);
    border-color: #0df46a;
    box-shadow: 0 0 35px rgba(13, 244, 106, 0.35);
  }

  body.theme-terminal .nav-links a {
    color: #9ffec9;
    border-color: rgba(13, 244, 106, 0.25);
  }

  body.theme-terminal .nav-links a:hover {
    border-color: #9ffec9;
  }

  body.theme-terminal .hero-summary,
  body.theme-terminal .status-line,
  body.theme-terminal .status-detail,
  body.theme-terminal .theme-label,
  body.theme-terminal .autopilot-note,
  body.theme-terminal .panel-header p,
  body.theme-terminal .senator-meta,
  body.theme-terminal .amendment-meta p {
    color: #9bf7c9;
  }

  body.theme-terminal .pill,
  body.theme-terminal .tag {
    background: rgba(13, 244, 106, 0.12);
    border-color: rgba(13, 244, 106, 0.45);
    color: #adffd8;
  }

  body.theme-terminal .status-pill {
    background: rgba(13, 244, 106, 0.3);
    color: #012812;
  }

  body.theme-terminal .control-bar {
    border-top: 1px solid rgba(13, 244, 106, 0.2);
    padding-top: 0.75rem;
  }

  body.theme-terminal .theme-button {
    border-color: rgba(13, 244, 106, 0.5);
    color: #96fccc;
    background: rgba(2, 26, 16, 0.9);
  }

  body.theme-terminal .theme-button.is-active {
    background: #0df46a;
    color: #022011;
  }

  body.theme-terminal .pill-button {
    background: #0df46a;
    color: #031910;
    box-shadow: 0 0 25px rgba(13, 244, 106, 0.45);
    text-transform: uppercase;
    letter-spacing: 0.08em;
  }

  body.theme-terminal .pill-button:hover {
    opacity: 1;
    filter: brightness(1.1);
  }

  body.theme-terminal .panel,
  body.theme-terminal .card,
  body.theme-terminal .turn-card,
  body.theme-terminal .amendment-card {
    background: rgba(2, 20, 12, 0.95);
    border-color: rgba(13, 244, 106, 0.35);
    box-shadow: 0 0 30px rgba(0, 0, 0, 0.75);
    color: #d6ffd7;
  }

  body.theme-terminal .turn-meta {
    color: #8ef7ba;
  }

  body.theme-terminal .empty-transcript {
    border-color: rgba(13, 244, 106, 0.35);
    color: #a4ffd3;
    background: rgba(2, 26, 14, 0.8);
  }

  body.theme-terminal .alert {
    background: rgba(255, 102, 102, 0.08);
    border-color: #ff7b7b;
    color: #ffc0c0;
  }

  body.theme-terminal .transcript-block pre {
    background: #04170c;
    color: #befed9;
  }

  body.theme-terminal .senator-bio,
  body.theme-terminal .bill-summary,
  body.theme-terminal .amendment-text,
  body.theme-terminal .turn-text p {
    color: #e1ffe6;
  }

  body.theme-terminal .theme-switcher {
    border-top: 1px solid rgba(13, 244, 106, 0.2);
    padding-top: 0.75rem;
  }

  body.theme-terminal .theme-button.is-active,
  body.theme-terminal .pill-button {
    text-shadow: none;
  }

  body.theme-blossom {
    background: radial-gradient(circle at 20% 20%, #ffe9f4, #ffd2ec, #ffc3e5);
    color: #5d1a3d;
    font-family: 'Baloo 2', 'Nunito', 'Trebuchet MS', sans-serif;
  }

  body.theme-blossom .hero {
    background: rgba(255, 255, 255, 0.85);
    border-color: #ff9bcf;
    box-shadow: 0 15px 35px rgba(255, 155, 207, 0.4);
  }

  body.theme-blossom .nav-links a {
    color: #c2125c;
    border-color: rgba(194, 18, 92, 0.2);
  }

  body.theme-blossom .nav-links a:hover {
    border-color: #c2125c;
  }

  body.theme-blossom .hero-summary,
  body.theme-blossom .status-line,
  body.theme-blossom .status-detail,
  body.theme-blossom .theme-label,
  body.theme-blossom .autopilot-note,
  body.theme-blossom .panel-header p,
  body.theme-blossom .senator-meta,
  body.theme-blossom .amendment-meta p {
    color: #7c2354;
  }

  body.theme-blossom .pill,
  body.theme-blossom .tag {
    background: rgba(255, 155, 207, 0.25);
    border-color: rgba(255, 155, 207, 0.7);
    color: #7c2354;
  }

  body.theme-blossom .status-pill {
    background: #ff8ac3;
    color: #4d0a2d;
  }

  body.theme-blossom .pill-button {
    background: linear-gradient(120deg, #ff4fa3, #ff8ed6);
    color: #fff;
    box-shadow: 0 12px 20px rgba(255, 79, 163, 0.4);
  }

  body.theme-blossom .pill-button:hover {
    opacity: 1;
    filter: brightness(1.05);
  }

  body.theme-blossom .theme-button {
    border-color: rgba(255, 155, 207, 0.8);
    background: rgba(255, 255, 255, 0.8);
    color: #a51c55;
  }

  body.theme-blossom .theme-button.is-active {
    background: #ff4fa3;
    color: #fff;
  }

  body.theme-blossom .panel,
  body.theme-blossom .card,
  body.theme-blossom .turn-card,
  body.theme-blossom .amendment-card {
    background: rgba(255, 255, 255, 0.92);
    border-color: rgba(255, 155, 207, 0.6);
    box-shadow: 0 12px 30px rgba(255, 155, 207, 0.35);
  }

  body.theme-blossom .empty-transcript {
    background: rgba(255, 235, 246, 0.9);
    border-color: rgba(255, 155, 207, 0.6);
    color: #872150;
  }

  body.theme-blossom .alert {
    background: rgba(255, 182, 193, 0.25);
    border-color: #ff4fa3;
    color: #b81052;
  }

  body.theme-blossom .transcript-block pre {
    background: rgba(255, 230, 240, 0.9);
    color: #6d1c42;
  }

  body.theme-blossom .senator-bio,
  body.theme-blossom .bill-summary,
  body.theme-blossom .amendment-text,
  body.theme-blossom .turn-text p {
    color: #5d1a3d;
  }

  body.theme-signal {
    background: linear-gradient(135deg, #f5f5f5, #dcdcdc);
    color: #111;
    font-family: 'Futura', 'Bahnschrift', 'Arial Narrow', sans-serif;
    text-transform: none;
  }

  body.theme-signal .hero {
    background: #fff;
    border: 4px solid #111;
    border-bottom: 12px solid #d40000;
    box-shadow: 0 25px 40px rgba(0, 0, 0, 0.2);
  }

  body.theme-signal .nav-links a {
    color: #111;
    border-color: rgba(17, 17, 17, 0.35);
  }

  body.theme-signal .nav-links a:hover {
    border-color: #d40000;
  }

  body.theme-signal .hero-summary,
  body.theme-signal .status-line,
  body.theme-signal .status-detail,
  body.theme-signal .theme-label,
  body.theme-signal .autopilot-note,
  body.theme-signal .panel-header p,
  body.theme-signal .senator-meta,
  body.theme-signal .amendment-meta p {
    color: #1f1f1f;
  }

  body.theme-signal .pill,
  body.theme-signal .tag {
    background: #f7f7f7;
    border: 2px solid #111;
    color: #111;
    text-transform: uppercase;
    letter-spacing: 0.08em;
  }

  body.theme-signal .status-pill {
    background: #d40000;
    color: #fff;
  }

  body.theme-signal .pill-button {
    background: #111;
    color: #fff;
    text-transform: uppercase;
    letter-spacing: 0.15em;
    border-radius: 0;
    padding: 0.6rem 1.6rem;
  }

  body.theme-signal .pill-button:hover {
    background: #d40000;
  }

  body.theme-signal .theme-button {
    border: 2px solid #111;
    background: #fff;
    color: #111;
    text-transform: uppercase;
  }

  body.theme-signal .theme-button.is-active {
    background: #d40000;
    color: #fff;
  }

  body.theme-signal .panel,
  body.theme-signal .card,
  body.theme-signal .turn-card,
  body.theme-signal .amendment-card {
    background: #fff;
    border: 3px solid #111;
    box-shadow: 12px 12px 0 #111;
  }

  body.theme-signal .empty-transcript {
    border: 3px dashed #111;
    color: #333;
    background: #fafafa;
  }

  body.theme-signal .alert {
    background: #fff0f0;
    border: 3px solid #d40000;
    color: #760000;
  }

  body.theme-signal .transcript-block pre {
    background: #f6f6f6;
    color: #111;
  }

  body.theme-orbit {
    background: radial-gradient(circle at 10% 20%, #0b1b2a, #030914);
    color: #e6f3ff;
    font-family: 'Orbitron', 'Share Tech Mono', 'Segoe UI', sans-serif;
    letter-spacing: 0.01em;
  }

  body.theme-orbit .hero {
    background: rgba(2, 9, 26, 0.9);
    border: 1px solid #5af1ff;
    box-shadow: 0 0 40px rgba(90, 241, 255, 0.25);
  }

  body.theme-orbit .nav-links a {
    color: #9be7ff;
    border-color: rgba(90, 241, 255, 0.25);
  }

  body.theme-orbit .nav-links a:hover {
    border-color: #5af1ff;
  }

  body.theme-orbit .hero-summary,
  body.theme-orbit .status-line,
  body.theme-orbit .status-detail,
  body.theme-orbit .theme-label,
  body.theme-orbit .autopilot-note,
  body.theme-orbit .panel-header p,
  body.theme-orbit .senator-meta,
  body.theme-orbit .amendment-meta p {
    color: #b4f3ff;
  }

  body.theme-orbit .pill,
  body.theme-orbit .tag {
    background: rgba(90, 241, 255, 0.12);
    border-color: rgba(90, 241, 255, 0.35);
    color: #bdf8ff;
  }

  body.theme-orbit .status-pill {
    background: rgba(90, 241, 255, 0.3);
    color: #03111f;
  }

  body.theme-orbit .pill-button {
    background: linear-gradient(135deg, #10b8ff, #62ffe1);
    color: #02101c;
    text-transform: uppercase;
    letter-spacing: 0.1em;
    box-shadow: 0 0 25px rgba(98, 255, 225, 0.45);
  }

  body.theme-orbit .pill-button:hover {
    filter: brightness(1.1);
  }

  body.theme-orbit .theme-button {
    border-color: rgba(90, 241, 255, 0.5);
    background: rgba(2, 14, 24, 0.85);
    color: #9be7ff;
  }

  body.theme-orbit .theme-button.is-active {
    background: #5af1ff;
    color: #03111f;
  }

  body.theme-orbit .panel,
  body.theme-orbit .card,
  body.theme-orbit .turn-card,
  body.theme-orbit .amendment-card {
    background: rgba(5, 20, 36, 0.95);
    border: 1px solid rgba(90, 241, 255, 0.25);
    box-shadow: 0 0 35px rgba(0, 0, 0, 0.6);
  }

  body.theme-orbit .empty-transcript {
    background: rgba(6, 26, 46, 0.9);
    border-color: rgba(90, 241, 255, 0.2);
    color: #c4fbff;
  }

  body.theme-orbit .alert {
    background: rgba(255, 123, 123, 0.14);
    border-color: rgba(255, 144, 144, 0.5);
    color: #ffd7d7;
  }

  body.theme-orbit .transcript-block pre {
    background: #07192a;
    color: #d6f9ff;
  }

  body.theme-orbit .senator-bio,
  body.theme-orbit .bill-summary,
  body.theme-orbit .amendment-text,
  body.theme-orbit .turn-text p {
    color: #e6f3ff;
  }

  body.theme-romance {
    background: radial-gradient(circle at 20% 20%, #fff0f3, #ffe1e7, #ffd6e1);
    color: #5c1121;
    font-family: 'Playfair Display', 'Cormorant Garamond', serif;
  }

  body.theme-romance .hero {
    background: rgba(255, 255, 255, 0.9);
    border-color: #f76c8c;
    box-shadow: 0 15px 30px rgba(247, 108, 140, 0.35);
  }

  body.theme-romance .nav-links a {
    color: #b1132f;
    border-color: rgba(177, 19, 47, 0.2);
  }

  body.theme-romance .nav-links a:hover {
    border-color: #b1132f;
  }

  body.theme-romance .hero-summary,
  body.theme-romance .status-line,
  body.theme-romance .status-detail,
  body.theme-romance .theme-label,
  body.theme-romance .autopilot-note,
  body.theme-romance .panel-header p,
  body.theme-romance .senator-meta,
  body.theme-romance .amendment-meta p {
    color: #7a1a2c;
  }

  body.theme-romance .pill,
  body.theme-romance .tag {
    background: rgba(255, 167, 186, 0.3);
    border-color: rgba(255, 87, 120, 0.5);
    color: #7a1a2c;
  }

  body.theme-romance .status-pill {
    background: #ff5f87;
    color: #fff;
  }

  body.theme-romance .pill-button {
    background: linear-gradient(120deg, #d70040, #ff5f87);
    color: #fff;
    border-radius: 999px;
    box-shadow: 0 12px 24px rgba(215, 0, 64, 0.35);
  }

  body.theme-romance .pill-button:hover {
    filter: brightness(1.1);
  }

  body.theme-romance .theme-button {
    border-color: rgba(255, 87, 120, 0.6);
    color: #b1132f;
    background: rgba(255, 255, 255, 0.85);
  }

  body.theme-romance .theme-button.is-active {
    background: #d70040;
    color: #fff;
  }

  body.theme-romance .panel,
  body.theme-romance .card,
  body.theme-romance .turn-card,
  body.theme-romance .amendment-card {
    background: rgba(255, 255, 255, 0.95);
    border-color: rgba(255, 87, 120, 0.4);
    box-shadow: 0 15px 30px rgba(215, 0, 64, 0.2);
  }

  body.theme-romance .empty-transcript {
    background: rgba(255, 230, 236, 0.9);
    border-color: rgba(255, 87, 120, 0.4);
    color: #7a1a2c;
  }

  body.theme-romance .alert {
    background: rgba(255, 147, 165, 0.3);
    border-color: #d70040;
    color: #7a1a2c;
  }

  body.theme-romance .transcript-block pre {
    background: rgba(255, 237, 241, 0.95);
    color: #7a1a2c;
  }

  body.theme-romance .senator-bio,
  body.theme-romance .bill-summary,
  body.theme-romance .amendment-text,
  body.theme-romance .turn-text p {
    color: #5c1121;
  }

  @media (max-width: 720px) {
    .grid {
      grid-template-columns: 1fr;
    }
  }
  "
}

fn render_intentions_panel(intentions: List(String)) -> String {
  let body = case intentions {
    [] ->
      "<p>No declared long-term initiatives. Share your ongoing goals so constituents can track them.</p>"
    _ ->
      intentions
      |> list.map(fn(line) { "<li>" <> escape_html(line) <> "</li>" })
      |> string.join("")
      |> fn(items) { "<ul class=\"intention-list\">" <> items <> "</ul>" }
  }

  "<section class=\"panel intention-panel\">
     <h2>Current Intentions</h2>
     " <> body <> "
   </section>"
}

fn render_mailbox_panel(
  senator: senators.Senator,
  notes: List(office.Note),
) -> String {
  let note_list = render_notes(notes)

  "<section class=\"panel mailbox-panel\">
     <h2>Constituent Mailbox</h2>
     <form method=\"post\" action=\"/senators/" <> senator.id <> "/notes\" class=\"mailbox-form\">
       <label>Name<br /><input type=\"text\" name=\"name\" placeholder=\"Your name\" /></label><br />
       <label>Contact<br /><input type=\"text\" name=\"contact\" placeholder=\"Email or phone\" /></label><br />
       <label>Message<br /><textarea name=\"body\" rows=\"4\" placeholder=\"Share your priority or feedback\"></textarea></label><br />
       <button type=\"submit\">Send to office</button>
     </form>
     <div class=\"note-list\">
       " <> note_list <> "
     </div>
   </section>"
}

fn render_statement_blog(
  posts: List(debate.DebateTurn),
  bill: session.Bill,
) -> String {
  let content = case posts {
    [] -> "<p>No floor statements yet for this session.</p>"
    _ ->
      posts
      |> list.map(fn(turn) { render_blog_entry(turn, bill) })
      |> string.join("")
  }

  "<section class=\"panel blog-panel\">
     <h2>Floor Statements Feed</h2>
     " <> content <> "
   </section>"
}

fn render_blog_entry(turn: debate.DebateTurn, bill: session.Bill) -> String {
  let intent = debate.vote_intent_label(turn.vote_intent)
  let procedure = debate.procedure_label(turn.procedure)

  "<article class=\"blog-entry\">
     <h3>Turn " <> int.to_string(turn.turn_index) <> ": " <> escape_html(
    bill.title,
  ) <> "</h3>
     <p class=\"blog-meta\">Vote intent: " <> escape_html(intent) <> " &middot; Procedure: " <> escape_html(
    procedure,
  ) <> " &middot; Purpose: " <> escape_html(turn.purpose) <> "</p>
     <div class=\"blog-body\">" <> format_speech(turn.speech) <> "</div>
   </article>"
}
