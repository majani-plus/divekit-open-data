# CLAUDE.md

Guidance for Claude Code in this repository: Dive Kit open data (datasets, schemas, docs). Start with [README.md](README.md), [CONTRIBUTING.md](CONTRIBUTING.md) and DATASETS.md. Changes reach `main` by pull request.

## Task tracking (beads)

All Dive Kit repos (`divekit-app`, `divekit-web`, `divekit-api`, `divekit-open-data`, `divekit-core`) share one [beads](https://github.com/steveyegge/beads) database at `~/Developer/majani-plus/divekit/.beads`, outside every repo. Track multi-step or multi-session work there, not in ad-hoc TODO files, so work that spans repos (a core change that the app, the API and the website must follow) lives in one graph.

- The database sits outside the git repos, so `bd` does not find it on its own: prefix every command with `BEADS_DIR=~/Developer/majani-plus/divekit/.beads` (or export it for the shell).
- Start of a session: `bd ready` for unblocked work, `bd list --status in_progress` after a context reset, `bd show <id>` for the details.
- While working: `bd create "…" -t task|bug|epic -p 0-3 [--parent <epic>] [-d "…"]`, `bd update <id> --claim`, `bd dep add <blocked> <blocker>`, and notes on the issue as you go (they survive context compaction).
- Done: `bd close <id> --reason "what landed, commit SHA"`. Name the repo in the title or notes when the work is repo-specific.
- Run `bd prime` for the full workflow and `bd <command> --help` for options.
