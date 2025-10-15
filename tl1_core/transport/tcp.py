"""Async TL1 transport over raw TCP or Telnet."""

from __future__ import annotations

import asyncio
from asyncio import StreamReader, StreamWriter
from typing import Optional

TELNET_IAC = 255
TELNET_DONT = 254
TELNET_DO = 253
TELNET_WONT = 252
TELNET_WILL = 251

DEFAULT_TIMEOUT = 5.0


class TL1Transport:
    """Provides asynchronous TL1 connectivity over TCP or Telnet."""

    def __init__(self, host: str, port: int = 3082, use_telnet: bool = False) -> None:
        self.host = host
        self.port = port
        self.use_telnet = use_telnet
        self._reader: Optional[StreamReader] = None
        self._writer: Optional[StreamWriter] = None
        self._lock = asyncio.Lock()

    async def connect(self) -> None:
        """Establish the TCP connection with a timeout."""
        try:
            self._reader, self._writer = await asyncio.wait_for(
                asyncio.open_connection(self.host, self.port), timeout=DEFAULT_TIMEOUT
            )
        except asyncio.TimeoutError as exc:  # pragma: no cover - network failure
            raise ConnectionError("Timed out while connecting to TL1 endpoint") from exc

    async def disconnect(self) -> None:
        """Close the connection if it exists."""
        if self._writer is not None:
            self._writer.close()
            await self._writer.wait_closed()
        self._reader = None
        self._writer = None

    async def send_command(self, command: str) -> None:
        """Send a TL1 command ensuring proper termination."""
        if not command.endswith(";"):
            command = f"{command};"
        async with self._lock:
            writer = self._ensure_writer()
            writer.write(command.encode("ascii") + b"\r\n")
            await writer.drain()

    async def read_response(self) -> str:
        """Read a TL1 response line handling Telnet negotiation."""
        reader = self._ensure_reader()
        try:
            raw = await asyncio.wait_for(reader.readline(), timeout=DEFAULT_TIMEOUT)
        except asyncio.TimeoutError as exc:  # pragma: no cover - network failure
            raise TimeoutError("Timed out while waiting for TL1 response") from exc
        if not raw:
            raise ConnectionError("Connection closed by remote host")
        data = self._filter_telnet(raw) if self.use_telnet else raw
        return data.decode("ascii", errors="ignore").strip()

    def _ensure_reader(self) -> StreamReader:
        if self._reader is None:
            raise ConnectionError("TL1 transport is not connected")
        return self._reader

    def _ensure_writer(self) -> StreamWriter:
        if self._writer is None:
            raise ConnectionError("TL1 transport is not connected")
        return self._writer

    @staticmethod
    def _filter_telnet(data: bytes) -> bytes:
        """Strip Telnet negotiation sequences from the data stream."""
        if TELNET_IAC not in data:
            return data
        result = bytearray()
        skip = False
        i = 0
        while i < len(data):
            byte = data[i]
            if skip:
                skip = False
                i += 1
                continue
            if byte == TELNET_IAC and i + 1 < len(data):
                command = data[i + 1]
                if command in {TELNET_DO, TELNET_DONT, TELNET_WILL, TELNET_WONT}:
                    i += 3
                    continue
                if command == TELNET_IAC:
                    result.append(byte)
                    i += 2
                    continue
                skip = True
                i += 1
                continue
            result.append(byte)
            i += 1
        return bytes(result)
