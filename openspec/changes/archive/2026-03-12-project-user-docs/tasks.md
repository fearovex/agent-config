# Task Plan: project-user-docs

Date: 2026-03-12
Design: openspec/changes/2026-03-12-project-user-docs/design.md

## Progress: 2/2 tasks

## Phase 1: Create docs/user-guide.md

- [x] 1.1 Create `docs/user-guide.md` ✓ with all six required sections, following the outline in design.md section "Section content outline for docs/user-guide.md":
  - Section 1: "## What is agent-config?" (plain-language intro, ≤40 lines)
  - Section 2: "## Deployment model" (install.sh + sync.sh, diagram, new machine setup)
  - Section 3: "## Global configuration out-of-the-box" (what arrives after install.sh, skill categories, memory layer, intent classification overview)
  - Section 4: "## Project-level customization" (precedence diagram + worked example: project-local sdd-apply override)
  - Section 5: "## Conflict resolution workflow" (3-step workflow: audit → fix → update, with realistic scenario and audit snippet)
  - Section 6: "## Quick-start checklist" (3 sub-checklists: new machine setup, first SDD cycle, deploying a config change)
  - Optional sections: Troubleshooting, See also (cross-links)
  - Document length: 250–400 lines (inclusive of blank lines and headings)
  - All relative links must resolve from docs/ directory (e.g., `[SKILL-RESOLUTION.md](./SKILL-RESOLUTION.md)`, `[skills/README.md](../skills/README.md)`)
  - Command reference table must include at least 15 distinct commands, grouped by category (Meta-tools, SDD Phases)
  - Use plain language (not copy-paste from CLAUDE.md)

## Phase 2: Update README.md and Verify

- [x] 2.1 Edit `README.md` ✓ to add a descriptive link to `docs/user-guide.md` in the overview section (within the first 40 lines, after line 16 "For the canonical reference...")
  - Link text: e.g., "For a user-focused guide, see [User Guide](./docs/user-guide.md)."
  - Placement: after the existing CLAUDE.md reference, before the "---" separator on line 17

- [x] 2.2 Verify all requirements from spec.md ✓
  - File `docs/user-guide.md` exists and is readable
  - All six required section headings present
  - Document length is between 250 and 400 lines (use `wc -l docs/user-guide.md` to verify)
  - Command reference table contains at least 15 commands
  - Three sub-checklists (new machine, SDD cycle, deploy config change) all present with `- [ ]` task list syntax
  - All cross-links resolve to existing files (verify paths: `docs/SKILL-RESOLUTION.md`, `docs/ORCHESTRATION.md`, `docs/format-types.md`, `../skills/README.md` from docs/)
  - README.md link appears in first 40 lines and points to correct path
  - Create `openspec/changes/2026-03-12-project-user-docs/verify-report.md` with verification checklist (all items marked `[x]`)

---

## Implementation Notes

- The document must be narrative-driven: guide the reader through setup, configuration, conflict resolution, then provide reference tables and checklists for quick lookup.
- Use one worked example throughout (skill override scenario) to illustrate precedence tiers and resolution workflow.
- ASCII diagrams (for precedence tiers and deployment flow) must be embedded in the Markdown; no separate image files.
- The conflict resolution scenario should include a realistic snippet from `audit-report.md` showing a failing criterion (e.g., missing skill entry) and the resolution command.
- Spec explicitly requires reference to these existing docs (verify they exist and links are valid):
  - `docs/SKILL-RESOLUTION.md`
  - `docs/ORCHESTRATION.md`
  - `docs/format-types.md`
  - `skills/README.md`
- Do not create additional files beyond `docs/user-guide.md` (no CLAUDE-OVERRIDES.md, no modular SETUP.md, etc.)
- The quick-start checklist for "Deploying a config change" must include `bash install.sh` step before git commit.

## Blockers

None. All dependencies (existing docs, CLAUDE.md, skills/README.md) are in place.

## Success Criteria (from spec.md)

1. docs/user-guide.md created with all 6 required sections (✓ during 1.1)
2. Global/local interaction explained with worked example (✓ during 1.1)
3. Conflict resolution workflow includes step-by-step guide with realistic output (✓ during 1.1)
4. Command reference table is human-readable, covers ≥15 commands (✓ during 1.1)
5. Quick-start checklist includes 3 scenarios (✓ during 1.1)
6. Document is 250–400 lines (✓ verify during 2.2)
7. README.md updated with link (✓ during 2.1)
8. No broken links to existing docs (✓ verify during 2.2)
9. User review confirms understandability (✓ covered by manual review in verify-report.md)
