# Dive Kit Open Datasets Documentation

Welcome! This guide will help you understand and contribute to the Dive Kit Open diving certification datasets. No technical expertise required!

## Table of Contents

- [What are these datasets?](#what-are-these-datasets)
- [Understanding the Data](#understanding-the-data)
  - [Agencies Dataset](#agencies-dataset)
  - [Certifications Dataset](#certifications-dataset)
  - [Cylinders Dataset](#cylinders-dataset)
  - [Dive Signals Dataset](#dive-signals-dataset)
  - [References Dataset](#references-dataset)
- [How to Read the Data](#how-to-read-the-data)
- [How to Contribute](#how-to-contribute)
- [Examples](#examples)
- [Common Questions](#common-questions)

## What are these datasets?

The Dive Kit Open project maintains five main datasets:

1. **Agencies** - A list of all scuba diving certification agencies (like PADI, SSI, NAUI)
2. **Certifications** - A comprehensive list of diving certifications offered by these agencies
3. **Cylinders** - Specifications for common scuba cylinders (volume, pressure, buoyancy)
4. **Dive Signals** - Diver communication signals (hand, light, and buddy-contact signals) with openly licensed illustrations
5. **References** - Vetted papers, books, standards and articles behind Dive Kit's calculators and guide, each tagged with what it is authoritative for

These datasets help developers, dive shops, and diving platforms standardize diving information across the industry.

## Understanding the Data

### Agencies Dataset

The agencies dataset (`datasets/agencies.json`) contains information about diving certification agencies.

Each agency entry includes:

- **id**: A unique identifier (e.g., "agency-padi")
- **name**: The official agency name (e.g., "Professional Association of Diving Instructors")
- **abbr**: The common abbreviation (e.g., "PADI")
- **website**: The agency's official website
- **status**: Whether the agency is "active", "merged", or "defunct"
- **logo**: Each agency has a logo file in `assets/agency-logos/`

### Certifications Dataset

The certifications dataset (`datasets/certifications.json`) contains all diving certifications.

Each certification entry includes:

- **id**: A unique identifier (e.g., "cert-padi-ow")
- **agency**: Which agency issues this cert (e.g., "agency-padi" or "PADI")
- **name**: The official certification name (e.g., "Open Water Diver")
- **abbr**: Common abbreviation (e.g., "OW")
- **category**: Type of certification:
  - `recreational` - Basic diving certifications
  - `technical` - Advanced/deep diving
  - `cave` - Cave diving specialties
  - `rescue` - Emergency/rescue training
  - `professional` - Instructor/divemaster levels
  - `freediving` - Breath-hold diving
  - `specialty` - Specific skills (photography, wreck, etc.)
- **prerequisites**: What you need before taking this course
- **limits**: What you can do with this certification
- **equivalent_to**: Similar certifications from other agencies

### Cylinders Dataset

The cylinders dataset (`datasets/cylinders.json`) contains specifications for common scuba cylinders.

Each cylinder entry includes:

- **id**: A unique identifier (e.g., "al80")
- **commonName**: The name divers use (e.g., "AL80")
- **waterVolumeL**: The cylinder's **true internal water volume** in liters, the physical space inside. This is the real figure, not a number tuned so that the ideal-gas math reproduces the cylinder's marketed name.
- **workingPressureBar**: Rated working pressure in bar. A cylinder rated in psi (every cu-ft-named tank) stores its psi rating converted to bar at two decimals, not rounded to a whole bar, so it converts back to the exact psi figure: an AL80 is 3000 psi = 206.84 bar (207 bar would read 3002 psi), an HP steel 3442 psi = 237.32 bar, an LP steel 2640 psi = 182.02 bar.
- **ratedCapacityCuft** (optional): The **marketed cubic-foot name** carried by imperial cylinders (an "AL80" carries `80`). It comes from the ideal gas law and is a label, not a measured deliverable.
- **material**: "steel", "aluminum", "composite", or "carbon_fiber"
- **emptyWeightKg** and **buoyancyKg**: Weight and buoyancy characteristics (full, at 50 bar, empty)

**On "free gas" capacity.** This dataset stores the physical facts (water volume and working pressure) plus the marketed name, and leaves the deliverable free gas for the consumer to derive. There is no single capacity number, because the answer depends on two choices:

1. **Gas law.** The ideal gas law (`free gas = waterVolumeL × workingPressureBar`) overstates a high-pressure cylinder. A real-gas model divides by a compressibility factor Z (about 1.03 for air at 207 bar), which is closer to the truth. An AL80 (11.1 L, 206.84 bar) is about 80 cu ft by the ideal law and about 77 to 79 cu ft real.
2. **Surface reference.** Free gas is measured at the surface, but is that 1 bar or 1 atmosphere (1.01325 bar)? The 1-atm convention behind US manufacturer charts (Luxfer lists ~77.4 cu ft for an AL80) reads about 1.3% lower than a 1-bar convention.

So one AL80 can legitimately read 80 (marketed, ideal), ~77.4 (Luxfer, real gas at 1 atm), or ~79 (real gas at 1 bar), all from the same `waterVolumeL` and `workingPressureBar`. Store the physics; pick your convention when you display it.

### Dive Signals Dataset

The dive signals dataset (`datasets/dive-signals.json`) is a machine-readable index of diver
communication signals, each paired with a vector illustration in `assets/dive-signals/`.

Each signal entry includes:

- **id**: A unique identifier (e.g., "hand-core-ok")
- **category**: One of:
  - `hand-core` - Essential hand signals every diver learns (OK, problem, up, share air)
  - `hand-technical` - Technical-diving hand signals (deco, gas switch, numbers 0-9)
  - `hand-fish-id` - Fun hand signals for pointing out marine life (turtle, shark, octopus)
  - `light` - Torch signals for night diving (OK circle, attention, emergency)
  - `touch-contact` - Buddy-contact (touch) signals for low or no visibility
- **name**: The signal's English name
- **description**: How the signal is performed and what it means
- **image**: Path to the signal's SVG illustration

The illustrations are licensed **CC BY 4.0**: you may use them anywhere, including commercially,
with the credit "Dive signals by Project Dive Kit — https://divekit.app". See
`assets/dive-signals/LICENSE.md`.

> **Safety note:** signal meanings vary slightly between training agencies and regions. Always
> agree on signals with your buddy or team before the dive. This dataset documents common usage;
> it is not a substitute for training.

### References Dataset

The references dataset (`datasets/references.json`) is a curated bibliography of the papers, books,
standards, manuals and articles Dive Kit's calculators and guide are built from, the planners they
are cross-checked against, and the community threads that shaped the app. It exists so an AI
assistant (or a curious diver) can cite a vetted source instead of searching the web.

Each reference entry includes:

- **id**: A unique identifier, kebab-case, prefixed `ref-` (e.g., `ref-baker-understanding-m-values`)
- **title**: The title of the work as published
- **authors**: Authors or issuing body, in published order (empty for anonymous web pages)
- **year**: Year of publication, or `null` for undated, living web pages
- **type**: What kind of source it is: `paper`, `book`, `standard`, `manual`, `article`, `blog`, `thread`, `dataset`, `website`, `talk`, `software`, `video`, `podcast`, `course_material`, or `report`
- **publisher** (optional): Publisher, journal, agency or site
- **url** (optional): Canonical URL, preferring the publisher or an open archive over a mirror
- **doi** (optional): DOI without the resolver prefix (e.g., `10.1002/cphy.c091004`)
- **access**: How you can actually get it: `open` (free online), `paywalled` (subscription), `borrow` (lendable scan, e.g. archive.org), or `print` (no reliable online copy)
- **topics**: One or more guide topics the reference supports (see below)
- **authoritative_for**: One plain sentence, under 200 characters, saying what Dive Kit relies on this source for
- **format** (optional, since v1.1.0): What opening the url gives you: `html`, `pdf`, `video`, `audio`, or `print`
- **recommended_by** (optional, since v1.1.0): Communities or publications that point divers to it, e.g. `r/scuba wiki`, `ScubaBoard sticky`, `DAN Alert Diver`
- **notes** (optional): Caveats, such as a superseded edition, a bot-blocking host, or which section to read
- **checked_at**: The date the URL was last verified to resolve

**Topics.** Each reference is tagged with one or more of these, aligned with the Dive Kit guide's own topic names:

- `deco_theory` - decompression models and the Bühlmann ZH-L family
- `gradient_factors` - gradient factors and deep-stops practice
- `oxygen_toxicity` - CNS and OTU oxygen limits
- `gas_density` - gas density and CO2 retention at depth
- `icd` - isobaric counter-diffusion
- `hpns` - high-pressure nervous syndrome
- `ccr` - closed-circuit rebreather diluent and setpoint planning
- `gas_selection` - choosing standard gases for a dive
- `gas_planning` - reserve and minimum-gas calculations
- `gas_blending` - partial-pressure and continuous blending methods
- `oxygen_handling` - oxygen cleaning and service standards
- `real_gas` - real-gas compressibility and equations of state
- `cylinders` - cylinder capacity and sizing conventions
- `buoyancy` - body composition and suit-lift buoyancy estimation
- `breathing_rate` - RMV/SAC measurement
- `conventions` - unit and reference-value conventions (seawater density, depth gauges)
- `training` - certification agencies and technical training paths
- `emergencies` - dive-injury emergency response
- `cross_checks` - independent planners and engines used to validate results
- `community` - forum and social threads that shaped a feature, not a source of numbers

**Adding a reference.** To add a record:

1. Pick an `id` matching `^ref-[a-z0-9-]+$`, unique within the file
2. Fill in every required field; add `publisher`, `doi` and `notes` where known
3. Check the `url` resolves with `curl -sIL -A 'Mozilla/5.0' <url>` and confirm it returns a 2xx or 3xx status. If a host blocks automated checks (some do), keep the record and add a note saying so instead of dropping it
4. Set `checked_at` to the date you verified the URL
5. Make sure the URL or DOI is not already used by another record; one record per work
6. Run `./scripts/validate.sh` before submitting

**Consumers.** This dataset is read by the Dive Kit MCP server's `lookup_references` tool, which
searches by `topics`, `type`, and free text over `title`, `authors`, `authoritative_for` and `notes`
(and returns the search sources when nothing matches),
and by the Dive Kit app's public guide, which links out to these sources from its "Further reading" pages.

### Search Sources Dataset

The search sources dataset (`datasets/search-sources.json`) lists where to search next when no
reference answers a question, in the order to try them. A search source is a place to look, not a
source Dive Kit relies on. Each entry includes:

- **id**: A unique identifier, kebab-case, prefixed `src-` (e.g., `src-dan`); unique across this file and the references
- **name**: The site or organisation
- **url**: Its home or search page
- **kind**: `organisation`, `journal_index`, `agency`, `forum`, or `encyclopedia`
- **use_for**: One sentence on what to search it for
- **topics**: The guide topics it is good for, from the same list as the references
- **vetted**: `true` for a research, medical or agency source whose content can be cited; `false` for community content to verify against a vetted source
- **how_to_search**: One sentence on how to search it (e.g., `site:dan.org <question>`)
- **notes** (optional): Caveats, such as how far to trust it or a host that blocks automated checks
- **checked_at**: The date the URL was last verified to resolve

## How to Read the Data

The data is stored in JSON format, which looks like this:

```json
{
  "id": "cert-padi-ow",
  "agency": "agency-padi",
  "name": "Open Water Diver",
  "abbr": "OW",
  "category": "recreational",
  "status": "active"
}
```

Think of it like a form where:

- Each line is a field name followed by its value
- Text values are in quotes
- The whole entry is wrapped in curly braces `{}`

### Understanding References

When you see a value starting with:

- `agency-` → This refers to an agency in the agencies dataset
- `cert-` → This refers to another certification

If a value doesn't start with these prefixes, it's just plain text.

For example:

- `"agency": "agency-padi"` → Links to PADI in the agencies dataset
- `"agency": "PADI"` → Just the text "PADI"

## How to Contribute

We welcome contributions! Here's how to help:

### 1. Reporting Issues

If you find incorrect information:

1. Go to the [GitHub repository](https://github.com/majani-plus/divekit-open-data)
2. Click "Issues" → "New Issue"
3. Describe what's wrong (e.g., "PADI Advanced Open Water max depth is 30m, not 40m")

### 2. Adding New Agencies

To add a new agency:

1. **Check if it already exists** - Search the `agencies.json` file
2. **Prepare the information**:

   - Official agency name
   - Common abbreviation
   - Official website
   - Logo image (PNG or SVG preferred)

3. **Add the agency entry** to `datasets/agencies.json`:

```json
{
  "id": "agency-example",
  "name": "Example Diving Agency",
  "abbr": "EDA",
  "website": "https://example-diving.org",
  "status": "active"
}
```

4. **Add the logo** to `assets/agency-logos/` named `agency-example.png`

### 3. Adding New Certifications

To add a new certification:

1. **Check if it already exists** - Search the `certifications.json` file
2. **Gather information**:

   - Official certification name
   - Which agency issues it
   - Prerequisites (if any)
   - Maximum depth/limits
   - Equivalent certifications from other agencies

3. **Add the certification** to `datasets/certifications.json`:

```json
{
  "id": "cert-example-advanced",
  "agency": "agency-example",
  "name": "Advanced Diver",
  "abbr": "AD",
  "category": "recreational",
  "status": "active",
  "prerequisites": {
    "certifications": ["cert-example-open-water"],
    "general": ["Minimum age 15 years", "10 logged dives"]
  },
  "limits": ["Maximum depth 30m", "No decompression diving"]
}
```

### 4. Updating Existing Data

To fix or update existing information:

1. Find the entry in the appropriate file
2. Make your changes
3. Ensure the format stays the same (quotes, commas, etc.)
4. Submit your changes

### 5. Validation

After making changes, validate your data:

1. Make sure all quotes and commas are in the right places
2. Check that IDs follow the format: `agency-` or `cert-` plus lowercase letters and hyphens
3. Verify that referenced agencies/certifications exist
4. Ensure unique agency names and abbreviations (no two agencies can have the same name or abbreviation)
5. Ensure unique certification names per agency (each agency can only have one certification with a given name)

#### Uniqueness Constraints

**For Agencies:**

- Each agency must have a unique `name` - no two agencies can share the same official name
- Each agency must have a unique `abbr` (abbreviation) - no two agencies can use the same abbreviation

**For Certifications:**

- Within each agency, certification names must be unique
- Within each agency, certification abbreviations must be unique
- Different agencies CAN have certifications with the same name (e.g., both PADI and SSI have "Open Water Diver")
- Different agencies CAN have certifications with the same abbreviation (e.g., both PADI and SSI can have "AOW")
- The combination of agency + certification name must be unique
- The combination of agency + certification abbreviation must be unique

**Running Validation:**

The project includes a validation script that checks all these constraints:

```bash
./scripts/validate.sh
```

This script will:

- Validate JSON syntax and schema compliance
- Check for duplicate IDs
- Verify agency names and abbreviations are unique
- Ensure certification names and abbreviations are unique within each agency
- Confirm all agency logos exist

## Examples

### Example: Finding Equivalent Certifications

Let's say you have a PADI Open Water certification and want to know the SSI equivalent:

1. Find the PADI Open Water entry in `certifications.json`
2. Look at the `equivalent_to` field
3. You'll see it lists "SSI Open Water Diver"

### Example: Understanding Prerequisites

To see what you need for PADI Advanced Open Water:

```json
{
  "id": "cert-padi-aow",
  "prerequisites": {
    "certifications": ["cert-padi-ow"],
    "general": ["Minimum age 12 years"]
  }
}
```

This means you need:

- PADI Open Water certification (or equivalent)
- To be at least 12 years old

### Example: Agency Status

Some agencies have merged or closed:

```json
{
  "id": "agency-example",
  "status": "merged",
  "replaced_by": "agency-other"
}
```

This tells you that this agency merged with another one.

## Common Questions

### Q: Why do some fields have null or empty values?

A: Not all information is available for every certification or agency. We add data as we verify it.

### Q: Can I add certifications from my local dive shop?

A: No, we only include certifications from recognized training agencies that issue official certification cards.

### Q: What's the difference between "deprecated" and "renamed" status?

A:

- **Deprecated**: The certification is no longer offered but existing certs are still valid
- **Renamed**: The certification still exists but under a new name

### Q: How often is the data updated?

A: We review and update the data regularly. Check the `meta.version` field in each file to see when it was last updated.

### Q: Can I use this data in my own project?

A: Yes! The datasets are MIT licensed, free for any use. The dive signal illustrations and `datasets/dive-signals.json` are CC BY 4.0. See LICENSE.md.

### Q: What if I find conflicting information?

A: Please report it as an issue. Include links to official sources so we can verify the correct information.

### Q: What are common validation errors?

A: Here are the most common validation errors and how to fix them:

1. **Duplicate agency name/abbreviation**: Two agencies have the same name or abbreviation
   - Fix: Check if one is a typo or if they're actually the same agency
2. **Duplicate certification name within agency**: An agency has two certifications with the same name
   - Fix: Often these are different levels (e.g., "Rescue Diver" vs "Master Rescue Diver") - make the names distinct
3. **Duplicate certification abbreviation within agency**: An agency has two certifications with the same abbreviation

   - Fix: Each certification needs a unique abbreviation within its agency (e.g., "RD" vs "MRD")

4. **Missing agency logo**: An agency exists in the dataset but has no logo file

   - Fix: Add a PNG or SVG logo to `assets/agency-logos/` with the agency ID as filename

5. **Invalid ID format**: IDs must follow the pattern `agency-xxx` or `cert-xxx`
   - Fix: Use only lowercase letters, numbers, and hyphens after the prefix

## Need More Help?

- **Questions?** Open a discussion on [GitHub](https://github.com/majani-plus/divekit-open-data/discussions)
- **Found a bug?** Report it in [Issues](https://github.com/majani-plus/divekit-open-data/issues)
- **Want to contribute code?** See [CONTRIBUTING.md](../CONTRIBUTING.md)

Remember: Every contribution helps make diving certification information more accessible to everyone! 🤿
