# TL1 Assistant

This repository hosts the foundations of the TL1 Assistant project. The initial scaffold includes:

- Asynchronous TCP/Telnet transport client.
- Local TL1 simulator for offline testing.
- Structured logging utilities.
- Configuration management storing user preferences in the local application data folder.
- Minimal PySide6 GUI with connect and command console.
- PowerShell helper scripts for building the executable and running the simulator.

## Development

Create a virtual environment and install dependencies listed in `pyproject.toml` (to be added in future phases). Run the UI with:

```bash
python -m ui.app
```

Launch the simulator in another shell:

```powershell
pwsh scripts/run_simulator.ps1
```

Build a standalone executable once PyInstaller configuration is complete:

```powershell
pwsh scripts/build_exe.ps1
```
