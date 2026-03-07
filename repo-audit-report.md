# Project Audit Report

Date: 2026-03-06
Repository: `claude-config`
Scope: Full repository consistency audit (documentation, active skills, memory artifacts, SDD artifacts)
Method: Static review of repository files and structure. No automated tests or runtime execution were performed.

Status: Initial correction pass applied on 2026-03-06. This report is preserved as the audit baseline; the workflow, count, and language findings were corrected in the same session.

## Executive Summary

The repository is structurally healthy, but it has several active inconsistencies between the documented workflow and the actual implementation. The most important problems are:

1. The repository still documents the pre-redesign `sync.sh` behavior in active files, even though `sync.sh` is now memory-only.
2. Multiple active documents report stale skill-catalog counts.
3. `skills/project-fix/SKILL.md` did not expose a canonical `## Rules` section, which weakened compliance with the repository skill contract.
4. `memory/MEMORY.md` violates the repository's English-only convention and still contains outdated command syntax.

## Findings

### HIGH-1: README documents the wrong `sync.sh` workflow

**Evidence**

- `sync.sh` explicitly states it only syncs `~/.claude/memory/ -> repo/memory/` and excludes skills, hooks, ai-context, openspec, `CLAUDE.md`, and `settings.json`.
  - Source: `sync.sh` header and final output block
- `README.md` still says:
  - `sync.sh` is `~/.claude/ -> repo` for general “session changes”
  - session changes to skills and `CLAUDE.md` must be synced with `bash sync.sh`
  - contributors should always run `sync.sh` before committing

**Affected files**

- `README.md:27-28`
- `README.md:154-168`
- `README.md:266-281`
- `sync.sh:2-10`
- `sync.sh:29-33`

**Impact**

This is a workflow-level inconsistency. Anyone following the README can use the wrong deployment path after editing skills or configuration, which directly contradicts the repo-authoritative model described elsewhere.

**Recommended fix**

Update `README.md` so that:

- `install.sh` is the only deploy path for config changes.
- `sync.sh` is described as memory-only.
- the contribution workflow uses `install.sh`, not `sync.sh`, after skill/config changes.

### HIGH-2: Active docs still describe the old full-sync and `rsync` model

**Evidence**

- `ai-context/known-issues.md` still says `sync.sh` copies `~/.claude/ -> repo`, recommends running `install.sh -> sync.sh`, and says `sync.sh` uses `rsync`.
- Exported instruction files still repeat the obsolete `rsync` note.

**Affected files**

- `ai-context/known-issues.md:32-63`
- `.github/copilot-instructions.md:316-318`
- `GEMINI.md:287-289`

**Impact**

This creates conflicting operational guidance across first-class project artifacts. The problem is larger than README drift because it affects memory docs and generated downstream instruction files.

**Recommended fix**

Normalize all active documentation to the current contract:

- `install.sh`: repo -> `~/.claude/`
- `sync.sh`: `~/.claude/memory/` -> `repo/memory/` only
- remove all `rsync` references from active files unless they are explicitly historical/archive-only notes

### HIGH-3: `skills/project-fix/SKILL.md` did not expose a canonical `## Rules` section

**Evidence**

- The live skill ended with `## Execution rules` rather than the repository-standard `## Rules` heading.
- The file contained `## Rules` only inside fenced template examples, not as the canonical terminal section of the skill.

**Affected files**

- `skills/project-fix/SKILL.md:59`
- `skills/project-fix/SKILL.md:536`

**Impact**

This weakens the skill's compliance with the repository's documented SKILL.md contract and can cause audit ambiguity about whether the skill is structurally complete.

**Recommended fix**

Rename the live `## Execution rules` section to `## Rules` so the skill exposes the canonical terminal section required by repository conventions.

### MEDIUM-1: Skill catalog counts are stale across active documents

**Evidence**

- The repository currently contains 49 `skills/**/SKILL.md` files.
- Active docs still claim different totals:
  - `README.md`: `~38 skills`
  - `ai-context/stack.md`: `~35 skills`
  - `.github/copilot-instructions.md`: `~47 skills`
  - `GEMINI.md`: `~47 skills`

**Affected files**

- `README.md:28`
- `ai-context/stack.md:29`
- `.github/copilot-instructions.md:61`
- `GEMINI.md:46`

**Impact**

This is a trust problem rather than a runtime defect, but it makes the catalog look unstable and makes audits harder because different “source-of-truth” documents disagree about basic inventory.

**Recommended fix**

Either update all active counts to 49 or stop hardcoding approximate totals in active documentation and describe the catalog by category only.

### MEDIUM-2: `ai-context/stack.md` still contains stale sync semantics

**Evidence**

- Early in the file, `ai-context/stack.md` says the repo is “captured back via `sync.sh`” and labels `sync.sh` as “Capture `~/.claude/` back into this repo”.
- Later in the same file, the workflow section correctly says `sync.sh` is memory-only.

**Affected files**

- `ai-context/stack.md:7`
- `ai-context/stack.md:28`
- `ai-context/stack.md:69-77`

**Impact**

This is an internal contradiction inside one file. A reader can get two different models depending on which section they read first.

**Recommended fix**

Rewrite the introductory description and directory comments to match the later, correct workflow section.

### MEDIUM-3: `memory/MEMORY.md` violates language and command conventions

**Evidence**

- The file is written in Spanish despite the repository convention that all content must be in English.
- It also references old slash-command forms such as `/project:setup` and `/sdd:ff <nombre>`.

**Affected files**

- `memory/MEMORY.md:1`
- `memory/MEMORY.md:32-38`
- `ai-context/conventions.md:7-15`

**Impact**

This is not a runtime issue, but it is a direct policy violation in a committed repository artifact and preserves outdated command syntax in memory that could be reused later.

**Recommended fix**

Translate the file to English or move it out of versioned project content if it is intentionally user-personal. Also normalize command examples to the current slash-command format.

## Additional Notes

- There is one active SDD change directory: `openspec/changes/project-claude-organizer-commands-conversion/`. It contains `proposal.md`, `prd.md`, `design.md`, `tasks.md`, and `specs/`. No structural inconsistency was detected there.
- No uncommitted git changes were present at audit time.

## Priority Order

1. Fix `skills/project-fix/SKILL.md`.
2. Correct README and `ai-context/known-issues.md` to the current `install.sh`/`sync.sh` contract.
3. Regenerate or update exported instruction files (`.github/copilot-instructions.md`, `GEMINI.md`).
4. Clean up stale skill-count references.
5. Normalize `memory/MEMORY.md` or explicitly exclude it from the English-only convention.

## Audit Result

Result: inconsistencies confirmed.

- High severity findings: 3
- Medium severity findings: 3
- Low severity findings: 0
