# CLOSURE: sdd-archive-move-incomplete

Date: 2026-03-20
Archived by: sdd-archive

## Summary

Fixed the `sdd-archive` skill's Step 4 ("Move to archive"), which was copying change files
to the archive destination but never deleting the source directory. This left ghost
duplicates under `openspec/changes/` after every archive operation.

## Changes Applied

- `skills/sdd-archive/SKILL.md` — Step 4 updated with three new sentences: semantic anchor
  for deletion intent, deletion instruction gated on copy confirmation, and confirmation
  output line. Pre-flight date-stripping block preserved intact.
- `~/.claude/skills/sdd-archive/SKILL.md` — Deployed via `install.sh` (confirmed identical
  to repo copy).
- `openspec/specs/sdd-archive-execution/spec.md` — Two new requirements added:
  "Step 4 MUST delete the source directory after successful copy" and
  "Step 4 MUST preserve the date-stripping pre-flight block", with full scenario coverage.

## Verification

verify-report.md: PASS — all 4 tasks complete, all spec requirements compliant, all
design decisions followed. No critical issues found.

## Spec Domains Affected

- `sdd-archive-execution` (master spec updated — delta merged)
