# Task Plan: user-docs-and-onboard-skill

Date: 2026-02-26
Design: openspec/changes/user-docs-and-onboard-skill/design.md

## Progress: 0/20 tasks

---

## Phase 1: New Documentation Files

- [ ] 1.1 Create `ai-context/scenarios.md` — 6-case onboarding guide, each case following the fixed template: `# Scenarios`, `> Last verified: 2026-02-26`, then Case 1–6 sections each with: **Symptoms**, **Command sequence**, **Expected outcome per command**, and **Common failure modes** table. Case 1 = brand-new (no `.claude/CLAUDE.md`); Case 2 = CLAUDE.md only (no SDD); Case 3 = partial SDD (openspec exists, ai-context sparse); Case 4 = local skill clutter in `.claude/skills/`; Case 5 = orphaned/stale changes in `openspec/changes/`; Case 6 = fully configured (start new feature with `/sdd-ff` or `/sdd-new`). Case 6 must NOT include `/project-setup`.

- [ ] 1.2 Create `ai-context/quick-reference.md` — single-page compact reference with `> Last verified: 2026-02-26` on the second line, then four sections in order: (1) "Your Situation → First Command" table with at least 5 rows; (2) "SDD Flow" section with the full phase ASCII diagram in a code block (explore → propose → spec/design → tasks → apply → verify → archive); (3) "Command Glossary" table listing all 9 meta-tool commands and all 11 SDD phase commands (one line each, alphabetical within each group); (4) "/sdd-ff vs /sdd-new" decision rule section containing a clear, self-contained criterion that does not require reading CLAUDE.md.

---

## Phase 2: New Skill — project-onboard

- [ ] 2.1 Create directory `skills/project-onboard/` and create `skills/project-onboard/SKILL.md` — SKILL.md header: `# project-onboard`, one-liner description, `**Triggers**: /project-onboard`. Include a **Process** section with the 5-step waterfall detection algorithm in strict priority order: Step 1 check `.claude/CLAUDE.md` (absent → Case 1); Step 2 check `openspec/config.yaml` (absent → Case 2); Step 3 check `ai-context/` with ≥ 4 of the 5 memory files populated (fewer → Case 3, list missing files); Step 4 (non-blocking) check `.claude/skills/` for local skill directories — flag for review if found, but continue; Step 5 check `openspec/changes/` for directories outside `archive/` that are missing `tasks.md` or `verify-report.md` (found → Case 5, list orphaned changes with which file is missing each); Step 6 — all healthy → Case 6.

- [ ] 2.2 Add **Output Format** section to `skills/project-onboard/SKILL.md` — define the structured diagnosis block contract exactly as specified in the design: `## Diagnosis`, `Project state: [Case N — Label]`, `Detected:` bullet list of evidence (specific files checked and their presence/absence), `Warnings:` section for secondary issues (stale docs, local skill flags), `## Recommended Command Sequence` numbered list, `## Notes` section. Specify that warnings for stale `ai-context/onboarding.md` (Last verified > 90 days) must be surfaced even when the primary case is 6, suggesting `/project-update`. Specify that the skill is read-only and must not create, modify, or delete any project files.

- [ ] 2.3 Add **Rules** section to `skills/project-onboard/SKILL.md` — must include: (a) Do not ask the user any questions; (b) Detection is derived from real file-system state — no hardcoded case lookup tables; (c) Priority order is strict — once a case is assigned at step N, do not also assign a lower-priority case (exception: Check 4 local skill flag is always surfaced as a warning, non-blocking); (d) Emit structured output only — no raw file listings or stack traces; (e) Make no file-system changes.

---

## Phase 3: Existing Skill Modifications

- [ ] 3.1 Modify `skills/project-audit/SKILL.md` — in the Dimension 2 (D2) section, append two new sub-checks after the existing file checks. Sub-check A: `ai-context/scenarios.md` — (1) if absent: emit LOW finding "scenarios.md missing — create via /project-onboard or manually"; (2) if present: read first 10 lines, search for `^> Last verified: (\d{4}-\d{2}-\d{2})$`; if field absent or malformed: emit LOW "Last verified field not found or malformed in scenarios.md"; if date > 90 days from today: emit LOW "scenarios.md stale (N days since last verification)"; if ≤ 90 days: no finding. Sub-check B: identical logic for `ai-context/quick-reference.md`. Explicitly note in both sub-checks that LOW severity findings are informational only and do NOT deduct from the D2 numeric score.

- [ ] 3.2 Modify `skills/sdd-archive/SKILL.md` — in Step 1 (verify it is archivable): add a sub-step that reads `verify-report.md` and surfaces the user-docs review checkbox status to the user as: "User docs review checkbox: [CHECKED / UNCHECKED / ABSENT]". This display is non-blocking — the archive operation continues regardless. In Step 5 (or the closure note / summary template at the end of the skill): add a `User Docs Reviewed:` field to the closure output. In the verify-report template embedded in the skill (if present): add the checkbox line `[ ] Review user docs (scenarios.md / quick-reference.md / onboarding.md) if this change affects user-facing workflows`.

