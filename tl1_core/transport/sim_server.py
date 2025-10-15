"""Lightweight TL1 simulator for local testing."""

from __future__ import annotations

import asyncio
import re
from dataclasses import dataclass
from typing import Dict, Optional

RAI_PATTERN = re.compile(r"RAI", re.IGNORECASE)


@dataclass
class SimulatedAlarm:
    """Represents a simulated alarm condition."""

    aid: str
    message: str


class TL1Simulator:
    """Async TCP server that echoes TL1 commands for development."""

    def __init__(self, host: str = "127.0.0.1", port: int = 3082) -> None:
        self.host = host
        self.port = port
        self.server: Optional[asyncio.base_events.Server] = None
        self.alarms: Dict[str, SimulatedAlarm] = {
            "OC12-1": SimulatedAlarm(aid="OC12-1", message="RAI"),
            "OC12-2": SimulatedAlarm(aid="OC12-2", message="CLEAR"),
        }

    async def start(self) -> None:
        """Start the simulator server."""
        self.server = await asyncio.start_server(self._handle_client, self.host, self.port)
        await self.server.start_serving()

    async def stop(self) -> None:
        """Stop the simulator server."""
        if self.server is not None:
            self.server.close()
            await self.server.wait_closed()
            self.server = None

    async def _handle_client(self, reader: asyncio.StreamReader, writer: asyncio.StreamWriter) -> None:
        while True:
            data = await reader.readline()
            if not data:
                break
            command = data.decode("ascii", errors="ignore").strip()
            response = self._process_command(command)
            writer.write(response.encode("ascii") + b"\r\n")
            await writer.drain()
        writer.close()
        await writer.wait_closed()

    def _process_command(self, command: str) -> str:
        """Generate a TL1-style response for the provided command."""
        ctag = self._extract_ctag(command) or "0"
        if "RTRV-ALM" in command:
            aid = self._extract_aid(command)
            alarm = self.alarms.get(aid or "", SimulatedAlarm(aid=aid or "UNKNOWN", message="CLEAR"))
            status = "RAI" if RAI_PATTERN.search(alarm.message) else alarm.message
            return f"M  {ctag} COMPLD\n{aid},{status};"
        return f"M  {ctag} COMPLD;"

    @staticmethod
    def _extract_ctag(command: str) -> Optional[str]:
        parts = command.split(":")
        if len(parts) >= 3:
            return parts[2]
        return None

    @staticmethod
    def _extract_aid(command: str) -> Optional[str]:
        match = re.search(r"AID=([A-Z0-9-]+)", command)
        if match:
            return match.group(1)
        return None


async def main() -> None:  # pragma: no cover - manual entry point
    """Run the simulator until interrupted."""
    simulator = TL1Simulator()
    await simulator.start()
    print(f"TL1 simulator listening on {simulator.host}:{simulator.port}")
    try:
        while True:
            await asyncio.sleep(3600)
    except (KeyboardInterrupt, asyncio.CancelledError):
        pass
    finally:
        await simulator.stop()


if __name__ == "__main__":  # pragma: no cover - script entry point
    asyncio.run(main())
