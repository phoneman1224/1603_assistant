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
