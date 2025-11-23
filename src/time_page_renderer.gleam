//// Full-page time legislation interface for AGATA.
//// A beautiful, innovative dashboard for Todd and Delaney to report status,
//// view active time bills, and track their work in real-time.

import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import human_status
import resource_state
import senators
import theme
import time_bill
import time_session

pub type TimeFragments {
  TimeFragments(
    order_banner: String,
    active_block: String,
    timeline: String,
    resources: String,
    senate_status: String,
  )
}

/// Render the complete time legislation page
pub fn render_time_page(
  current_status: Option(human_status.HumanStatus),
  active_bill: Option(time_bill.TimeBill),
  recent_reports: List(human_status.BlockReport),
  completed_tasks: List(time_session.CompletedTask),
  resources: resource_state.ResourceState,
  all_bills: List(time_bill.TimeBill),
  senators_list: List(senators.Senator),
  current_theme: theme.Theme,
) -> String {
  let body_class = theme.body_class(current_theme)
  let _nav_links = render_nav_links(current_theme)
  let _theme_switcher = render_theme_switcher(current_theme)

  let hero = render_hero(current_status, current_theme)
  let status_input = render_status_input_section()
  let active_block = render_active_block_section(active_bill, current_status)
  let report_input = render_report_input_section(active_bill)
  let timeline = render_timeline_section(recent_reports, all_bills, completed_tasks)
  let resources_panel = render_resources_panel(resources)
  let senate_status = render_senate_status(senators_list)
  let order_banner = render_time_order_banner(active_bill)

  "<!doctype html>
   <html lang=\"en\">
     <head>
       <meta charset=\"utf-8\" />
       <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />
       <title>AGATA Time Legislation | Harmony Chamber</title>
       <style>" <> time_stylesheet() <> "</style>
     </head>
     <body class=\"" <> body_class <> " time-page\">
       <div class=\"time-container\">
        " <> hero <> "
        <div id=\"time-order-banner\">
          " <> order_banner <> "
        </div>
         
         <div class=\"time-grid\">
           <div class=\"time-main\">
             " <> status_input <> "
             " <> active_block <> "
             " <> report_input <> "
             <div id=\"timeline-section\">
               " <> timeline <> "
             </div>
           </div>
           
           <div class=\"time-sidebar\">
             <div id=\"resources-panel\">
               " <> resources_panel <> "
             </div>
             <div id=\"senate-status-panel\">
               " <> senate_status <> "
             </div>
           </div>
         </div>
       </div>
       " <> live_update_script() <> "
     </body>
  </html>"
}

pub fn render_time_fragments(
  current_status: Option(human_status.HumanStatus),
  active_bill: Option(time_bill.TimeBill),
  recent_reports: List(human_status.BlockReport),
  completed_tasks: List(time_session.CompletedTask),
  resources: resource_state.ResourceState,
  all_bills: List(time_bill.TimeBill),
  senators_list: List(senators.Senator),
  _current_theme: theme.Theme,
) -> TimeFragments {
  TimeFragments(
    order_banner: render_time_order_banner(active_bill),
    active_block: render_active_block_section(active_bill, current_status),
    timeline: render_timeline_section(recent_reports, all_bills, completed_tasks),
    resources: render_resources_panel(resources),
    senate_status: render_senate_status(senators_list),
  )
}

fn render_hero(
  status: Option(human_status.HumanStatus),
  current_theme: theme.Theme,
) -> String {
  let status_indicator = case status {
    None ->
      "<span class=\"status-badge status-waiting\">⏳ Awaiting Status</span>"
    Some(s) -> {
      let energy_avg = average_energy(s.todd_energy, s.delaney_energy)
      let badge_class = case energy_avg {
        time_bill.High -> "status-badge status-high"
        time_bill.Medium -> "status-badge status-medium"
        time_bill.Low -> "status-badge status-low"
      }
      "<span class=\""
      <> badge_class
      <> "\">⚡ "
      <> time_bill.energy_to_string(energy_avg)
      <> " energy</span>"
    }
  }

  let nav_links = render_nav_links(current_theme)
  let theme_switcher = render_theme_switcher(current_theme)

  "<header class=\"time-hero\">
     <div class=\"hero-content\">
       <div class=\"hero-top\">
         <div>
           <p class=\"eyebrow\">AGATA / Harmony Chamber</p>
           <h1>⏱️ Time Legislation</h1>
           <p class=\"hero-subtitle\">Micro-block governance for Todd & Delaney</p>
         </div>
         " <> status_indicator <> "
       </div>
       
       <nav class=\"nav-links\">
         " <> nav_links <> "
       </nav>
       
       <div class=\"hero-meta\">
         <span class=\"pill ghost-pill\">🔄 Auto-sync ~3s</span>
         <span class=\"pill ghost-pill\">📊 Live tracking</span>
         <span class=\"pill ghost-pill\">🎯 Micro-blocks: 5-15 min</span>
       </div>
       
      " <> theme_switcher <> "
    </div>
  </header>"
}

fn render_time_order_banner(bill: Option(time_bill.TimeBill)) -> String {
  let content = case bill {
    None ->
      "<p>The Senate is ready when you are. Submit a status report to trigger the next order.</p>"
    Some(current) -> {
      let next_block = time_bill.next_block(current)
      let pillar_names =
        current.pillar_links
        |> list.map(fn(p) { time_bill.pillar_to_string(p) })
        |> string.join(", ")
      let pillar_display = case pillar_names {
        "" -> "pillars TBD"
        other -> other
      }

      let block_detail = case next_block {
        None ->
          "<p class=\"order-detail\">No pending micro-block yet; the Senate is still sculpting the next assignment.</p>"
        Some(block) -> {
          let instruction_preview = case block.instructions {
            [] -> "No steps provided yet."
            [first, .._] -> escape_html(first)
          }
          "<p class=\"order-detail\">Next block: "
          <> int.to_string(block.duration_minutes)
          <> " min · "
          <> escape_html(instruction_preview)
          <> "</p>"
        }
      }

      let base_info =
        "<div class=\"order-heading\">
           <span class=\"order-label\">Latest order</span>
           <strong>"
        <> escape_html(current.title)
        <> " ("
        <> current.id
        <> ")</strong>
         </div>
         <p class=\"order-purpose\">"
        <> escape_html(current.purpose)
        <> "</p>"
        <> "<p class=\"order-detail\">Pillars: "
        <> escape_html(pillar_display)
        <> " · Horizon: "
        <> escape_html(time_bill.time_horizon_to_string(current.time_horizon))
        <> "</p>"

      base_info <> block_detail
    }
  }

  "<div class=\"time-order-banner\" role=\"status\" aria-live=\"polite\">
     " <> content <> "
   </div>"
}

