/**
 * Builds datasets/i18n/<locale>/dive-signals.json from the Dive Kit app's
 * assets/locales/<locale>/signals.json, and reports every id that does not match.
 *
 * Signal key `hand.fishId.smallCreature` -> id `hand-fish-id-small-creature`.
 * Checklists are not imported: datasets/checklists.json and datasets/i18n/<locale>/checklists.json
 * are the source the app reads, and are edited here directly.
 *
 * Usage: bun scripts/import-app-signal-translations.ts [path/to/divekit-app]   (default ../divekit-app)
 */
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';

const APP = resolve(process.argv[2] ?? '../divekit-app');
const LOCALES = ['de', 'pl', 'ru', 'sv', 'tr', 'zh', 'ko'];
const NOW = new Date().toISOString().slice(0, 19) + 'Z';
const VERSION = NOW.slice(0, 10).replaceAll('-', '.') + '.1';

const kebab = (s: string) => s.replace(/([a-z0-9])([A-Z])/g, '$1-$2').toLowerCase();
const json = (p: string) => JSON.parse(readFileSync(p, 'utf8'));
const write = (p: string, data: unknown) => {
  mkdirSync(resolve(p, '..'), { recursive: true });
  writeFileSync(p, JSON.stringify(data, null, 2) + '\n');
};
const locale = (loc: string) => json(`${APP}/assets/locales/${loc}/signals.json`);
const at = (obj: any, path: string): string | undefined => path.split('.').reduce((o, k) => o?.[k], obj);
const problems: string[] = [];

const signals = json('datasets/dive-signals.json').signals as { id: string; name: string; description: string }[];
const signalIds = new Set(signals.map((s) => s.id));
// Leaf objects carrying `name` are signals; `sections` holds the category headings (no base field).
const signalKeys = (obj: any, path: string[] = []): string[][] =>
  Object.entries(obj).flatMap(([k, v]: [string, any]) =>
    path.length === 0 && k === 'sections' ? [] : typeof v?.name === 'string' ? [[...path, k]] : signalKeys(v, [...path, k]),
  );

const en = locale('en');
const appSignalIds = new Map(signalKeys(en).map((p) => [p.map(kebab).join('-'), p.join('.')]));
for (const [id, key] of appSignalIds) if (!signalIds.has(id)) problems.push(`app signal ${key} (${id}) is not in dive-signals.json`);
for (const s of signals) {
  const key = appSignalIds.get(s.id);
  if (!key) { problems.push(`dive-signals.json ${s.id} has no app translation key`); continue; }
  for (const f of ['name', 'description'] as const)
    if (at(en, `${key}.${f}`) !== s[f]) problems.push(`note: ${s.id}.${f} English differs between app and dataset`);
}

const counts: Record<string, number> = {};
for (const loc of LOCALES) {
  const t = locale(loc);
  const strings: Record<string, Record<string, string>> = {};
  let n = 0;
  for (const s of signals) {
    const key = appSignalIds.get(s.id);
    if (!key) continue;
    for (const f of ['name', 'description']) {
      const text = at(t, `${key}.${f}`);
      if (text === undefined) problems.push(`${loc}: no translation for ${s.id}.${f}`);
      else ((strings[s.id] ??= {})[f] = text), n++;
    }
  }
  for (const p of signalKeys(t)) if (!signalIds.has(p.map(kebab).join('-'))) problems.push(`${loc}: key ${p.join('.')} maps to nothing`);
  write(`datasets/i18n/${loc}/dive-signals.json`, {
    $schema: 'https://open.divekit.app/schemas/translations/translations.schema.v1.0.0.json',
    meta: { version: VERSION, generated_at: NOW, locale: loc, base: 'dive-signals.json', license: 'CC-BY-4.0', source: 'Dive Kit app translations' },
    strings,
  });
  counts[loc] = n;
}

console.log(`signals: ${signals.length}, text fields: ${signals.length * 2}`);
console.table(counts);
console.log(problems.length ? problems.join('\n') : 'Every id and key matches.');
