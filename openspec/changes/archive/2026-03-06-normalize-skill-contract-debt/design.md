# Design: normalize-skill-contract-debt

## Overview

This change removes active-catalog contract drift by aligning three layers at once:

1. Live skill files
2. Live repository documentation / exported instructions
3. Active master specs used by audit and authoring flows

The implementation is intentionally narrow: normalize headings and trigger strings, then tighten the audit/documentation contract so the repo no longer advertises multiple active forms for the same structure.

## Decisions

### 1. Prefer normalization over compatibility expansion

The repo already decided that `procedural` means `## Process`. The simplest fix is to rename the remaining alternate process headings in active skills rather than broadening the contract further.

### 2. Keep legacy terminology only in historical artifacts

Archived changes may still mention `Execution Rules`, but active docs and active validation paths should not preserve that term as an equivalent live structure.

### 3. Keep trigger aliases human-readable but command-shaped

The active trigger list should surface the slash-command form first for all command skills. Descriptive natural-language trigger phrases remain allowed.

## File Changes

### Active skills

- Update SDD phase `**Triggers**` from legacy `sdd:phase` tokens to `/sdd-phase`.
- Add or rename top-level `## Process` headings in:
  - `skills/sdd-ff/SKILL.md`
  - `skills/sdd-new/SKILL.md`
  - `skills/project-setup/SKILL.md`
  - `skills/project-audit/SKILL.md`
  - `skills/project-fix/SKILL.md`
- Add slash-command trigger forms to:
  - `skills/project-setup/SKILL.md`
  - `skills/project-update/SKILL.md`
- Tighten `skills/project-audit/SKILL.md` to validate only `## Rules` for active skills.

### Active docs

- Align `CLAUDE.md`, `ai-context/conventions.md`, `.github/copilot-instructions.md`, and `docs/format-types.md` with the normalized contract.

### Active specs

- Update `openspec/specs/skill-format-types/spec.md` to reflect canonical `## Rules` and literal `## Process` in active procedural skills.
- Update `openspec/specs/project-audit-core/spec.md` to state that compatibility policy does not preserve legacy heading equivalence in the active catalog.
- Update `openspec/specs/audit-execution/spec.md` so the batching rule lives in the canonical `## Rules` section.

## Verification

Verification is documentation- and contract-based:

- Search all active SDD / `project-*` skills for trigger normalization.
- Search the affected procedural skills for literal `## Process` headings.
- Search active docs/specs for remaining live-canonical acceptance of `## Execution rules`.
- Run `install.sh` and file diagnostics on edited files.