fn render_status_input_section() -> String {
  "<section class=\"time-card status-input-card\" id=\"status-input\">
     <div class=\"card-header\">
       <h2>📍 Report Current Status</h2>
       <p>Tell the Senate where you are and what you need</p>
     </div>
     
     <form class=\"status-form\" method=\"post\" action=\"/time/status\">
       <div class=\"form-grid\">
        <div class=\"form-group\">
        <label>⏰ Time (local EST)</label>
          <div class=\"time-entry\">
            <input type=\"text\" id=\"status-timestamp\" name=\"timestamp\" placeholder=\"2025-01-15 09:30 AM\" required />
            <button type=\"button\" class=\"time-entry-btn\" onclick=\"promptTimestamp('status-timestamp','status time')\">🕘 Edit</button>
          </div>
        </div>
         
         <div class=\"form-group\">
           <label>⏱️ Block preference <span class=\"info-icon\" title=\"Choose the duration you'd like for the next micro-block.\">?</span></label>
           <select name=\"block_preference\" required>
             <option value=\"5\">5 minutes</option>
             <option value=\"10\" selected>10 minutes</option>
             <option value=\"15\">15 minutes</option>
             <option value=\"20\">20 minutes</option>
             <option value=\"25\">25 minutes</option>
             <option value=\"30\">30 minutes</option>
             <option value=\"unsure\">Flexible</option>
           </select>
           <p class=\"field-hint\">Pick a length that respects your energy and obligations.</p>
         </div>
         
         <div class=\"form-group full-width\">
           <label>📍 Location</label>
           <input type=\"text\" name=\"location\" placeholder=\"AGATA farmhouse\" required />
         </div>
       </div>
       
       <div class=\"form-grid human-energy-grid\">
         <div class=\"energy-card\">
           <h3>Todd <span class=\"info-icon\" title=\"Share Todd's current energy level.\">?</span></h3>
           <p class=\"field-hint\">This helps the Senate honor fatigue and breaks.</p>
           <div class=\"energy-buttons\">
             <label class=\"energy-btn\">
               <input type=\"radio\" name=\"todd_energy\" value=\"low\" />
               <span class=\"energy-low\">Low</span>
             </label>
             <label class=\"energy-btn\">
               <input type=\"radio\" name=\"todd_energy\" value=\"medium\" checked />
               <span class=\"energy-medium\">Medium</span>
             </label>
             <label class=\"energy-btn\">
               <input type=\"radio\" name=\"todd_energy\" value=\"high\" />
               <span class=\"energy-high\">High</span>
             </label>
           </div>
           <input type=\"text\" name=\"todd_mood\" placeholder=\"Mood (focused, steady)\" />
         </div>
         
         <div class=\"energy-card\">
           <h3>Delaney <span class=\"info-icon\" title=\"Delaney’s energy helps plan collaboration.\">?</span></h3>
           <p class=\"field-hint\">Let the Senate know if Delaney’s creative energy is up or gently fading.</p>
           <div class=\"energy-buttons\">
             <label class=\"energy-btn\">
               <input type=\"radio\" name=\"delaney_energy\" value=\"low\" />
               <span class=\"energy-low\">Low</span>
             </label>
             <label class=\"energy-btn\">
               <input type=\"radio\" name=\"delaney_energy\" value=\"medium\" checked />
               <span class=\"energy-medium\">Medium</span>
             </label>
             <label class=\"energy-btn\">
               <input type=\"radio\" name=\"delaney_energy\" value=\"high\" />
               <span class=\"energy-high\">High</span>
             </label>
           </div>
           <input type=\"text\" name=\"delaney_mood\" placeholder=\"Mood (energized, reflective)\" />
         </div>
       </div>
       
       <div class=\"form-grid\">
         <div class=\"form-group\">
           <label>🏃 Physical state</label>
           <input type=\"text\" name=\"physical_state\" placeholder=\"at desk with coffee\" />
         </div>
         
       <div class=\"form-group\">
         <label>💻 Tools available</label>
         <input type=\"text\" name=\"internet_tools\" placeholder=\"laptop, good wifi\" />
       </div>
      </div>

      <div class=\"form-grid\">
        <div class=\"form-group\">
          <label>🧭 Todd's immediate needs</label>
          <textarea name=\"todd_needs\" rows=\"2\" placeholder=\"One need per line\"></textarea>
          <p class=\"textarea-hint\">List the top 1-2 requests for Todd so the Senate knows what to honor.</p>
        </div>

        <div class=\"form-group\">
          <label>🧭 Delaney's immediate needs</label>
          <textarea name=\"delaney_needs\" rows=\"2\" placeholder=\"One need per line\"></textarea>
          <p class=\"textarea-hint\">Share what Delaney will need after the current block.</p>
        </div>
      </div>
      
       <div class=\"form-group\">
         <label>⚠️ Hard constraints (next 2-3 hours) <span class=\"info-icon\" title=\"Include scheduled calls, appointments, or urgent obligations.\">?</span></label>
          <textarea name=\"constraints\" rows=\"2\" placeholder=\"Todd has call at 11 AM\"></textarea>
          <p class=\"textarea-hint\">Name anything that cannot be rescheduled this afternoon.</p>
        </div>
        
      <div class=\"form-group\">
        <label>📝 Tasks on your mind <span class=\"info-icon\" title=\"Capture what you’re already thinking about so the Senate can prioritize.\">?</span></label>
        <textarea name=\"tasks\" rows=\"3\" placeholder=\"One task per line\"></textarea>
        <p class=\"textarea-hint\">What’s already in your head that we can either finish or pause?</p>
      </div>
        
        <div class=\"status-actions\">
          <button type=\"button\" id=\"save-status-draft\" class=\"btn-secondary\">
            💾 Save Draft
          </button>
          <span id=\"status-draft-feedback\" class=\"status-feedback\" aria-live=\"polite\"></span>
        </div>
        
        <button type=\"submit\" class=\"btn-primary\">
          📤 Submit Status to Senate
        </button>
     </form>
     
     <details class=\"help-section\">
       <summary>💡 How this works</summary>
       <p>The Senate uses your status to design the next micro-block. Be honest about energy levels and constraints—the Senate will respect them and design realistic, achievable tasks.</p>
     </details>
   </section>"
}

fn render_active_block_section(
  bill: Option(time_bill.TimeBill),
  status: Option(human_status.HumanStatus),
) -> String {
  let content = case bill {
    None -> render_no_active_block(status)
    Some(b) -> render_active_block_content(b, status)
  }

  "<section class=\"time-card active-block-card\" id=\"active-block\">
     " <> content <> "
   </section>"
}

fn render_no_active_block(status: Option(human_status.HumanStatus)) -> String {
  let message = case status {
    None ->
      "<p class=\"empty-message\">📋 Submit a status report above to receive your first time bill from the Senate.</p>"
    Some(_) ->
      "<p class=\"empty-message\">🏛️ The Senate is deliberating on your next micro-block. Check back in a moment...</p>
       <div class=\"loading-indicator\">
         <div class=\"spinner\"></div>
         <p>Senators are reviewing your status and crafting the next time bill</p>
       </div>"
  }

  "<div class=\"card-header\">
     <h2>🎯 Active Time Block</h2>
     <p>Your current assignment from the Senate</p>
   </div>
   <div class=\"empty-state\">
     " <> message <> "
   </div>"
}

