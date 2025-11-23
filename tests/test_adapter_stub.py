"""
Stub tests to validate wiring without hitting external services.
These tests auto-skip if required environment variables are absent.
"""
import asyncio
import os

from todoist_adapter.config import load_settings
from todoist_adapter.models import LegislationTask
from todoist_adapter.service import AdapterService


def _maybe_settings():
    if not os.getenv("TODOIST_API_TOKEN") or not os.getenv("HARMONY_CORE_URL"):
        return None
    return load_settings()


def test_create_task_stub(monkeypatch):
    settings = _maybe_settings()
    if not settings:
        return  # skip when env not provided
    service = AdapterService(settings)

    def fake_create_task(payload, project_id, labels):
        class FakeTask:
            id = "fake123"

        return FakeTask()

    monkeypatch.setattr(service.todoist, "create_task", fake_create_task)

    payload = LegislationTask(
        title="Test",
        description="Demo",
        tags=["alpha"],
        priority_tags=["urgent"],
        due="tomorrow",
        harmony_uid="uid-1",
    )

    mapping = service.create_legislation_task(payload)
    assert mapping.todoist_id == "fake123"
    assert mapping.harmony_uid == "uid-1"


def test_completion_webhook_no_mapping():
    settings = _maybe_settings()
    if not settings:
        return  # skip when env not provided
    service = AdapterService(settings)
    payload = {"event_name": "item:completed", "event_data": {"id": "unknown"}}
    asyncio.run(service.handle_webhook_event(payload))  # Should no-op without raising
