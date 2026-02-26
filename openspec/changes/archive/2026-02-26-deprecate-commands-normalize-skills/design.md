# Technical Design: deprecate-commands-normalize-skills

Date: 2026-02-26
Proposal: openspec/changes/deprecate-commands-normalize-skills/proposal.md

## General Approach

This change is a targeted textual surgery on four files: `skills/project-audit/SKILL.md`,
`skills/project-fix/SKILL.md`, `skills/project-setup/SKILL.md`, and `CLAUDE.md`. No new
files are created. No behavioral logic is added. The work consists of removing all audit
pressure toward `.claude/commands/`, redistributing 10 freed scoring points from D5 to D4,
and adding a zero-penalty INFO notice for projects that still have a legacy `commands/`
directory. After apply, `install.sh` deploys the updated files to `~/.claude/`.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|---------------|
| Remove D5 entirely vs. reduce its weight | Remove entirely (0 pts) | Keep D5 at 5 pts, merge into D6 | D5 has no valid scoring purpose once commands/ is deprecated. Any residual weight still penalizes modern-standard projects. Full removal is unambiguous. |
| Redistribute freed 10 pts to D4 vs. spread across all | Assign all 10 pts to D4 (Skills) | Distribute 5+5 to D4+D6, or add a new D10 | D4 (Skills Quality) is the direct replacement for D5 (Commands Quality). Moving the full weight there preserves the total-100 invariant with minimal score table changes. |
| D4 expansion strategy — how to make the extra 10 pts earnable | New D4c tier: recommended global skills coverage becomes scored (0–10 pts) | Inflate existing 4a/4b rubric, add new D4 sub-dimension for skills depth | D4c already exists as an informational check. Promoting it to scored (10 pts) requires real work from projects and avoids phantom score inflation. |
| INFO notice placement — D1 sub-check vs. standalone note | Standalone note inside Phase A discovery block comment in project-audit SKILL.md | Add as a D1 row in the checks table | A D1 row would imply a fix action and FIX_MANIFEST entry. A standalone note with no score and no FIX_MANIFEST action matches the "zero penalty" requirement cleanly. |
| project-fix step 2.4 — remove vs. leave as no-op | Remove the entire step 2.4 block | Replace handler body with a comment, keep the heading | Removing it eliminates dead code. An old FIX_MANIFEST entry of type `fix_commands_registry` will hit the "no handler — skipped" path, which is safe. |
| project-setup rules — add explicit note vs. no change | Add one-line explicit rule: "NEVER create a `.claude/commands/` directory" | No change needed since setup never created one | The proposal explicitly calls this out. Adding the rule makes the constraint self-documenting for future maintainers of the skill. |
| CLAUDE.md audit dimensions description — update vs. no change | No change needed | Grep showed zero commands-related references in CLAUDE.md | The file already contains no commands registry references. Touching it for this change is unnecessary and would bloat the diff. |

## Data Flow

This change affects the audit → fix pipeline. The modified flow after apply:

