//// HTML rendering for time legislation status reports.
//// Provides a live-updating window showing Todd and Delaney's current status,
//// active time bills, and recent block completions.

import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import human_status
import resource_state
import time_bill

/// Render the status report panel for the main page
pub fn render_status_panel(
  current_status: Option(human_status.HumanStatus),
  active_bill: Option(time_bill.TimeBill),
  recent_reports: List(human_status.BlockReport),
  resources: resource_state.ResourceState,
) -> String {
  let status_content = case current_status {
    None -> render_no_status()
    Some(status) -> render_current_status(status)
  }

  let bill_content = case active_bill {
    None -> render_no_active_bill()
    Some(bill) -> render_active_bill(bill)
  }

  let reports_content = render_recent_reports(recent_reports)
  let resources_content = render_resources_summary(resources)

  "<section class=\"panel time-status-panel\" id=\"time-status-panel\">
     <div class=\"panel-header\">
       <h2>⏱️ Time Legislation Status</h2>
       <p>Live status from Todd & Delaney • Updates every 3s</p>
     </div>
     <div class=\"time-status-grid\">
       " <> status_content <> "
       " <> bill_content <> "
       " <> reports_content <> "
       " <> resources_content <> "
     </div>
   </section>"
}

/// Render current human status
fn render_current_status(status: human_status.HumanStatus) -> String {
  let todd_energy_class = energy_class(status.todd_energy)
  let delaney_energy_class = energy_class(status.delaney_energy)

  let block_pref = case status.block_preference {
    Some(minutes) -> int.to_string(minutes) <> " min"
    None -> "flexible"
  }

  let constraints = case status.hard_constraints {
    [] -> "<p class=\"status-note\">No hard constraints</p>"
    items ->
      "<div class=\"constraint-list\">"
      <> list.map(items, fn(c) {
        "<span class=\"pill constraint-pill\">⚠️ " <> escape_html(c) <> "</span>"
      })
      |> string.join("")
      <> "</div>"
  }

  "<div class=\"status-card current-status\">
     <h3>Current Status</h3>
     <p class=\"status-timestamp\">📍 " <> escape_html(status.timestamp) <> "</p>
     <p class=\"status-location\">📍 " <> escape_html(status.location) <> "</p>
     
     <div class=\"energy-grid\">
       <div class=\"energy-item\">
         <span class=\"energy-label\">Todd</span>
         <span class=\"pill energy-pill " <> todd_energy_class <> "\">" <> time_bill.energy_to_string(
    status.todd_energy,
  ) <> "</span>
         <span class=\"mood-text\">" <> escape_html(status.todd_mood) <> "</span>
       </div>
       <div class=\"energy-item\">
         <span class=\"energy-label\">Delaney</span>
         <span class=\"pill energy-pill " <> delaney_energy_class <> "\">" <> time_bill.energy_to_string(
    status.delaney_energy,
  ) <> "</span>
         <span class=\"mood-text\">" <> escape_html(status.delaney_mood) <> "</span>
       </div>
     </div>

     <div class=\"status-meta\">
       <p><strong>Block preference:</strong> " <> block_pref <> "</p>
       <p><strong>Physical state:</strong> " <> escape_html(
    status.physical_state,
  ) <> "</p>
       <p><strong>Tools:</strong> " <> escape_html(status.internet_tools) <> "</p>
     </div>

     " <> constraints <> "
   </div>"
}

fn render_no_status() -> String {
  "<div class=\"status-card empty-status\">
     <h3>Awaiting Status Report</h3>
     <p>No status report received yet. Todd and Delaney should submit their current state.</p>
     <div class=\"status-template\">
       <pre>## STATUS
Time (local): [timestamp]
Block length preference: 10
Location: AGATA farmhouse
Todd_energy: medium
Delaney_energy: high
...</pre>
     </div>
   </div>"
}

/// Render active time bill
fn render_active_bill(bill: time_bill.TimeBill) -> String {
  let next_block = time_bill.next_block(bill)

  let block_content = case next_block {
    None -> "<p class=\"status-note\">All blocks completed!</p>"
    Some(block) -> render_micro_block(block)
  }

  let pillars =
    bill.pillar_links
    |> list.map(fn(p) {
      "<span class=\"pill pillar-pill\">" <> time_bill.pillar_to_string(p) <> "</span>"
    })
    |> string.join(" ")

  "<div class=\"status-card active-bill\">
     <h3>Active Time Bill</h3>
     <p class=\"bill-id\">" <> escape_html(bill.id) <> "</p>
     <h4>" <> escape_html(bill.title) <> "</h4>
     <p class=\"bill-purpose\">" <> escape_html(bill.purpose) <> "</p>
     <div class=\"bill-meta\">
       <p><strong>Horizon:</strong> " <> time_bill.time_horizon_to_string(
    bill.time_horizon,
  ) <> "</p>
       <p><strong>Pillars:</strong> " <> pillars <> "</p>
     </div>
     <div class=\"next-block\">
       <h4>Next Block:</h4>
       " <> block_content <> "
     </div>
   </div>"
}

