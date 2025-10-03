#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$HOME/1603_assistant"
SCRIPTS="$ROOT/scripts"
DIST="$ROOT/dist"
mkdir -p "$SCRIPTS" "$DIST"

write() { mkdir -p "$(dirname "$1")"; cat > "$1"; echo "  -> wrote $1"; }

echo "[1/3] Writing helper scripts…"

# --- scripts/validate.sh
write "$SCRIPTS/validate.sh" <<'EOF'
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
EOF
chmod +x "$SCRIPTS/validate.sh"

# --- scripts/linux_bootstrap.sh
write "$SCRIPTS/linux_bootstrap.sh" <<'EOF'
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
EOF
chmod +x "$SCRIPTS/linux_bootstrap.sh"

# --- scripts/make_release.sh
write "$SCRIPTS/make_release.sh" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.."; pwd)"
DIST="$ROOT/dist"
NAME="1603_assistant-$(date +%Y%m%d-%H%M%S)"
TMP="$(mktemp -d)"

mkdir -p "$DIST"
rsync -a --exclude '.venv' --exclude '__pycache__' --exclude '.git' "$ROOT/" "$TMP/$NAME/"
( cd "$TMP" && zip -qr "$DIST/$NAME.zip" "$NAME" )
rm -rf "$TMP"
echo "[release] Wrote: $DIST/$NAME.zip"
EOF
chmod +x "$SCRIPTS/make_release.sh"

# --- scripts/sync_to_github.sh
write "$SCRIPTS/sync_to_github.sh" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.."; pwd)"
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <git_remote_url>"
  exit 1
fi
REMOTE="$1"
cd "$ROOT"
[[ -d .git ]] || { git init; git branch -m main || true; }
[[ -f .gitignore ]] || cat > .gitignore <<GIT
.venv/
__pycache__/
*.pyc
dist/
logs/
GIT
[[ -f .gitattributes ]] || cat > .gitattributes <<GITA
* text=auto
*.sh text eol=lf
*.py text eol=lf
*.json text eol=lf
*.md text eol=lf
GITA
git add .
git commit -m "Initial: catalogs, schemas, validators, scripts" || true
git remote remove origin >/dev/null 2>&1 || true
git remote add origin "$REMOTE"
git push -u origin main
echo "[git] Pushed to $REMOTE"
EOF
chmod +x "$SCRIPTS/sync_to_github.sh"

# --- windows_bootstrap.ps1 (works with Python 3.13.7)
write "$ROOT/windows_bootstrap.ps1" <<'EOF'
$ErrorActionPreference = "Stop"
$ROOT = Split-Path -Parent $MyInvocation.MyCommand.Path
$venvPy = Join-Path $ROOT ".venv\Scripts\python.exe"
$sysPy = "python"
try {
  & $sysPy -m venv (Join-Path $ROOT ".venv")
  & $venvPy -m pip install --upgrade pip
  & $venvPy -m pip install jsonschema==4.22.0
  $py = $venvPy
} catch {
  Write-Warning "Venv failed; using system Python."
  $py = $sysPy
}
& $py (Join-Path $ROOT "src\entrypoint.py") --validate
& $py (Join-Path $ROOT "src\entrypoint.py") --catalog tl1 --find RTRV-ATTR-T1
& $py (Join-Path $ROOT "src\entrypoint.py") --catalog tap --find TAP-047
& $py (Join-Path $ROOT "src\entrypoint.py") --catalog dlp --find DLP-203
& $py (Join-Path $ROOT "src\entrypoint.py") --parse (Join-Path $ROOT "tests\vectors\discovery\RTRV-HDR_basic\raw.txt")
Write-Host "[bootstrap] Done."
EOF

# --- windows_bootstrap.cmd
write "$ROOT/windows_bootstrap.cmd" <<'EOF'
@echo off
setlocal
set PS1=%~dp0windows_bootstrap.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
endlocal
EOF

echo "[2/3] Quick run: validate now (uses venv if present)…"
bash "$SCRIPTS/linux_bootstrap.sh" || true

echo "[3/3] Build a distributable ZIP…"
bash "$SCRIPTS/make_release.sh"

cat <<'NEXT'
-------------------------------------------
Scripts installed.

Run next:
  # Validate again any time
  scripts/validate.sh

  # Make another ZIP
  scripts/make_release.sh

  # Push to GitHub (replace URL)
  scripts/sync_to_github.sh git@github.com:<YOU>/1603_assistant.git

Windows:
  - After you push, download ZIP on Windows and run:
    windows_bootstrap.cmd
-------------------------------------------
NEXT
