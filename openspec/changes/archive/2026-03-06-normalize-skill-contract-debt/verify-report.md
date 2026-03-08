# Verify Report: normalize-skill-contract-debt

Date: 2026-03-06
Status: PASS WITH WARNINGS

## Verified Criteria

- [x] Affected SDD phase skills now expose slash-command triggers instead of legacy `sdd:phase` trigger markers.
- [x] Affected active procedural skills now expose a literal `## Process` heading.
- [x] Active docs and audit/spec contracts now describe `## Rules` as the canonical terminal rules heading for the live catalog.
- [x] `bash install.sh` completed successfully after the normalization change.

## Validation Performed

1. Searched active skill files, active docs, and active specs for remaining live uses of legacy trigger markers and alternate process headings.
2. Ran diagnostics on all edited live files.
3. Re-checked `skills/sdd-ff/SKILL.md` and `skills/sdd-new/SKILL.md` after nesting their step headings under `## Process`.
4. Ran `bash install.sh` from the repository root.

## Warnings

- The existing skill-file validator still reports `format:`, `model:`, and `thinking:` as unsupported frontmatter attributes. This is a pre-existing external tooling mismatch and not a regression from this change.
- MCP registration was skipped during `install.sh` because the `claude` CLI is not available in PATH.

## Outcome

The active repository contract for SDD and `project-*` skills is now internally aligned across the live skills, active docs, and active master specs.