```
/project-audit
    │
    ├── Phase A discovery (bash script)
    │       └── [NEW] if d(".claude/commands") == 1
    │               → emit INFO finding: legacy commands/ detected
    │               → zero score penalty, no FIX_MANIFEST entry
    │
    ├── Dimension 1 checks
    │       └── [REMOVED] "Has Commands registry" row
    │               (was: ⚠️ MEDIUM if missing)
    │
    ├── Dimension 4 — Skills Quality  [EXPANDED: 10 → 20 pts]
    │       ├── 4a. Registry vs disk  (unchanged)
    │       ├── 4b. Minimum content   (unchanged)
    │       └── 4c. Global tech skills coverage  [PROMOTED: info → scored, 0–10 pts]
    │
    ├── Dimension 5 — Commands Quality  [REMOVED]
    │
    └── Score table
            └── D4 max: 10 → 20 pts
                D5 row: removed
                Total: still 100 pts
                                          │
                                          ▼
                                  audit-report.md
                                          │
                                          ▼
                               /project-fix reads FIX_MANIFEST
                                          │
                                          ├── Phase 2.4 Fix Commands registry  [REMOVED]
                                          │
                                          └── (all other phases unchanged)
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `skills/project-audit/SKILL.md` | Modify | (1) Remove row "Has Commands registry" from D1 checks table (line 66); (2) Add INFO notice block for legacy commands/ detection after the D1 section or in the Phase A script note; (3) Remove entire "Dimension 5 — Commands Quality" section (lines 192–208); (4) Remove D5 row from Score table in Report Format (line 445); (5) Remove D5 dimension block from report template ("## Dimension 5 — Commands [OK]" section, lines 535–545); (6) Update D4 max pts from 10 → 20 in report Score table (line 444); (7) Update D4 detailed scoring row (line 633) to 20 pts with expanded description; (8) Remove "Commands" row from Detailed Scoring table (line 634); (9) Promote D4c from informational to scored with 0–10 pts rubric |
| `skills/project-fix/SKILL.md` | Modify | (1) Remove step "2.4 Fix Commands registry" block (line 231–233 region); (2) Add explicit execution rule: "NEVER touch `.claude/commands/` — commands/ is a deprecated mechanism; this skill does not create, modify, or delete files under that path" |
| `skills/project-setup/SKILL.md` | Modify | Add one line to the Rules section: "NEVER create a `.claude/commands/` directory — commands/ is a legacy mechanism; skills/ is the only supported extensibility path" |
| `CLAUDE.md` (repo root) | No change | Grep confirms zero commands-related references — file is already clean |

## Interfaces and Contracts

This change is purely textual (Markdown edits). No new interfaces, types, DTOs, or YAML
schemas are introduced. The FIX_MANIFEST schema in `project-audit/SKILL.md` is unchanged
(no new action types required). The removed `fix_commands_registry` action type disappears
silently from the schema — any stale FIX_MANIFEST entry of that type will be handled by
project-fix's existing "no handler — skipped" path.

The only behavioral contract change:

```
BEFORE:
  project-audit score table: D4 max=10, D5 max=10, total=100
  D1 MEDIUM finding possible: "Has Commands registry" missing
  D5 findings possible: commands/ registry drift

AFTER:
  project-audit score table: D4 max=20, D5 row absent, total=100
  D1: no "Has Commands registry" row — no MEDIUM finding for this
  D5: dimension does not exist
  INFO notice (zero score): emitted only if .claude/commands/ exists on disk
  D4c: scored 0–10 pts (global tech skills coverage)
```

## D4c Scoring Rubric (new)

The promoted D4c sub-dimension awards 0–10 points based on how many of the
stack-relevant global skills are installed in the project:

| Coverage | Points |
|----------|--------|
| No relevant global skills detected in stack, or all applicable ones already added | 10 (full credit) |
| ≥ 75% of applicable global skills installed | 8 |
| 50–74% installed | 5 |
| 25–49% installed | 2 |
| < 25% installed (relevant skills exist but none added) | 0 |

"Applicable" means: the project stack uses the technology AND a matching global
skill exists in `~/.claude/skills/`. Projects with no matching global skills get
full credit automatically (nothing to add).

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Integration (manual) | Run `/project-audit` on a project with NO `.claude/commands/` — verify score row for D5 is absent, D4 max shows 20, total is still 100 | /project-audit |
| Integration (manual) | Run `/project-audit` on a project WITH `.claude/commands/` — verify INFO notice appears, zero score impact | /project-audit |
| Integration (manual) | Run `/project-fix` on an audit report that has NO `fix_commands_registry` entry — verify no commands/ files created | /project-fix |
| Regression (manual) | Run `/project-audit` on claude-config itself — verify new score >= previous score | /project-audit |
| Smoke (manual) | Run `/project-setup` on a blank test directory — verify no `.claude/commands/` directory is created | /project-setup |

No automated test framework exists in this repo (SKILL.md files, not code). Verification
is performed by running the actual skills against real projects, as documented above.

## Migration Plan

No data migration required.

All changes are in SKILL.md files and CLAUDE.md (which requires no changes). After apply:
1. Run `bash install.sh` from repo root to deploy updated files to `~/.claude/`
2. Run `/project-audit` on this repo (claude-config) to confirm score >= previous
3. Record result in `verify-report.md`
4. `git commit` with message `feat(audit): deprecate commands dimension, normalize scoring to skills`

## Open Questions

None.

All ambiguities in the proposal were resolved during design:
- CLAUDE.md requires no changes (no commands references existed).
- D4c scoring rubric is fully defined above.
- The INFO notice will be placed as an explicit conditional note inside the Phase A script
  commentary section of `project-audit/SKILL.md`, after the orphaned-changes detection block.
  It emits a LOW finding with no FIX_MANIFEST entry and no score impact.