fn render_active_block_content(
  bill: time_bill.TimeBill,
  status: Option(human_status.HumanStatus),
) -> String {
  let next_block = time_bill.next_block(bill)

  let block_content = case next_block {
    None ->
      "<div class=\"completion-celebration\">
         <h3>🎉 All blocks completed!</h3>
         <p>Submit a new status report to get your next assignment.</p>
       </div>"
    Some(block) -> render_micro_block_detail(block)
  }

  let pillars =
    bill.pillar_links
    |> list.map(fn(p) {
      "<span class=\"pill pillar-pill\">"
      <> pillar_emoji(p)
      <> " "
      <> time_bill.pillar_to_string(p)
      <> "</span>"
    })
    |> string.join(" ")

  let summary_snippet = case next_block {
    Some(block) ->
      case block.instructions {
        [] -> bill.purpose
        [first, .._] -> first
      }
    None -> bill.purpose
  }

  let constraints_list = case status {
    None -> []
    Some(s) -> s.hard_constraints
  }

  let constraints_html = case constraints_list {
    [] -> "<p class=\"constraints-empty\">No additional constraints reported.</p>"
    items ->
      "<ul>"
      <> list.map(items, fn(item) {
        "<li>⚠️ " <> escape_html(item) <> "</li>"
      })
      |> string.join("")
      <> "</ul>"
  }

  let vote_status =
    "<div class=\"vote-status\">
       <span>Senate status:</span>
       <strong>" <> time_bill.status_to_string(bill.status) <> "</strong>
     </div>"

  let budget_details = case bill.budget_thinking {
    None ->
      "<div class=\"budget-empty\">No budget recommendations yet.</div>"
    Some(budget) ->
      "<div class=\"budget-note\">
         <strong>Budget guidance:</strong>
         <p>" <> escape_html(budget.notes) <> "</p>
         <p class=\"budget-estimate\">Estimated cost: "
          <> case budget.estimated_cost {
            None -> "TBD"
            Some(value) -> "$" <> float.to_string(value)
          }
          <> " | Category: " <> escape_html(budget.category) <> "</p>
       </div>"
  }

  let summary_details =
    "<details class=\"senate-details\">
       <summary>Senate summary</summary>
       <p>" <> escape_html(summary_snippet) <> "</p>
       " <> vote_status <> "
     </details>"

  let reasoning_details =
    "<details class=\"senate-details\">
       <summary>Senate reasoning</summary>
       <p>Priority pillar(s): " <> string.join(
         bill.pillar_links
         |> list.map(fn(p) { escape_html(time_bill.pillar_to_string(p)) }),
         ", ",
       ) <> "</p>
       <p>Constraints considered:</p>
       " <> constraints_html <> "
     </details>"

        let timer_html = case next_block {
    Some(block) ->
      "<div class=\"block-schedule\">
         <div class=\"block-timer\" id=\"block-countdown\" data-duration=\""
         <> int.to_string(block.duration_minutes)
         <> "\" data-bill-id=\""
         <> bill.id
         <> "\">
           ⏱️ <span class=\"countdown-value\">"
         <> format_countdown(block.duration_minutes * 60)
         <> "</span>
         </div>
         <div class=\"block-stats\">
           <div>
             <span class=\"stat-label\">Objective</span>
             <p class=\"stat-value\">" <> escape_html(summary_snippet) <> "</p>
           </div>
           <div>
             <span class=\"stat-label\">Priority</span>
             <p class=\"stat-value\">" <> time_bill.time_horizon_to_string(bill.time_horizon) <> "</p>
           </div>
         </div>
       </div>"
    None -> "<div class=\"block-schedule inactive\">No active block yet.</div>"
  }

  "<div class=\"card-header\">
     <div>
       <h2>🎯 Active Time Block</h2>
       <p class=\"bill-id\">" <> escape_html(bill.id) <> "</p>
     </div>
     <span class=\"pill horizon-pill\">" <> horizon_emoji(bill.time_horizon) <> " " <> time_bill.time_horizon_to_string(
    bill.time_horizon,
  ) <> "</span>
  </div>
  
  <div class=\"bill-header\">
    <h3>" <> escape_html(bill.title) <> "</h3>
    <p class=\"bill-purpose\">" <> escape_html(bill.purpose) <> "</p>
    <div class=\"bill-pillars\">" <> pillars <> "</div>
  </div>
  
  <div class=\"bill-meta\">
    " <> timer_html <> "
    <div class=\"budget-wrapper\">
      <h4>Budget guidance</h4>
      " <> budget_details <> "
    </div>
  </div>

  <div class=\"senate-reasoning\">
    " <> summary_details <> "
    " <> reasoning_details <> "
  </div>
  
  " <> block_content
}

fn render_micro_block_detail(block: time_bill.MicroBlock) -> String {
  let duration_class = case block.duration_minutes {
    5 -> "duration-short"
    10 -> "duration-medium"
    _ -> "duration-long"
  }

  let todd_section = render_person_tasks("Todd", block.assignees.todd_tasks)
  let delaney_section =
    render_person_tasks("Delaney", block.assignees.delaney_tasks)
  let joint_section = render_joint_tasks(block.assignees.joint_tasks)

  let instructions =
    block.instructions
    |> list.index_map(fn(instr, idx) { "<li class=\"instruction-step\">
         <span class=\"step-number\">" <> int.to_string(idx + 1) <> "</span>
         <span class=\"step-text\">" <> escape_html(instr) <> "</span>
       </li>" })
    |> string.join("")

  let artifacts =
    block.expected_artifacts
    |> list.map(fn(art) {
      "<li class=\"artifact-item\">📄 " <> escape_html(art) <> "</li>"
    })
    |> string.join("")

  "<div class=\"micro-block-detail\">
     <div class=\"block-meta\">
       <span class=\"pill duration-pill " <> duration_class <> "\">
         ⏱️ " <> int.to_string(block.duration_minutes) <> " minutes
       </span>
       <span class=\"limitation-badge\">
         ⚠️ " <> escape_html(block.limitation_note) <> "
       </span>
     </div>
     
     <div class=\"assignments-section\">
       <h4>👥 Assignments</h4>
       <div class=\"assignments-grid\">
         " <> todd_section <> "
         " <> delaney_section <> "
         " <> joint_section <> "
       </div>
     </div>
     
     <div class=\"instructions-section\">
       <h4>📋 Step-by-Step Instructions</h4>
       <ol class=\"instruction-list\">" <> instructions <> "</ol>
     </div>
     
     <div class=\"artifacts-section\">
       <h4>📦 Expected Artifacts</h4>
       <ul class=\"artifact-list\">" <> artifacts <> "</ul>
     </div>
     
     <div class=\"reflection-section\">
       <h4>💭 Reflection Prompts (for after)</h4>
       <ul class=\"reflection-list\">" <> list.map(
    block.reflection_prompts,
    fn(prompt) { "<li>" <> escape_html(prompt) <> "</li>" },
  )
  |> string.join("") <> "</ul>
     </div>
     
     <div class=\"block-actions\">
       <a href=\"#report-input\" class=\"btn-primary\">
         ✅ Complete & Report
       </a>
     </div>
   </div>"
}

fn render_person_tasks(person: String, tasks: List(String)) -> String {
  case tasks {
    [] -> ""
    _ -> "<div class=\"person-tasks\">
         <h5>" <> person <> "</h5>
         <ul>" <> list.map(tasks, fn(task) {
        "<li>• " <> escape_html(task) <> "</li>"
      })
      |> string.join("") <> "</ul>
       </div>"
  }
}

fn render_joint_tasks(tasks: List(String)) -> String {
  case tasks {
    [] -> ""
    _ -> "<div class=\"person-tasks joint-tasks\">
         <h5>🤝 Together</h5>
         <ul>" <> list.map(tasks, fn(task) {
        "<li>• " <> escape_html(task) <> "</li>"
      })
      |> string.join("") <> "</ul>
       </div>"
  }
}

