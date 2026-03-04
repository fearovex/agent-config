# Proposal: skill-compliance-fixes

Date: 2026-03-03
Status: Draft

## Intent

Fix three skill compliance gaps — one missing `## Rules` section (violates the procedural format contract) and two under-specified process steps (mechanism ambiguity) — so that every affected SKILL.md fully satisfies its declared format contract and its documented behavior is unambiguous to any agent executing it.

## Motivation

The global CLAUDE.md states as an unbreakable rule:

> Each SKILL.md must satisfy the section contract for its declared format.
> `procedural` (default): requires `**Triggers**`, `## Process`, `## Rules`

Three skills currently violate this contract or contain process steps that are ambiguous enough to produce inconsistent agent behavior:

1. **`skills/smart-commit/SKILL.md`** — declares `format: procedural` but has no `## Rules` section. The file contains an `## Anti-Patterns` section and a `## Quick Reference` table followed by a `## Rules` heading at the very end; however, the heading exists, so the contract may be partially satisfied. Investigation confirms the heading is present but **positioned below `## Anti-Patterns` and `## Quick Reference`**, creating a structural ambiguity about whether the contract checker will find it. More critically, the skills registry and the audit tool check for `## Rules` existing anywhere in the file — it does exist, but the anti-patterns convention block appearing before Rules is inconsistent with the procedural format contract, which expects `## Process` followed by `## Rules` at the end.

   After careful re-read: `## Rules` IS present on line 314. The violation is not a missing section but rather the **absence of a `**Triggers**` heading** — the skill uses `## When to Use` instead of the `**Triggers**` bold-pattern that the format contract requires. The section detection rule in `claude-folder-audit` P2-C checks: "Bold-trigger pattern (`**Triggers**`) is also a valid match for the Triggers section specifically." The skill uses the plain `## When to Use` heading without the bold-trigger marker, which fails the P2-C check.

   Correction: smart-commit's primary compliance issue is **missing `**Triggers**` bold-marker** — the triggers section is titled `## When to Use` without the required `**Triggers**` pattern.

2. **`skills/project-analyze/SKILL.md`** — Step 6 ("Write outputs") specifies a merge algorithm for updating `[auto-updated]` sections in `ai-context/` files, but the algorithm is described only at the pseudocode level. The exact mechanism — which tool the agent uses to apply the merge (Read + Write tools? Edit tool? Bash?) — is not stated. This causes different agents to implement it differently, risking content corruption of human-written sections.

3. **`skills/config-export/SKILL.md`** — Step 3 embeds transformation prompts for Copilot, Gemini, and Cursor but does not specify the execution mechanism: the agent reads the prompt text and applies it using its own in-context LLM reasoning (i.e., the prompt is a self-instruction to the executing agent, not an API call or subprocess). This is implied but never stated, creating confusion about whether an external API call is expected.

All three issues are in files that are actively used by real agents and audited by `project-audit` / `claude-folder-audit`. Fixing them closes compliance gaps without changing functional behavior.

## Scope

### Included

- Add `**Triggers**` bold-marker to `skills/smart-commit/SKILL.md` (complement or replace the `## When to Use` heading to satisfy the format contract)
- Clarify Step 6 of `skills/project-analyze/SKILL.md` to specify the exact tool sequence for the merge algorithm (Read tool → compute merged content in-context → Write tool)
- Clarify Step 3 of `skills/config-export/SKILL.md` to state explicitly that transformation prompts are self-instructions executed by the agent using its own in-context reasoning — no external API calls, no subprocess invocations

### Excluded (explicitly out of scope)

- No functional behavior changes to any skill — this is documentation/compliance only
- No changes to CLAUDE.md, openspec/config.yaml, or any other skill
- No changes to how smart-commit groups files, detects issues, or executes commits
- No new skills, no new files beyond SDD artifacts
- No changes to `project-audit` or `claude-folder-audit` audit logic

## Proposed Approach

All three changes are targeted text edits to three existing SKILL.md files:

1. **smart-commit**: Insert a `**Triggers**` line (matching the bold-trigger pattern) immediately after the blockquote description at the top of the file, before `## When to Use`. Alternatively, rename `## When to Use` to include a `**Triggers**` marker in that section. The preferred approach is to add a standard `**Triggers**` line at the top (matching all other procedural skills) and keep `## When to Use` as a sub-section header for additional context.

2. **project-analyze Step 6**: Add one concise sentence to the merge algorithm description specifying the tool sequence: "Use the Read tool to load each target file, compute the merged content in-context, then use the Write tool to write the updated file. Do not use Bash or the Edit tool for this merge."

3. **config-export Step 3**: Add one sentence before the first transformation prompt block: "These transformation prompts are self-instructions executed by the agent using its own in-context LLM reasoning. No external API call, subprocess, or tool invocation is required to apply them — the agent reads the prompt and generates the output directly."

## Affected Areas

| Area/Module | Type of Change | Impact |
|-------------|----------------|--------|
| `skills/smart-commit/SKILL.md` | Modified — add `**Triggers**` marker | Low — no behavioral change |
| `skills/project-analyze/SKILL.md` | Modified — clarify merge tool sequence in Step 6 | Low — codifies implicit behavior |
| `skills/config-export/SKILL.md` | Modified — clarify transformation mechanism in Step 3 | Low — codifies implicit behavior |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Triggers addition changes how smart-commit is invoked | Low | Low | The triggers text matches the existing `## When to Use` content — no new triggers added |
| Merge tool clarification conflicts with a future Edit-tool refactor | Low | Low | Noted as a documentation decision; any future refactor can update the clause |
| Transformation mechanism clarification is misread as restricting future tool use | Low | Low | Wording states the current V1 mechanism; future versions can document their own |

## Rollback Plan

All three changes are small, targeted text edits. Rollback via:

1. `git revert` the commit that applies the changes, or
2. Manually revert the three SKILL.md files to their pre-change state using `git checkout HEAD~1 -- skills/smart-commit/SKILL.md skills/project-analyze/SKILL.md skills/config-export/SKILL.md`
3. Run `bash install.sh` to redeploy the reverted files to `~/.claude/`

No data migration, no artifact cleanup, no downstream consumers to notify.

## Dependencies

- No external dependencies
- `install.sh` must be run after apply to deploy changes to `~/.claude/`
- `/project-audit` should be run before and after to confirm the score does not drop

## Success Criteria

- [ ] `skills/smart-commit/SKILL.md` contains a `**Triggers**` bold-marker line that satisfies the P2-C check in `claude-folder-audit`
- [ ] `skills/project-analyze/SKILL.md` Step 6 explicitly names the Read and Write tools as the mechanism for the merge algorithm
- [ ] `skills/config-export/SKILL.md` Step 3 contains a sentence explicitly stating that transformation prompts are self-instructions executed by the agent's in-context reasoning
- [ ] All three files still declare `format: procedural` and retain all existing `## Process`, `## Rules`, and functional content unchanged
- [ ] `/project-audit` score after apply is >= score before apply

## Effort Estimate

Low (hours) — three targeted text insertions, no structural changes