- [ ] 3.3 Modify `skills/project-update/SKILL.md` — after Step 1 (quick diagnosis), insert Step 1b: Stale-doc scan. The step must: (a) attempt to read `ai-context/onboarding.md`, `ai-context/scenarios.md` (if exists), `ai-context/quick-reference.md` (if exists); (b) for each file that exists, search for `^> Last verified: (\d{4}-\d{2}-\d{2})$` in the first 10 lines; (c) if field is absent or malformed, treat as infinitely stale; (d) if date > 90 days from today, add to the proposed change plan as a "REFRESH" item; (e) if file does not exist, skip silently (no error); (f) in Step 3 (execution), for each REFRESH item, offer regeneration with explicit user confirmation before overwriting — never automatic.

---

## Phase 4: Registry and Architecture Updates

- [ ] 4.1 Modify `CLAUDE.md` — in the "Meta-tools Skills" group of the Skills Registry section, add one new row: `- \`~/.claude/skills/project-onboard/SKILL.md\`` with a description that reads "diagnosing the current project state, detecting which of 6 onboarding cases applies, and recommending the exact command sequence". Also add `project-onboard` to the "Available Commands → Meta-tools" table with action: "Reads project file system, detects onboarding case (1-6), recommends first command".

- [ ] 4.2 Modify `ai-context/architecture.md` — in the artifact/file table (or the equivalent section documenting known ai-context files and skills), add three new rows: (1) `ai-context/scenarios.md` — 6-case onboarding guide, case-based entry point for users arriving at different project states; (2) `ai-context/quick-reference.md` — single-page SDD quick reference, situation table + glossary + flow diagram; (3) `skills/project-onboard/SKILL.md` — automated project state diagnostic, triggered by `/project-onboard`.

---

## Phase 5: Verification and Sync

- [ ] 5.1 Verify `ai-context/scenarios.md` manually — open the file and confirm: exactly 6 case sections present; each case contains Symptoms, Command sequence, Expected outcome per command, and Common failure modes table; Case 6 does not include `/project-setup`; `Last verified:` field is on the second line in the format `> Last verified: YYYY-MM-DD`.

- [ ] 5.2 Verify `ai-context/quick-reference.md` manually — open the file and confirm: `Last verified:` field on second line; situation table has ≥ 5 rows; SDD flow ASCII diagram is in a code block; glossary lists all 9 meta-tool commands and all 11 SDD phase commands; `/sdd-ff` vs `/sdd-new` decision rule is present and self-contained.

- [ ] 5.3 Verify `skills/project-onboard/SKILL.md` — open the file and confirm: trigger is `/project-onboard`; 5-check waterfall is documented in priority order; output format matches the design contract; Rules section states no questions, no file-system changes, no raw listings; skill is discoverable from CLAUDE.md Skills Registry.

- [ ] 5.4 Verify `skills/project-audit/SKILL.md` — open the D2 section and confirm: two new sub-checks for `scenarios.md` and `quick-reference.md` are present; each sub-check handles the three states (absent, malformed date, stale date); LOW severity is stated explicitly; no score deduction is mentioned.

- [ ] 5.5 Verify `skills/sdd-archive/SKILL.md` and `skills/project-update/SKILL.md` — confirm: sdd-archive has the user-docs review checkbox in the verify-report template and surfaces it in Step 1 (non-blocking); project-update has the Step 1b stale-doc scan with all five behaviors (read, parse, treat-absent-as-stale, add-to-plan, skip-missing-silently) and requires explicit confirmation before regenerating.

- [ ] 5.6 Run `sync.sh` from the repo root to propagate all new and modified files to `~/.claude/` — confirm the command exits with status 0 and that `~/.claude/skills/project-onboard/SKILL.md`, `~/.claude/ai-context/scenarios.md`, and `~/.claude/ai-context/quick-reference.md` exist in the runtime directory after sync.

- [ ] 5.7 Run `/project-audit` on `claude-config` — confirm: D2 emits no LOW findings for `scenarios.md` or `quick-reference.md` (both files exist with fresh dates); overall score is >= score recorded before this change was applied; no new HIGH or MEDIUM findings introduced by the changes.

---

## Implementation Notes

- `Last verified:` field format is `> Last verified: YYYY-MM-DD` (Markdown blockquote). It must appear on the **second line** of the file, immediately after the `# Title` heading. Parser regex used by D2 and project-update is `^> Last verified: (\d{4}-\d{2}-\d{2})$`.
- Check 4 in the project-onboard waterfall is **non-blocking** — a project can be simultaneously in Case 6 (healthy SDD) and have local skill issues. The skill surfaces both, with the local skill issue as a warning appended to the Case 6 diagnosis.
- All edits to existing SKILL.md files are **strictly additive** — no existing content is removed or reordered. New steps or sub-checks are inserted at the specified positions.
- The `sdd-archive` user-docs checkbox must NOT block the archive operation. It is surfaced as informational and noted in the output.
- The `project-update` regeneration must NEVER be automatic. The user must explicitly confirm before any file is overwritten.
- After `sync.sh`, run `install.sh` if the runtime environment requires it to pick up changes.

## Blockers

None. All dependencies confirmed in the proposal:
- `ai-context/onboarding.md` exists (created by archived change `enhance-project-audit-skill-review`).
- `skills/project-audit/SKILL.md` is at the D9-extended version.
- `skills/sdd-archive/SKILL.md` and `skills/project-update/SKILL.md` are both present in the skills catalog.
- Project-audit score on `claude-config` is confirmed >= 75 (pre-condition for apply).
