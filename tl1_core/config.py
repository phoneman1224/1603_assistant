"""Application configuration management utilities."""

from __future__ import annotations

import os
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Dict

import yaml

APP_FOLDER_NAME = "TL1Assistant"
CONFIG_FILENAME = "config.yaml"


def _get_local_appdata() -> Path:
    """Return the platform-specific directory for local application data."""
    if os.name == "nt":
        base = os.environ.get("LOCALAPPDATA") or os.environ.get("APPDATA")
        if base:
            return Path(base)
        return Path.home() / "AppData" / "Local"
    return Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local" / "share"))


@dataclass
class AppConfig:
    """Represents the persisted configuration for the TL1 Assistant."""

    host: str = "10.60.165.44"
    port: int = 3082
    transport: str = "tcp"
    mode: str = "supervised"
    file_path: Path = field(init=False)

    def __post_init__(self) -> None:
        base_dir = _get_local_appdata() / APP_FOLDER_NAME
        base_dir.mkdir(parents=True, exist_ok=True)
        self.file_path = base_dir / CONFIG_FILENAME

    def to_dict(self) -> Dict[str, Any]:
        """Return a dictionary representation of the configuration."""
        return {
            "host": self.host,
            "port": self.port,
            "transport": self.transport,
            "mode": self.mode,
        }

    def save(self) -> None:
        """Persist the configuration to disk."""
        with self.file_path.open("w", encoding="utf-8") as fh:
            yaml.safe_dump(self.to_dict(), fh, sort_keys=False)

    @classmethod
    def load(cls) -> "AppConfig":
        """Load configuration from disk, creating defaults when missing."""
        instance = cls()
        if instance.file_path.exists():
            with instance.file_path.open("r", encoding="utf-8") as fh:
                data: Dict[str, Any] = yaml.safe_load(fh) or {}
            for key, value in data.items():
                if hasattr(instance, key):
                    setattr(instance, key, value)
        else:
            instance.save()
        return instance
