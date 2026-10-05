#!/usr/bin/env node
// Writes the offline service worker (offline.js + flutter_service_worker.js)
// into a built Flutter web directory, with a fresh cache name and the full
// precache file list. Used by scripts/flutter-build.mjs and tools/cf-build.sh.
import { readdirSync, readFileSync, statSync, writeFileSync, existsSync } from "node:fs";
import { join, relative, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";

const here = fileURLToPath(new URL(".", import.meta.url));
const defaultApp = resolve(here, "..", "khmer_calendar");

function walkFiles(dir, base = dir, out = []) {
  if (!existsSync(dir)) return out;
  for (const name of readdirSync(dir)) {
    if (name.startsWith(".")) continue;
    const p = join(dir, name);
    if (statSync(p).isDirectory()) {
      walkFiles(p, base, out);
      continue;
    }
    const rel = "./" + relative(base, p).split(sep).join("/");
    if (rel.endsWith(".map")) continue;
    if (rel.includes("/weather/")) continue;
    out.push(rel);
  }
  return out;
}

export function writeOfflineWorker(siteDir, app = defaultApp) {
  const template = readFileSync(join(app, "web/offline.js"), "utf8");
  const files = walkFiles(siteDir);
  const stamp = Date.now();
  const injected = template
    .replace(/const CACHE = '[^']+';/, `const CACHE = 'khmer-calendar-web-${stamp}';`)
    .replace(/const PRECACHE = \[[\s\S]*?\];/, `const PRECACHE = ${JSON.stringify(files, null, 2)};`);
  writeFileSync(join(siteDir, "offline.js"), injected);
  writeFileSync(join(siteDir, "flutter_service_worker.js"), injected);
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const dir = process.argv[2];
  if (!dir) {
    console.error("usage: node scripts/offline-worker.mjs <built-web-dir>");
    process.exit(1);
  }
  writeOfflineWorker(resolve(dir));
  console.log("Offline worker written to", resolve(dir));
}
