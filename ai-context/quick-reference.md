# Quick Reference — Claude Code SDD

> Last verified: 2026-02-26

---

## Your Situation → First Command

| Situation | First Command |
|-----------|--------------|
| Brand-new project, no Claude config at all | `/project-setup` |
| Have CLAUDE.md but no `openspec/` or `ai-context/` | `/project-audit` |
| `ai-context/` exists but files are empty stubs | `/memory-init` |
| Have local `.claude/skills/` that need cleanup | `/project-audit` (check Dimension 9) |
| Have stale/unfinished SDD changes | `/sdd-status` |
| Want to audit the current project health | `/project-audit` |
| Want to fix everything the audit found | `/project-fix` |
| Not sure what state the project is in | `/project-onboard` |
| Ready to start a new feature | `/sdd-ff <change>` or `/sdd-new <change>` |
| Need to update ai-context/ after a major change | `/memory-update` |

---

## SDD Flow

```
                  (optional)
                  /sdd-explore
                       │
                       ▼
                  /sdd-propose
                       │
              ┌────────┴────────┐
              ▼                 ▼
         /sdd-spec         /sdd-design    ← parallel
              └────────┬────────┘
                       ▼
                  /sdd-tasks
                       │
                       ▼
                  /sdd-apply
                       │
                       ▼
                  /sdd-verify
                       │
                       ▼
                 /sdd-archive
```

**Shortcuts**:
- `/sdd-ff <change>` — runs propose → spec+design → tasks automatically, asks before apply
- `/sdd-new <change>` — same as ff but offers explore phase and adds confirmation gates

---

## Command Glossary

### Meta-tools

| Command | What it does |
|---------|-------------|
| `/project-audit` | Deep diagnostic of Claude/SDD config — produces `.claude/audit-report.md` with score and FIX_MANIFEST |
| `/project-fix` | Applies corrections from `audit-report.md` — the apply phase of the meta-SDD cycle |
| `/project-onboard` | Reads project file system, detects which of 6 onboarding cases applies, recommends first command |
| `/project-setup` | Bootstraps SDD + memory structure in the current project (first-time setup) |
| `/project-update` | Updates project CLAUDE.md and ai-context/ to match the current global config state |
| `/memory-init` | Generates `ai-context/` files by reading the project from scratch |
| `/memory-update` | Updates `ai-context/` with the work done in the current session |
| `/skill-add <name>` | Adds an existing global skill from `~/.claude/skills/` to the project CLAUDE.md registry |
| `/skill-create <name>` | Creates a new skill from scratch (launches skill-creator workflow) |

### SDD Phase Commands

| Command | What it does |
|---------|-------------|
| `/sdd-apply <change>` | Implements the task plan from `tasks.md` — the coding phase |
| `/sdd-archive <change>` | Merges delta specs to master and moves change to archive — irreversible |
| `/sdd-design <change>` | Creates the technical design: decisions, data flow, file change matrix |
| `/sdd-explore <topic>` | Investigates an area before committing to changes — read-only |
| `/sdd-ff <change>` | Fast-forward: propose → spec+design (parallel) → tasks, then asks before apply |
| `/sdd-new <change>` | Full SDD cycle with optional explore phase and confirmation gates |
| `/sdd-propose <change>` | Creates the change proposal: problem, solution, success criteria |
| `/sdd-spec <change>` | Writes delta specifications with Given/When/Then scenarios |
| `/sdd-status` | Shows all active changes and artifact presence from `openspec/changes/` |
| `/sdd-tasks <change>` | Breaks the design into an atomic task plan |
| `/sdd-verify <change>` | Verifies implementation against specs — produces `verify-report.md` |

---

## /sdd-ff vs /sdd-new

**Use `/sdd-ff` when**:
- The change is well-understood and requirements are clear
- You want to move fast without confirmation prompts
- You are comfortable with Claude running propose → spec+design → tasks automatically

**Use `/sdd-new` when**:
- The change is complex, vague, or touches multiple systems
- You want to review the proposal before spec and design begin
- You want an optional exploration phase to understand the codebase first
- You want confirmation gates between phases

**Rule of thumb**: If you could write the proposal yourself in 5 minutes, use `/sdd-ff`. If you need to think about it, use `/sdd-new`.

---

## Artifact Locations

| Artifact | Path | Produced by | Consumed by |
|----------|------|-------------|-------------|
| Audit report | `.claude/audit-report.md` | `/project-audit` | `/project-fix` |
| SDD config | `openspec/config.yaml` | `/project-setup`, `/project-fix` | All SDD phases |
| Change artifacts | `openspec/changes/<name>/` | SDD phase skills | Next phase skills |
| Archived changes | `openspec/changes/archive/YYYY-MM-DD-<name>/` | `/sdd-archive` | Reference only |
| Project memory | `ai-context/*.md` | `/memory-init`, `/memory-update` | All skills at session start |
