# 🤝 Contributing to Project Dive Kit Open

Thank you for your interest in contributing!
This repository hosts the **open data, schemas, and public standards** that power the [Dive Kit](https://divekit.app) ecosystem.
Everything here is published at [open.divekit.app](https://open.divekit.app) for use by the community.

We welcome contributions of all kinds — from fixing a typo to adding new datasets, improving schemas, or refining visuals.

---

## 🧭 What This Repo Contains

This repository is structured into several areas:

| Folder      | Purpose                                                                    |
| ----------- | -------------------------------------------------------------------------- |
| `datasets/` | JSON datasets for dive certifications, agencies, cylinders, and signals    |
| `schemas/`  | JSON Schema definitions for validation and interoperability                |
| `assets/`   | Visual assets (dive signal illustrations, agency logos, Dive Kit branding) |
| `docs/`     | Design guidelines and documentation                                        |
| `scripts/`  | Validation and testing scripts                                             |

If you're contributing to a specific folder, please follow the corresponding section below.

---

## 📋 General Contribution Steps

1. **Fork** the repository and create a new branch.
2. **Make your changes** in the appropriate folder:
   - Update or add a dataset (`datasets/`)
   - Update or add a schema (`schemas/`)
   - Add new or improved visuals (`assets/`)
3. **Validate your data** (see below).
4. **Commit** with a clear message (e.g. `Add CMAS Trimix certifications`).
5. **Open a Pull Request** to `main` describing what you changed and why.
6. Our CI will automatically validate your JSON and schema files.
7. Once approved, your change will appear on [open.divekit.app](https://open.divekit.app).

**Every change goes through a pull request, including maintainers' and automated agents' changes.** Never push to `main` directly, even when an admin token lets the push through the branch ruleset. A maintainer reviews and squash-merges the pull request.

---

## ✅ Validation & Formatting

All JSON data must:

- Be **valid JSON** (use 2-space indentation).
- Conform to the **matching schema** (in `/schemas`).
- Include `"$schema"` and `meta` fields in top-level JSON files:
  ```json
  {
    "$schema": "https://open.divekit.app/schemas/certifications/dive-certifications.schema.v1.0.0.json",
    "meta": {
      "version": "2025.10",
      "generated_at": "2025-10-31T00:00:00Z"
    },
    "certifications": [...]
  }
  ```

* Use UTF-8 encoding.
* Avoid trailing commas.

You can validate locally with:

```bash
./scripts/validate.sh
```

Or validate individual files with:

```bash
npx ajv validate \
  -s schemas/certifications/dive-certifications.schema.v1.0.0.json \
  -d datasets/certifications.json
```

---

## 🧩 Dataset Contributions

For new or updated datasets:

- Include all required fields as defined in the schema.
- Keep **data factual** and verifiable.
- For certifications:
  - Include agency, prerequisites, equivalencies, and limits.
  - Use plain text for limits (free-form list).
- For agencies:
  - Include full name, abbreviation, website, and region.
  - **IMPORTANT:** When adding a new agency, you must also add the corresponding agency logo to `assets/agency-logos/`. Logo files should be named using the pattern `agency-{id}.{svg|png}` (e.g., `agency-padi.svg`).
- For dive signals:
  - Include `id`, `category`, `name`, `description`, and `image` as defined in the schema.
  - **IMPORTANT:** Every signal entry must reference an SVG illustration in `assets/dive-signals/`. When adding a new signal, add both the dataset entry and the artwork (see Visual Contributions below).
  - Signal meanings are safety-relevant. Only submit signals documented by recognized training agencies or established community practice, and describe them accurately.

Refer to the schema files in `/schemas` for detailed field requirements and examples.

---

## 📚 Adding a reference

References live in `datasets/references.json`, and search sources live in `datasets/search-sources.json`. The README section "References and search sources" shows one example record of each.

1. **Required fields:** `id` (`ref-` plus kebab-case, unique across both files), `title`, `authors` (empty for an anonymous page), `type`, `access`, `topics`, `authoritative_for` (one sentence, under 200 characters) and `checked_at`. Add `year`, `publisher`, `url`, `doi`, `format`, `recommended_by` and `notes` when you know them.
2. **Link to the source itself.** The `url` must be the publisher's page or an official mirror, such as the agency, the journal, the author's own site or an open archive. Never link a pirated manual, a scan of a paid book, or a re-upload of someone else's video.
3. **Set `access` honestly:** `open` is free online, `paywalled` is behind a subscription or purchase, `borrow` is a lendable scan such as archive.org, and `print` means there is no reliable online copy.
4. **Check the link.** Run `curl -sIL -A 'Mozilla/5.0' <url>` and expect a 2xx or 3xx status. Some hosts block automated checks. Keep those records, open the page in a browser, and add the note "Site blocks automated checks; open it in a browser." Set `checked_at` to today.
5. **Put it in its place.** A record goes in the block of its first topic, with ids A to Z inside the block (see "Order" in the README).
6. **Validate** with `./scripts/validate.sh` from the repository root. It checks the schema, duplicate ids across both files, and the order.

A search source follows the same steps, with an `src-` id and `kind`, `use_for`, `topics`, `vetted` and `how_to_search`. Mark community sites `vetted: false`.

---

## 🧱 Schema Contributions

For schema updates or new schemas:

- Follow [JSON Schema Draft 2020-12](https://json-schema.org/draft/2020-12/schema).
- Include a top-level `$id` and `$schema` URL referencing `open.divekit.app`.
- Include `"version"` and `"title"` fields.
- Keep schemas backward-compatible where possible.
  Breaking changes require a new major version (e.g. `v2.0.0`).
- Schema files should be versioned and placed in appropriate subdirectories (e.g., `schemas/certifications/dive-certifications.schema.v1.0.0.json`).

Pull requests that modify schemas will trigger stricter validation checks.

---

## 🎨 Visual Contributions

### Dive Signal Illustrations

When adding or updating signal artwork in `assets/dive-signals/`:

- Format: **SVG only**, pure vector paths (no embedded raster images).
- Place the file in the matching category folder (`hand/core/`, `hand/technical/`, `hand/fish-id/`, `light/`, `buddy-contact/`).
- File naming: kebab-case matching the dataset entry's `image` path (e.g., `pressure-check.svg`).
- Match the existing visual style: simple line-art figures with flat fills, readable at small sizes.
- Run the file through `svgo` before committing.
- Every illustration must have a corresponding entry in `datasets/dive-signals.json`.
- By contributing, you license the artwork under **CC BY 4.0** (see `assets/dive-signals/LICENSE.md`).

### Agency Logos

When adding or updating agency logos in `assets/agency-logos/`:

- Format: **SVG** preferred, **PNG** accepted (with transparent background).
- File naming: Use the pattern `agency-{id}.{svg|png}` where `{id}` matches the agency ID in the dataset (e.g., `agency-padi.svg`, `agency-ssi.svg`).
- Keep file sizes reasonable (< 100KB preferred).
- Ensure logos are clear and recognizable at various sizes.
- **Note:** Agency logos are third-party trademarks. Only include official logos for reference purposes.

### Design Guidelines

For any visual assets:

- Use consistent styling where applicable.
- Run SVG files through an optimizer before committing (`svgo` recommended).
- Include appropriate licensing information (see `assets/*/LICENSE.md` files).

---

## 🔎 Quality & Style Guidelines

- **No personal or unverifiable data.** Only publish information confirmed via reputable training agency sources.
- **Neutral tone.** Avoid opinions, marketing, or subjective commentary.
- **Keep changes atomic.** Each PR should cover one focused topic (e.g., one schema or one dataset).

---

## 🧪 Testing Changes Locally

You can preview the site locally using any static file server:

```bash
# Using Python
python3 -m http.server
# then open http://localhost:8000

# Or using the provided test script
./scripts/test-local.sh
```

---

## 📜 Licensing

By contributing to this repository, you agree that:

- All datasets you contribute are licensed under **MIT**.
- Dive signal illustrations (and `datasets/dive-signals.json`) you contribute are licensed under **CC BY 4.0**.
- All schemas and code you contribute are licensed under **MIT**.
- You own or have the rights to any content you submit.

Full license details: [LICENSE.md](LICENSE.md)

---

## 💬 Community & Support

- **Discussions:** [GitHub Discussions →](https://github.com/majani-plus/divekit-open-data/discussions)
- **Issues:** Use GitHub Issues for bugs, schema suggestions, or data corrections.
- **Website:** [open.divekit.app](https://open.divekit.app)

---

## 🧭 Mission

> Project Dive Kit Open exists to unify how the diving world represents, shares,
> and understands its data — safely, transparently, and for everyone.

Thank you for helping make that vision real 🌊
