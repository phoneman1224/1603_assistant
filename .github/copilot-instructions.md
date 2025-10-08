# Copilot Hints

- Data is the source of truth: `data/commands.json`, `data/playbooks.json`.
- Backend (FastAPI) lives under `src/webapi`.
- Add routers under `src/webapi/routers/` as app grows.
- Endpoints:
  - GET /commands, GET /playbooks
  - POST /build { command, aid?, ctag?, raw? }
  - POST /send  { host, port, command }
- TL1 builder must tolerate optional `[ ]`; never hard-fail when optionals are omitted.
- Frontend: React + Vite in `webui/` (Axios for HTTP). API base `http://127.0.0.1:8000`.

Refer to `.github/copilot-overview.md` and `.github/copilot-tasks.md` for full guidance.
