import logging
from datetime import datetime
from typing import Dict, List, Optional

import httpx
from todoist_api_python.api import TodoistAPI
from todoist_api_python.models import Task

from todoist_adapter.models import LegislationTask

log = logging.getLogger(__name__)


class TodoistClient:
    def __init__(self, token: str):
        self.api = TodoistAPI(token)
        self.token = token

    def create_task(
        self,
        payload: LegislationTask,
        project_id: Optional[str],
        labels: List[str],
    ) -> Task:
        """Mapping: priorityTags → Todoist labels."""
        try:
            return self.api.add_task(
                content=payload.title,
                description=payload.description,
                project_id=project_id,
                labels=labels,
                due_string=payload.due,
            )
        except Exception as exc:
            log.exception("Todoist create_task failed")
            raise exc

    def fetch_completed_since(
        self, since: Optional[datetime], project_id: Optional[str]
    ) -> List[Dict]:
        """
        Fetch completed items using the Sync API endpoint.
        Using raw HTTP because the python SDK does not expose completed items.
        """
        params: Dict[str, str] = {}
        if since:
            params["since"] = since.isoformat()
        if project_id:
            params["project_id"] = project_id

        headers = {"Authorization": f"Bearer {self.token}"}
        url = "https://api.todoist.com/sync/v9/completed/get_all"
        resp = httpx.get(url, headers=headers, params=params, timeout=10.0)
        resp.raise_for_status()
        data = resp.json()
        return data.get("items", [])
