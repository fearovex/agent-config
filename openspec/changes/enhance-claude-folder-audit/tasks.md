# Task Plan: enhance-claude-folder-audit

Date: 2026-03-03
Design: openspec/changes/enhance-claude-folder-audit/design.md

## Progress: 15/17 tasks

---

## Phase 1: Foundation — ADR and Documentation

- [x] 1.1 Create `docs/adr/016-enhance-claude-folder-audit-content-quality-convention.md` — new ADR documenting the content-quality-as-sub-phase convention for project-mode audit checks; status: Accepted; context must reference ADR-015 and the P1-Phase C / P2/P3-Phase C / P6 / P7 / P8 pattern ✓
- [x] 1.2 Modify `docs/adr/README.md` — append one row to the index table for ADR-016 with columns: Number, Title, Status, Date (2026-03-03) ✓

---

## Phase 2: SKILL.md — Check P1 Extension (CLAUDE.md content quality)

- [x] 2.1 Modify `skills/claude-folder-audit/SKILL.md` — in Check P1, add **Phase C — CLAUDE.md content quality** sub-block immediately after Phase B; the sub-block must: (a) read CLAUDE.md content; (b) check for required section headings (`## Tech Stack` or `## Stack`, `## Architecture`, `## Unbreakable Rules`, `## Plan Mode Rules`, `## Skills Registry`) using the line-prefix rule (`## <name>` starting the line); (c) produce a MEDIUM finding per missing section; (d) check total line count and produce MEDIUM if <30 lines or LOW if 30–50 lines; (e) check for `/sdd-ff` or `/sdd-new` anywhere and produce LOW if absent; (f) check for skill path entries under Skills Registry and produce LOW if none found ✓
- [x] 2.2 Modify `skills/claude-folder-audit/SKILL.md` — update the `check:` identifier comment in Step 3 header from `P1..P5` to `P1..P8` to reflect the new check count ✓

---

## Phase 3: SKILL.md — Check P2 and P3 Extension (SKILL.md frontmatter and section contracts)

- [x] 3.1 Modify `skills/claude-folder-audit/SKILL.md` — in Check P2, add **Phase C — SKILL.md content quality** sub-block after the existing reachability check loop; the sub-block applies only when SKILL.md exists and passed the P2 reachability check; it must: (a) verify YAML frontmatter presence (file starts with `---`); produce MEDIUM if absent and skip further sub-checks for that skill; (b) extract `format:` value; produce LOW if absent (default procedural); produce LOW if unrecognized value (default procedural); (c) run section contract check per format type: procedural requires `**Triggers**` or `## Triggers`, `## Process` or at least one `### Step N` heading, and `## Rules`; reference requires `**Triggers**` or `## Triggers`, `## Patterns` or `## Examples`, and `## Rules`; anti-pattern requires `**Triggers**` or `## Triggers`, `## Anti-patterns`, and `## Rules`; produce MEDIUM per missing required element; (d) count post-frontmatter body lines; produce LOW if <30; (e) check for `TODO:` anywhere; produce INFO if found ✓
- [x] 3.2 Modify `skills/claude-folder-audit/SKILL.md` — in Check P3, add the identical **Phase C — SKILL.md content quality** sub-block as task 3.1 (same logic, same findings, applied to local-registered skills); P4 orphaned skills are explicitly NOT subject to these sub-checks ✓

---

## Phase 4: SKILL.md — New Checks P6, P7, P8

- [x] 4.1 Modify `skills/claude-folder-audit/SKILL.md` — append **Check P6 — Memory Layer (ai-context/)** after Check P5; check must: (a) test for `<cwd>/ai-context/` directory presence; produce MEDIUM if absent (remediation: Run /memory-init) and skip file sub-checks; (b) if present, check each of the five required files (`stack.md`, `architecture.md`, `conventions.md`, `known-issues.md`, `changelog-ai.md`); produce LOW per missing file; (c) for each present file, count lines; produce INFO if <10 lines ✓
- [x] 4.2 Modify `skills/claude-folder-audit/SKILL.md` — append **Check P7 — Feature Domain Knowledge Layer (ai-context/features/)** after Check P6; check must: (a) test for `<cwd>/ai-context/features/` presence; produce INFO (not MEDIUM) if absent; (b) if present but contains only files starting with `_`, produce INFO; (c) note presence of `_template.md` as INFO; (d) for each non-template file (name does NOT start with `_`): check for 6 required section headings (`## Domain Overview`, `## Business Rules and Invariants`, `## Data Model Summary`, `## Integration Points`, `## Decision Log`, `## Known Gotchas`) using line-prefix rule; produce LOW per missing section; count lines and produce INFO if <30; (e) severity cap: P7 MUST NOT produce findings above LOW ✓
- [x] 4.3 Modify `skills/claude-folder-audit/SKILL.md` — append **Check P8 — .claude/ Folder Inventory** after Check P7; check must: (a) enumerate all items directly under `<cwd>/.claude/` (one level only, not recursive); compare against expected set: `CLAUDE.md`, `skills/`, `audit-report.md`, `claude-folder-audit-report.md`, `settings.json`, `settings.local.json`, `openspec/`, `ai-context/`, `hooks/`; produce MEDIUM per unexpected item (remediation: review manually; document in CLAUDE.md if intentional); (b) if `hooks/` is present, enumerate `.js` and `.sh` files within it; produce LOW per empty hook file; (c) if `hooks/` is absent, produce INFO; (d) if all items are expected, report inventory count as INFO ✓

