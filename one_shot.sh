#!/usr/bin/env bash
set -euo pipefail

# --- basics ---
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "$REPO_ROOT" ] || { echo "[ERR] Not inside a git repo."; exit 2; }
cd "$REPO_ROOT"
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
ts="$(date +%Y-%m-%dT%H:%M:%S)"

# --- remote check ---
if ! git remote get-url origin >/dev/null 2>&1; then
  echo "[ERR] No 'origin' remote set. Example:"
  echo "      git remote add origin https://github.com/<you>/<repo>.git"
  exit 3
fi

# --- write files (no colors, no tricks) ---
mkdir -p .github

cat > README-dev.md <<'MD'
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
MD

cat > .github/copilot-instructions.md <<'MD'
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
MD

cat > .github/copilot-overview.md <<'MD'
# 1603 Assistant — Full Design Brief

## Vision
TL1 Command Builder for Alcatel/Nokia 1603 SM & 1603 SMX.

## Goals
- System select → Category → Command → Wizard → Preview → Send/Log
- SecureCRT send (optional), local socket send, persistent console

## Stack
- Backend: FastAPI
- Frontend: React + Vite + TypeScript
- Data: `data/commands.json`, `data/playbooks.json`

## Priorities
1) Data ingestion from manuals → JSON
2) Tolerant builder (<AID>, <CTAG>, optional [PARAMS])
3) Endpoints: /commands /playbooks /build /send (/log later)
4) UI wizard + console
5) Logging + SecureCRT integration
6) Tests & mock device
MD

cat > .github/copilot-tasks.md <<'MD'
# Copilot Task Index

## Data
- [ ] scripts/build_commands_json.py (parse manuals → JSON)
- [ ] Validate schema; merge SM/SMX via "system" field

## Backend
- [ ] Split routers: commands.py, playbooks.py, tl1.py
- [ ] /log endpoint (append to logs/YYYYMMDD.txt)
- [ ] Better error handling & models

## Frontend
- [ ] Wizard component (webui/src/components/Wizard.tsx)
- [ ] Category tabs + search
- [ ] Persistent bottom console
- [ ] Integrate /send response stream

## Integration
- [ ] send_tl1.ps1 for SecureCRT
- [ ] Local file logging

## Quality
- [ ] pytest for builder/transport
- [ ] Mock TL1 device for tests
- [ ] Keep README-dev updated
MD

cat > TODO.md <<'MD'
# Roadmap / TODO

- Ingest full TL1 catalog into data/commands.json
- Expand builder (all param types; preserve [ ] optionals)
- SecureCRT send + local logging
- Persistent console with history
- Playbooks: troubleshooting + provisioning (all scenarios)
- Category rules:
  - System: ALW/INH/SET/ABT/CONFIG/CPY
  - Alarms: ALM/COND
  - Retrieve: RTRV
  - Troubleshooting: CONN/DGN/DISC/OPR/RLS/RD/TST/SW/CHG-ACCMD-T1
  - Provisioning: ED/ENT/RMV/RST/DLT
- Unit tests + mock responses
MD

# sample data placeholders if missing
mkdir -p data
[ -f data/commands.json ]   || echo '[]'  > data/commands.json
[ -f data/playbooks.json ]  || echo '{}'  > data/playbooks.json

# gitignore hygiene
touch .gitignore
for l in ".venv/" "node_modules/" "webui/dist/" ".DS_Store" "*.bak-*"; do
  grep -qxF "$l" .gitignore || echo "$l" >> .gitignore
done

# --- commit & push ---
git add -A
if git diff --cached --quiet; then
  echo "[INFO] No changes to commit."
else
  git commit -m "Docs: add Copilot overview, tasks, instructions, README-dev, TODO"
fi

# set upstream if missing
if git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
  git push
else
  git push -u origin "$BRANCH"
fi

# --- verify ---
git fetch origin "$BRANCH" >/dev/null 2>&1 || true
LOCAL_HEAD="$(git rev-parse "$BRANCH")"
REMOTE_HEAD="$(git ls-remote --heads origin "$BRANCH" | awk '{print $1}')"

echo "Local HEAD : $LOCAL_HEAD"
echo "Remote HEAD: $REMOTE_HEAD"

for f in README-dev.md .github/copilot-instructions.md .github/copilot-overview.md .github/copilot-tasks.md TODO.md; do
  [ -f "$f" ] || { echo "[ERR] missing: $f"; exit 5; }
done

if [ -n "$REMOTE_HEAD" ] && [ "$REMOTE_HEAD" = "$LOCAL_HEAD" ]; then
  echo "[OK] Verified: latest commit is on GitHub."
  REPO_PATH="$(git remote get-url origin | sed -E 's#.*github.com[/:]##; s#\.git$##')"
  echo "Open: https://github.com/$REPO_PATH"
  exit 0
else
  echo "[WARN] Verification incomplete."
  echo "Run: git status; git log -3 --oneline; git ls-remote --heads origin $BRANCH"
  exit 6
fi
