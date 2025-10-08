# 1603 Assistant — Copilot Playbook (Do This Next)

## Ground Rules
- Data is the source of truth: `data/commands.json`, `data/playbooks.json`. Do NOT hardcode TL1 syntax.
- Tolerant builder: preserve optional `[ ... ]`; never fail if optionals are missing.
- Small PRs, clear commit messages referencing IDs below.

## Project Map
- Backend (FastAPI): `src/webapi/app.py`, `src/webapi/routers/*`, `src/webapi/services/*`
- Frontend (React/Vite): `webui/*`
- Data: `data/commands.json`, `data/playbooks.json`

## Definition of Done
1) Unit tests for backend where applicable
2) Function-level docstrings
3) UI wired to backend (if UI feature)
4) No new console errors
5) Update `README-dev.md` when behavior changes

## Checklist — Data Layer
**DL-01** Build TL1 catalog
- `scripts/build_commands_json.py` parses 1603 SM & 1603 SMX manuals → `data/commands.json` with fields:
  - `command`, `category`, `system` (["1603 SM","1603 SMX"]), `syntax`, `params` (with required flags), `description`
- Add JSON Schema `data/commands.schema.json` and validate in the script.
- Update `README-dev.md` with usage.

**DL-02** Playbooks schema + validation
- `data/playbooks.schema.json` + `scripts/validate_playbooks.py`.

## Checklist — Backend (FastAPI)
**BE-01** Routers + models
- Routers:
  - `src/webapi/routers/commands.py` → `GET /commands`
  - `src/webapi/routers/playbooks.py` → `GET /playbooks`
  - `src/webapi/routers/tl1.py` → `POST /build`, `POST /send`, `POST /log`
- Pydantic models in `src/webapi/models.py`. Mount routers in `app.py`.

**BE-02** TL1 builder (tolerant)
- `src/webapi/services/tl1_builder.py`:
  - Substitute `<AID>` / `<CTAG>` if provided
  - Preserve optional `[ ... ]`
  - Ensure trailing `;`
  - Minimal validation (don’t reject missing optionals)
- Tests in `tests/test_tl1_builder.py`.

**BE-03** Transport + logging
- `src/webapi/services/transport.py` best-effort receive/read.
- `/log` appends `{timestamp, command, response}` to `logs/YYYYMMDD.txt` and returns size.

## Checklist — Frontend (React/Vite)
**FE-01** Wizard UI
- `webui/src/components/Wizard.tsx`: System, Category, Command, inputs for AID/CTAG, optionals panel.
- Live syntax, **Preview** via `/build`.

**FE-02** Console + send
- Bottom console pane (always visible). On **Send**, call `/send`, print command/response, call `/log`.
- Simple search/filter for command list.

**FE-03** Polish
- Tabs: Retrieval, Provisioning, Loopback, Diagnostics, Perf Mon, Switching, Security.

## Checklist — Integration
**IN-01** SecureCRT stub (optional Windows)
- `send_tl1.ps1` logs and (optionally) invokes SecureCRT CLI if present. Document in `README-dev.md`.

## Checklist — Quality
**QA-01** Tests & CI
- Add pytest config and unit tests for builder.
- Workflow `.github/workflows/ci.yml` to run Python tests and `webui` build.

## Starting Prompts for Copilot Chat
1) “@workspace Implement DL-01 and DL-02 from `.github/copilot-playbook.md` (scripts, schemas, README updates).”
2) “@workspace Implement BE-01 and BE-02 (routers, models, tolerant builder + tests).”
3) “@workspace Implement FE-01 and FE-02 (Wizard, console, wire to `/build` & `/send`).”
4) “@workspace Implement BE-03 and QA-01 (transport read, `/log`, pytest, CI workflow).”

## Final Acceptance
- Backend: `uvicorn src.webapi.app:app --reload`
- Frontend: `npm run dev`
- Wizard → Preview → Send → Console shows response → `/log` grows
- Schemas validate; CI passes on PR
