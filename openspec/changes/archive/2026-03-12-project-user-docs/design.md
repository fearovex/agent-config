# Technical Design: 2026-03-12-project-user-docs

Date: 2026-03-12
Proposal: openspec/changes/2026-03-12-project-user-docs/proposal.md

## General Approach

Create one new file (`docs/user-guide.md`) written in plain Markdown, structured as a narrative
guide from setup through conflict resolution, with a command reference table and quick-start
checklists. Add a single descriptive link to `docs/user-guide.md` in `README.md`. No scripts,
no skills, and no CLAUDE.md changes are required — this is a pure documentation deliverable.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|----------------------|---------------|
| Single vs. modular docs | Single `user-guide.md` | Modular (SETUP.md + CONFIG.md + ADVANCED.md) | Proposal and exploration both select Approach A; one discoverable entry point beats cross-linking friction for first-time readers |
| Link placement in README.md | Add a "User Guide" link in the first 40 lines (overview section) | Footnote at end of README | Spec requires link in overview; high-discoverability placement aligns with new-user mental model |
| Precedence diagram format | ASCII diagram embedded in user-guide.md | Separate diagram file, image | No build tooling in this repo (Markdown + Bash only); ASCII is renderable everywhere and version-controllable |
| Cross-links from user-guide.md | Relative paths from `docs/` directory | Absolute paths, anchors only | Relative links resolve correctly when rendered in GitHub and locally; consistent with existing docs/ convention |
| Content scope | Setup, configuration, conflict resolution, commands, quick-start | Covering skill authoring, ai-context/ internals, full CLAUDE.md syntax | Proposal explicitly defers deep dives to technical docs; user guide is onboarding, not reference |
| Worked example subject | Skill override (project-local `.claude/skills/sdd-apply/SKILL.md`) | Command override, CLAUDE.md toggle | Skill override is the most common and concrete customization; illustrates all three precedence tiers |

## Data Flow

This change is documentation-only — no runtime data flow changes. The document creation flow is:

```
author writes docs/user-guide.md
  ├── Reads: proposal.md, exploration.md, spec.md
  ├── Reads: existing docs/ (ORCHESTRATION.md, SKILL-RESOLUTION.md, format-types.md)
  ├── Reads: existing skills/README.md
  └── Reads: CLAUDE.md (command list, global/local model)
      │
      ▼
docs/user-guide.md (new file, 250–400 lines)
      │
      ▼
README.md (modified — one link added in overview section)
```

User reads flow (after change is applied):

```
New user opens README.md
  → sees "User Guide" link
  → opens docs/user-guide.md
  → reads What is agent-config? → Deployment → Global config
  → reads Project-level customization (with precedence diagram + worked example)
  → reads Conflict resolution workflow (with realistic scenario)
  → consults Command reference table
  → follows Quick-start checklist
  → cross-links to SKILL-RESOLUTION.md / ORCHESTRATION.md for deep dives
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `docs/user-guide.md` | Create | New human-readable guide: 6 required sections, precedence diagram, worked skill-override example, conflict resolution workflow with audit snippet, command table (≥15 commands, 2 groups), three quick-start checklists, troubleshooting, see-also links |
| `README.md` | Modify | Add one descriptive link to `docs/user-guide.md` in the overview section (within first 40 lines) |

## Interfaces and Contracts

No code interfaces. The document contract is defined by the spec:

```
docs/user-guide.md MUST contain:
  Section 1: "## What is agent-config?"             (≤ 40 lines)
  Section 2: "## Deployment model"                  (install.sh + sync.sh, diagram)
  Section 3: "## Global configuration out-of-the-box"
  Section 4: "## Project-level customization"       (precedence diagram + worked example)
  Section 5: "## Conflict resolution workflow"      (3-step: audit → fix → update, realistic snippet)
  Section 6: "## Quick-start checklist"             (3 sub-checklists: new machine, SDD cycle, deploy)

  Total length: 250–400 lines
  All relative links must resolve from docs/ directory.

README.md MUST contain:
  A link matching: [User Guide](docs/user-guide.md) or equivalent descriptive text
  Placed within the first 40 lines of the file.
```

### Section content outline for docs/user-guide.md

```
# User Guide — agent-config

Last updated: 2026-03-12

## What is agent-config?
  - Plain-language description (not agent-speak)
  - Two components: skill catalog + memory layer
  - Purpose: reusable SDD workflow across projects

## Deployment model
  - install.sh: repo → ~/.claude/ (config deploy, one-way)
  - sync.sh: ~/.claude/memory/ → repo/memory/ (memory capture, one-way)
  - ASCII diagram showing both directions
  - New machine setup commands
  - Explicit: sync.sh does NOT deploy skills or CLAUDE.md

## Global configuration out-of-the-box
  - What arrives after install.sh
  - Skill categories (table: type → examples)
  - Memory layer (ai-context/ files)
  - CLAUDE.md intent classification overview

## Project-level customization
  - When to override (project needs different behavior)
  - Three-tier precedence diagram (ASCII)
  - Worked example: project-local sdd-apply override
    (directory tree + what happens at runtime)
  - Brief note on intent_classification override with example block

## Conflict resolution workflow
  - Step 1: /project-audit (produces audit-report.md)
  - Step 2: /project-fix (applies corrections)
  - Step 3: /project-update (syncs CLAUDE.md)
  - Realistic scenario: missing skill entry in audit, snippet, resolution

## Command reference at a glance
  - Table: Meta-tools (≥8 rows)
  - Table: SDD Phases (≥8 rows)
  - Plain language — not CLAUDE.md verbatim

## Quick-start checklist
  ### New machine setup
  - [ ] clone + install.sh + verify
  ### First SDD cycle
  - [ ] sdd-ff → approve → sdd-apply → install.sh → commit
  ### Deploying a config change
  - [ ] edit repo → install.sh → git commit

## Troubleshooting
  - sync.sh gotcha (does not deploy skills)
  - Direct ~/.claude/ edits are lost on next install.sh
  - Claude not picking up changes → run install.sh

## See also
  - SKILL-RESOLUTION.md (relative link)
  - ORCHESTRATION.md (relative link)
  - format-types.md (relative link)
  - skills/README.md (relative link from docs/ = ../skills/README.md)
```

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Manual — line count | `wc -l docs/user-guide.md` is between 250 and 400 | Bash |
| Manual — section headings | All 6 required section headings present | grep / read |
| Manual — link validity | Each relative link resolves to an existing file from docs/ | Bash (ls / test -f) |
| Manual — README link | `docs/user-guide.md` link appears in README.md first 40 lines | head -40 README.md |
| Manual — command table | Count non-header rows in command table ≥ 15 | read |
| Manual — quick-start checklists | Three sub-sections with task list items (`- [ ]`) present | grep |

No automated test framework required — validation is manual review per verify-report.md.

## Migration Plan

No data migration required. This change adds two files/modifications to a Markdown-only
repository with no build pipeline. Rollback is deletion of `docs/user-guide.md` and
reversion of the one-line README.md addition.

## Open Questions

None. The exploration and spec fully resolved outstanding questions:
- Intent classification override syntax: include a brief inline example, link to CLAUDE.md for full syntax.
- ai-context/ coverage: mention it exists, defer to `/memory-init` skill.
- Conflict resolution depth: one simplified scenario (2-3 findings) with a snippet.
