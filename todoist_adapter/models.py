from dataclasses import dataclass
from datetime import datetime
from typing import List, Optional


@dataclass
class LegislationTask:
    title: str
    description: str
    tags: List[str]
    priority_tags: List[str]
    due: Optional[str]  # ISO8601 or relative (e.g., "tomorrow 9am")
    harmony_uid: str


@dataclass
class TaskMapping:
    harmony_uid: str
    todoist_id: str
    completed: bool = False
    completed_at: Optional[datetime] = None
