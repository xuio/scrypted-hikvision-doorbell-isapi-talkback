# Operations

## Build

```sh
npm run build
```

This produces:

```text
dist/hikvision-doorbell-isapi-talkback-plugin.zip
```

## Deploy

```sh
SCRYPTED_HOST=scrypted-mac.local ./scripts/deploy-macos.sh
```

The script stores timestamped backups under the installed Scrypted plugin
directory before replacing anything.

## Rollback

On the Scrypted host, restore the backed-up directory and zip:

```sh
BASE="$HOME/.scrypted/volume/plugins/@vityevato/hikvision-doorbell/zip"
rm -rf "$BASE/unzipped"
cp -a "$BASE/unzipped.backup-before-isapi-talkback-YYYYMMDDTHHMMSSZ" "$BASE/unzipped"
cp -a "$BASE/1-....zip.backup-before-isapi-talkback-YYYYMMDDTHHMMSSZ" "$BASE/1-....zip"
pkill -f "/Applications/Scrypted.app/Contents/MacOS/scrypted-electron" || true
open -a Scrypted
```

Use the exact backup paths printed by `deploy-macos.sh`.

## Pinning

```sh
SCRYPTED_HOST=scrypted-mac.local ./scripts/pin-macos-metadata.sh
```

The pin script:

- backs up Scrypted's LevelDB directory
- stops Scrypted to release the LevelDB lock
- changes only `Plugin/@vityevato/hikvision-doorbell.packageJson.version`
- restarts Scrypted

Default pin version:

```text
9999.0.0
```

To unpin, restore the database backup printed by the pin script or set the plugin
metadata version back to the upstream version.
