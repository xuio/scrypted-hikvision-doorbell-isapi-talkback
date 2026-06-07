#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

SCRYPTED_HOST="${SCRYPTED_HOST:-${1:-}}"
PLUGIN_ZIP="${PLUGIN_ZIP:-$ROOT_DIR/dist/hikvision-doorbell-isapi-talkback-plugin.zip}"
REMOTE_TMP='/tmp/hikvision-doorbell-isapi-talkback-plugin.zip'

if [ -z "$SCRYPTED_HOST" ]; then
  echo "Set SCRYPTED_HOST or pass the host as the first argument." >&2
  exit 2
fi

if [ ! -f "$PLUGIN_ZIP" ]; then
  echo "Plugin zip not found: $PLUGIN_ZIP" >&2
  echo "Run: npm run build" >&2
  exit 2
fi

scp "$PLUGIN_ZIP" "$SCRYPTED_HOST:$REMOTE_TMP"

ssh "$SCRYPTED_HOST" "REMOTE_TMP='$REMOTE_TMP' bash -s" <<'REMOTE'
set -euo pipefail
TS="$(date -u +%Y%m%dT%H%M%SZ)"
BASE="$HOME/.scrypted/volume/plugins/@vityevato/hikvision-doorbell/zip"
ZIP_FILE="$(find "$BASE" -maxdepth 1 -type f -name "*.zip" | head -n 1)"
UNZIPPED_BACKUP="$BASE/unzipped.backup-before-isapi-talkback-$TS"
ZIP_BACKUP="$ZIP_FILE.backup-before-isapi-talkback-$TS"

cp -a "$BASE/unzipped" "$UNZIPPED_BACKUP"
cp -a "$ZIP_FILE" "$ZIP_BACKUP"

rm -rf "$BASE/unzipped.new"
mkdir -p "$BASE/unzipped.new"
unzip -q "$REMOTE_TMP" -d "$BASE/unzipped.new"

rm -rf "$BASE/unzipped"
mv "$BASE/unzipped.new" "$BASE/unzipped"
cp "$REMOTE_TMP" "$ZIP_FILE"

pkill -f "/Applications/Scrypted.app/Contents/MacOS/scrypted-electron" || true
sleep 4
open -a Scrypted
sleep 10

ps aux | grep "child @vityevato/hikvision-doorbell" | grep -v grep >/dev/null

printf 'unzipped_backup=%s\nzip_backup=%s\n' "$UNZIPPED_BACKUP" "$ZIP_BACKUP"
REMOTE