fn render_report_input_section(bill: Option(time_bill.TimeBill)) -> String {
  let form_state = case bill {
    None -> "disabled"
    Some(_) -> ""
  }

  "<section class=\"time-card report-input-card\" id=\"report-input\">
     <div class=\"card-header\">
       <h2>✅ Report Block Completion</h2>
       <p>Tell the Senate what happened</p>
     </div>
     
     <form class=\"report-form\" method=\"post\" action=\"/time/report\" " <> form_state <> ">
       <div class=\"form-grid\">
        <div class=\"form-group\">
          <label>⏰ Time completed <span class=\"info-icon\" title=\"When you wrapped up the block.\">?</span></label>
          <div class=\"time-entry\">
            <input type=\"text\" id=\"report-timestamp\" name=\"timestamp\" placeholder=\"2025-01-15 09:45 AM\" required />
            <button type=\"button\" class=\"time-entry-btn\" onclick=\"promptTimestamp('report-timestamp','completion time')\">🕘 Edit</button>
          </div>
          <p class=\"field-hint\">Automatically fills with now but remains editable.</p>
        </div>
         
         <div class=\"form-group\">
           <label>⏱️ Actual time used <span class=\"info-icon\" title=\"How many minutes the block actually needed.\">?</span></label>
           <input type=\"number\" name=\"actual_minutes\" placeholder=\"12\" min=\"1\" max=\"60\" required />
           <p class=\"field-hint\">Report the real minutes so resource tracking stays accurate.</p>
         </div>
       </div>
       
       <div class=\"energy-inputs\">
         <div class=\"energy-group\">
           <h3>Todd (after)</h3>
           <div class=\"energy-buttons\">
             <label class=\"energy-btn\">
               <input type=\"radio\" name=\"todd_energy_after\" value=\"low\" />
               <span class=\"energy-low\">Low</span>
             </label>
             <label class=\"energy-btn\">
               <input type=\"radio\" name=\"todd_energy_after\" value=\"medium\" checked />
               <span class=\"energy-medium\">Medium</span>
             </label>
             <label class=\"energy-btn\">
               <input type=\"radio\" name=\"todd_energy_after\" value=\"high\" />
               <span class=\"energy-high\">High</span>
             </label>
           </div>
         </div>
         
         <div class=\"energy-group\">
           <h3>Delaney (after)</h3>
           <div class=\"energy-buttons\">
             <label class=\"energy-btn\">
               <input type=\"radio\" name=\"delaney_energy_after\" value=\"low\" />
               <span class=\"energy-low\">Low</span>
             </label>
             <label class=\"energy-btn\">
               <input type=\"radio\" name=\"delaney_energy_after\" value=\"medium\" checked />
               <span class=\"energy-medium\">Medium</span>
             </label>
             <label class=\"energy-btn\">
               <input type=\"radio\" name=\"delaney_energy_after\" value=\"high\" />
               <span class=\"energy-high\">High</span>
             </label>
           </div>
         </div>
       </div>
       
        <div class=\"form-group\">
          <label>✅ What got done</label>
          <textarea name=\"completed\" rows=\"3\" placeholder=\"One accomplishment per line\" required></textarea>
          <p class=\"textarea-hint\">Be brief — what did you actually finish during this block?</p>
        </div>
        
        <div class=\"form-group\">
          <label>⚠️ Where you got stuck (if any)</label>
          <textarea name=\"stuck\" rows=\"2\" placeholder=\"Blockers or challenges\"></textarea>
          <p class=\"textarea-hint\">What slowed you down or still needs confirmation?</p>
        </div>
        
        <div class=\"form-group\">
          <label>💡 New needs or tasks that emerged</label>
          <textarea name=\"new_needs\" rows=\"2\" placeholder=\"What came up during the work\"></textarea>
          <p class=\"textarea-hint\">Capture anything that should go on the Senate radar next.</p>
        </div>
       
       <button type=\"submit\" class=\"btn-primary\">
         📤 Submit Report to Senate
       </button>
     </form>
   </section>"
}

fn render_timeline_section(
  reports: List(human_status.BlockReport),
  _bills: List(time_bill.TimeBill),
  completed_tasks: List(time_session.CompletedTask),
) -> String {
  let report_content = case reports {
    [] ->
      "<div class=\"empty-state\">
         <p class=\"empty-message\">📊 Your work timeline will appear here as you complete blocks.</p>
       </div>"
    _ ->
      "<div class=\"timeline\">"
      <> list.take(reports, 10)
      |> list.map(render_timeline_item)
      |> string.join("")
      <> "</div>"
  }

  let completion_content = case completed_tasks {
    [] ->
      "<div class=\"empty-state\">
         <p class=\"empty-message\">✅ No external task completions yet.</p>
       </div>"
    _ ->
      "<ul class=\"external-completions\">"
      <> list.take(completed_tasks, 10)
      |> list.map(render_completion_item)
      |> string.join("")
      <> "</ul>"
  }

  "<section class=\"time-card timeline-card\">
     <div class=\"card-header\">
       <h2>📊 Work Timeline</h2>
       <p>Recent completed blocks</p>
     </div>
     " <> report_content <> "

     <div class=\"card-header secondary\">
       <h3>External Task Completions</h3>
       <p>Todoist and other adapters reporting done work</p>
     </div>
     " <> completion_content <> "
   </section>"
}

fn render_completion_item(item: time_session.CompletedTask) -> String {
  "<li><strong>"
  <> escape_html(item.harmony_uid)
  <> "</strong> ("
  <> escape_html(item.task_id)
  <> ") — "
  <> escape_html(item.completed_at)
  <> "</li>"
}

fn render_timeline_item(report: human_status.BlockReport) -> String {
  let completed_items =
    report.completed
    |> list.map(fn(item) { "<li>✅ " <> escape_html(item) <> "</li>" })
    |> string.join("")

  let stuck_section = case report.stuck_on {
    [] -> ""
    items -> "<div class=\"stuck-section\">
         <strong>⚠️ Stuck on:</strong>
         <ul>" <> list.map(items, fn(item) {
        "<li>" <> escape_html(item) <> "</li>"
      })
      |> string.join("") <> "</ul>
       </div>"
  }

  let completed_count = list.length(report.completed)
  let energy_summary =
    "Todd: " <> time_bill.energy_to_string(report.todd_energy)
    <> " · Delaney: "
    <> time_bill.energy_to_string(report.delaney_energy)

  "<article class=\"timeline-item\">
     <div class=\"timeline-marker\"></div>
     <div class=\"timeline-content\">
       <div class=\"timeline-header\">
         <span class=\"timeline-time\">⏰ " <> escape_html(report.timestamp) <> "</span>
         <span class=\"pill duration-pill\">⏱️ " <> int.to_string(
    report.actual_minutes,
  ) <> " min</span>
       </div>
       <div class=\"timeline-meta\">
         <span class=\"meta-badge\">✅ Completed: " <> int.to_string(completed_count) <> "</span>
         <span class=\"meta-badge\">⚡ Energy: " <> escape_html(energy_summary) <> "</span>
       </div>
       <ul class=\"timeline-completed\">" <> completed_items <> "</ul>
       " <> stuck_section <> "
     </div>
   </article>"
}

