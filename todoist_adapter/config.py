import json
import os
from dataclasses import dataclass
from typing import Dict, List, Optional


@dataclass
class Settings:
    todoist_token: str
    project_id: Optional[str]
    default_labels: List[str]
    label_map: Dict[str, str]
    harmony_core_url: str
    state_path: str
    callback_timeout: float
    webhook_secret: Optional[str]


def load_settings() -> Settings:
    """
    Load adapter configuration from environment variables.

    Required:
    - TODOIST_API_TOKEN
    - HARMONY_CORE_URL

    Optional:
    - TODOIST_PROJECT_ID
    - TODOIST_DEFAULT_LABELS (comma-separated)
    - TODOIST_LABEL_MAP (JSON: {"priorityTags.<tag>": "TodoistLabelName"})
    - HARMONY_STATE_PATH (default: ./todoist_state.json)
    - HARMONY_CALLBACK_TIMEOUT (seconds, float)
    - TODOIST_WEBHOOK_SECRET (shared secret for webhook validation)
    """

    token = os.getenv("TODOIST_API_TOKEN")
    core_url = os.getenv("HARMONY_CORE_URL")
    if not token or not core_url:
        raise ValueError("Missing TODOIST_API_TOKEN or HARMONY_CORE_URL")

    default_labels = _split_csv(os.getenv("TODOIST_DEFAULT_LABELS", "Harmony-Legislation"))
    label_map = _parse_label_map(os.getenv("TODOIST_LABEL_MAP", "{}"))

    return Settings(
        todoist_token=token,
        project_id=os.getenv("TODOIST_PROJECT_ID"),
        default_labels=default_labels,
        label_map=label_map,
        harmony_core_url=core_url.rstrip("/"),
        state_path=os.getenv("HARMONY_STATE_PATH", "todoist_state.json"),
        callback_timeout=float(os.getenv("HARMONY_CALLBACK_TIMEOUT", "5.0")),
        webhook_secret=os.getenv("TODOIST_WEBHOOK_SECRET"),
    )


def _split_csv(raw: str) -> List[str]:
    return [item.strip() for item in raw.split(",") if item.strip()]


def _parse_label_map(raw: str) -> Dict[str, str]:
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return {}
