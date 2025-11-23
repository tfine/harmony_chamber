import asyncio
import logging
from datetime import datetime, timezone
from typing import List

from todoist_adapter.config import Settings
from todoist_adapter.harmony_client import HarmonyClient
from todoist_adapter.models import LegislationTask, TaskMapping
from todoist_adapter.state_store import StateStore
from todoist_adapter.todoist_client import TodoistClient

log = logging.getLogger(__name__)


class AdapterService:
    def __init__(self, settings: Settings):
        self.settings = settings
        self.todoist = TodoistClient(settings.todoist_token)
        self.harmony = HarmonyClient(settings.harmony_core_url, settings.callback_timeout)
        self.state = StateStore(settings.state_path)

    def _labels_for(self, payload: LegislationTask) -> List[str]:
        labels = list(self.settings.default_labels)
        # Mapping: priorityTags → Todoist labels
        for tag in payload.priority_tags:
            mapped = self.settings.label_map.get(f"priorityTags.{tag}") or self.settings.label_map.get(tag)
            if mapped:
                labels.append(mapped)
        # Generic tags passthrough
        for tag in payload.tags:
            mapped = self.settings.label_map.get(tag)
            labels.append(mapped or tag)
        # Deduplicate
        return list(dict.fromkeys(labels))

    def create_legislation_task(self, payload: LegislationTask) -> TaskMapping:
        labels = self._labels_for(payload)
        task = self.todoist.create_task(payload, self.settings.project_id, labels)
        mapping = TaskMapping(harmony_uid=payload.harmony_uid, todoist_id=task.id)
        self.state.upsert_mapping(mapping)
        log.info(
            "Created Todoist task",
            extra={"harmony_uid": payload.harmony_uid, "todoist_id": task.id},
        )
        return mapping

    async def poll_todoist_for_completions(self) -> None:
        since = self.state.last_completed_sync()
        completed = self.todoist.fetch_completed_since(since, self.settings.project_id)
        if not completed:
            return

        now = datetime.now(timezone.utc)
        for item in completed:
            todoist_id = item.get("task_id") or item.get("id")
            completed_at = item.get("completed_at")
            harmony_uid = self.state.harmony_uid_for_todoist(todoist_id)
            if not harmony_uid:
                continue

            # Update local state and notify Harmony core
            parsed_completed = (
                datetime.fromisoformat(completed_at.replace("Z", "+00:00"))
                if completed_at
                else now
            )
            self.state.mark_completed(harmony_uid, parsed_completed)
            await self.harmony.send_completion(
                harmony_uid=harmony_uid,
                task_id=todoist_id,
                completed_at=parsed_completed.isoformat(),
            )
            log.info(
                "Synced completion to Harmony",
                extra={"harmony_uid": harmony_uid, "todoist_id": todoist_id},
            )

        self.state.update_last_completed_sync(now)

    async def handle_webhook_event(self, event: dict) -> None:
        """
        Todoist webhooks deliver task completed events with the task ID.
        This handler keeps the code shared with the polling path.
        """
        if event.get("event_name") != "item:completed":
            return
        item = event.get("event_data", {})
        todoist_id = item.get("id")
        completed_at = item.get("completed_at") or datetime.now(timezone.utc).isoformat()
        harmony_uid = self.state.harmony_uid_for_todoist(todoist_id)
        if not harmony_uid:
            return

        parsed_completed = datetime.fromisoformat(completed_at.replace("Z", "+00:00"))
        self.state.mark_completed(harmony_uid, parsed_completed)
        await self.harmony.send_completion(
          harmony_uid=harmony_uid,
          task_id=todoist_id,
          completed_at=parsed_completed.isoformat(),
        )
        log.info(
            "Webhook synced completion to Harmony",
            extra={"harmony_uid": harmony_uid, "todoist_id": todoist_id},
        )
