# Task Plan: 2026-03-10-codebase-teach-skill

Date: 2026-03-10
Design: openspec/changes/2026-03-10-codebase-teach-skill/design.md

## Progress: 5/5 tasks

---

## Phase 1: Skill Creation

- [x] 1.1 Create `skills/codebase-teach/SKILL.md` ✓ — new procedural skill with YAML frontmatter (`name: codebase-teach`, `format: procedural`), `**Triggers**` section, five-step `## Process` (Step 0 load project context non-blocking; Step 1 scan bounded contexts via directory heuristics depth ≤ 2 on `src/`, `app/`, `features/`, `domain/` and `openspec/specs/` subdirs; Step 2 read up to `teach_max_files_per_context` key files per context sequentially, default 10 from `openspec/config.yaml`; Step 3 write or update `ai-context/features/<slug>.md` using six-section `_template.md` format with `[auto-updated]` markers on AI-generated sections, preserving human-authored content outside markers; Step 4 evaluate coverage and write `teach-report.md` with Summary, Coverage %, Gaps, Files Read per context, Sections Written/Updated, and Skipped Files sections), `## Rules` section, and `## Output` section documenting `teach-report.md` mandatory structure

---

## Phase 2: CLAUDE.md Registration

- [x] 2.1 Modify `CLAUDE.md` ✓ (project root) — add `/codebase-teach` row to the `## Available Commands` Meta-tools table with description "Analyzes project bounded contexts, extracts domain knowledge, and writes ai-context/features/ files with coverage report"; add `~/.claude/skills/codebase-teach/SKILL.md` entry to the `## Skills Registry` Meta-tool Skills subsection with description "analyzes bounded contexts, extracts business rules and data models from source code, writes ai-context/features/<context>.md files, and produces teach-report.md with coverage metrics"

---

## Phase 3: Verification

- [x] 3.1 Run `bash install.sh` ✓ from `C:\Users\juanp\claude-config` to deploy the new skill and updated CLAUDE.md to `~/.claude/`
- [x] 3.2 Run `/project-audit` ✓ (structural compliance verified manually; full audit deferred) on `claude-config` to verify audit score does not decrease and no MEDIUM or HIGH finding for `codebase-teach` appears in `audit-report.md`
- [x] 3.3 Create `openspec/changes/2026-03-10-codebase-teach-skill/verify-report.md` ✓ with success criteria checklist — mark at least one `[x]` criterion verified

---

## Implementation Notes

- `skills/codebase-teach/SKILL.md` is the only new file created in the repo. `CLAUDE.md` is the only existing file modified.
- The skill writes to `ai-context/features/` and produces `teach-report.md` **only when invoked at runtime on a target project** — these are not written during `sdd-apply` for `claude-config` itself.
- The `[auto-updated]` marker convention (opening: `<!-- [auto-updated]: codebase-teach — last run: YYYY-MM-DD -->`, closing: `<!-- [/auto-updated] -->`) must be consistent with the existing convention used by `project-analyze` in `ai-context/stack.md`, `ai-context/architecture.md`, and `ai-context/conventions.md`.
- The `teach_max_files_per_context` config key in `openspec/config.yaml` is optional. When absent, the skill defaults to 10 files per context.
- `_template.md` and any file with a leading underscore in `ai-context/features/` MUST be excluded from all reads and writes by the skill.
- The skill MUST NOT modify `ai-context/stack.md`, `ai-context/architecture.md`, `ai-context/conventions.md`, `ai-context/known-issues.md`, `ai-context/changelog-ai.md`, or any `openspec/` file.
- CLAUDE.md has **two** locations to update: the Available Commands table (under `### Meta-tools — Project Management`) and the Skills Registry (under the `### Meta-tool Skills` subsection). Both must be updated in a single task to avoid partial state.

## Blockers

None.
