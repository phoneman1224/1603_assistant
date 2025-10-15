"""Minimal PySide6 application entry point."""

from __future__ import annotations

import asyncio
import sys
import threading

from PySide6 import QtCore, QtWidgets

from tl1_core import AppConfig, SessionLogger, TL1Transport


class MainWindow(QtWidgets.QMainWindow):
    """Basic TL1 Assistant window with connect and console widgets."""

    def __init__(self) -> None:
        super().__init__()
        self.setWindowTitle("TL1 Assistant")
        self.resize(800, 600)

        self.config = AppConfig.load()
        self.logger = SessionLogger()
        self.transport = TL1Transport(self.config.host, self.config.port)
        self.loop = asyncio.new_event_loop()
        self._loop_thread = threading.Thread(target=self._run_loop, daemon=True)
        self._loop_thread.start()

        self.console = QtWidgets.QPlainTextEdit(readOnly=True)
        self.command_input = QtWidgets.QLineEdit()
        self.connect_button = QtWidgets.QPushButton("Connect")
        self.send_button = QtWidgets.QPushButton("Send")

        self._setup_layout()
        self._connect_signals()

    def _setup_layout(self) -> None:
        central = QtWidgets.QWidget()
        self.setCentralWidget(central)

        layout = QtWidgets.QVBoxLayout(central)
        layout.addWidget(self.console)

        form_layout = QtWidgets.QHBoxLayout()
        form_layout.addWidget(self.command_input)
        form_layout.addWidget(self.send_button)
        layout.addLayout(form_layout)
        layout.addWidget(self.connect_button)

    def _connect_signals(self) -> None:
        self.connect_button.clicked.connect(self._on_connect_clicked)  # type: ignore[arg-type]
        self.send_button.clicked.connect(self._on_send_clicked)  # type: ignore[arg-type]

    def append_console(self, message: str) -> None:
        self.console.appendPlainText(message)

    def _post_message(self, message: str) -> None:
        QtCore.QTimer.singleShot(0, lambda: self.append_console(message))

    def _run_loop(self) -> None:
        asyncio.set_event_loop(self.loop)
        self.loop.run_forever()

    def _on_connect_clicked(self) -> None:
        asyncio.run_coroutine_threadsafe(self._async_connect(), self.loop)

    def _on_send_clicked(self) -> None:
        command = self.command_input.text().strip()
        if not command:
            return
        self.command_input.clear()
        asyncio.run_coroutine_threadsafe(self._async_send(command), self.loop)

    async def _async_connect(self) -> None:
        self._post_message("Connecting...")
        try:
            await self.transport.connect()
        except Exception as exc:  # pragma: no cover - UI feedback
            self._post_message(f"Connection failed: {exc}")
            return
        self._post_message("Connected")
        self.logger.write("connect", host=self.config.host, port=self.config.port)
        asyncio.run_coroutine_threadsafe(self._read_loop(), self.loop)

    async def _async_send(self, command: str) -> None:
        self._post_message(f"TX: {command}")
        self.logger.write("send", command=command)
        try:
            await self.transport.send_command(command)
        except Exception as exc:  # pragma: no cover - UI feedback
            self._post_message(f"Send failed: {exc}")

    async def _read_loop(self) -> None:
        while True:
            try:
                response = await self.transport.read_response()
            except Exception as exc:  # pragma: no cover - UI feedback
                self._post_message(f"RX error: {exc}")
                break
            self._post_message(f"RX: {response}")
            self.logger.write("receive", response=response)

    def closeEvent(self, event) -> None:  # type: ignore[override]
        self.logger.close()
        if self.loop.is_running():
            self.loop.call_soon_threadsafe(self.loop.stop)
            self._loop_thread.join(timeout=1)
        return super().closeEvent(event)


def main() -> None:
    """Launch the Qt event loop."""
    app = QtWidgets.QApplication(sys.argv)
    window = MainWindow()
    window.show()
    sys.exit(app.exec())


if __name__ == "__main__":  # pragma: no cover - entry point
    main()