fn render_resources_panel(resources: resource_state.ResourceState) -> String {
  let tracking = resources.time_tracking
  let total_hours = int.to_float(tracking.total_minutes_completed) /. 60.0
  let todd_hours = int.to_float(tracking.todd_minutes) /. 60.0
  let delaney_hours = int.to_float(tracking.delaney_minutes) /. 60.0

  let allocated = resource_state.total_allocated(resources)
  let _unallocated = resource_state.unallocated_budget(resources)
  let budget_percent =
    case resources.available_budget >. 0.0 {
      True -> {
        allocated /. resources.available_budget *. 100.0
      }
      False -> 0.0
    }
    |> float.round
    |> int.to_string
  let time_goal_minutes = 240.0
  let time_percent =
    case int.to_float(tracking.total_minutes_completed) >=. time_goal_minutes {
      True -> "100"
      False ->
        int.to_float(tracking.total_minutes_completed) /. time_goal_minutes *. 100.0
        |> float.round
        |> int.to_string
    }

  "<section class=\"sidebar-card resources-card\">
     <h3>💰 Resources</h3>
     
     <div class=\"resource-section\">
       <h4>Budget</h4>
       <div class=\"budget-bar\">
         <div class=\"budget-fill\" style=\"width: " <> budget_percent <> "%\"></div>
       </div>
       <div class=\"budget-stats\">
         <div class=\"stat\">
           <span class=\"stat-label\">Available</span>
           <span class=\"stat-value\">$" <> format_float(
    resources.available_budget,
  ) <> "</span>
         </div>
         <div class=\"stat\">
           <span class=\"stat-label\">Allocated</span>
           <span class=\"stat-value\">$" <> format_float(allocated) <> "</span>
         </div>
       </div>
     </div>
     
       <div class=\"resource-section\">
         <h4>Time Tracked</h4>
         <div class=\"time-stats\">
           <div class=\"stat-large\">
             <span class=\"stat-value-large\">" <> format_float(total_hours) <> "</span>
             <span class=\"stat-label\">total hours</span>
           </div>
         <div class=\"stat-grid\">
           <div class=\"stat\">
             <span class=\"stat-label\">Todd</span>
             <span class=\"stat-value\">" <> format_float(todd_hours) <> "h</span>
           </div>
           <div class=\"stat\">
             <span class=\"stat-label\">Delaney</span>
             <span class=\"stat-value\">" <> format_float(delaney_hours) <> "h</span>
           </div>
          <div class=\"stat\">
            <span class=\"stat-label\">Blocks</span>
            <span class=\"stat-value\">" <> int.to_string(
    tracking.blocks_completed,
  ) <> "</span>
          </div>
        </div>
        <div class=\"resource-progress\">
          <span class=\"progress-label\">Time progress (4h target)</span>
          <div class=\"progress-track\">
            <div class=\"progress-fill\" style=\"width: " <> time_percent <> "%\"></div>
          </div>
          <span class=\"progress-value\">" <> time_percent <> "% of target</span>
        </div>
      </div>
    </div>
  </section>"
}

fn render_senate_status(senators_list: List(senators.Senator)) -> String {
  let count = list.length(senators_list)

  "<section class=\"sidebar-card senate-card\">
     <h3>🏛️ Senate Status</h3>
     <div class=\"senate-info\">
       <div class=\"stat-large\">
         <span class=\"stat-value-large\">" <> int.to_string(count) <> "</span>
         <span class=\"stat-label\">senators</span>
       </div>
       <p class=\"senate-note\">
         The full AGATA Senate is reviewing your status and crafting time bills 
         that balance immediate needs with long-term vision.
       </p>
       <a href=\"/senators\" class=\"btn-secondary\">
         View Senate Roster →
       </a>
     </div>
   </section>"
}

