# 1603 Assistant — Copilot Playbook (Do This Next)

This playbook tells GitHub Copilot exactly what to implement, in what order, and how to judge success.
Use these prompts in **Copilot Chat** (VS Code) or GitHub.com Codespaces.

---

## Ground Rules
- **Data is the source of truth:** `data/commands.json`, `data/playbooks.json`. Do not hardcode TL1 syntax in code.
- **Tolerant builder:** Optional fields in `[ ... ]` must be preserved; never fail because optionals are missing.
- **Traceability:** Reference the checklist item you are completing in commit messages (e.g., `feat(builder): ... (#DL-01)`).
- **Small PRs:** Implement one checklist item per PR when possible.

---

## Project Map (authoritative)
- Backend (FastAPI): `src/webapi/app.py`, `src/webapi/routers/*`, `src/webapi/services/*`
- Frontend (React/Vite): `webui/*`
- Data: `data/commands.json`, `data/playbooks.json`
- Dev docs: `README-dev.md`
- Copilot guides: `.github/copilot-instructions.md`, `.github/copilot-overview.md`
- This file: `.github/copilot-playbook.md`

---

## Definition of Done (per feature)
1) Unit tests passing (where applicable)
2) Code documented at the function level
3) UI wired to backend (if UI feature)
4) No new console errors/warnings
5) Update `README-dev.md` when user-facing behavior changes

---

## Checklist — Data Layer
**ID DL-01** — Script to build the TL1 catalog  
- Create `scripts/build_commands_json.py` that parses our 1603 manuals (SM & SMX) and outputs `data/commands.json` (merged) with fields:
  - `command`, `category`, `system` (["1603 SM","1603 SMX"] as applicable), `syntax`, `params` (with required flags), `description`
- Provide a JSON Schema at `data/commands.schema.json` and validate output.
- Add `make build-data` (or `python scripts/build_commands_json.py`) instructions to `README-dev.md`.

**ID DL-02** — Playbook model & validation  
- Create `data/playbooks.schema.json` and a tiny validator script `scripts/validate_playbooks.py`.

**Copilot prompt:**  
> Implement DL-01 and DL-02 from `.github/copilot-playbook.md`. Create the scripts, schemas, and update `README-dev.md`. Include unit tests for the parser if feasible.

---

## Checklist — Backend (FastAPI)
**ID BE-01** — Router split & models  
- Move endpoints from `app.py` into routers:
  - `src/webapi/routers/commands.py` → GET `/commands`
  - `src/webapi/routers/playbooks.py` → GET `/playbooks`
  - `src/webapi/routers/tl1.py` → POST `/build`, POST `/send`, POST `/log`
- Add Pydantic models for inputs/outputs in `src/webapi/models.py`.
- Mount routers in `app.py`.

**ID BE-02** — TL1 builder (tolerant)  
- Implement `src/webapi/services/tl1_builder.py`:
  - Substitute `<AID>` and `<CTAG>` if provided
  - Preserve optional `[ ... ]` sections
  - Ensure trailing `;`
  - Do minimal validation; don’t reject missing optionals
- Unit tests in `tests/test_tl1_builder.py`.

**ID BE-03** — Transport & logging  
- In `src/webapi/services/transport.py`, add response receive/read (non-blocking best-effort).
- Implement `/log` to append `{timestamp, command, response}` to `logs/YYYYMMDD.txt` and return file size.

**Copilot prompt:**  
> Implement BE-01 to BE-03 per `.github/copilot-playbook.md`. Include Pydantic models, routers, and tests for the builder.

---

## Checklist — Frontend (React/Vite)
**ID FE-01** — Wizard UI  
- Create `webui/src/components/Wizard.tsx` with fields: System select, Category select, Command select, inputs for AID/CTAG, optionals panel.
- Show live syntax and a **Preview** area driven by `/build`.

**ID FE-02** — Console + send  
- Bottom console pane (always visible). When user clicks **Send**, call `/send`, print command and response to console, and call `/log`.
- Add basic filter/search box in the left command list.

**ID FE-03** — Visual polish  
- Add simple tabs (Retrieval, Provisioning, Loopback, Diagnostics, Perf Mon, Switching, Security).
- No external UI kit required; keep styles minimal.

**Copilot prompt:**  
> Implement FE-01 to FE-03 per `.github/copilot-playbook.md`. Wire to backend, ensure no console errors.

---

## Checklist — Integration
**ID IN-01** — SecureCRT stub (Windows optional)  
- Add `send_tl1.ps1` that writes command to a log and (optionally) invokes SecureCRT CLI if available. Document usage in `README-dev.md`.

**Copilot prompt:**  
> Implement IN-01 with a safe PowerShell stub and docs. Do not require SecureCRT to run by default.

---

## Checklist — Quality
**ID QA-01** — Tests & CI  
- Add `pytest` config and minimal tests for builder.
- Create GitHub Actions workflow `.github/workflows/ci.yml`:
  - Python: install, run unit tests
  - Frontend: `npm ci && npm run build`

**Copilot prompt:**  
> Implement QA-01. Add a CI that runs backend tests and builds the frontend.

---

## Sample Commit Messages
- `feat(builder): tolerant TL1 substitution and semicolon enforcement (#BE-02)`
- `feat(api): split routers and add models (#BE-01)`
- `feat(ui): add Wizard and bottom console (#FE-01 #FE-02)`
- `chore(data): add schemas and parsers (#DL-01 #DL-02)`
- `ci: add Python tests and web build (#QA-01)`

---

## Starting Prompts (paste these into Copilot Chat)
1) **Kickoff (data + backend):**  
   “@workspace Implement DL-01, DL-02, BE-01, and BE-02 from `.github/copilot-playbook.md`. Create scripts/schemas, routers/models, and the tolerant builder with tests.”

2) **UI pass:**  
   “@workspace Implement FE-01 and FE-02. Build `Wizard.tsx`, hook up `/build` and `/send`, and add a persistent bottom console.”

3) **Transport + logging + CI:**  
   “@workspace Implement BE-03 and QA-01. Improve transport read path, add `/log`, create pytest suite, and a CI workflow to run tests and build the web UI.”

---

## Acceptance Checklist (final)
- Run backend: `uvicorn src.webapi.app:app --reload`
- Run frontend: `npm run dev` (Vite)
- Select command → fill fields → **Build** → preview → **Send** → see response in console → **Log** grows
- Data schemas validate; CI passes on PR

