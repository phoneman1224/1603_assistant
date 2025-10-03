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
