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
