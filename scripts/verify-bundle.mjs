#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';

const target = process.argv[2];
if (!target) {
  console.error('usage: verify-bundle.mjs <unzipped-plugin-dir-or-plugin.zip>');
  process.exit(2);
}

function readBundle(targetPath) {
  const stat = fs.statSync(targetPath);
  if (stat.isDirectory()) {
    return fs.readFileSync(path.join(targetPath, 'main.nodejs.js'), 'utf8');
  }

  return execFileSync('unzip', ['-p', targetPath, 'main.nodejs.js'], {
    encoding: 'utf8',
    maxBuffer: 8 * 1024 * 1024,
  });
}

const bundle = readBundle(target);

const counts = {
  twoWayAudioChannel: bundle.split('twoWayAudioChannel').length - 1,
  twoWayAudioStorageReads: bundle.split('this.storage.getItem("twoWayAudioChannel")||"1"').length - 1,
  startIntercomRtspChannel: bundle.split('r=this.getRtspChannel()||"1"').length - 1,
  patchedStartIntercomChannel: bundle.split('r=this.storage.getItem("twoWayAudioChannel")||"1"').length - 1,
  patchedCloseChannel: bundle.split('const e=this.storage.getItem("twoWayAudioChannel")||"1"').length - 1,
};

const expectations = [
  ['twoWayAudioChannel', counts.twoWayAudioChannel >= 5],
  ['twoWayAudioStorageReads', counts.twoWayAudioStorageReads === 4],
  ['startIntercomRtspChannel', counts.startIntercomRtspChannel === 0],
  ['patchedStartIntercomChannel', counts.patchedStartIntercomChannel === 1],
  ['patchedCloseChannel', counts.patchedCloseChannel === 2],
];

const failed = expectations.filter(([, ok]) => !ok);
if (failed.length) {
  console.error(JSON.stringify(counts, null, 2));
  throw new Error(`bundle verification failed: ${failed.map(([name]) => name).join(', ')}`);
}

console.log(`bundle verification OK: ${JSON.stringify(counts)}`);

