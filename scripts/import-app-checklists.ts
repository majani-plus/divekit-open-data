/**
 * Builds datasets/checklists.json and datasets/i18n/<locale>/{checklists,dive-signals}.json
 * from the Dive Kit app (divekit-app), and reports every id that does not match.
 *
 * The preset structure (sections, steps, timers, note fields) comes from the app's
 * src/data/checklist-presets.ts, loaded with i18n stubbed so each string comes back as
 * its locale key. The text comes from assets/locales/<locale>/checklists.json and
 * signals.json. Ids: preset `recPreDive` -> `rec-pre-dive`, its first section
 * `rec-pre-dive-s1`, that section's first step `rec-pre-dive-s1-1`; signal key
 * `hand.fishId.smallCreature` -> `hand-fish-id-small-creature`.
 *
 * Usage: bun scripts/import-app-checklists.ts [path/to/divekit-app]   (default ../divekit-app)
 */
import { plugin } from 'bun';
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';

const APP = resolve(process.argv[2] ?? '../divekit-app');
const LOCALES = ['de', 'pl', 'ru', 'sv', 'tr', 'zh', 'ko'];
const NOW = new Date().toISOString().slice(0, 19) + 'Z';
const VERSION = NOW.slice(0, 10).replaceAll('-', '.') + '.1';
const SITE = 'https://open.divekit.app/schemas';

type Provenance = { basis: 'own-words' | 'paraphrased' | 'reproduced'; source: string; agency: string | null; url: string | null };
type Meta = { use: string; unit: string | null; provenance: Provenance };

// What the app's catalog comment and docs/features/plan/CHECKLISTS.md say about each preset.
const META: Record<string, Meta> = {
  recPreDive: { use: 'predive', unit: null, provenance: { basis: 'paraphrased', source: 'The BWRAF recreational buddy check (BCD, Weights, Releases, Air, Final check) as taught in entry-level training, PADI among others.', agency: 'agency-padi', url: null } },
  ocTecPreDive: { use: 'predive', unit: null, provenance: { basis: 'paraphrased', source: "PADI TecRec's predive checklist: preparation, then a head-to-toe team match.", agency: 'agency-padi', url: null } },
  tecPlan: { use: 'dive-plan', unit: null, provenance: { basis: 'paraphrased', source: "PADI TecRec's technical dive planning sheet.", agency: 'agency-padi', url: null } },
  jjLandPrep: { use: 'ccr-build', unit: 'JJ-CCR', provenance: { basis: 'paraphrased', source: 'JJ-CCR user manual, section 9.1 (preparations on land).', agency: null, url: null } },
  jjPreDive: { use: 'predive', unit: 'JJ-CCR', provenance: { basis: 'paraphrased', source: 'JJ-CCR user manual, section 9.2 (shortly before diving).', agency: null, url: null } },
  jjInWater: { use: 'in-water', unit: 'JJ-CCR', provenance: { basis: 'paraphrased', source: 'JJ-CCR user manual, section 9.3 (shortly after entering the water).', agency: null, url: null } },
  fxFunctionality: { use: 'ccr-build', unit: 'FX CCR', provenance: { basis: 'reproduced', source: 'Sub-Gravity FX-CCR Functionality Checklist v1.5 (Calibration Kit), items 1 to 13. The condensed sheet gives the step labels, the detailed sheet the step descriptions.', agency: null, url: null } },
  fxPreDive: { use: 'predive', unit: 'FX CCR', provenance: { basis: 'reproduced', source: 'Sub-Gravity FX-CCR Functionality Checklist v1.5 (Calibration Kit), items 14 to 20.', agency: null, url: null } },
  fxAfterDive: { use: 'post-dive', unit: 'FX CCR', provenance: { basis: 'reproduced', source: 'FX CCR User Manual 2025.1 (iQsub Technologies), section 5.6.', agency: null, url: null } },
  chaosGue: { use: 'predive', unit: null, provenance: { basis: 'paraphrased', source: "GUE's CHAOS rebreather check (Controller, HUD, ADV, O2, Symptoms). The acronym and order are GUE's; the step explanations are written for Dive Kit.", agency: 'agency-gue', url: null } },
  gueEdge: { use: 'predive', unit: null, provenance: { basis: 'paraphrased', source: "GUE's EDGE team pre-dive check (Goal, Unified team, Equipment, Exposure, Decompression, Gas, Environment). The acronym and order are GUE's; the step explanations are written for Dive Kit.", agency: 'agency-gue', url: null } },
  tdiStart: { use: 'predive', unit: null, provenance: { basis: 'paraphrased', source: "TDI's START team pre-dive check (S-drill, Team, Air, Route, Tables), following TDI's published description. The step explanations are written for Dive Kit.", agency: 'agency-tdi', url: null } },
  postDive: { use: 'post-dive', unit: null, provenance: { basis: 'own-words', source: 'Written for Dive Kit after the post-dive management topics of Rebreather Forum 3.', agency: null, url: 'https://rebreatherforum.tech/wp-content/uploads/2022/11/RF3-proceedings.small_.pdf' } },
};

