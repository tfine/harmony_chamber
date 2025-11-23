"""
CLI + FastAPI entrypoint for the Harmony↔Todoist adapter.
"""
import argparse
import asyncio
import hashlib
import hmac
import json
import logging
from typing import Any, Dict

from fastapi import FastAPI, Header, HTTPException, Request
import uvicorn

from todoist_adapter.config import load_settings
from todoist_adapter.models import LegislationTask
from todoist_adapter.service import AdapterService


logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
)
log = logging.getLogger(__name__)

app = FastAPI(title="Harmony Todoist Adapter")
settings = load_settings()
service = AdapterService(settings)


def verify_signature(raw_body: bytes, signature: str, secret: str) -> bool:
    digest = hmac.new(secret.encode(), raw_body, hashlib.sha256).hexdigest()
    return hmac.compare_digest(digest, signature)


@app.post("/webhook/todoist")
async def todoist_webhook(
    request: Request,
    x_todoist_hmac_sha256: str = Header(None),
) -> Dict[str, str]:
    raw_body = await request.body()
    if settings.webhook_secret:
        if not x_todoist_hmac_sha256:
            raise HTTPException(status_code=401, detail="Missing signature")
        if not verify_signature(raw_body, x_todoist_hmac_sha256, settings.webhook_secret):
            raise HTTPException(status_code=401, detail="Invalid signature")

    payload = await request.json()
    await service.handle_webhook_event(payload)
    return {"status": "ok"}


def run_cli() -> None:
    parser = argparse.ArgumentParser(description="Harmony ↔ Todoist adapter")
    sub = parser.add_subparsers(dest="command", required=True)

    create_cmd = sub.add_parser("create-task", help="Create a Todoist task from Harmony payload")
    create_cmd.add_argument("--title", required=True)
    create_cmd.add_argument("--description", required=True)
    create_cmd.add_argument("--tags", nargs="*", default=[])
    create_cmd.add_argument("--priority-tags", nargs="*", default=[])
    create_cmd.add_argument("--due", default=None)
    create_cmd.add_argument("--harmony-uid", required=True)

    sub.add_parser("poll", help="Poll Todoist for completions and sync to Harmony")
    sub.add_parser("serve", help="Run webhook server (FastAPI/uvicorn)")

    args = parser.parse_args()

    if args.command == "create-task":
        payload = LegislationTask(
            title=args.title,
            description=args.description,
            tags=args.tags,
            priority_tags=args.priority_tags,
            due=args.due,
            harmony_uid=args.harmony_uid,
        )
        service.create_legislation_task(payload)
    elif args.command == "poll":
        asyncio.run(service.poll_todoist_for_completions())
    elif args.command == "serve":
        uvicorn.run(app, host="0.0.0.0", port=8082)


if __name__ == "__main__":
    run_cli()
