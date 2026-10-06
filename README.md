# <img src="assets/divekit/favicon.png" alt="Dive Kit" width="32" height="32" align="center" /> Project Dive Kit — Open Data & Standards

**Welcome to the open data, schemas, and public standards hub of the Dive Kit ecosystem.**
This repository powers [open.divekit.app](https://open.divekit.app) — the canonical home for all open, machine-readable resources maintained by the Dive Kit project.

---

## 🧭 Purpose

`majani-plus/divekit-open-data` provides:

- **Public Datasets** – Canonical, versioned JSON datasets for dive certifications, agencies, cylinders, dive signals, and references.
- **Schemas & Standards** – JSON Schema definitions for validating and interoperating with Dive Kit's open data formats.
- **Visual Assets** – Openly licensed dive signal illustrations (CC BY 4.0), agency logos (third-party trademarks), and Dive Kit branding.
- **Documentation** – Design guidelines, contributor guidelines, and open-data governance notes.

Our goal is to make diving data **accessible, standardized, and developer-friendly**, so apps, researchers, and training platforms can all share a common foundation.

---

## 📁 Repository Structure

```
divekit-open-data/
├── datasets/
│ ├── certifications.json
│ ├── agencies.json
│ ├── cylinders.json
│ ├── dive-signals.json
│ ├── references.json
│ ├── search-sources.json
│ └── LICENSE.md
│
├── schemas/
│ ├── certifications/
│ │ └── dive-certifications.schema.v1.0.0.json
│ ├── agencies/
│ │ └── agencies.schema.v1.0.0.json
│ ├── cylinders/
│ │ └── cylinders.schema.v1.0.0.json
│ ├── dive-signals/
│ │ └── dive-signals.schema.v1.0.0.json
│ ├── references/
│ │ ├── references.schema.v1.0.0.json
│ │ └── references.schema.v1.1.0.json
│ ├── search-sources/
│ │ └── search-sources.schema.v1.0.0.json
│ └── LICENSE.md
│
├── assets/
│ ├── dive-signals/       # CC BY 4.0 licensed signal illustrations
│ │ ├── hand/core/
│ │ ├── hand/technical/
│ │ ├── hand/fish-id/
│ │ ├── light/
│ │ ├── buddy-contact/
│ │ └── LICENSE.md
│ ├── agency-logos/       # Third-party trademarks
│ │ └── ...
│ ├── divekit/              # Dive Kit brand assets
│ │ ├── logo.png
│ │ ├── logo-squircle-light.png   # iOS-style app icon
│ │ ├── logo-squircle-dark.png
│ │ ├── logo-circle-light.png
│ │ ├── logo-circle-dark.png
│ │ ├── apple-touch-icon.png
│ │ ├── favicon.png
│ │ └── favicon-dark.png
│ ├── fonts/                # Inter, Source Serif 4, IBM Plex Mono (SIL OFL 1.1)
│ ├── site.css              # Site styles (divekit.app editorial system)
│ └── site.js               # Theme switch and header
│
├── docs/
│ ├── DATASETS.md
│ ├── COLORS.md
│ └── LICENSE.md
│
├── scripts/
│ ├── validate.sh
│ └── test-local.sh
│
├── index.html            # open.divekit.app home page
├── view.html             # Dataset browser (each dataset as a searchable table)
├── 404.html
├── CONTRIBUTING.md
├── LICENSE.md
└── CNAME (→ open.divekit.app)

```

---

## 🧩 Key Resources

| Resource                        | Description                                                        | URL                                                                                                   |
| ------------------------------- | ------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------- |
| **Dive Certifications Dataset** | Comprehensive global database of scuba certifications and agencies | [View JSON →](https://open.divekit.app/datasets/certifications.json)                                    |
| **Dive Certifications Schema**  | JSON Schema for validating certification data                      | [View Schema →](https://open.divekit.app/schemas/certifications/dive-certifications.schema.v1.0.0.json) |
| **Agencies Dataset**            | List of recognized certifying agencies                             | [View JSON →](https://open.divekit.app/datasets/agencies.json)                                          |
| **Agencies Schema**             | JSON Schema for validating agencies data                           | [View Schema →](https://open.divekit.app/schemas/agencies/agencies.schema.v1.0.0.json)                  |
| **Cylinder Database**           | Specifications for common scuba cylinders                          | [View JSON →](https://open.divekit.app/datasets/cylinders.json)                                         |
| **Cylinder Schema**             | JSON Schema for validating cylinder data                           | [View Schema →](https://open.divekit.app/schemas/cylinders/cylinders.schema.v1.0.0.json)                |
| **Dive Signals Dataset**        | Diver communication signals with names, meanings, and artwork      | [View JSON →](https://open.divekit.app/datasets/dive-signals.json)                                      |
| **Dive Signals Schema**         | JSON Schema for validating dive signal data                        | [View Schema →](https://open.divekit.app/schemas/dive-signals/dive-signals.schema.v1.0.0.json)          |
| **References Dataset**          | Vetted papers, books, standards and articles behind Dive Kit, with topics and what each is authoritative for | [View JSON →](https://open.divekit.app/datasets/references.json)                                        |
| **References Schema**           | JSON Schema for validating reference records                                                                 | [View Schema →](https://open.divekit.app/schemas/references/references.schema.v1.1.0.json)               |
| **Search Sources Dataset**      | Where to search next when no reference answers a question, each marked vetted or not                       | [View JSON →](https://open.divekit.app/datasets/search-sources.json)                                    |
| **Search Sources Schema**       | JSON Schema for validating search source records                                                             | [View Schema →](https://open.divekit.app/schemas/search-sources/search-sources.schema.v1.0.0.json)       |
| **Dive Signal Illustrations**   | CC BY 4.0 vector artwork for every signal in the dataset           | [View Illustrations →](https://github.com/majani-plus/divekit-open-data/tree/main/assets/dive-signals) |
| **Agency Logos**                | Collection of scuba diving agency logos                            | [View Logos →](https://github.com/majani-plus/divekit-open-data/tree/main/assets/agency-logos)        |
| **Dataset Documentation**       | Beginner-friendly guide to understanding and contributing          | [View Guide →](https://open.divekit.app/docs/DATASETS.md)                                               |
| **Docs**                        | Design guidelines and documentation                                | [View Docs →](https://github.com/majani-plus/divekit-open-data/tree/main/docs)                        |

---

## 📚 References and search sources

Two files hold everything Dive Kit knows about sources. Both are meant to grow with contributions.

- **`datasets/references.json`** lists the sources Dive Kit relies on: the papers, books, standards, manuals, articles and videos behind its calculators and guide. Each record says what the source is authoritative for, so an assistant can cite it.
- **`datasets/search-sources.json`** lists where to search next when no reference answers a question: organisations, journal indexes, training agencies, forums and wikis, in the order to try them. `vetted` says whether what you find there can be cited as trustworthy. ScubaBoard and the r/scuba wiki are useful but not vetted.

A reference record, as it is in the file:

```json
{
  "id": "ref-baker-understanding-m-values",
  "title": "Understanding M-values",
  "authors": ["Baker, Erik C."],
  "year": null,
  "type": "article",
  "publisher": "Shearwater Research",
  "url": "https://www.shearwater.com/wp-content/uploads/2019/05/understanding_m-values.pdf",
  "access": "open",
  "topics": ["deco_theory", "gradient_factors"],
  "authoritative_for": "Plain-language explanation of M-values and the decompression zone behind the gradient-factor method.",
  "checked_at": "2026-09-26"
}
```

Optional fields a record can add: `doi`, `notes`, `format` (`html`, `pdf`, `video`, `audio` or `print`) and `recommended_by` (for example `["r/scuba wiki", "DAN Alert Diver"]`).

A search source record:

```json
{
  "id": "src-dan",
  "name": "DAN (Divers Alert Network)",
  "url": "https://dan.org/",
  "kind": "organisation",
  "use_for": "Diving medicine, fitness to dive, injuries, incident data and safety research.",
  "topics": ["emergencies", "deco_theory", "oxygen_toxicity"],
  "vetted": true,
  "how_to_search": "site:dan.org <question>",
  "checked_at": "2026-09-27"
}
```

**Order.** `references.json` keeps one block per topic, in the order of the schema's topic list (`deco_theory` first, `community` last). A record belongs to the block of its first topic, and ids run A to Z inside each block. `search-sources.json` is in the order to try the sources: vetted sources first, community sources last. `scripts/validate.sh` checks both files, their ids across both files, and the references order.

**How Dive Kit uses them.** The Dive Kit MCP server's `lookup_references` tool searches `references.json`. When nothing matches, it returns `search-sources.json` so the assistant knows where to look next and says the result is not Dive Kit-vetted. The Dive Kit guide cites references by id. To add a record, see [Adding a reference](CONTRIBUTING.md#-adding-a-reference) in CONTRIBUTING.

---

## 🧠 How to Use

### For Everyone

If you're new to working with data or just want to understand what's in these datasets, check out our [Dataset Documentation](https://open.divekit.app/docs/DATASETS.md) for a beginner-friendly guide.

### For Developers

You can consume the datasets directly from the web:

```bash
curl https://open.divekit.app/datasets/certifications.json
```

Validate them against the corresponding schema:

```bash
npx ajv validate \
  -s https://open.divekit.app/schemas/certifications/dive-certifications.schema.v1.0.0.json \
  -d https://open.divekit.app/datasets/certifications.json
```

### For Designers / Educators

Use the dive signal illustrations from [`assets/dive-signals`](https://github.com/majani-plus/divekit-open-data/tree/main/assets/dive-signals)
in briefing cards, slides, posters, or your own apps. They are licensed **CC BY 4.0**: free for any use,
including commercial, as long as you credit "Dive signals by Project Dive Kit — https://divekit.app".

Agency logos in [`assets/agency-logos`](https://github.com/majani-plus/divekit-open-data/tree/main/assets/agency-logos)
are third-party trademarks and should be used for reference purposes only.

---

## ✅ Validation

Before submitting changes, you can validate the datasets locally:

```bash
./scripts/validate.sh
```

This script will:

- ✅ Validate schema files against JSON Schema specifications
- ✅ Validate each JSON dataset file against its referenced schema
- ✅ Check for duplicate IDs within datasets
- ✅ Report detailed errors if validation fails

**Requirements:**

- [Bun](https://bun.sh) (recommended) or Node.js
- [jq](https://jqlang.github.io/jq/) (JSON processor)

All pull requests are automatically validated via GitHub Actions.

---

## 🤝 Contributing

We welcome contributions of:

- New or corrected certification data
- Updated equivalencies or limits
- Additional recognized agencies
- Translations or metadata
- Documentation improvements

📚 **New to contributing?** Start with our [Dataset Documentation](docs/DATASETS.md) for a step-by-step guide on how to add or update data.

For technical details, see [`CONTRIBUTING.md`](CONTRIBUTING.md) for workflow and validation rules.

All JSON datasets must pass schema validation via CI before merging.

---

## 🧾 License

Unless otherwise noted:

| Type                   | License                                                   | Notes                                            |
| ---------------------- | --------------------------------------------------------- | ------------------------------------------------ |
| **Datasets & Docs**    | [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) | Free to share/remix with attribution             |
| **Dive Signal Illustrations** | [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) | Credit "Dive signals by Project Dive Kit — https://divekit.app" |
| **Schemas & Code**     | [MIT](https://opensource.org/licenses/MIT)                | Free to use in software projects                 |
| **Agency Logos**       | Third-party trademarks                                    | Owned by respective agencies, reference use only |
| **Dive Kit Brand Assets** | All rights reserved                                       | Dive Kit trademark, permission required for use     |

See [LICENSE.md](LICENSE.md) for full details.

---

## 🗓️ Versioning & Governance

Each dataset and schema is versioned semantically (`v1.0.0`, `v1.1.0`, …).
Breaking changes will increment the major version.

All changes are tracked via pull requests and validated in CI.
Community suggestions are discussed in [Discussions](https://github.com/majani-plus/divekit-open-data/discussions).

---

## 🧭 Mission

> Dive Kit Open exists to unify how the diving world represents, shares, and understands its data — safely, transparently, and for everyone.

---

**Maintained by:** [Project Dive Kit](https://github.com/majani-plus)
**Canonical URL:** [https://open.divekit.app](https://open.divekit.app)