const kebab = (s: string) => s.replace(/([a-z0-9])([A-Z])/g, '$1-$2').toLowerCase();
const json = (p: string) => JSON.parse(readFileSync(p, 'utf8'));
const write = (p: string, data: unknown) => {
  mkdirSync(resolve(p, '..'), { recursive: true });
  writeFileSync(p, JSON.stringify(data, null, 2) + '\n');
};
const locale = (loc: string, ns: string) => json(`${APP}/assets/locales/${loc}/${ns}.json`);
const at = (obj: any, path: string): string | undefined => path.split('.').reduce((o, k) => o?.[k], obj);
const problems: string[] = [];

// ─── Checklists ──────────────────────────────────────────────────────────────

plugin({
  name: 'stub-i18n',
  setup(b) {
    b.onLoad({ filter: /src\/utils\/i18n(\/index)?\.(ts|tsx|js)$/ }, () => ({ contents: 'export default { t: (k) => k };', loader: 'js' }));
  },
});
const presets = await import(`${APP}/src/data/checklist-presets.ts`);
const defs = presets.CHECKLIST_PRESET_IDS.map((id: string) => presets.getChecklistPresetDefinition(id));

// Every text field as [dataset id, field, app key], in catalog order.
const fields: [string, string, string][] = [];
const strip = (k: string) => k.replace(/^checklists:/, '');
const en = locale('en', 'checklists');

const checklists = defs.map((def: any) => {
  const id = kebab(def.presetId);
  const meta = META[def.presetId];
  if (!meta) throw new Error(`No META for preset ${def.presetId}`);
  fields.push([id, 'name', strip(def.name)], [id, 'description', strip(def.description)]);
  return {
    id,
    app_preset_id: def.presetId,
    name: at(en, strip(def.name)),
    description: at(en, strip(def.description)),
    use: meta.use,
    unit: meta.unit,
    provenance: meta.provenance,
    sections: def.sections.map((section: any, i: number) => {
      const sid = `${id}-s${i + 1}`;
      if (!section.title.endsWith(`.sections.${i}.title`)) problems.push(`${sid}: title key ${section.title} is out of position`);
      fields.push([sid, 'title', strip(section.title)]);
      return {
        id: sid,
        title: at(en, strip(section.title)),
        steps: section.steps.map((step: any, j: number) => {
          const stepId = `${sid}-${j + 1}`;
          if (!step.label.endsWith(`.sections.${i}.steps.${j}.label`)) problems.push(`${stepId}: label key ${step.label} is out of position`);
          fields.push([stepId, 'label', strip(step.label)]);
          if (step.description) fields.push([stepId, 'description', strip(step.description)]);
          return {
            id: stepId,
            label: at(en, strip(step.label)),
            ...(step.description && { description: at(en, strip(step.description)) }),
            ...(step.timer && {
              timer: step.timer.mode === 'countdown' ? { mode: 'countdown', duration_sec: step.timer.durationSec } : { mode: 'stopwatch' },
            }),
            ...(step.textInput && { notes: true }),
          };
        }),
      };
    }),
  };
});
for (const [id, field, key] of fields) if (at(en, key) === undefined) problems.push(`en: ${id}.${field} has no English text (${key})`);

write('datasets/checklists.json', {
  $schema: `${SITE}/checklists/checklists.schema.v1.0.0.json`,
  meta: { version: VERSION, generated_at: NOW, license: 'MIT', source: 'Dive Kit app checklist presets' },
  checklists,
});