fn render_no_active_bill() -> String {
  "<div class=\"status-card empty-bill\">
     <h3>No Active Time Bill</h3>
     <p>The Senate is deliberating on the next micro-block assignment.</p>
     <p class=\"status-note\">Check back soon for new time legislation.</p>
   </div>"
}

/// Render a micro-block
fn render_micro_block(block: time_bill.MicroBlock) -> String {
  let duration_class = case block.duration_minutes {
    5 -> "duration-short"
    10 -> "duration-medium"
    _ -> "duration-long"
  }

  let todd_tasks = render_task_list("Todd", block.assignees.todd_tasks)
  let delaney_tasks = render_task_list("Delaney", block.assignees.delaney_tasks)
  let joint_tasks = render_task_list("Both", block.assignees.joint_tasks)

  let instructions =
    block.instructions
    |> list.index_map(fn(instr, idx) {
      "<li><strong>" <> int.to_string(idx + 1) <> ".</strong> " <> escape_html(
        instr,
      ) <> "</li>"
    })
    |> string.join("")

  let artifacts =
    block.expected_artifacts
    |> list.map(fn(art) { "<li>📄 " <> escape_html(art) <> "</li>" })
    |> string.join("")

  "<div class=\"micro-block\">
     <div class=\"block-header\">
       <span class=\"pill duration-pill " <> duration_class <> "\">" <> int.to_string(
    block.duration_minutes,
  ) <> " min</span>
       <span class=\"limitation-note\">⚠️ " <> escape_html(
    block.limitation_note,
  ) <> "</span>
     </div>
     
     <div class=\"task-assignments\">
       " <> todd_tasks <> "
       " <> delaney_tasks <> "
       " <> joint_tasks <> "
     </div>

     <div class=\"block-instructions\">
       <h5>Instructions:</h5>
       <ol>" <> instructions <> "</ol>
     </div>

     <div class=\"block-artifacts\">
       <h5>Expected artifacts:</h5>
       <ul>" <> artifacts <> "</ul>
     </div>
   </div>"
}

fn render_task_list(person: String, tasks: List(String)) -> String {
  case tasks {
    [] -> ""
    _ ->
      "<div class=\"task-group\">
         <h5>" <> person <> ":</h5>
         <ul>"
      <> list.map(tasks, fn(task) { "<li>" <> escape_html(task) <> "</li>" })
      |> string.join("")
      <> "</ul>
       </div>"
  }
}

/// Render recent block reports
fn render_recent_reports(reports: List(human_status.BlockReport)) -> String {
  let content = case reports {
    [] ->
      "<p class=\"status-note\">No completed blocks yet. Reports will appear here after work is done.</p>"
    _ ->
      reports
      |> list.take(3)
      |> list.map(render_block_report_card)
      |> string.join("")
  }

  "<div class=\"status-card recent-reports\">
     <h3>Recent Completions</h3>
     " <> content <> "
   </div>"
}

fn render_block_report_card(report: human_status.BlockReport) -> String {
  let completed =
    report.completed
    |> list.map(fn(item) { "<li>✅ " <> escape_html(item) <> "</li>" })
    |> string.join("")

  let stuck = case report.stuck_on {
    [] -> ""
    items ->
      "<div class=\"stuck-items\"><strong>Stuck on:</strong><ul>"
      <> list.map(items, fn(item) { "<li>⚠️ " <> escape_html(item) <> "</li>" })
      |> string.join("")
      <> "</ul></div>"
  }

  "<article class=\"report-card\">
     <p class=\"report-time\">⏱️ " <> escape_html(report.timestamp) <> " • " <> int.to_string(
    report.actual_minutes,
  ) <> " min</p>
     <div class=\"report-energy\">
       <span>Todd: " <> time_bill.energy_to_string(report.todd_energy) <> "</span>
       <span>Delaney: " <> time_bill.energy_to_string(
    report.delaney_energy,
  ) <> "</span>
     </div>
     <ul class=\"completed-list\">" <> completed <> "</ul>
     " <> stuck <> "
   </article>"
}