---

## Phase 5: SKILL.md — Report Format and Rules Updates

- [x] 5.1 Modify `skills/claude-folder-audit/SKILL.md` — extend the project-mode report format template (Step 4) to append three new check section blocks after `## Check P5 — Scope Tier Overlap`: `## Check P6 — Memory Layer (ai-context/)`, `## Check P7 — Feature Domain Knowledge Layer (ai-context/features/)`, `## Check P8 — .claude/ Folder Inventory`; each block shows `[findings or "No findings."]`; all three must appear even when they produce zero findings ✓
- [x] 5.2 Modify `skills/claude-folder-audit/SKILL.md` — extend the project-mode Recommended Next Steps template to cover P6 and P8 remediation hints: when highest-severity is MEDIUM from P6, first step is "Run /memory-init to generate the ai-context/ memory layer for this project"; when highest-severity is MEDIUM from P8, first step references manual review of the unexpected `.claude/` item; when no HIGH or MEDIUM findings exist across all 8 checks, use "Project Claude configuration appears healthy — no required actions detected" ✓
- [x] 5.3 Modify `skills/claude-folder-audit/SKILL.md` — update the Rules section to add: (a) severity caps for all new checks: P6 MEDIUM max; P7 LOW max; P8 MEDIUM max; (b) INFO findings from check sections MUST NOT appear in the Findings Summary table (which covers HIGH/MEDIUM/LOW only); (c) section detection rule: a section is present when a line STARTS with `## <section-name>` (lines inside fenced code blocks are not considered); (d) the `name:` field is not a required frontmatter check for P2/P3 sub-checks (only `format:` is validated in addition to frontmatter presence) ✓

---

## Phase 6: Cleanup and Memory Update

- [x] 6.1 Remove empty orphan directory `openspec/changes/claude-folder-audit-deep-inspection/` using `rmdir` (must fail safely if directory is non-empty — do not use `rm -rf`) ✓
- [x] 6.2 Modify `ai-context/architecture.md` — add entry to the audit inventory section documenting the new checks: P1-Phase C (CLAUDE.md content quality), P2-Phase C and P3-Phase C (SKILL.md frontmatter and section contract), P6 (ai-context/ core files), P7 (ai-context/features/ layer), P8 (.claude/ folder inventory); update check count from 5 to 8 for project mode ✓
- [x] 6.3 Run `bash install.sh` from `C:/Users/juanp/claude-config` to deploy the updated `skills/claude-folder-audit/SKILL.md` to `~/.claude/skills/claude-folder-audit/SKILL.md` — verify the deployed file contains the new check sections ✓

---

## Implementation Notes

- The existing P1 Phase A and Phase B logic MUST be preserved verbatim — do not refactor or rename any identifiers. Phase C is purely additive.
- The existing P2 and P3 structural reachability logic MUST be preserved verbatim. Phase C content sub-checks run only when SKILL.md exists (i.e., passes P2/P3 reachability). P4 orphaned skills are explicitly excluded from content sub-checks.
- Section detection rule (applies uniformly to P1-Phase C, P2-Phase C, P3-Phase C, P7): a section is present when at least one line in the file STARTS with `## <section-name>` (top-level heading, no leading whitespace). Bold-trigger pattern (`**Triggers**`) is also a valid match for the Triggers section specifically.
- YAML frontmatter extraction (P2-Phase C, P3-Phase C): scan for a leading `---` line, find the closing `---`, and look for a `format: <value>` line inside the block. A simple line-prefix scan is sufficient — no YAML parser required.
- The Findings Summary table MUST include only HIGH / MEDIUM / LOW findings. INFO observations appear in their respective check sections but NEVER in the summary table.
- All new checks (P6, P7, P8) are additive — they do not modify or replace existing P1–P5 findings accumulation. All 8 checks run to completion regardless of findings from earlier checks (the only exception is the existing P2/P3 skip when P1 finds no CLAUDE.md — this behavior is preserved unchanged).
- P8 expected item set includes `ai-context/` and `hooks/` (confirmed from spec scenario for P8) in addition to the items listed in the design. The spec is the authoritative source for the expected set.
- rmdir on the orphan directory (task 6.1) is safe because the directory is confirmed empty. If it fails (non-empty), do not force-delete — investigate first.
- ADR-016 must reference ADR-015 (feature-domain-knowledge-layer) explicitly, as P7 is the V2 audit integration deferred in ADR-015.

## Blockers

None.

All prior artifacts (proposal, exploration, specs, design) are complete. The only external reference files (`docs/format-types.md`, `ai-context/features/_template.md`) are confirmed present.
