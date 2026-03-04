# Technical Design: skill-compliance-fixes

Date: 2026-03-03
Proposal: openspec/changes/skill-compliance-fixes/proposal.md

## General Approach

Three targeted text insertions into three existing SKILL.md files. No structural changes, no new files (beyond SDD artifacts). Each insertion is a single sentence or a single line that closes a compliance or clarity gap without altering any functional logic. The changes are applied using the Edit tool against the three files in the repo, then deployed via `install.sh`.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|---------------|
| Add `**Triggers**` as a standalone line above `## When to Use` in smart-commit | Insert `**Triggers**: When the user says "commit", "smart commit", or /commit.` as a new line after the blockquote description | Rename `## When to Use` heading to `**Triggers**`; add inline to existing heading | Adding a standalone bold-trigger line follows the pattern of all other procedural skills (sdd-ff, sdd-propose, etc.) and keeps `## When to Use` intact as a human-readable section header — zero behavioral regression risk |
| Specify Read + Write tools for project-analyze merge algorithm | Add one sentence to Step 6 naming Read and Write tools | Specify Edit tool; leave unspecified | The merge algorithm is a full file replacement (compute merged content then overwrite), not a targeted line replacement — Edit tool is inappropriate. The current skill produces correct output when agents use Read + Write; naming the tools codifies observed behavior |
| Position mechanism statement for config-export before the first prompt block | Insert before the `#### Copilot transformation prompt` sub-heading | Insert after each prompt individually; insert in a separate sub-step | A single statement before the first prompt applies to all three targets equally, avoids repetition, and is read before the agent encounters any prompt — natural reading order |
| Apply changes via Edit tool (not Write tool) | Edit tool — targeted diff | Write tool (full file overwrite) | Edit tool preserves all other content with surgical precision; full overwrite risks introducing whitespace or encoding differences in unrelated sections |

## Data Flow

These are documentation-only changes. No runtime data flow is altered. The affected flows for reference:

```
smart-commit execution (unchanged after fix):
  User: /commit
    → Agent reads skills/smart-commit/SKILL.md
    → Step 1: git status --porcelain + git diff --cached
    → Step 1b: grouping heuristic
    → Step 2: analyze changes → commit message
    → Step 3: detect issues
    → Step 4: present summary
    → Step 5: execute commit

project-analyze Step 6 merge (clarified, not changed):
  Agent reads target ai-context/ file (Read tool)
    → Computes merged content in-context
    → Writes updated file (Write tool)
    [Bash: NOT used for this step]
    [Edit tool: NOT used for this step]

config-export Step 3 transformation (clarified, not changed):
  Agent reads source bundle (CLAUDE.md + ai-context/)
    → Applies transformation prompt as self-instruction (in-context LLM reasoning)
    → Generates output content directly
    [No external API call]
    [No subprocess]
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `skills/smart-commit/SKILL.md` | Modify | Add `**Triggers**` bold-marker line after the blockquote description (line ~20), before `## When to Use` |
| `skills/project-analyze/SKILL.md` | Modify | Add one sentence to Step 6 merge algorithm block specifying Read and Write tools as the execution mechanism |
| `skills/config-export/SKILL.md` | Modify | Add one sentence before the `#### Copilot transformation prompt` sub-heading in Step 3 specifying the in-context LLM reasoning mechanism |

## Interfaces and Contracts

No new interfaces or contracts. The changes clarify existing contracts.

**smart-commit Triggers line (exact text to insert):**

```markdown
**Triggers**: When the user says "commit", "smart commit", or /commit.
```

Insert after the `> Analyzes staged and unstaged files...` blockquote description, before `## When to Use`.

**project-analyze Step 6 tool specification sentence (exact text to insert):**

```
Use the Read tool to load each target file, compute the merged content in-context, then use the Write tool to write the updated file. Do not use Bash or the Edit tool for this merge.
```

Insert immediately after the closing ``` fence of the merge algorithm pseudocode block in Step 6, before the `**Print summary to user:**` paragraph.

**config-export Step 3 mechanism statement (exact text to insert):**

```
These transformation prompts are self-instructions executed by the agent using its own in-context LLM reasoning. No external API call, subprocess, or tool invocation is required to apply them — the agent reads the prompt and generates the output directly.
```

Insert before the `#### Copilot transformation prompt` sub-heading in Step 3.

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Format contract check | Verify `**Triggers**` is detected in smart-commit by running `/project-audit` | Manual — project-audit |
| Merge tool specification | Confirm Step 6 text contains "Read tool" and "Write tool" | Manual — file read |
| Transformation mechanism | Confirm Step 3 text contains the mechanism statement | Manual — file read |
| Regression (behavioral) | Run `/project-audit` before and after; score must not drop | Manual — project-audit |

## Migration Plan

No data migration required. The three SKILL.md files are documentation only. After applying edits:
1. Run `bash install.sh` to deploy updated files to `~/.claude/`
2. Run `/project-audit` to confirm score >= previous

## Open Questions

None.
