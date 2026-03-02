# Task Plan: skill-scope-global-vs-project

Date: 2026-03-02
Design: openspec/changes/skill-scope-global-vs-project/design.md

## Progress: 14/14 tasks

---

## Phase 1: skill-add — Duplicate Check and Preview Redesign

- [x] 1.1 Modify `skills/skill-add/SKILL.md` — Step 5: extend the duplicate check to scan for BOTH `~/.claude/skills/<name>/` AND `.claude/skills/<name>/` entries in the registry; stop with "Skill already registered. No changes made." if either is found
- [x] 1.2 Modify `skills/skill-add/SKILL.md` — Step 6: redesign the preview block so that the default action shown is local copy (`.claude/skills/<name>/SKILL.md`) and Option A (global reference, `~/.claude/skills/<name>/SKILL.md`) is listed as an explicit secondary choice; update the confirm prompt to `Y / A for Option A / N`
- [x] 1.3 Modify `skills/skill-add/SKILL.md` — Step 7: split into Step 7a (default — copy skill file to `.claude/skills/<name>/SKILL.md`, prepend origin comment `<!-- skill-add: copied from ~/.claude/skills/<name>/SKILL.md on YYYY-MM-DD -->`, add local-path registry entry in CLAUDE.md) and Step 7b (Option A — add `~/.claude/skills/<name>/SKILL.md` registry entry only, display notice that the skill will not be present for collaborators)
- [x] 1.4 Modify `skills/skill-add/SKILL.md` — Step 8: update the confirmation message to reflect the copy-by-default result; remove the "Want a local copy?" suggestion (it is now the default, not an upsell)
- [x] 1.5 Modify `skills/skill-add/SKILL.md` — Rules section: update rules to state that local copy is the default strategy; remove the statement that Option A (registry reference) is the default; document that `--copy` flag is no longer needed because copy is the default

---

## Phase 2: skill-creator — Context-Aware Placement Default

- [x] 2.1 Modify `skills/skill-creator/SKILL.md` — Step 1 (Gather information): add a context-detection block BEFORE the placement prompt using the following logic:
  - `is_claude_config` = `install.sh` exists at cwd root AND (`openspec/config.yaml` declares `project.name: claude-config` OR `basename(cwd) == "claude-config"`)
  - `has_project_context` = `openspec/` exists OR `.claude/` exists at cwd root
  - If `has_project_context AND NOT is_claude_config` → default_placement = project-local (option 1)
  - Else → default_placement = global (option 2)
- [x] 2.2 Modify `skills/skill-creator/SKILL.md` — Step 1 placement prompt: reframe the question to display the detected default with `[DEFAULT]` marker; format: `1. This project only → .claude/skills/ [DEFAULT]` or `2. Global catalog → ~/.claude/skills/ [DEFAULT]` depending on context; if context is ambiguous (neither project nor claude-config), present both options with no pre-selected default
- [x] 2.3 Modify `skills/skill-creator/SKILL.md` — Process: /skill-add section: remove the "Addition strategy" subsection (Option A / Option B description) since that logic is now fully owned by `skills/skill-add/SKILL.md`; keep the verify-existence and project `.claude/skills/` directory steps, but remove any duplication of the strategy decision

---

## Phase 3: project-fix — move-to-global Handler Demotion

- [x] 3.1 Modify `skills/project-fix/SKILL.md` — `move-to-global` handler (after `5.4 flag_irrelevant`): verify the handler heading and output block do NOT contain any implication of automated file-system action; ensure the output block includes the two-tier model explanation note (shown once per fix run): "`.claude/skills/` is project-local (versioned in repo — team-visible); `~/.claude/skills/` is machine-global (available across all projects but not present for collaborators who clone)" ✓
- [x] 3.2 Modify `skills/project-fix/SKILL.md` — Phase 5 checkpoint counter block: confirm the `move-to-global` counter line reads `ℹ️ move-to-global : [N] (manual — see instructions above)` and is NOT counted under automated corrections applied; verify the checkpoint summary does NOT include `move-to-global` items in any `✅` count line ✓

---

## Phase 4: CLAUDE.md — Skills Registry Two-Tier Comment

- [x] 4.1 Modify `CLAUDE.md` (project root, the claude-config repo CLAUDE.md): add the two-tier comment block at the top of the `## Skills Registry` section, immediately before the first registry entry:
  ```
  <!-- Skills Registry: paths starting with .claude/skills/ are local copies (versioned in this repo).
       Paths starting with ~/.claude/skills/ are global references (machine-local, not in this repo).
       .claude/skills/ MUST NOT be excluded by .gitignore — local copies must be committed. -->
  ```

---

## Phase 5: Deploy and Verify

- [x] 5.1 Run `install.sh` from `C:/Users/juanp/claude-config` to deploy the three updated skill files (`skill-add`, `skill-creator`, `project-fix`) and the updated `CLAUDE.md` to `~/.claude/`
- [x] 5.2 Run `/project-audit` on `claude-config` and verify the score is >= the score recorded before this change; record the result
- [x] 5.3 Update `ai-context/changelog-ai.md` with an entry documenting this change: files modified, decisions applied, and the resulting /project-audit score

---

## Implementation Notes

- All three SKILL.md edits are to Markdown prose only — no scripts, no YAML schema changes, no new files beyond this tasks.md
- The `skill-creator` Step 1 context detection block uses pseudo-code logic that Claude interprets at runtime; it does NOT need to be executable bash
- The origin comment prepended to copied SKILL.md files must use the exact format: `<!-- skill-add: copied from ~/.claude/skills/<name>/SKILL.md on YYYY-MM-DD -->`; it is placed BEFORE the YAML frontmatter block (or before the first `#` heading if no frontmatter exists)
- The `--copy` flag mentioned in the current `skill-add` Rules section becomes obsolete because copy is the new default; the flag reference should be removed or replaced with a note that copy is now default
- In `skill-creator`, the `/skill-add` section currently duplicates the addition strategy (Option A / Option B). Task 2.3 removes that duplication — `skill-creator` delegates to `skill-add` for the copy-vs-reference decision
- The `project-fix` `move-to-global` handler already says "No automated action taken" — task 3.1 reinforces this by adding the two-tier explanation, not by rewriting the handler from scratch
- Phase 5 tasks (5.1–5.3) are operational verification steps; they are not file edits and must be performed by the implementer manually after Phases 1–4 are complete

## Blockers

None.
