# 1603 Assistant — Developer Notes

## Layout
- `data/commands.json`, `data/playbooks.json` — TL1 command catalog + playbooks
- `src/webapi/app.py` (+ `services/`) — FastAPI backend
- `webui/` — Vite + React + TypeScript web UI

## API
- GET `/health` → `{ "status": "ok" }`
- GET `/commands` → list of command objects
- GET `/playbooks` → playbook scenarios
- POST `/build` → `{ command: "<built TL1>" }`
- POST `/send` → `{ ok: true, response: "<raw device reply>" }` (socket stub)

## TL1 Builder Rules (forgiving)
- `<AID>` and `<CTAG>` are substituted if provided
- Optional fields in `[brackets]` are preserved if passed raw
- Ensures trailing `;` if missing

## Quick run (dev)

### Backend
```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn src.webapi.app:app --reload    # http://127.0.0.1:8000

cd webui
npm install
npm run dev                            # http://127.0.0.1:5173


---

### 3) Add Copilot hints (optional, recommended)
```bash
mkdir -p .github
cat > .github/copilot-instructions.md <<'MD'
# Copilot Hints
- Treat `data/commands.json` and `data/playbooks.json` as the source of truth.
- Backend lives under `src/webapi`; add routers under `src/webapi/routers` as needed.
- Web UI uses React + Vite in `webui/`. Prefer Axios for API calls.
- Endpoints to use:
  - GET /commands, GET /playbooks
  - POST /build (payload: { command, aid?, ctag?, raw? })
  - POST /send (payload: { host, port, command })
- TL1 builder must be tolerant of optional `[ ]` sections; do not hard-fail on missing optionals.
