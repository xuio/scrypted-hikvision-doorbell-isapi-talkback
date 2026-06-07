#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$ROOT_DIR/.build"
DIST_DIR="$ROOT_DIR/dist"
PACKAGE_DIR="$BUILD_DIR/package"
PLUGIN_DIR="$BUILD_DIR/plugin"

UPSTREAM_PACKAGE="${UPSTREAM_PACKAGE:-@vityevato/hikvision-doorbell}"
UPSTREAM_VERSION="${UPSTREAM_VERSION:-2.0.8}"
OUTPUT_ZIP="$DIST_DIR/hikvision-doorbell-isapi-talkback-plugin.zip"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR" "$DIST_DIR"

npm pack "${UPSTREAM_PACKAGE}@${UPSTREAM_VERSION}" --pack-destination "$BUILD_DIR" --json > "$BUILD_DIR/npm-pack.json"
TARBALL="$(node -e 'const fs = require("fs"); const p = JSON.parse(fs.readFileSync(process.argv[1], "utf8")); console.log(p[0].filename);' "$BUILD_DIR/npm-pack.json")"

tar -xzf "$BUILD_DIR/$TARBALL" -C "$BUILD_DIR"

mkdir -p "$PLUGIN_DIR"
unzip -q "$PACKAGE_DIR/dist/plugin.zip" -d "$PLUGIN_DIR"

node "$SCRIPT_DIR/patch-bundle.mjs" "$PLUGIN_DIR"
node "$SCRIPT_DIR/verify-bundle.mjs" "$PLUGIN_DIR"

rm -f "$OUTPUT_ZIP"
(
  cd "$PLUGIN_DIR"
  zip -qr "$OUTPUT_ZIP" .
)

node "$SCRIPT_DIR/verify-bundle.mjs" "$OUTPUT_ZIP"

echo "$OUTPUT_ZIP"

