# 1603 Assistant — Developer Notes

## Layout
- `data/commands.json`, `data/playbooks.json` — TL1 command catalog + playbooks
- `src/webapi/app.py` (+ `services/`) — FastAPI backend
- `webui/` — Vite + React + TypeScript web UI

## API
- `GET /health` → `{ "status": "ok" }`
- `GET /commands` → list of command objects
- `GET /playbooks` → playbook scenarios
- `POST /build` → `{ "command": "<built TL1>" }`
- `POST /send` → `{ "ok": true, "response": "<raw device reply>" }`

## TL1 Builder Rules (forgiving)
- Substitute `<AID>` and `<CTAG>` if provided
- Preserve optional `[ ... ]` when present
- Ensure trailing `;`
- Do not reject missing optionals

## Quick run (dev)

### Backend
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn src.webapi.app:app --reload    # http://127.0.0.1:8000

### Frontend
cd webui
npm install
npm run dev                            # http://127.0.0.1:5173
