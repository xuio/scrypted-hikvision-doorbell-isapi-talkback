# Scrypted Hikvision Doorbell ISAPI Talkback Patch

This repository builds a patched Scrypted plugin bundle for Hikvision and Metzler
video doorbells where:

- video uses an RTSP stream channel such as `101`
- ISAPI two-way audio uses a separate `TwoWayAudio` channel such as `1`
- the native Hikvision indoor station must keep working
- HomeKit/Scrypted talkback should work without switching the Hikvision system to
  standard SIP/PBX mode

The upstream npm package already contains an ISAPI/HTTP talkback implementation,
but it reuses the RTSP channel for ISAPI two-way audio. On some Hikvision door
stations this makes talkback fail because `/ISAPI/System/TwoWayAudio/channels/1`
is valid while `/ISAPI/System/TwoWayAudio/channels/101` is not.

This patch keeps the original plugin id and device model, and only adds a separate
`twoWayAudioChannel` setting that defaults to `1`.

## Status

Validated on a Scrypted macOS installation with:

- door station ISAPI channel: `1`
- door station two-way audio codec: `G.711ulaw`
- Scrypted RTSP video channel: `101`
- native Hikvision indoor station preserved
- HomeKit doorbell ring preserved
- HomeKit talkback working over ISAPI

## Quick Start

Build the patched plugin zip:

```sh
npm run build
```

Output:

```text
dist/hikvision-doorbell-isapi-talkback-plugin.zip
```

The build script downloads `@vityevato/hikvision-doorbell@2.0.8` from npm,
extracts its `dist/plugin.zip`, applies the patch, verifies the result, and writes
a patched zip. The original npm tarball and generated plugin zip are not committed.

## Deploy To A macOS Scrypted Host

Set `SCRYPTED_HOST` to your Mac running Scrypted:

```sh
SCRYPTED_HOST=scrypted-mac.local ./scripts/deploy-macos.sh
```

The deploy script:

- backs up the installed unzipped plugin directory
- backs up the installed plugin zip
- replaces both with the patched bundle
- restarts Scrypted so the plugin loads the patched code

After deployment, set or confirm the doorbell settings in Scrypted:

- `SIP Mode`: `Don't Use SIP`
- `Two-way audio channel`: `1`
- RTSP channel remains whatever your camera uses, commonly `101`

## Optional Pin

Scrypted's built-in plugin updater checks npm `latest` against the installed
plugin metadata version. If a newer upstream version appears, Scrypted can replace
the patched bundle.

On a macOS Scrypted host, this repository can pin the installed plugin metadata to
a high local version:

```sh
SCRYPTED_HOST=scrypted-mac.local ./scripts/pin-macos-metadata.sh
```

The default pin version is `9999.0.0`. This keeps the plugin id unchanged, preserves
HomeKit identity, and prevents the updater from treating npm releases as newer.

## What Changes

The patch updates only the doorbell plugin's ISAPI intercom path:

- `twoWayAudioCodec(channel)`
- `openTwoWayAudio(channel, stream)`
- `closeTwoWayAudio(channel, sessionId)`
- HTTP/ISAPI intercom cleanup paths

These now use:

```text
storage["twoWayAudioChannel"] || "1"
```

instead of:

```text
getRtspChannel() || "1"
```

Video, snapshots, doorbell events, lock handling, SIP settings, and native
Hikvision indoor-station configuration are not intentionally changed.

## Attribution

This repository builds on the npm package:

- package: `@vityevato/hikvision-doorbell`
- version: `2.0.8`
- author: Roman Sokolov
- license: Apache

The original package is not distributed in this repository. The build script
downloads it from npm and applies a narrow local patch.

This project is not affiliated with Hikvision, Metzler, Scrypted, or the original
plugin author.

## License

Apache-2.0. See [LICENSE](LICENSE).
