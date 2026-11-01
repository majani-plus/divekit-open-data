# Dive Kit Open: colour and type

This site uses the Dive Kit brand palette, shared with the app and [divekit.app](https://divekit.app). The source of
truth is the brand guidelines in the app repo (`divekit-app/docs/brand/BRAND_GUIDELINES.md`), introduced with
Dive Kit 3.0.0. The values below are the website set.

## Palette

| Role | Light | Dark | Use |
|---|---|---|---|
| Paper | `#f7f6f2` | `#1a1916` | page background |
| Paper raised | `#ffffff` | `#23221e` | cards, inputs, tables |
| Paper tint | `#f1f0ea` | `#2d2b27` | code blocks, read-only strips |
| Ink | `#101114` | `#f2efe6` | text, headings, the logo |
| Ink secondary | `#3d4047` | `#bdb8ab` | secondary text |
| Ink muted | `#676a71` | `#9a9588` | labels, captions |
| Rule | ink at 14% | ink at 14% | hairlines |
| Rule strong | ink at 45% | ink at 45% | table head underline, secondary buttons |
| Accent (Slate blue) | `#1f4fd1` | `#86a2f0` | links and primary buttons |
| Accent strong | `#1c3c9c` | `#c3d1f7` | hover |

The accent is for things the reader acts on (links, buttons). It is never used in the logo, which is one colour:
ink on paper or paper on ink.

## Type

- Archivo for headings (600 to 700) and body (400 to 500), self-hosted from `assets/fonts/`.
- IBM Plex Mono for labels, table heads, code and figure captions.
- The DIVE KIT lockup in the header and footer is the outlined wordmark (inline SVG), never retyped.

## Usage

The palette lives as CSS custom properties in `assets/site.css`, shared by `index.html`, `view.html` and
`404.html`. The `.dark` class on `<html>` swaps in the dark palette, following the system theme unless
`?theme=light|dark` is set, as on divekit.app.

## Contrast

- Accent `#1f4fd1` on white: 6.78:1; on paper: 6.27:1
- Ink `#101114` on paper: 17.46:1
- Ink secondary `#3d4047` on white: 10.38:1
- Ink muted `#676a71` on paper tint: 4.74:1
- Dark: accent `#86a2f0` on paper: 7.07:1; ink on paper: 15.29:1

The old palette (paper `#fbfaf7`, accent `#0369a1` / `#38bdf8`, Inter and Source Serif 4) and the wave logo are
retired.
