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
"$PY" "$ROOT/src/entrypoint.py" --validate
EOF
chmod +x "$SCRIPTS/validate.sh"

# --- scripts/linux_bootstrap.sh
write "$SCRIPTS/linux_bootstrap.sh" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.."; pwd)"

echo "[bootstrap] Creating venv…"
python3 -m venv "$ROOT/.venv"
source "$ROOT/.venv/bin/activate"
pip install --upgrade pip
pip install jsonschema==4.22.0

echo "[bootstrap] Done."
EOF
chmod +x "$SCRIPTS/linux_bootstrap.sh"

# --- scripts/make_release.sh
write "$SCRIPTS/make_release.sh" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.."; pwd)"
STAMP=$(date +%Y%m%d-%H%M%S)
OUT="$ROOT/dist/1603_assistant-$STAMP.zip"

echo "[release] Packaging to $OUT"
cd "$ROOT"
zip -r "$OUT" . -x '*.venv*' -x '__pycache__/*'
EOF
chmod +x "$SCRIPTS/make_release.sh"

# --- scripts/sync_to_github.sh
write "$SCRIPTS/sync_to_github.sh" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.."; pwd)"

REMOTE="git@github.com:phoneman1224/1603_assistant.git"

cd "$ROOT"
git init
git remote remove origin 2>/dev/null || true
git remote add origin "$REMOTE"
git add .
git commit -m "Sync update $(date +%F-%T)" || true
git branch -M main
git push -u origin main
EOF
chmod +x "$SCRIPTS/sync_to_github.sh"

# --- Windows bootstrap helpers
write "$ROOT/windows_bootstrap.ps1" <<'EOF'
Write-Host "[bootstrap] Setting up Python venv..."
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install --upgrade pip
pip install jsonschema==4.22.0
Write-Host "[bootstrap] Done."
EOF

write "$ROOT/windows_bootstrap.cmd" <<'EOF'
@echo off
echo [bootstrap] Setting up Python venv...
python -m venv .venv
call .venv\Scripts\activate.bat
pip install --upgrade pip
pip install jsonschema==4.22.0
echo [bootstrap] Done.
EOF

echo "[2/3] Scripts written."
echo "[3/3] Next steps:"
echo "  scripts/linux_bootstrap.sh   # create venv + deps"
echo "  scripts/validate.sh          # validate all catalogs"
echo "  scripts/make_release.sh      # build release ZIP"
echo "  scripts/sync_to_github.sh    # push to GitHub"
