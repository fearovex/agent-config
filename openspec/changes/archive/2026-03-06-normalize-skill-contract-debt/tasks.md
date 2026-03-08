# Tasks: normalize-skill-contract-debt

## Phase 1 — Contract artifacts

- [x] 1.1 Add delta specs for `skill-format-types`, `project-audit-core`, and `audit-execution` covering trigger normalization, literal `## Process`, and canonical `## Rules`.
- [x] 1.2 Record the intended repo-level contract in `proposal.md` and `design.md`.

## Phase 2 — Live catalog normalization

- [x] 2.1 Normalize `**Triggers**` in affected `skills/sdd-*` files and add slash-command triggers to `project-setup` and `project-update`.
- [x] 2.2 Rename alternate process headings to literal `## Process` in affected active procedural skills.
- [x] 2.3 Tighten `skills/project-audit/SKILL.md` so active-catalog validation expects canonical `## Rules` only.

## Phase 3 — Docs, specs, verification

- [x] 3.1 Align active docs and exported instructions with the normalized contract.
- [x] 3.2 Promote the contract into the active master specs.
- [x] 3.3 Validate edited files, run `install.sh`, and create `verify-report.md`.
