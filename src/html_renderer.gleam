import chamber
import debate
import gleam/int
import gleam/list
import gleam/string
import senators

pub fn render_senator_profile(senator: senators.Senator) -> String {
  let paragraphs =
    senator.biography
    |> string.split("\n\n")
    |> list.map(fn(chunk) { "<p>" <> escape_html(chunk) <> "</p>" })
    |> string.join("")

  "<article class=\"card senator-card\">
     <h3>" <> escape_html(senator.name) <> "</h3>
     <p class=\"senator-state\">" <> escape_html(senator.state) <> "</p>
     <div class=\"senator-biography\">" <> paragraphs <> "</div>
   </article>"
}

pub fn render_senator_list(items: List(senators.Senator)) -> String {
  let cards =
    items
    |> list.map(render_senator_profile)
    |> string.join("")

  "<section class=\"panel senator-panel\">
     <div class=\"panel-header\">
       <h2>Senatorial Ledger</h2>
       <p>Static roster, batch #1 of Harmony Chamber.</p>
     </div>
     <div class=\"senator-grid\">" <> cards <> "</div>
   </section>"
}

pub fn render_turn(turn: debate.DebateTurn) -> String {
  let formatted = format_speech_text(turn.text)
  "<article class=\"card turn-card\">
     <div class=\"turn-meta\">
       <span class=\"turn-id\">Turn #" <> int.to_string(turn.id) <> "</span>
       <span class=\"turn-senator\">Speaker: " <> escape_html(turn.senator_id) <> "</span>
     </div>
     <div class=\"turn-text\"><p>" <> formatted <> "</p></div>
   </article>"
}

pub fn render_transcript(turns: List(debate.DebateTurn)) -> String {
  let body = case turns {
    [] ->
      "<div class=\"empty-transcript\">
           <p>No speeches recorded yet. The queue below shows who will open proceedings.</p>
         </div>"
    _ ->
      turns
      |> list.map(render_turn)
      |> string.join("")
  }

  "<section class=\"panel transcript-panel\">
     <div class=\"panel-header\">
       <h2>Debate Transcript</h2>
       <p>Live log of speeches during the current session.</p>
     </div>
     <div class=\"transcript-grid\">" <> body <> "</div>
   </section>"
}

pub fn render_page(
  chamber: chamber.Chamber,
  senator_list: List(senators.Senator),
) -> String {
  let bill_section = render_bill(chamber, senator_list)
  let transcript_section = render_transcript(debate.transcript(chamber.debate))
  let senator_section = render_senator_list(senator_list)

  "<!doctype html>
   <html lang=\"en\">
     <head>
       <meta charset=\"utf-8\" />
       <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />
       <title>Harmony Chamber Simulation</title>
       <style>" <> stylesheet() <> "</style>
     </head>
     <body>
       <div class=\"page\">
         <header class=\"hero\">
           <div>
             <p class=\"eyebrow\">Harmony Chamber</p>
             <h1>Senate Simulation v0.1</h1>
             <p class=\"hero-summary\">
               Gleam, BEAM, and careful transcripts keep this chamber humming while
               OpenAI agents wait in the wings.
             </p>
           </div>
           <div class=\"hero-badge\">
             <span>Server 0.0.0.0:8080</span>
             <span>BEAM / Mist / Wisp</span>
           </div>
         </header>
         <main class=\"grid\">
           " <> bill_section <> "
           " <> transcript_section <> "
         </main>
         " <> senator_section <> "
       </div>
     </body>
   </html>"
}

fn render_bill(
  chamber: chamber.Chamber,
  senator_list: List(senators.Senator),
) -> String {
  let bill = chamber.bill
  let phase = render_phase_badge(chamber.debate.phase)
  let queue_html = render_queue(chamber.debate.queue, senator_list)

  "<section class=\"panel bill-panel\">
     <div class=\"panel-header\">
       <h2>" <> escape_html(bill.title) <> "</h2>
       <div class=\"phase-wrapper\">" <> phase <> "</div>
     </div>
     <div class=\"bill-meta\">
       <span class=\"bill-id\">Bill " <> escape_html(bill.id) <> "</span>
     </div>
     <p class=\"bill-summary\">" <> escape_html(bill.summary) <> "</p>
     <div class=\"queue-panel\">
       <h3>Speaking Queue</h3>
       " <> queue_html <> "
     </div>
   </section>"
}

fn render_queue(queue: List(String), senators: List(senators.Senator)) -> String {
  case queue {
    [] ->
      "<p class=\"queue-empty\">No senators are currently scheduled. Add speakers to begin a session.</p>"
    [next, ..rest] -> {
      let next_label = escape_html(senator_label(senators, next))
      let remainder =
        rest
        |> list.map(fn(id) {
          "<li>" <> escape_html(senator_label(senators, id)) <> "</li>"
        })
        |> string.join("")

      let rest_block = case remainder == "" {
        True ->
          "<p class=\"queue-empty\">The queue will recycle after the opening turn.</p>"
        False -> "<ol class=\"queue-list\">" <> remainder <> "</ol>"
      }

      "<div class=\"queue-next\">
         <span>Next Speaker</span>
         <strong>" <> next_label <> "</strong>
       </div>
       " <> rest_block <> ""
    }
  }
}

