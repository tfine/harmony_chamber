# vibe coded and in rapid flux

# harmony_chamber

Harmony Chamber is a Gleam/Erlang application that simulates a live Senate floor.
Every senator runs as an independent BEAM process, debates are powered by GPT‑4.1,
and long-term recall is backed by Pinecone. A built-in autopilot keeps the
session moving so you can watch speeches, amendments, and votes update in real
time through the web UI.

## Features

- **Live debate orchestration** – Each senator has a mailbox, intentions log, and
  Pinecone-backed memory. Debate turns, amendments, and voting follow actual
  parliamentary flow.
- **Concurrent LLM workers** – GPT calls run in isolated processes with
  per-senator timeouts, retry/backoff, and a boot-time probe to verify keys.
- **Persistent memory** – Every speech is embedded and stored in Pinecone, then
  recalled with progressively wider filters so senators cite prior arguments.
- **Autopilot** – A background process advances the chamber on a configurable
  interval and snapshots state to disk.
- **Constituent portal** – `/senators`, `/senators/{id}`, and
  `/senators/{id}/notes` expose public biographies and mailboxes.
- **Observability** – Structured log lines show Pinecone status, LLM request
  lengths, per-senator timeouts, and memory recall issues.

## Requirements

- Erlang/OTP 25+ (needed by Gleam)
- Gleam 1.0+
- Access to the OpenAI API (tested with `gpt-4.1-mini`)
- Pinecone project + index for embeddings

## Setup

1. **Install dependencies**
   ```sh
   # macOS (example)
   brew install gleam
   ```
   Ensure `gleam --version` and `erl` both work.
2. **Clone and enter the repo**
   ```sh
   git clone https://github.com/tfine/harmony_chamber.git
   cd harmony_chamber
   ```
3. **Create your `.env`**
   ```sh
   cp .env.example .env
   ```
   Fill in at least:
   - `OPENAI_API_KEY`
   - `PINECONE_API_KEY`
   - `PINECONE_ENVIRONMENT`
   - `PINECONE_INDEX`
   - Optional tuning knobs (timeouts, autopilot cadence, memory mode, etc.)
4. **Export variables for the current shell**
   ```sh
   set -a
   . .env
   set +a
   ```
   (PowerShell: `Get-Content .env | foreach { if ($_ -and $_ -notmatch '^#') { $_.Split('=') | Set-Item Env:\$($_[0]) $_[1] } }`)
5. **Run migrations/tests (optional)**
   ```sh
   gleam build   # compile once; validates env + dependencies
   gleam test    # no-op today but kept for future suites
   ```
6. **Start the chamber**
   ```sh
   gleam run -m harmony_chamber
   ```
   The server binds to `http://0.0.0.0:8080`. Logs will show a Pinecone connection
   and an LLM probe before traffic begins. Visit `http://localhost:8080` to watch
   the debate. Use the Autopilot controls in the UI to pause/resume ticks.

### Verifying LLM credentials

Use the demo helper to confirm OpenAI access without starting the web server:

```sh
gleam run -m demo demo_senator_llm
```

### Vector memory smoke test

To verify Pinecone credentials end-to-end, run:

```sh
gleam run -m pinecone_scripts
```

## Routes & UI Highlights

- `/` – Main chamber view with debate log, vote tracker, and senator roster.
- `/senators` – Grid of every senator plus their latest intent/speech snippet.
- `/senators/{id}` – Procedurally generated profile page with biography,
  live notes, and recent turns.
- `/senators/{id}/notes` – POST endpoint for constituent messages (form is on
  the profile page).

## Development workflow

- `gleam run -m harmony_chamber` – Run the app (remember to source `.env` in
  the same shell before launching so the BEAM VM inherits env vars).
- `gleam test` – Placeholder test suite.
- `session_snapshot.etf` – On-disk snapshot updated by autopilot after each tick.

Senator public pages remain available even when debate is paused. Constituents
can leave notes from the profile page, and logs in your terminal will reflect
incoming mail plus any LLM or Pinecone activity.