/// Render resources summary
fn render_resources_summary(resources: resource_state.ResourceState) -> String {
  let tracking = resources.time_tracking
  let total_hours = int.to_float(tracking.total_minutes_completed) /. 60.0
  let todd_hours = int.to_float(tracking.todd_minutes) /. 60.0
  let delaney_hours = int.to_float(tracking.delaney_minutes) /. 60.0

  let allocated = resource_state.total_allocated(resources)
  let unallocated = resource_state.unallocated_budget(resources)

  "<div class=\"status-card resources-summary\">
     <h3>Resources</h3>
     
     <div class=\"resource-section\">
       <h4>💰 Budget</h4>
       <div class=\"budget-bars\">
         <div class=\"budget-item\">
           <span>Available</span>
           <strong>$" <> float_to_string(resources.available_budget) <> "</strong>
         </div>
         <div class=\"budget-item\">
           <span>Allocated</span>
           <strong>$" <> float_to_string(allocated) <> "</strong>
         </div>
         <div class=\"budget-item\">
           <span>Unallocated</span>
           <strong>$" <> float_to_string(unallocated) <> "</strong>
         </div>
       </div>
     </div>

     <div class=\"resource-section\">
       <h4>⏰ Time Tracked</h4>
       <div class=\"time-stats\">
         <div class=\"time-item\">
           <span>Total</span>
           <strong>" <> float_to_string(total_hours) <> " hrs</strong>
         </div>
         <div class=\"time-item\">
           <span>Todd</span>
           <strong>" <> float_to_string(todd_hours) <> " hrs</strong>
         </div>
         <div class=\"time-item\">
           <span>Delaney</span>
           <strong>" <> float_to_string(delaney_hours) <> " hrs</strong>
         </div>
         <div class=\"time-item\">
           <span>Blocks</span>
           <strong>" <> int.to_string(tracking.blocks_completed) <> "</strong>
         </div>
       </div>
     </div>
   </div>"
}

/// Helper to get CSS class for energy level
fn energy_class(level: time_bill.EnergyLevel) -> String {
  case level {
    time_bill.Low -> "energy-low"
    time_bill.Medium -> "energy-medium"
    time_bill.High -> "energy-high"
  }
}

/// Helper to format float with 2 decimals
fn float_to_string(value: Float) -> String {
  // Simple formatting - Gleam doesn't have built-in decimal formatting
  let rounded = float.round(value *. 100.0) /. 100.0
  float.to_string(rounded)
}

/// Escape HTML special characters
fn escape_html(text: String) -> String {
  text
  |> string.replace("&", "&amp;")
  |> string.replace("<", "&lt;")
  |> string.replace(">", "&gt;")
  |> string.replace("\"", "&quot;")
  |> string.replace("'", "&#39;")
}