fn render_phase_badge(phase: debate.Phase) -> String {
  let #(label, css) = case phase {
    debate.Ongoing -> #("Open Debate", "phase-ongoing")
    debate.VoteRequested -> #("Vote Requested", "phase-requested")
    debate.Voting -> #("Voting", "phase-voting")
    debate.Completed -> #("Completed", "phase-complete")
  }

  "<span class=\"phase-badge " <> css <> "\">" <> label <> "</span>"
}

fn senator_label(senators_list: List(senators.Senator), id: String) -> String {
  case senators_list {
    [] -> id
    [senator, ..rest] ->
      case senator.id == id {
        True -> senator.name
        False -> senator_label(rest, id)
      }
  }
}

fn format_speech_text(text: String) -> String {
  let escaped = escape_html(text)
  let paragraph_breaks = string.replace(escaped, "\n\n", "</p><p>")
  string.replace(paragraph_breaks, "\n", "<br />")
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
    --parchment: #f2eee4;
    --ink: #2d2d2d;
    --accent: #c7a75b;
    --shadow: rgba(0, 0, 0, 0.08);
  }

  * {
    box-sizing: border-box;
  }

  body {
    font-family: 'Georgia', 'Garamond', 'Times New Roman', serif;
    background: var(--parchment);
    margin: 0;
    color: var(--ink);
  }

  .page {
    max-width: 1200px;
    margin: 0 auto;
    padding: 2rem 1.5rem 4rem;
  }

  .hero {
    background: #f7f3e8;
    border: 2px solid var(--accent);
    border-radius: 1rem;
    padding: 2rem;
    display: flex;
    justify-content: space-between;
    gap: 2rem;
    box-shadow: 0 10px 30px var(--shadow);
  }

  .eyebrow {
    text-transform: uppercase;
    letter-spacing: 0.2em;
    font-size: 0.8rem;
    margin: 0 0 0.5rem;
    color: #8c6b35;
  }

  .hero h1 {
    margin: 0 0 0.5rem;
    font-size: 2.4rem;
  }

  .hero-summary {
    margin: 0;
    max-width: 32rem;
  }

  .hero-badge {
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: flex-end;
    gap: 0.5rem;
    font-size: 0.9rem;
  }

  .hero-badge span {
    background: #fffaf0;
    border: 1px solid var(--accent);
    padding: 0.4rem 0.75rem;
    border-radius: 999px;
  }

  .grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
    gap: 1.5rem;
    margin-top: 2rem;
  }

  .panel {
    background: #fffaf3;
    border: 2px solid #d6c7a5;
    border-radius: 1rem;
    padding: 1.5rem;
    box-shadow: 0 8px 24px var(--shadow);
  }

  .panel-header h2 {
    margin: 0;
    font-size: 1.5rem;
  }

  .panel-header p {
    margin: 0.25rem 0 0;
    color: #5c4a2a;
  }

  .bill-summary {
    margin: 0 0 1.5rem;
    line-height: 1.6;
  }

  .bill-meta {
    font-size: 0.9rem;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    margin-bottom: 0.75rem;
    color: #866327;
  }

  .phase-wrapper {
    display: flex;
    justify-content: flex-end;
  }

  .phase-badge {
    padding: 0.35rem 0.75rem;
    border-radius: 999px;
    border: 1px solid var(--accent);
    font-size: 0.85rem;
  }

  .phase-ongoing {
    background: #fff1d6;
  }

  .phase-requested {
    background: #fde7c0;
  }

  .phase-voting {
    background: #f9d2a3;
  }

  .phase-complete {
    background: #e8d7bd;
  }

  .queue-panel h3 {
    margin-top: 0;
  }

  .queue-next {
    background: #fef5df;
    border: 1px solid var(--accent);
    border-radius: 0.75rem;
    padding: 0.75rem 1rem;
    margin-bottom: 1rem;
    display: flex;
    flex-direction: column;
    gap: 0.25rem;
  }

  .queue-next span {
    text-transform: uppercase;
    font-size: 0.8rem;
    letter-spacing: 0.1em;
    color: #7a5c2a;
  }

  .queue-next strong {
    font-size: 1.1rem;
  }

  .queue-list {
    padding-left: 1.25rem;
    margin: 0;
  }

  .queue-empty {
    margin: 0;
    color: #7a6a4a;
    font-style: italic;
  }

  .card {
    background: #fffdf7;
    border: 1px solid rgba(135, 108, 63, 0.4);
    border-radius: 0.75rem;
    padding: 1rem;
    box-shadow: 0 6px 18px var(--shadow);
  }

  .senator-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
    gap: 1rem;
    margin-top: 1rem;
  }

  .senator-card h3 {
    margin: 0;
  }

  .senator-state {
    margin: 0.25rem 0 0.75rem;
    font-size: 0.95rem;
    color: #6b5333;
  }

  .senator-biography p {
    margin: 0 0 0.75rem;
    line-height: 1.55;
  }

  .transcript-grid {
    display: flex;
    flex-direction: column;
    gap: 1rem;
  }

  .turn-meta {
    display: flex;
    justify-content: space-between;
    font-size: 0.9rem;
    margin-bottom: 0.5rem;
    color: #6a5533;
  }

  .turn-text p {
    margin: 0;
    line-height: 1.5;
  }

  .empty-transcript {
    border: 1px dashed #c5b083;
    border-radius: 0.75rem;
    padding: 1rem;
    background: #fff7e6;
  }

  @media (max-width: 720px) {
    .hero {
      flex-direction: column;
    }

    .hero-badge {
      align-items: flex-start;
    }
  }
  "
}
