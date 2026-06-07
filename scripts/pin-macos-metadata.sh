#!/usr/bin/env bash
set -euo pipefail

SCRYPTED_HOST="${SCRYPTED_HOST:-${1:-}}"
PIN_VERSION="${PIN_VERSION:-9999.0.0}"

if [ -z "$SCRYPTED_HOST" ]; then
  echo "Set SCRYPTED_HOST or pass the host as the first argument." >&2
  exit 2
fi

ssh "$SCRYPTED_HOST" "PIN_VERSION='$PIN_VERSION' bash -s" <<'REMOTE'
set -euo pipefail
TS="$(date -u +%Y%m%dT%H%M%SZ)"
DB="$HOME/.scrypted/volume/scrypted.db"
BACKUP="$HOME/.scrypted/volume/scrypted.db.backup-before-hikvision-pin-$TS"

cp -a "$DB" "$BACKUP"

pkill -f "/Applications/Scrypted.app/Contents/MacOS/scrypted-electron" || true
sleep 5

cd /Applications/Scrypted.app/Contents/Resources/app
ELECTRON_RUN_AS_NODE=1 /Applications/Scrypted.app/Contents/MacOS/scrypted-electron <<'JS'
const { Level } = require('level');
const path = require('path');

const key = 'Plugin/@vityevato/hikvision-doorbell';
const pinnedVersion = process.env.PIN_VERSION;
const dbPath = path.join(process.env.HOME, '.scrypted/volume/scrypted.db');

(async () => {
  const db = new Level(dbPath, { valueEncoding: 'utf8' });
  await db.open();
  const raw = await db.get(key);
  const plugin = JSON.parse(raw);

  if (!plugin?.packageJson || plugin.packageJson.name !== '@vityevato/hikvision-doorbell') {
    throw new Error(`Unexpected plugin metadata at ${key}`);
  }

  const oldVersion = plugin.packageJson.version;
  plugin.packageJson.version = pinnedVersion;
  plugin.packageJson.description = 'Hikvision Doorbell Plugin for Scrypted (local ISAPI talkback patch pinned)';
  plugin.packageJson.scrypted = plugin.packageJson.scrypted || {};
  plugin.packageJson.scrypted.name = 'Hikvision Doorbell Plugin (Pinned ISAPI Talkback)';

  await db.put(key, JSON.stringify(plugin));
  await db.close();

  console.log(JSON.stringify({ key, oldVersion, pinnedVersion }));
})().catch(e => {
  console.error(e);
  process.exit(1);
});
JS

open -a Scrypted
sleep 12
ps aux | grep "child @vityevato/hikvision-doorbell" | grep -v grep >/dev/null

printf 'db_backup=%s\n' "$BACKUP"
REMOTE
