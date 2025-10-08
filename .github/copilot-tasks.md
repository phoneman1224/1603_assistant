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
