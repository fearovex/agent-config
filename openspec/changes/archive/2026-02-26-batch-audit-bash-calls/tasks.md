# Task Plan: batch-audit-bash-calls

Date: 2026-02-26
Design: openspec/changes/batch-audit-bash-calls/design.md

## Progress: 3/4 tasks

---

## Phase 1: Settings — Permissions

- [x] 1.1 Modify `settings.json` — add `"Bash"` as a new entry in the `permissions.allow` array, preserving all existing entries (`"Read"`, `"Glob"`, `"Grep"`) and all other top-level fields (`alwaysThinkingEnabled`, `effortLevel`, `model`, `mcpServers`) unchanged ✓

---

## Phase 2: Skill — Batching Rule

- [x] 2.1 Modify `skills/project-audit/SKILL.md` — append a new rule (Rule 8) inside the existing `## Execution Rules` section (after rule 7 `"When finished, I notify the user: ..."`) with the following content:
  - Rule text: "All shell-based discovery MUST be consolidated into a single Bash script call (Phase A). Maximum 3 Bash calls per audit run. Never issue individual `ls`, `grep`, `wc -l`, or `find` calls per dimension."
  - Immediately after the rule, embed the full inline shell script template (fenced `sh` block) from `openspec/changes/batch-audit-bash-calls/design.md` section "Reference script template" — the script that collects all structural facts and outputs `key=value` lines.
  - After the script block, document the output key schema (one-line description per key: CLAUDE_MD_EXISTS, ROOT_CLAUDE_MD_EXISTS, OPENSPEC_EXISTS, CONFIG_YAML_EXISTS, INSTALL_SH_EXISTS, SYNC_SH_EXISTS, STACK_MD_EXISTS, ARCH_MD_EXISTS, CONV_MD_EXISTS, ISSUES_MD_EXISTS, CHANGELOG_MD_EXISTS, CLAUDE_MD_LINES, STACK_MD_LINES, ORPHANED_CHANGES, SDD_SKILLS_PRESENT)
  - No other sections of SKILL.md are modified (dimensions, report format, scoring, existing rules 1–7 are untouched) ✓

---

## Phase 3: Verification Artifacts

- [x] 3.1 Run `install.sh` from `C:/Users/juanp/claude-config` to deploy updated `settings.json` and `skills/project-audit/SKILL.md` to `~/.claude/` (shell command: `bash C:/Users/juanp/claude-config/install.sh`) ✓

- [ ] 3.2 Create `openspec/changes/batch-audit-bash-calls/verify-report.md` — after manual test, record the results: whether `/project-audit` ran without Bash approval prompts, whether the report format matches pre-change output, and the audit score on claude-config itself (must be >= baseline)

---

## Implementation Notes

- The script template to embed verbatim is in `design.md` under the heading "Reference script template (to be embedded in SKILL.md)". Copy the `sh` fenced block exactly — do not alter the script logic.
- Task 2.1 modifies only the `## Execution Rules` section. All dimension descriptions, report format, and scoring rules remain untouched.
- Task 1.1 modifies only the `permissions.allow` array. The `mcpServers` block must not change.
- Task 3.1 must run after both 1.1 and 2.1 are complete.
- Task 3.2 (verify-report.md) requires a manual `/project-audit` run by the user after `install.sh` completes. It cannot be automated.

## Blockers

None. Both target files are standalone text files with no external dependencies.
