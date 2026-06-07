#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';

const pluginDir = process.argv[2];
if (!pluginDir) {
  console.error('usage: patch-bundle.mjs <unzipped-plugin-dir>');
  process.exit(2);
}

const bundlePath = path.join(pluginDir, 'main.nodejs.js');
const sourceMapPath = path.join(pluginDir, 'main.nodejs.js.map');

function replaceOnce(source, from, to, label) {
  const count = source.split(from).length - 1;
  if (count !== 1) {
    throw new Error(`${label}: expected 1 match, found ${count}`);
  }
  return source.replace(from, to);
}

let bundle = fs.readFileSync(bundlePath, 'utf8');

const replacements = [
  {
    label: 'switchHttpSession channel',
    from: 'const e=this.getRtspChannel()||"1",r=this.httpStreamSwitcher.getCurrentSessionId();',
    to: 'const e=this.storage.getItem("twoWayAudioChannel")||"1",r=this.httpStreamSwitcher.getCurrentSessionId();',
  },
  {
    label: 'startIntercom codec channel',
    from: 'await this.stopRing(),r=this.getRtspChannel()||"1";try{n=await this.getClient().twoWayAudioCodec(r)}',
    to: 'await this.stopRing(),r=this.storage.getItem("twoWayAudioChannel")||"1";try{n=await this.getClient().twoWayAudioCodec(r)}',
  },
  {
    label: 'stopIntercom close channel',
    from: 'const e=this.getRtspChannel()||"1";try{await this.getClient().closeTwoWayAudio(e,t),',
    to: 'const e=this.storage.getItem("twoWayAudioChannel")||"1";try{await this.getClient().closeTwoWayAudio(e,t),',
  },
  {
    label: 'settings entry',
    from: 'return t.unshift({key:E,subgroup:"Advanced",title:"Provided devices",description:"Additional devices provided by this doorbell",value:r,choices:["Locks","Contact Sensors","Tamper Alert"],multiple:!0}),',
    to: 'return t.unshift({key:E,subgroup:"Advanced",title:"Provided devices",description:"Additional devices provided by this doorbell",value:r,choices:["Locks","Contact Sensors","Tamper Alert"],multiple:!0}),t.unshift({subgroup:"Advanced",key:"twoWayAudioChannel",title:"Two-way audio channel",description:"ISAPI TwoWayAudio channel id. Use 1 when the door station reports channel 1; keep RTSP video on its streaming channel.",value:this.storage.getItem("twoWayAudioChannel")||"1",type:"string"}),',
  },
];

for (const replacement of replacements) {
  bundle = replaceOnce(bundle, replacement.from, replacement.to, replacement.label);
}

fs.writeFileSync(bundlePath, bundle);

if (fs.existsSync(sourceMapPath)) {
  const sourceMap = JSON.parse(fs.readFileSync(sourceMapPath, 'utf8'));
  const mainSourceIndex = sourceMap.sources.findIndex((source) => source.endsWith('../src/main.ts'));

  if (mainSourceIndex >= 0 && sourceMap.sourcesContent?.[mainSourceIndex]) {
    let source = sourceMap.sourcesContent[mainSourceIndex];

    source = replaceOnce(
      source,
      '    private async switchHttpSession (initialSetup: boolean = false): Promise<HttpSession | null>',
      `    private getTwoWayAudioChannel(): string\n    {\n        return this.storage.getItem('twoWayAudioChannel') || '1';\n    }\n\n    private async switchHttpSession (initialSetup: boolean = false): Promise<HttpSession | null>`,
      'source helper insertion',
    );

    source = source.replaceAll(
      "this.getRtspChannel() || '1'",
      'this.getTwoWayAudioChannel()',
    );

    source = replaceOnce(
      source,
      `ret.unshift(\n            {\n                key: PROVIDED_DEVICES_KEY,`,
      `ret.unshift(\n            {\n                subgroup: 'Advanced',\n                key: 'twoWayAudioChannel',\n                title: 'Two-way audio channel',\n                description: 'ISAPI TwoWayAudio channel id. Commonly 1 even when RTSP video uses 101.',\n                value: this.storage.getItem('twoWayAudioChannel') || '1',\n                type: 'string',\n            },\n        );\n\n        ret.unshift(\n            {\n                key: PROVIDED_DEVICES_KEY,`,
      'source settings insertion',
    );

    sourceMap.sourcesContent[mainSourceIndex] = source;
    fs.writeFileSync(sourceMapPath, `${JSON.stringify(sourceMap)}\n`);
  }
}

console.log('patched Hikvision doorbell ISAPI two-way audio channel handling');

