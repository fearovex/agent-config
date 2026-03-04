# Task Plan: tech-skill-auto-activation

Date: 2026-03-03
Design: openspec/changes/tech-skill-auto-activation/design.md

## Progress: 6/6 tasks

## Phase 1: Modify sdd-apply/SKILL.md

- [x] 1.1 Insert **Step 0 — Technology Skill Preload** block immediately before the current `### Step 1 — Read full context` heading in `skills/sdd-apply/SKILL.md`. The block must contain:
  - The scope guard logic (check design.md file matrix for non-doc extensions)
  - Detection source priority: `ai-context/stack.md` primary, `openspec/config.yaml project.stack` secondary
  - Non-blocking behavior for missing files (INFO skip, no `blocked`/`failed`)
  - The detection report format (one line per loaded skill)

- [x] 1.2 Embed the **Stack-to-Skill Mapping Table** inside the Step 0 block in `skills/sdd-apply/SKILL.md`. The table must cover all 21 technology catalog skills with their keyword(s) and skill directory names (exact paths as shown in the design's Interface section).

- [x] 1.3 Replace the existing "I load technology skills if applicable" paragraph in the `## Code standards` section of `skills/sdd-apply/SKILL.md` with a forward reference: `"Technology skills are loaded automatically in Step 0 — Technology Skill Preload. No manual judgment is required here."` Do NOT delete the section heading; only replace the body paragraph.

## Phase 2: ADR Creation

- [x] 2.1 Create `docs/adr/017-tech-skill-mapping-table-inline-convention.md` using the `docs/templates/adr-template.md` template. Pre-filled by sdd-ff agent — confirmed present with correct title, status, context, and decision.

- [x] 2.2 Append a new row to the ADR index table in `docs/adr/README.md`:
  `| [017](017-tech-skill-mapping-table-inline-convention.md) | Tech Skill Mapping Table — Inline Convention in sdd-apply | Proposed | 2026-03-03 |`
  Pre-added by sdd-ff agent — confirmed present.

## Phase 3: Deploy and Verify

- [x] 3.1 Run `bash install.sh` from the repo root (`C:/Users/juanp/claude-config`) to deploy the updated `skills/sdd-apply/SKILL.md` to `~/.claude/skills/sdd-apply/SKILL.md`. Result: 47 skills loaded, no errors.

- [x] 3.2 Update `ai-context/changelog-ai.md` — entry appended: `2026-03-03 | tech-skill-auto-activation | Added Step 0 to sdd-apply with Stack-to-Skill Mapping Table and scope guard; added ADR-017.`

---

## Implementation Notes

- All edits are in Markdown (`.md`) files — no code compilation or test runner required.
- Step 1.1 and 1.2 are in the same file (`skills/sdd-apply/SKILL.md`) and should be done together in one edit session to avoid conflicting writes.
- Step 1.3 is in the same file — do it in the same pass as 1.1 and 1.2 to minimize round-trips.
- The ADR must be created AFTER the design is complete (this task plan IS the completion of design + tasks).
- `install.sh` must be run after SKILL.md is edited, not before — task 3.1 is the deploy step.

## Blockers

None. All dependencies (template file, ADR README, skill file) are confirmed present.
