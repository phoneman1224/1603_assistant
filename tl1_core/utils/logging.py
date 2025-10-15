"""Utilities for structured JSON logging."""

from __future__ import annotations

import json
import os
import uuid
from datetime import datetime
from pathlib import Path
from typing import Any, Dict

APP_FOLDER_NAME = "TL1Assistant"
LOG_FOLDER_NAME = "logs"


def _get_log_dir() -> Path:
    """Return the directory where log files are stored."""
    if os.name == "nt":
        base = Path(os.environ.get("LOCALAPPDATA", Path.home()))
    else:
        base = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local" / "share"))
    log_dir = base / APP_FOLDER_NAME / LOG_FOLDER_NAME
    log_dir.mkdir(parents=True, exist_ok=True)
    return log_dir


class SessionLogger:
    """Write structured JSON log entries for a session."""

    def __init__(self) -> None:
        self.session_id = uuid.uuid4().hex
        timestamp = datetime.utcnow().strftime("%Y%m%d")
        log_dir = _get_log_dir()
        self.file_path = log_dir / f"{timestamp}_session-{self.session_id}.jsonl"
        self._file = self.file_path.open("a", encoding="utf-8")

    def write(self, event: str, **payload: Any) -> None:
        """Write a JSON log entry."""
        entry: Dict[str, Any] = {
            "session": self.session_id,
            "timestamp": datetime.utcnow().isoformat(timespec="milliseconds"),
            "event": event,
            "data": payload,
        }
        self._file.write(json.dumps(entry, ensure_ascii=False) + "\n")
        self._file.flush()

    def close(self) -> None:
        """Close the log file."""
        if not self._file.closed:
            self._file.close()

    def __enter__(self) -> "SessionLogger":
        return self

    def __exit__(self, exc_type, exc, tb) -> None:  # type: ignore[override]
        self.close()
