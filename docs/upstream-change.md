# Upstreamable Change

The source-level change should be small:

1. Add a helper on the doorbell camera class:

```ts
private getTwoWayAudioChannel(): string {
    return this.storage.getItem('twoWayAudioChannel') || '1';
}
```

2. Add an advanced Scrypted setting:

```ts
{
    subgroup: 'Advanced',
    key: 'twoWayAudioChannel',
    title: 'Two-way audio channel',
    description: 'ISAPI TwoWayAudio channel id. Commonly 1 even when RTSP video uses 101.',
    value: this.storage.getItem('twoWayAudioChannel') || '1',
    type: 'string',
}
```

3. Use that channel for the HTTP/ISAPI intercom paths:

```ts
const channel = this.getTwoWayAudioChannel();
```

instead of:

```ts
const channel = this.getRtspChannel() || '1';
```

Affected methods:

- `switchHttpSession`
- `startIntercom`
- `stopIntercom`
- HTTP cleanup/error cleanup that calls `closeTwoWayAudio`

The change should not reconfigure SIP, Standard SIP/PBX mode, RTSP channels,
HomeKit pairing, or Hikvision indoor-station relationships.