/// Additional CSS for time status panel
pub fn time_status_styles() -> String {
  "
  .time-status-panel {
    grid-column: 1 / -1;
    background: linear-gradient(135deg, #fff9f0, #fff4e6);
    border: 2px solid #ff9f43;
    box-shadow: 0 12px 30px rgba(255, 159, 67, 0.25);
  }

  .time-status-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
    gap: 1rem;
    margin-top: 1rem;
  }

  .status-card {
    background: #fff;
    border: 1px solid rgba(255, 159, 67, 0.3);
    border-radius: 0.75rem;
    padding: 1rem;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
  }

  .status-card h3 {
    margin: 0 0 0.75rem 0;
    color: #d35400;
    font-size: 1.1rem;
  }

  .status-card h4 {
    margin: 0.5rem 0 0.25rem 0;
    color: #e67e22;
  }

  .status-card h5 {
    margin: 0.5rem 0 0.25rem 0;
    font-size: 0.9rem;
    color: #d35400;
  }

  .status-timestamp,
  .status-location {
    margin: 0.25rem 0;
    color: #7f8c8d;
    font-size: 0.9rem;
  }

  .energy-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 0.75rem;
    margin: 0.75rem 0;
  }

  .energy-item {
    display: flex;
    flex-direction: column;
    gap: 0.25rem;
    padding: 0.5rem;
    background: #fef5e7;
    border-radius: 0.5rem;
  }

  .energy-label {
    font-weight: 700;
    font-size: 0.85rem;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    color: #d35400;
  }

  .energy-pill {
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.05em;
  }

  .energy-pill.energy-low {
    background: #ffebee;
    border-color: #e74c3c;
    color: #c0392b;
  }

  .energy-pill.energy-medium {
    background: #fff3e0;
    border-color: #f39c12;
    color: #d68910;
  }

  .energy-pill.energy-high {
    background: #e8f5e9;
    border-color: #27ae60;
    color: #1e8449;
  }

  .mood-text {
    font-style: italic;
    color: #7f8c8d;
    font-size: 0.85rem;
  }

  .status-meta {
    margin-top: 0.75rem;
    padding-top: 0.75rem;
    border-top: 1px solid rgba(255, 159, 67, 0.2);
  }

  .status-meta p {
    margin: 0.25rem 0;
    font-size: 0.9rem;
  }

  .constraint-list {
    display: flex;
    flex-wrap: wrap;
    gap: 0.5rem;
    margin-top: 0.5rem;
  }

  .constraint-pill {
    background: #fff3cd;
    border-color: #ffc107;
    color: #856404;
  }

  .pillar-pill {
    background: #e3f2fd;
    border-color: #2196f3;
    color: #0d47a1;
    font-size: 0.75rem;
  }

  .duration-pill {
    font-weight: 700;
  }

  .duration-pill.duration-short {
    background: #e8f5e9;
    border-color: #4caf50;
    color: #2e7d32;
  }

  .duration-pill.duration-medium {
    background: #fff3e0;
    border-color: #ff9800;
    color: #e65100;
  }

  .duration-pill.duration-long {
    background: #ffebee;
    border-color: #f44336;
    color: #c62828;
  }

  .micro-block {
    background: #fef5e7;
    border: 1px solid rgba(255, 159, 67, 0.3);
    border-radius: 0.5rem;
    padding: 0.75rem;
    margin-top: 0.5rem;
  }

  .block-header {
    display: flex;
    flex-wrap: wrap;
    gap: 0.5rem;
    align-items: center;
    margin-bottom: 0.75rem;
  }

  .limitation-note {
    font-size: 0.85rem;
    color: #856404;
    font-style: italic;
  }

  .task-assignments {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
    margin: 0.75rem 0;
  }

  .task-group h5 {
    margin: 0 0 0.25rem 0;
    color: #d35400;
  }

  .task-group ul {
    margin: 0;
    padding-left: 1.25rem;
  }

  .task-group li {
    margin: 0.15rem 0;
    font-size: 0.9rem;
  }

  .block-instructions ol,
  .block-artifacts ul {
    margin: 0.25rem 0 0 0;
    padding-left: 1.25rem;
  }

  .block-instructions li,
  .block-artifacts li {
    margin: 0.25rem 0;
    font-size: 0.9rem;
  }

  .report-card {
    background: #fef5e7;
    border: 1px solid rgba(255, 159, 67, 0.2);
    border-radius: 0.5rem;
    padding: 0.75rem;
    margin: 0.5rem 0;
  }

  .report-time {
    margin: 0 0 0.5rem 0;
    font-weight: 600;
    color: #d35400;
    font-size: 0.9rem;
  }

  .report-energy {
    display: flex;
    gap: 1rem;
    margin: 0.25rem 0 0.5rem 0;
    font-size: 0.85rem;
    color: #7f8c8d;
  }

  .completed-list {
    margin: 0.5rem 0;
    padding-left: 1.25rem;
  }

  .completed-list li {
    margin: 0.15rem 0;
    font-size: 0.9rem;
  }

  .stuck-items {
    margin-top: 0.5rem;
    padding: 0.5rem;
    background: #fff3cd;
    border-radius: 0.35rem;
    font-size: 0.85rem;
  }

  .stuck-items ul {
    margin: 0.25rem 0 0 0;
    padding-left: 1.25rem;
  }

  .resource-section {
    margin: 0.75rem 0;
  }

  .resource-section h4 {
    margin: 0 0 0.5rem 0;
    color: #d35400;
  }

  .budget-bars,
  .time-stats {
    display: grid;
    gap: 0.5rem;
  }

  .budget-item,
  .time-item {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 0.5rem;
    background: #fef5e7;
    border-radius: 0.35rem;
  }

  .budget-item span,
  .time-item span {
    color: #7f8c8d;
    font-size: 0.9rem;
  }

  .budget-item strong,
  .time-item strong {
    color: #d35400;
  }

  .status-note {
    color: #7f8c8d;
    font-style: italic;
    margin: 0.5rem 0;
  }

  .status-template pre {
    background: #2c3e50;
    color: #ecf0f1;
