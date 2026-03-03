# Task Plan: claude-folder-audit

Date: 2026-03-03
Design: openspec/changes/claude-folder-audit/design.md

## Progress: 9/9 tasks

---

## Phase 1: Skill Creation

- [x] 1.1 Create `skills/claude-folder-audit/SKILL.md` ✓ with YAML frontmatter (`name`, `description`, `format: procedural`), **Triggers** block, `## Purpose`, `## Process` (Steps 1–5: path normalization, mode detection, 5 audit checks, report generation, summary output), `## Rules`; the Process section must implement all 5 checks per spec folder-audit-execution and emit findings in schema `{severity, check, title, detail, remediation}`; report must be written to the expanded path of `~/.claude/claude-folder-audit-report.md` in the format defined in spec folder-audit-reporting (header, findings summary table, per-check sections with `## Check N — <Name>`, `## Findings Summary`, `## Recommended Next Steps`)

---

## Phase 2: Integration

- [x] 2.1 Modify `CLAUDE.md` ✓ — add `### System Audits` subsection under `## Skills Registry` with entry: `- \`~/.claude/skills/claude-folder-audit/SKILL.md\` — audits the ~/.claude/ runtime folder for installation drift, skill deployment gaps, orphaned artifacts, and scope tier compliance`
- [x] 2.2 Modify `skills/project-onboard/SKILL.md` ✓ — add Check 7 (non-blocking, global-config mode only) after Check 6 in the Process section: when `install.sh` and `skills/` exist at project root, append to the Warnings section of any case diagnosis the line `"- Run /claude-folder-audit to verify ~/.claude/ is in sync with this repo (installation drift check)."`; this check MUST NOT change case assignment or stop processing

---

## Phase 3: Verification Inputs

- [x] 3.1 Manually run the skill on the `claude-config` project ✓ (`C:/Users/juanp/claude-config`) and confirm `~/.claude/claude-folder-audit-report.md` is created; inspect it to verify: (a) header includes Mode, Runtime root, Source root, Run date; (b) `## Findings Summary` table is present; (c) each check section appears; (d) `## Recommended Next Steps` section is present
- [x] 3.2 Confirm the skill produces zero writes ✓ to any file other than `~/.claude/claude-folder-audit-report.md` during execution (read-only constraint per spec)
- [x] 3.3 Confirm Windows path handling ✓: report path uses forward slashes and resolves to `C:/Users/juanp/.claude/claude-folder-audit-report.md` (not a tilde-unexpanded path)

---

## Phase 4: Deployment and Audit

- [x] 4.1 Run `install.sh` ✓ from `C:/Users/juanp/claude-config` to deploy `skills/claude-folder-audit/` to `~/.claude/skills/claude-folder-audit/`
- [x] 4.2 Run `/project-audit` ✓ and confirm D1 (Skills Registry integrity) passes for `claude-folder-audit` and D4 (skill format compliance) passes for the new skill

---

## Phase 5: Documentation and Memory

- [x] 5.1 Update `ai-context/changelog-ai.md` ✓ — record the addition of `claude-folder-audit` skill, the `CLAUDE.md` registry entry, and the `project-onboard` Check 7 hint

---

## Implementation Notes

- The SKILL.md Process section is the executable specification: Claude reads and follows it step-by-step. Write it as an ordered instruction set, not a prose description.
- Path normalization must follow the `install.sh` priority chain: `$HOME` first, then `$USERPROFILE`, then `$HOMEDRIVE$HOMEPATH`. Never rely on shell tilde expansion.
- All 5 checks must run regardless of whether earlier checks produce HIGH findings (no early abort).
- Severity caps: Check 3 (drift) findings must not exceed MEDIUM; Check 4 (orphaned artifacts) findings must not exceed MEDIUM.
- The report overwrites the previous run — never appends.
- The project-onboard Check 7 is non-blocking: it only appends a warning line; it must not alter the case assignment or interrupt the existing 6-check waterfall.
- The CLAUDE.md `### System Audits` section must be created only if it does not already exist; if it exists, append under it.
- `openspec/changes/` subdirectories in the runtime are INFO notes, not MEDIUM findings (they are work-in-progress SDD artifacts).

## Blockers

None.
