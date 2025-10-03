#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.."; pwd)"

if command -v python3 >/dev/null 2>&1 && python3 -m venv --help >/dev/null 2>&1; then
  echo "[bootstrap] Creating venv…"
  python3 -m venv "$ROOT/.venv" || true
  if [[ -x "$ROOT/.venv/bin/pip" ]]; then
    "$ROOT/.venv/bin/pip" -q install --upgrade pip
    "$ROOT/.venv/bin/pip" -q install jsonschema==4.22.0
  else
    echo "[bootstrap] venv ensurepip missing; using system Python."
  fi
else
  echo "[bootstrap] No venv module; using system Python."
fi

exec "$ROOT/scripts/validate.sh"
