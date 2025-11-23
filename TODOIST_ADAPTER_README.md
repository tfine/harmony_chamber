# Harmony ↔ Todoist Adapter

Python adapter that bridges Harmony/AGATA “legislation tasks” into Todoist and reports completions back to Harmony core.

## Requirements
- Python 3.10+
- Env vars:
  - `TODOIST_API_TOKEN` (required)
  - `HARMONY_CORE_URL` (required, e.g., `https://harmony-core.local`)
  - `TODOIST_PROJECT_ID` (optional, target project)
  - `TODOIST_DEFAULT_LABELS` (optional, comma-separated; default: `Harmony-Legislation`)
  - `TODOIST_LABEL_MAP` (optional JSON; example below)
  - `HARMONY_STATE_PATH` (optional path for local JSON state; default `./todoist_state.json`)
  - `HARMONY_CALLBACK_TIMEOUT` (seconds, default `5.0`)
  - `TODOIST_WEBHOOK_SECRET` (optional HMAC secret for webhook validation)

Example label map (priorityTags → Todoist labels):
```json
{"priorityTags.urgent": "Urgent", "priorityTags.education": "Education", "accessibility": "Accessibility"}
```

## Installation
```bash
python -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
```

## Usage
### Create a Todoist task from Harmony payload
```bash
python -m todoist_adapter.app create-task \
  --title "Prepare accessibility brief" \
  --description "Draft memo for the AGATA time block" \
  --tags accessibility research \
  --priority-tags urgent \
  --due "tomorrow 9am" \
  --harmony-uid "leg-1234"
```

### Poll Todoist for completions (cron / background worker)
```bash
python -m todoist_adapter.app poll
```
Run on a schedule (cron, systemd timer, or containerized worker) to push completions to Harmony.

### Webhook server
```bash
python -m todoist_adapter.app serve  # binds 0.0.0.0:8082
```
Expose `/webhook/todoist` to Todoist. If `TODOIST_WEBHOOK_SECRET` is set, requests must include `X-Todoist-Hmac-Sha256` matching the HMAC of the raw body.

## Data Flow
- Harmony → Adapter: calls `create_legislation_task(payload)`; adapter creates Todoist task, stores mapping `harmony_uid ↔ task_id`.
- Todoist → Adapter: via polling or webhook, completed tasks are detected; adapter posts `{harmony_uid, task_id, completed_at}` to `POST /task_completed` on Harmony core.
- State: local JSON file for mappings and last sync cursor; replace with DB/queue as needed.

### ASCII flow
```
Harmony core (Gleam) --(task payload)--> Adapter (Python)
Adapter --(Todoist API)--> Todoist
Todoist --(webhook/poll)--> Adapter --(POST /task_completed)--> Harmony core
```

## Development & Testing
- The included `tests/test_adapter_stub.py` are environment-gated stubs. Set `TODOIST_API_TOKEN` and `HARMONY_CORE_URL` to run, or they will auto-skip.
- Prefer adding VCR/fixture-backed tests for real Todoist interactions.

## Metadata Notes
- Mapping: `priorityTags` → Todoist labels (via `TODOIST_LABEL_MAP`).
- Mapping: due date strings are passed through Todoist `due_string` for natural language handling.

## Scheduling Guidance
- Polling: run every 2–5 minutes if webhooks are not available.
- Webhooks: recommended where supported; keep `TODOIST_WEBHOOK_SECRET` set.
