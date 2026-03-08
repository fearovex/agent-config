# Proposal: normalize-skill-contract-debt

## Problem

The SDD and `project-*` skill audit identified active consistency debt in the live catalog:

1. Several SDD phase skills still advertise legacy `sdd:phase` triggers instead of the slash-command form the repo documents.
2. Multiple procedural skills still rely on alternate process headings even though the canonical format contract says procedural skills require `## Process`.
3. `project-audit`, `docs/format-types.md`, and exported instructions still preserve legacy `## Execution rules` acceptance in active-catalog validation paths, which weakens `## Rules` as the canonical terminal section.

This leaves the repository with a split contract between docs, audit behavior, and the active skill files.

## Proposed Solution

Normalize the live skill catalog and its governing documents around one active contract:

- Slash-command triggers are the canonical command form for SDD and `project-*` skills.
- Live procedural skills use a literal `## Process` section.
- Active-catalog validation and documentation treat `## Rules` as the only canonical terminal rules heading.

The change will update the affected active skills, align `CLAUDE.md`, `.github/copilot-instructions.md`, `ai-context/conventions.md`, `docs/format-types.md`, and tighten `project-audit` plus its related specs so the repo describes and validates the same contract.

## Success Criteria

- [ ] All SDD phase skills and affected `project-*` skills expose slash-command triggers in `**Triggers**`.
- [ ] Active procedural skills named in the audit expose a literal `## Process` heading without changing their functional content.
- [ ] Active-catalog documentation and audit logic no longer accept `## Execution rules` as an equivalent live canonical heading.
- [ ] `project-audit`, its supporting specs, and exported instructions describe the same structural contract as the live skills.

## Scope

In scope:

- Active skill files in `skills/sdd-*` and `skills/project-*`
- Active repository documentation and exported instructions
- Active master specs that govern format and audit execution

Out of scope:

- Rewriting archived change artifacts for historical terminology
- Changing command behavior beyond contract normalization
- Adding automated lint tooling for SKILL.md files