// Translation files: { strings: { <base id>: { <base field>: text } } }, in base order.
const usedKeys = new Set(fields.map(([, , k]) => k));
const leafPaths = (obj: any, prefix = ''): string[] =>
  Object.entries(obj).flatMap(([k, v]) => (typeof v === 'string' ? [prefix + k] : leafPaths(v, `${prefix}${k}.`)));

const counts: Record<string, Record<string, number>> = {};
const translation = (loc: string, base: string, license: string, strings: Record<string, Record<string, string>>) => ({
  $schema: `${SITE}/translations/translations.schema.v1.0.0.json`,
  meta: { version: VERSION, generated_at: NOW, locale: loc, base, license, source: 'Dive Kit app translations' },
  strings,
});

for (const loc of LOCALES) {
  const t = locale(loc, 'checklists');
  const strings: Record<string, Record<string, string>> = {};
  let n = 0;
  for (const [id, field, key] of fields) {
    const text = at(t, key);
    if (text === undefined) problems.push(`${loc} checklists: no translation for ${id}.${field} (${key})`);
    else ((strings[id] ??= {})[field] = text), n++;
  }
  for (const key of leafPaths(t.presets ?? {}, 'presets.')) if (!usedKeys.has(key)) problems.push(`${loc} checklists: key ${key} maps to nothing`);
  write(`datasets/i18n/${loc}/checklists.json`, translation(loc, 'checklists.json', 'MIT', strings));
  (counts[loc] ??= {}).checklists = n;
}

// ─── Dive signals ────────────────────────────────────────────────────────────

const signals = json('datasets/dive-signals.json').signals as { id: string; name: string; description: string }[];
const signalIds = new Set(signals.map((s) => s.id));
// Leaf objects carrying `name` are signals; `sections` holds the category headings (no base field).
const signalKeys = (obj: any, path: string[] = []): string[][] =>
  Object.entries(obj).flatMap(([k, v]: [string, any]) =>
    path.length === 0 && k === 'sections' ? [] : typeof v?.name === 'string' ? [[...path, k]] : signalKeys(v, [...path, k]),
  );

const enSignals = locale('en', 'signals');
const appSignalIds = new Map(signalKeys(enSignals).map((p) => [p.map(kebab).join('-'), p.join('.')]));
for (const [id, key] of appSignalIds) if (!signalIds.has(id)) problems.push(`app signal ${key} (${id}) is not in dive-signals.json`);
for (const s of signals) {
  const key = appSignalIds.get(s.id);
  if (!key) { problems.push(`dive-signals.json ${s.id} has no app translation key`); continue; }
  for (const f of ['name', 'description'] as const)
    if (at(enSignals, `${key}.${f}`) !== s[f]) problems.push(`note: ${s.id}.${f} English differs between app and dataset`);
}

for (const loc of LOCALES) {
  const t = locale(loc, 'signals');
  const strings: Record<string, Record<string, string>> = {};
  let n = 0;
  for (const s of signals) {
    const key = appSignalIds.get(s.id);
    if (!key) continue;
    for (const f of ['name', 'description']) {
      const text = at(t, `${key}.${f}`);
      if (text === undefined) problems.push(`${loc} signals: no translation for ${s.id}.${f}`);
      else ((strings[s.id] ??= {})[f] = text), n++;
    }
  }
  for (const p of signalKeys(t)) if (!signalIds.has(p.map(kebab).join('-'))) problems.push(`${loc} signals: key ${p.join('.')} maps to nothing`);
  write(`datasets/i18n/${loc}/dive-signals.json`, translation(loc, 'dive-signals.json', 'CC-BY-4.0', strings));
  counts[loc].signals = n;
}

const steps = checklists.flatMap((c: any) => c.sections.flatMap((s: any) => s.steps));
console.log(`checklists: ${checklists.length}, sections: ${checklists.reduce((a: number, c: any) => a + c.sections.length, 0)}, steps: ${steps.length}, text fields: ${fields.length}`);
console.log(`signals: ${signals.length}, text fields: ${signals.length * 2}`);
console.table(counts);
console.log(problems.length ? problems.join('\n') : 'Every id and key matches.');
