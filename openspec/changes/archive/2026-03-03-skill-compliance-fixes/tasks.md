# Task Plan: skill-compliance-fixes

Date: 2026-03-03
Design: openspec/changes/skill-compliance-fixes/design.md

## Progress: 6/6 tasks

## Phase 1: Apply Compliance Fixes

- [x] 1.1 Edit `skills/smart-commit/SKILL.md` — insert the line `**Triggers**: When the user says "commit", "smart commit", or /commit.` on a new line immediately after the `> Analyzes staged and unstaged files...` blockquote description block (after the closing line of the blockquote, before the `## When to Use` heading). Preserve all existing content. ✓

- [x] 1.2 Edit `skills/project-analyze/SKILL.md` — in Step 6, insert the following sentence immediately after the closing ``` fence of the merge algorithm pseudocode block (the block that ends with `WRITE updated file`), before the `**Print summary to user:**` paragraph: `Use the Read tool to load each target file, compute the merged content in-context, then use the Write tool to write the updated file. Do not use Bash or the Edit tool for this merge.` ✓

- [x] 1.3 Edit `skills/config-export/SKILL.md` — in Step 3, insert the following two sentences immediately before the `#### Copilot transformation prompt` sub-heading: `These transformation prompts are self-instructions executed by the agent using its own in-context LLM reasoning. No external API call, subprocess, or tool invocation is required to apply them — the agent reads the prompt and generates the output directly.` ✓

## Phase 2: Deploy and Verify

- [x] 2.1 Run `bash install.sh` from the repo root (`C:/Users/juanp/claude-config/`) to deploy the updated skill files to `~/.claude/skills/` ✓

- [x] 2.2 Verify `~/.claude/skills/smart-commit/SKILL.md` contains the `**Triggers**` line — use Read tool to confirm the line is present ✓

- [x] 2.3 Run `/project-audit` and confirm the audit score is >= the score before this change was applied; create `openspec/changes/skill-compliance-fixes/verify-report.md` with at least one `[x]` criterion checked ✓

---

## Implementation Notes

- All edits MUST use the Edit tool (targeted replacement), not the Write tool (full overwrite), to minimize the risk of introducing unintended whitespace or encoding differences.
- The smart-commit Triggers line MUST match the bold-trigger pattern exactly: starts with `**Triggers**` (double asterisks, no space before the colon). Variants like `**Trigger**` (singular) or `## Triggers` will fail the P2-C scanner.
- The project-analyze sentence must be inserted AFTER the closing ``` of the pseudocode block and BEFORE `**Print summary to user:**` — not inside the pseudocode block itself.
- The config-export sentences must appear BEFORE the `#### Copilot transformation prompt` line — not after, not between the three prompt sub-sections.
- Do not modify any other content in the three SKILL.md files beyond the specified insertions.

## Blockers

None.
