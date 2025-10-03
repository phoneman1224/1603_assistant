#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.."; pwd)"
PY="$ROOT/.venv/bin/python"
[[ -x "$PY" ]] || PY="$(command -v python3)"

echo "[validate] Using Python: $PY"
$PY "$ROOT/src/entrypoint.py" --validate || true
$PY "$ROOT/src/entrypoint.py" --catalog tl1 --find RTRV-ATTR-T1 || true
$PY "$ROOT/src/entrypoint.py" --catalog tap --find TAP-047 || true
$PY "$ROOT/src/entrypoint.py" --catalog dlp --find DLP-203 || true
$PY "$ROOT/src/entrypoint.py" --parse "$ROOT/tests/vectors/discovery/RTRV-HDR_basic/raw.txt" || true
echo "[validate] Done."
