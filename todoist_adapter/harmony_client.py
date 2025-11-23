import logging
from typing import Any, Dict

import httpx

log = logging.getLogger(__name__)


class HarmonyClient:
    def __init__(self, base_url: str, timeout: float):
        self.base_url = base_url
        self.timeout = timeout

    async def send_completion(self, harmony_uid: str, task_id: str, completed_at: str) -> None:
        payload: Dict[str, Any] = {
            "harmony_uid": harmony_uid,
            "task_id": task_id,
            "completed_at": completed_at,
        }
        url = f"{self.base_url}/task_completed"
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            try:
                resp = await client.post(url, json=payload)
                resp.raise_for_status()
            except Exception:
                log.exception("Failed to send completion callback to Harmony core")
                raise
