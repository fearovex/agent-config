# Task Plan: deprecate-commands-normalize-skills

Date: 2026-02-26
Design: openspec/changes/deprecate-commands-normalize-skills/design.md

## Progress: 15/15 tasks

---

## Phase 1: Remove Commands Dimension from project-audit (D5 + D1 check)

- [x] 1.1 Modify `skills/project-audit/SKILL.md` — remove the "Has Commands registry" row from the Dimension 1 checks table (the row that assigns a MEDIUM severity when the commands table is absent from CLAUDE.md)
- [x] 1.2 Modify `skills/project-audit/SKILL.md` — remove the "Commands registry present" row from the Dimension 1 report format block (the table inside the D1 template section)
- [x] 1.3 Modify `skills/project-audit/SKILL.md` — remove the entire "Dimension 5 — Commands Quality" section (all sub-checks 5a, 5b, their rubric, and the section heading)
- [x] 1.4 Modify `skills/project-audit/SKILL.md` — remove the D5 row from the Score table inside the Report Format section (the row "Commands registry complete and functional")
- [x] 1.5 Modify `skills/project-audit/SKILL.md` — remove the "## Dimension 5 — Commands" block from the report template (the block that defines the generated audit-report.md D5 section)

## Phase 2: Expand Dimension 4 scoring in project-audit

- [x] 2.1 Modify `skills/project-audit/SKILL.md` — update the D4 max points value from 10 to 20 in the Score table inside the Report Format section (the row "Skills registry complete and functional — max: 10" → max: 20)
- [x] 2.2 Modify `skills/project-audit/SKILL.md` — update the D4 row in the Detailed Scoring table at the bottom of the file to show a maximum of 20 points and include both sub-criteria (registry accuracy + content depth = 10 pts; global tech skills coverage = 10 pts)
- [x] 2.3 Modify `skills/project-audit/SKILL.md` — promote D4c (recommended global skills coverage) from informational to scored: replace any "INFO only" or "no score" note with the new rubric (no relevant skills or all applicable added = 10 pts; ≥75% = 8 pts; 50–74% = 5 pts; 25–49% = 2 pts; <25% = 0 pts)
- [x] 2.4 Modify `skills/project-audit/SKILL.md` — update the D4 section's stated maximum points cap from 10 to 20 wherever it appears inside the Dimension 4 evaluation block

## Phase 3: Add INFO notice for legacy commands/ detection in project-audit

- [x] 3.1 Modify `skills/project-audit/SKILL.md` — add a conditional INFO/LOW finding block in the Phase A discovery section: "If `.claude/commands/` directory exists on disk → emit LOW finding: 'Legacy `.claude/commands/` directory detected — migrate to `.claude/skills/` following the official Claude Code standard.' No score penalty. No FIX_MANIFEST entry."

## Phase 4: Update project-fix — remove step 2.4 and add no-commands rule

- [x] 4.1 Modify `skills/project-fix/SKILL.md` — remove the entire "Step 2.4 Fix Commands registry" block (the step that created or repaired the commands registry in target projects)
- [x] 4.2 Modify `skills/project-fix/SKILL.md` — add an explicit rule to the Rules section: "NEVER touch `.claude/commands/` — commands/ is a deprecated mechanism; this skill does not create, modify, or delete files under that path. Any FIX_MANIFEST action of type `fix_commands_registry` or targeting `.claude/commands/` MUST be skipped and noted in the output as 'skipped — commands/ is deprecated'."

## Phase 5: Update project-setup — add no-commands rule

- [x] 5.1 Modify `skills/project-setup/SKILL.md` — add one explicit rule to the Rules section: "NEVER create a `.claude/commands/` directory — commands/ is a legacy mechanism; `.claude/skills/` is the only supported extensibility path for new projects."

## Phase 6: Deploy, verify, and document

- [x] 6.1 Run `bash install.sh` from `C:/Users/juanp/claude-config` to deploy all modified SKILL.md files to `~/.claude/`
- [x] 6.2 Run `/project-audit` on the claude-config repo and confirm: (a) D4 max shows 20 pts, (b) no D5 row in score table, (c) total is 100, (d) new score >= baseline in `.claude/audit-report.md`
- [x] 6.3 Create `openspec/changes/deprecate-commands-normalize-skills/verify-report.md` with at least one `[x]` checked criterion documenting the audit run result

---

## Implementation Notes

- Task ordering within each phase respects the logical structure of `project-audit/SKILL.md`: Phase A discovery → D1 section → D4 section → D5 section → Report Format (score table) → Report Template (D5 block) → Detailed Scoring table. Edit in this order to avoid confusing line references.
- The TOTAL row in the score table must remain 100 after the changes in Phase 1 and Phase 2. Verify the arithmetic after task 2.1 before proceeding to 2.2+.
- The D4c rubric defined in design.md is the authoritative source for task 2.3. Copy it verbatim to avoid introducing a discrepancy between design and implementation.
- The INFO notice in task 3.1 carries zero score impact and generates NO FIX_MANIFEST entry. Do not add a `required_actions` entry for it.
- CLAUDE.md at the repo root requires no changes — design confirmed zero commands references exist there.
- `ai-context/` files require no updates for this change — the architecture and conventions docs do not mention commands/.

## Blockers

None.

All prior artifacts (proposal, specs, design) are complete and consistent. No external dependencies or missing information prevent implementation.