fn render_nav_links(current_theme: theme.Theme) -> String {
  [
    nav_link("/", "Chamber", current_theme),
    nav_link("/time", "Time Legislation", current_theme),
    nav_link("/senators", "Senators", current_theme),
    nav_link("/docket", "Docket", current_theme),
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

fn render_theme_switcher(current_theme: theme.Theme) -> String {
  let buttons =
    theme.available()
    |> list.map(fn(option) {
      let active = option == current_theme
      let href = case theme.query_suffix(option) {
        "" -> "/time"
        suffix -> "/time" <> suffix
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

// Helper functions

fn average_energy(
  e1: time_bill.EnergyLevel,
  e2: time_bill.EnergyLevel,
) -> time_bill.EnergyLevel {
  case e1, e2 {
    time_bill.High, time_bill.High -> time_bill.High
    time_bill.Low, time_bill.Low -> time_bill.Low
    _, _ -> time_bill.Medium
  }
}

fn pillar_emoji(pillar: time_bill.Pillar) -> String {
  case pillar {
    time_bill.Farm -> "🌾"
    time_bill.Film -> "🎬"
    time_bill.Music -> "🎵"
    time_bill.Residency -> "🏠"
    time_bill.DigitalLab -> "💻"
    time_bill.MeshNetwork -> "🌐"
    time_bill.Institute -> "🎓"
    time_bill.Governance -> "⚖️"
    time_bill.Ritual -> "🕯️"
    time_bill.History -> "📚"
    time_bill.Education -> "📖"
  }
}

fn horizon_emoji(horizon: time_bill.TimeHorizon) -> String {
  case horizon {
    time_bill.ThisHour -> "⚡"
    time_bill.Today -> "📅"
    time_bill.ThisWeek -> "📆"
    time_bill.ThisMonth -> "🗓️"
    time_bill.ThisQuarter -> "📊"
    time_bill.LongTerm -> "🌟"
  }
}

fn format_float(value: Float) -> String {
  let rounded = int.to_float(float.round(value *. 100.0)) /. 100.0
  float.to_string(rounded)
}

fn format_countdown(seconds: Int) -> String {
  let minutes = seconds / 60
  let remainder = seconds % 60
  let pad = fn(value: Int) {
    case value < 10 {
      True -> "0" <> int.to_string(value)
      False -> int.to_string(value)
    }
  }
  pad(minutes) <> ":" <> pad(remainder)
}

fn escape_html(text: String) -> String {
  // Simple HTML escaping - just handle the most critical characters
  text
  |> string.replace("&", " and ")
  |> string.replace("<", " ")
  |> string.replace(">", " ")
}

fn live_update_script() -> String {
  "<script>
     (function() {
       const STATUS_DRAFT_KEY = 'agata_time_status_draft';
       const REPORT_DRAFT_KEY = 'agata_time_report_draft';
       let autoRefreshEnabled = true;
       const formFieldSelectors = [
         '#status-input input',
         '#status-input textarea',
         '#status-input select',
         '#report-input input',
         '#report-input textarea',
       ];

       const statusForm = document.querySelector('#status-input form');
       const reportForm = document.querySelector('#report-input form');
       const statusFeedback = document.getElementById('status-draft-feedback');
       const saveDraftButton = document.getElementById('save-status-draft');

       function disableAutoRefresh() {
         autoRefreshEnabled = false;
       }

       function enableAutoRefresh() {
         autoRefreshEnabled = true;
       }

       function promptTimestamp(fieldId, label) {
         disableAutoRefresh();
         const field = document.getElementById(fieldId);
         if (!field) return;
         const current = field.value || '';
         const entry = prompt('Enter ' + label + ' (e.g. 2025-01-15 09:30 AM)', current);
         if (entry !== null) {
           field.value = entry;
           // Dispatch events so autosave picks up the programmatic change.
           field.dispatchEvent(new Event('input', { bubbles: true }));
           field.dispatchEvent(new Event('change', { bubbles: true }));
         }
       }

       window.promptTimestamp = promptTimestamp;

       formFieldSelectors.forEach(selector => {
         document.querySelectorAll(selector).forEach(element => {
           element.addEventListener('focus', disableAutoRefresh);
           element.addEventListener('blur', enableAutoRefresh);
         });
       });

       function gatherFormData(form) {
         const data = {};
         form.querySelectorAll('input[name], textarea[name], select[name]').forEach(element => {
           if (element.type === 'radio') {
             if (element.checked) {
               data[element.name] = element.value;
             }
             return;
           }
           data[element.name] = element.value;
         });
         return data;
       }

       function applyFormData(form, data) {
         if (!data) return;
         Object.keys(data).forEach(name => {
           const radios = form.querySelectorAll('input[name=\"' + name + '\"][type=\"radio\"]');
           if (radios.length > 0) {
             radios.forEach(radio => {
               radio.checked = radio.value === data[name];
             });
             return;
           }
           const field = form.querySelector('[name=\"' + name + '\"]');
           if (field) {
             field.value = data[name];
           }
         });
       }

       function showFeedback(element, message) {
         if (!element) return;
         element.textContent = message;
         setTimeout(() => {
           element.textContent = '';
         }, 3200);
       }

       function saveDraft(key, form, feedback, showMessage) {
         if (!form) return;
         try {
           localStorage.setItem(key, JSON.stringify(gatherFormData(form)));
         } catch (_error) {
           return;
         }
         if (showMessage) {
           showFeedback(feedback, 'Draft saved locally');
         }
       }

       function restoreDraft(key, form) {
         if (!form) return;
         try {
           const payload = localStorage.getItem(key);
           if (!payload) return;
           applyFormData(form, JSON.parse(payload));
         } catch (_error) {
           // ignore
         }
       }

       function scheduleAutoSave(form, key) {
         if (!form) return;
         let timeout = null;
         const handler = () => {
           clearTimeout(timeout);
           timeout = setTimeout(() => saveDraft(key, form, null, false), 600);
         };
         form.querySelectorAll('input[name], textarea[name], select[name]').forEach(element => {
           element.addEventListener('input', handler);
           element.addEventListener('change', handler);
         });
       }

       function formatLocalTimestamp() {
         const now = new Date();
         const formatter = new Intl.DateTimeFormat('en-US', {
           timeZone: 'America/New_York',
           year: 'numeric',
           month: '2-digit',
           day: '2-digit',
           hour: 'numeric',
           minute: '2-digit',
           hour12: true,
         });

         const parts = formatter.formatToParts(now);
         const map = {};
         parts.forEach(part => {
           map[part.type] = part.value;
         });

         const year = map.year || now.getUTCFullYear().toString();
         const month = map.month ? map.month.padStart(2, '0') : padNumber(now.getMonth() + 1);
         const day = map.day ? map.day.padStart(2, '0') : padNumber(now.getDate());
         const hour = map.hour ? map.hour.padStart(2, '0') : padNumber(now.getHours() % 12 || 12);
         const minute = map.minute ? map.minute.padStart(2, '0') : padNumber(now.getMinutes());
         const period = map.dayPeriod || (now.getHours() >= 12 ? 'PM' : 'AM');

         return `${year}-${month}-${day} ${hour}:${minute} ${period} EST`;
       }

       function padNumber(value) {
         return value.toString().padStart(2, '0');
       }

       function autoExpandTextarea(textarea) {
         textarea.style.height = 'auto';
         textarea.style.height = textarea.scrollHeight + 'px';
       }

       if (statusForm) {
         restoreDraft(STATUS_DRAFT_KEY, statusForm);
         scheduleAutoSave(statusForm, STATUS_DRAFT_KEY);
         statusForm.querySelectorAll('textarea').forEach(autoExpandTextarea);
         statusForm.addEventListener('submit', () => {
           setSubmitLoading(statusForm);
         });
       }

       if (saveDraftButton && statusForm) {
         saveDraftButton.addEventListener('click', () => {
           saveDraft(STATUS_DRAFT_KEY, statusForm, statusFeedback, true);
         });
       }

       if (reportForm) {
         restoreDraft(REPORT_DRAFT_KEY, reportForm);
         scheduleAutoSave(reportForm, REPORT_DRAFT_KEY);
         reportForm.querySelectorAll('textarea').forEach(autoExpandTextarea);
        const statusTimestamp = document.getElementById('status-timestamp');
        const reportTimestamp = document.getElementById('report-timestamp');
        if (statusTimestamp && !statusTimestamp.value) {
          statusTimestamp.value = formatLocalTimestamp();
        }
        if (reportTimestamp && !reportTimestamp.value) {
          reportTimestamp.value = formatLocalTimestamp();
        }

        const markEdited = (element) => {
          element.dataset.userEdited = 'true';
        };

        if (statusTimestamp) {
          statusTimestamp.addEventListener('input', () => markEdited(statusTimestamp));
        }
        if (reportTimestamp) {
          reportTimestamp.addEventListener('input', () => markEdited(reportTimestamp));
        }

        function refreshTimestampFields() {
          const now = formatLocalTimestamp();
          if (statusTimestamp && statusTimestamp.dataset.userEdited !== 'true') {
            statusTimestamp.value = now;
          }
          if (reportTimestamp && reportTimestamp.dataset.userEdited !== 'true') {
            reportTimestamp.value = now;
          }
        }

        refreshTimestampFields();
        setInterval(refreshTimestampFields, 60_000);
         reportForm.addEventListener('submit', () => {
           disableAutoRefresh();
           appendTimelineFromReport();
           setSubmitLoading(reportForm);
         });
       }

       function ensureTimelineContainer() {
         let container = document.querySelector('.timeline-card .timeline');
         if (container) return container;
         const timelineCard = document.querySelector('.timeline-card');
         if (!timelineCard) return null;
         const newContainer = document.createElement('div');
         newContainer.className = 'timeline';
         const emptyState = timelineCard.querySelector('.empty-state');
         if (emptyState) emptyState.remove();
         timelineCard.appendChild(newContainer);
         return newContainer;
       }

       function splitLines(raw) {
         return raw
           .split(/\\r?\\n/)
           .map(line => line.trim())
           .filter(line => line !== '');
       }

       function appendTimelineFromReport() {
         if (!reportForm) return;
         const container = ensureTimelineContainer();
         if (!container) return;
         const completed = reportForm.elements['completed']?.value || '';
         const stuck = reportForm.elements['stuck']?.value || '';
         const energyTodd = reportForm.elements['todd_energy_after']?.value || 'medium';
         const energyDelaney = reportForm.elements['delaney_energy_after']?.value || 'medium';
         const timestamp = reportForm.elements['timestamp']?.value || formatLocalTimestamp();
         const minutes = reportForm.elements['actual_minutes']?.value || '0';
         const completedItems = splitLines(completed);
         const stuckItems = splitLines(stuck);
         const article = document.createElement('article');
         article.className = 'timeline-item';
         article.innerHTML = `
           <div class=\"timeline-marker\"></div>
           <div class=\"timeline-content\">
             <div class=\"timeline-header\">
               <span class=\"timeline-time\">⌚ ${escapeHtml(timestamp)}</span>
               <span class=\"pill duration-pill\">⏱️ ${escapeHtml(minutes)} min</span>
             </div>
             <div class=\"timeline-meta\">
               <span class=\"meta-badge\">✅ Completed: ${completedItems.length}</span>
               <span class=\"meta-badge\">⚡ Energy: Todd ${escapeHtml(energyTodd)}, Delaney ${escapeHtml(energyDelaney)}</span>
             </div>
             <ul class=\"timeline-completed\">
               ${completedItems.map(item => `<li>✅ ${escapeHtml(item)}</li>`).join('')}
             </ul>
             ${stuckItems.length ? `
               <div class=\"stuck-section\">
                 <strong>⚠️ Stuck on:</strong>
                 <ul>${stuckItems.map(item => `<li>${escapeHtml(item)}</li>`).join('')}</ul>
               </div>` : ''}
           </div>
         `;
         container.prepend(article);
       }

       function escapeHtml(value) {
         return value
           .replace(/&/g, ' and ')
           .replace(/</g, ' ')
           .replace(/>/g, ' ');
       }

       function setSubmitLoading(form) {
         const button = form.querySelector('button[type=\"submit\"]');
         if (button) button.classList.add('is-loading');
       }

       let countdownInterval = null;

       function initCountdown() {
         if (countdownInterval) {
           clearInterval(countdownInterval);
           countdownInterval = null;
         }

         const countdownEl = document.getElementById('block-countdown');
         if (!countdownEl) return;
         const durationMinutes = parseInt(countdownEl.dataset.duration, 10) || 0;
         let remaining = durationMinutes * 60;
         const display = countdownEl.querySelector('.countdown-value');
         const billId = countdownEl.dataset.billId;
         const countdownKey = billId ? `time-countdown-${billId}` : null;

         if (countdownKey) {
           const stored = localStorage.getItem(countdownKey);
           if (stored) {
             try {
               const parsed = JSON.parse(stored);
               const elapsed = (Date.now() - parsed.timestamp) / 1000;
               const restored = parsed.remaining - elapsed;
               if (!Number.isNaN(restored)) {
                 remaining = Math.max(0, Math.min(durationMinutes * 60, restored));
               }
             } catch (_error) {
               // ignore corrupted state
             }
           }
         }

         const clearCountdownStorage = () => {
           if (countdownKey) {
             localStorage.removeItem(countdownKey);
           }
         };

         const persistCountdown = () => {
           if (!countdownKey) return;
           try {
             localStorage.setItem(
               countdownKey,
               JSON.stringify({ remaining, timestamp: Date.now() }),
             );
           } catch (_error) {
             // ignore quota errors
           }
         };

         const tick = () => {
           if (display) {
             const minutes = Math.floor(Math.max(remaining, 0) / 60);
             const seconds = Math.floor(Math.max(remaining, 0) % 60);
             const pad = value => value.toString().padStart(2, '0');
             display.textContent = `${pad(minutes)}:${pad(seconds)}`;
           }
           if (remaining <= 0) {
             if (!countdownEl.dataset.ended) {
               countdownEl.dataset.ended = 'true';
               alert('Time block ended — please report completion to the Senate.');
             }
             clearCountdownStorage();
             return;
           }
           remaining -= 1;
           persistCountdown();
         };
         tick();
         countdownInterval = setInterval(tick, 1000);
       }

       initCountdown();

       const fragmentEndpoint =
         window.location.pathname.replace(/\\/$/, '') + '/fragments' + window.location.search;

       function updateFragment(id, html) {
         const container = document.getElementById(id);
         if (!container) return;
         container.innerHTML = html;
       }

       function replaceSection(id, html) {
         const element = document.getElementById(id);
         if (!element) return;
         element.outerHTML = html;
       }

       async function refreshTimeFragments() {
         if (document.hidden || !autoRefreshEnabled) return;
         try {
           const response = await fetch(fragmentEndpoint, {
             headers: { 'X-Harmony-Refresh': '1' },
           });
           if (!response.ok) return;
           const payload = await response.json();
           updateFragment('time-order-banner', payload.order_banner);
           replaceSection('active-block', payload.active_block);
           updateFragment('timeline-section', payload.timeline);
           updateFragment('resources-panel', payload.resources);
           updateFragment('senate-status-panel', payload.senate_status);
           initCountdown();
         } catch (_error) {
           // Ignore transient network issues
         }
       }

       setInterval(refreshTimeFragments, 3000);
       window.addEventListener('visibilitychange', () => {
         if (!document.hidden) refreshTimeFragments();
       });
     })();
   </script>"
}

fn time_stylesheet() -> String {
  "/* Time Legislation Page Styles */
  * { box-sizing: border-box; margin: 0; padding: 0; }
  
  body.time-page {
    font-family: Inter, -apple-system, BlinkMacSystemFont, sans-serif;
    background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
    min-height: 100vh;
  }
  
  .time-container {
    max-width: 1400px;
    margin: 0 auto;
    padding: 2rem;
  }
  
  .time-hero {
    background: white;
    border-radius: 1rem;
    padding: 2rem;
    margin-bottom: 2rem;
    box-shadow: 0 4px 6px rgba(0,0,0,0.1);
  }

  .time-order-banner {
    background: #0f172a;
    color: #f8fafc;
    border-radius: 1rem;
    padding: 1.25rem 1.5rem;
    margin-bottom: 1.5rem;
    border: 1px solid rgba(248, 250, 252, 0.2);
    box-shadow: 0 10px 30px rgba(15, 23, 42, 0.35);
  }

  .order-heading {
    display: flex;
    align-items: baseline;
    gap: 0.75rem;
    flex-wrap: wrap;
  }

  .order-label {
    font-size: 0.75rem;
    letter-spacing: 0.2em;
    opacity: 0.8;
    text-transform: uppercase;
    color: #93c5fd;
  }

  .time-order-banner strong {
    font-size: 1.1rem;
    color: #fff;
  }

  .order-purpose {
    margin-top: 0.5rem;
    color: #cbd5f5;
  }

  .order-detail {
    margin-top: 0.15rem;
    color: #94a3b8;
    font-size: 0.95rem;
  }
  
  .hero-top {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    margin-bottom: 1rem;
  }
  
  .eyebrow {
    text-transform: uppercase;
    font-size: 0.75rem;
    letter-spacing: 0.1em;
    color: #6b7280;
    margin-bottom: 0.5rem;
  }
  
  .time-hero h1 {
    font-size: 2.5rem;
    font-weight: 700;
    color: #1f2937;
    margin-bottom: 0.5rem;
  }
  
  .hero-subtitle {
    color: #6b7280;
    font-size: 1.1rem;
  }
  
  .status-badge {
    padding: 0.5rem 1rem;
    border-radius: 999px;
    font-weight: 600;
    font-size: 0.9rem;
  }
  
  .status-high { background: #d1fae5; color: #065f46; }
  .status-medium { background: #fef3c7; color: #92400e; }
  .status-low { background: #fee2e2; color: #991b1b; }
  .status-waiting { background: #e0e7ff; color: #3730a3; }
  
  .time-grid {
    display: grid;
    grid-template-columns: 1fr 350px;
    gap: 2rem;
  }
  
  .time-card, .sidebar-card {
    background: white;
    border-radius: 1rem;
    padding: 2rem;
    margin-bottom: 2rem;
    box-shadow: 0 4px 6px rgba(0,0,0,0.1);
  }
  
  .card-header h2 {
    font-size: 1.5rem;
    color: #1f2937;
    margin-bottom: 0.5rem;
  }
  
  .card-header p {
    color: #6b7280;
    margin-bottom: 1.5rem;
  }
  
  .form-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 1rem;
    margin-bottom: 1rem;
  }
  
  .form-group.full-width {
    grid-column: 1 / -1;
  }
  
  .form-group label {
    display: block;
    font-weight: 600;
    margin-bottom: 0.5rem;
    color: #374151;
  }
  
  .form-group input, .form-group select, .form-group textarea {
    width: 100%;
    padding: 0.75rem;
    border: 2px solid #e5e7eb;
    border-radius: 0.5rem;
    font-size: 1rem;
  }

  .time-entry {
    display: flex;
    gap: 0.5rem;
    align-items: stretch;
  }

  .time-entry input {
    flex: 1;
  }

  .time-entry-btn {
    background: #f3f4f6;
    border: 2px solid #e5e7eb;
    border-radius: 0.5rem;
    padding: 0.6rem 0.9rem;
    font-size: 0.9rem;
    font-weight: 600;
    cursor: pointer;
    transition: border-color 0.2s, background 0.2s;
  }

  .time-entry-btn:hover {
    border-color: #3b82f6;
    background: #e0e7ff;
  }
  
  .energy-inputs {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 1.5rem;
    margin: 1.5rem 0;
  }
  
  .energy-group h3 {
    font-size: 1.1rem;
    margin-bottom: 0.75rem;
    color: #1f2937;
  }
  
  .energy-buttons {
    display: flex;
    gap: 0.5rem;
    margin-bottom: 0.75rem;
  }
  
  .energy-btn {
    flex: 1;
    cursor: pointer;
  }
  
  .energy-btn input {
    display: none;
  }
  
  .energy-btn span {
    display: block;
    padding: 0.5rem;
    text-align: center;
    border-radius: 0.5rem;
    border: 2px solid #e5e7eb;
    transition: all 0.2s;
  }
  
  .energy-btn input:checked + span {
    border-color: currentColor;
    font-weight: 600;
  }
  
  .energy-low { color: #dc2626; }
  .energy-medium { color: #f59e0b; }
  .energy-high { color: #10b981; }
  
  .btn-primary, .btn-secondary {
    padding: 0.75rem 1.5rem;
    border-radius: 0.5rem;
    font-weight: 600;
    border: none;
    cursor: pointer;
    transition: all 0.2s;
    text-decoration: none;
    display: inline-block;
  }
  
  .btn-primary {
    background: #3b82f6;
    color: white;
  }
  
  .btn-primary:hover {
    background: #2563eb;
  }
  
  .btn-secondary {
    background: #e5e7eb;
    color: #374151;
  }
  
  .pill {
    display: inline-block;
    padding: 0.25rem 0.75rem;
    border-radius: 999px;
    font-size: 0.875rem;
    font-weight: 500;
  }
  
  .ghost-pill {
    background: #f3f4f6;
    color: #6b7280;
  }
  
  .pillar-pill {
    background: #dbeafe;
    color: #1e40af;
    margin-right: 0.5rem;
  }
  
  .duration-pill {
    font-weight: 600;
  }
  
  .duration-short { background: #d1fae5; color: #065f46; }
  .duration-medium { background: #fef3c7; color: #92400e; }
  .duration-long { background: #fee2e2; color: #991b1b; }
  
  .empty-state {
    text-align: center;
    padding: 3rem 2rem;
    color: #6b7280;
  }
  
  .spinner {
    width: 40px;
    height: 40px;
    margin: 1rem auto;
    border: 4px solid #e5e7eb;
    border-top-color: #3b82f6;
    border-radius: 50%;
    animation: spin 1s linear infinite;
  }
  
  @keyframes spin {
    to { transform: rotate(360deg); }
  }
  
  .timeline {
    position: relative;
    padding-left: 2rem;
  }
  
  .timeline-item {
    position: relative;
    padding-bottom: 2rem;
  }
  
  .timeline-marker {
    position: absolute;
    left: -2rem;
    width: 12px;
    height: 12px;
    background: #3b82f6;
    border-radius: 50%;
    top: 0.5rem;
  }
  
  .timeline-item::before {
    content: \"\";
    position: absolute;
    left: -1.45rem;
    top: 1.5rem;
    bottom: 0;
    width: 2px;
    background: #e5e7eb;
  }
  
  .timeline-item:last-child::before {
    display: none;
  }
  
  @media (max-width: 1024px) {
    .time-grid {
      grid-template-columns: 1fr;
    }
    
    .form-grid, .energy-inputs {
      grid-template-columns: 1fr;
    }
  }
  
  .info-icon {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    width: 1.2rem;
    height: 1.2rem;
    border-radius: 50%;
    border: 1px solid rgba(59, 130, 246, 0.4);
    font-size: 0.85rem;
    color: #1d4ed8;
    margin-left: 0.35rem;
    background: rgba(59, 130, 246, 0.1);
  }

  .field-hint, .textarea-hint {
    font-size: 0.8rem;
    color: #4b5563;
    margin-top: 0.25rem;
  }

  .textarea-hint {
    margin-bottom: 0.5rem;
  }

  .status-actions {
    display: flex;
    align-items: center;
    gap: 1rem;
    margin-bottom: 1rem;
  }

  .status-feedback {
    color: #10b981;
    font-size: 0.9rem;
  }

  .human-energy-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
    gap: 1rem;
    margin-bottom: 1rem;
  }

  .energy-card {
    background: #ffffff;
    border: 1px solid #e5e7eb;
    border-radius: 1rem;
    padding: 1rem;
    box-shadow: 0 2px 4px rgba(15, 23, 42, 0.05);
  }

  .energy-card h3 {
    margin-bottom: 0.25rem;
    font-size: 1rem;
  }

  .energy-card .field-hint {
    margin-bottom: 0.5rem;
  }

  .block-meta {
    display: flex;
    flex-wrap: wrap;
    gap: 0.75rem;
    margin-bottom: 1rem;
    align-items: center;
  }

  .block-schedule {
    display: flex;
    flex-direction: column;
    gap: 1rem;
    padding: 1rem 0;
    border-top: 1px solid #e5e7eb;
    border-bottom: 1px solid #e5e7eb;
  }

  .block-schedule.inactive {
    color: #6b7280;
  }

  .block-timer {
    display: inline-flex;
    align-items: center;
    gap: 0.5rem;
    font-weight: 600;
  }

  .countdown-value {
    font-size: 1.2rem;
    letter-spacing: 0.05em;
  }

  .block-stats {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
    gap: 1rem;
  }

  .stat-label {
    display: block;
    font-size: 0.8rem;
    color: #6b7280;
  }

  .stat-value {
    font-weight: 600;
  }

  .bill-meta {
    padding: 1rem 0;
    border-bottom: 1px solid #e5e7eb;
  }

  .budget-wrapper {
    margin-top: 1rem;
    background: #f8fafc;
    border-radius: 0.75rem;
    padding: 0.75rem;
  }

  .budget-note {
    font-size: 0.9rem;
    color: #1f2937;
  }

  .budget-estimate {
    margin-top: 0.35rem;
    font-size: 0.85rem;
    color: #475569;
  }

  .senate-reasoning {
    display: flex;
    flex-direction: column;
    gap: 0.75rem;
    margin-bottom: 1rem;
  }

  .senate-details {
    border: 1px solid #e5e7eb;
    border-radius: 0.75rem;
    padding: 0.75rem 1rem;
    background: #fdfdfd;
  }

  .senate-details summary {
    font-weight: 600;
    cursor: pointer;
  }

  .timeline-meta {
    display: flex;
    flex-wrap: wrap;
    gap: 0.75rem;
    margin: 0.75rem 0;
  }

  .meta-badge {
    background: #e0f2fe;
    color: #0369a1;
    padding: 0.25rem 0.75rem;
    border-radius: 999px;
    font-size: 0.85rem;
    font-weight: 600;
  }

  .resource-progress {
    margin-top: 1rem;
    display: flex;
    flex-direction: column;
    gap: 0.4rem;
  }

  .progress-label {
    font-size: 0.85rem;
    color: #475569;
  }

  .progress-track {
    height: 6px;
    background: #e5e7eb;
    border-radius: 999px;
    overflow: hidden;
  }

  .progress-fill {
    height: 100%;
    background: linear-gradient(135deg, #f97316, #ef4444);
  }

  .progress-value {
    font-size: 0.8rem;
    color: #4b5563;
  }

  .btn-primary.is-loading::after,
  .btn-secondary.is-loading::after {
    content: '';
    display: inline-block;
    width: 1rem;
    height: 1rem;
    margin-left: 0.5rem;
    border: 2px solid rgba(255, 255, 255, 0.6);
    border-top-color: white;
    border-radius: 50%;
    animation: spin 0.8s linear infinite;
  }

  .btn-secondary.is-loading::after {
    border: 2px solid rgba(59, 130, 246, 0.6);
    border-top-color: #1d4ed8;
  }

  .btn-primary.is-loading,
  .btn-secondary.is-loading {
    cursor: wait;
    opacity: 0.85;
  }

  @media (max-width: 768px) {
    .form-grid {
      grid-template-columns: 1fr;
    }
    .bill-meta, .senate-reasoning {
      padding: 0.75rem 0;
    }
  }

  @media (prefers-color-scheme: dark) {
    body.time-page {
      background: #020617;
    }
    .time-card, .sidebar-card {
      background: #0f172a;
      color: #e2e8f0;
    }
    .time-card input,
    .time-card textarea,
    .time-card select {
      background: #020617;
      border-color: #1f2937;
      color: #e2e8f0;
    }
    .pill {
      background: #1d4ed8;
      color: white;
    }
  }
  "
}
