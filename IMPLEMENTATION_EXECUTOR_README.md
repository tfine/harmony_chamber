# Implementation Executor (Mandates → GitHub PR)

This Python tool consumes implementation mandates from Harmony, drafts a plan (optionally via GLM 4.6), creates a branch, commits a placeholder change, and opens a PR. It reports status back to Harmony.

## Env vars
- `GITHUB_TOKEN` (required) – repo access
- `HARMONY_IMPL_STATUS_URL` (required) – `https://harmony-core/api/v1/implementations/status`
- `GLM_API_KEY` (optional) – z.ai GLM 4.6 for plan drafting

## Usage
```bash
python -m implementation_executor.main \
  --mandate /path/to/mandate.json \
  --base-branch main
```
`mandate.json` fields: `id, bill_id, bill_title, bill_summary, constitution_id, category, target_repo, branch_hint`.

## Flow
1) Load mandate + env.
2) (Optional) Call GLM 4.6 to draft plan.
3) Clone repo, create branch `branch_hint-{id}`.
4) Write `IMPLEMENTATION_PLAN.md`, commit, push.
5) Open PR with bill context.
6) POST status updates (`running`, `completed`, or `errored`) back to Harmony.

## Notes
- Repo allowlist should be enforced by Harmony when emitting mandates.
- Extend the executor to run tests, apply code changes, and add MCP/tooling as needed. This skeleton prioritizes end-to-end wiring for launch.
