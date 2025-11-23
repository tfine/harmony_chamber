import json
from datetime import datetime
from pathlib import Path
from typing import Dict, Optional

from todoist_adapter.models import TaskMapping


class StateStore:
    def __init__(self, path: str):
        self.path = Path(path)
        self._data = {"mappings": {}, "last_completed_sync": None}
        self._load()

    def _load(self) -> None:
        if self.path.exists():
            try:
                self._data = json.loads(self.path.read_text())
            except Exception:
                # Corrupt or unreadable state; start fresh but keep the file for inspection.
                self._data = {"mappings": {}, "last_completed_sync": None}

    def save(self) -> None:
        self.path.write_text(json.dumps(self._data, default=str, indent=2))

    def upsert_mapping(self, mapping: TaskMapping) -> None:
        self._data["mappings"][mapping.harmony_uid] = {
            "todoist_id": mapping.todoist_id,
            "completed": mapping.completed,
            "completed_at": mapping.completed_at.isoformat()
            if mapping.completed_at
            else None,
        }
        self.save()

    def mark_completed(self, harmony_uid: str, completed_at: datetime) -> Optional[str]:
        mapping = self._data["mappings"].get(harmony_uid)
        if not mapping:
            return None
        mapping["completed"] = True
        mapping["completed_at"] = completed_at.isoformat()
        self.save()
        return mapping["todoist_id"]

    def todoist_id_for(self, harmony_uid: str) -> Optional[str]:
        record = self._data["mappings"].get(harmony_uid)
        if not record:
            return None
        return record["todoist_id"]

    def harmony_uid_for_todoist(self, todoist_id: str) -> Optional[str]:
        for uid, record in self._data["mappings"].items():
            if record.get("todoist_id") == todoist_id:
                return uid
        return None

    def update_last_completed_sync(self, timestamp: datetime) -> None:
        self._data["last_completed_sync"] = timestamp.isoformat()
        self.save()

    def last_completed_sync(self) -> Optional[datetime]:
        raw = self._data.get("last_completed_sync")
        if not raw:
            return None
        try:
            return datetime.fromisoformat(raw)
        except Exception:
            return None
