# Technical Design: add-orchestrator-skills

Date: 2026-02-26
Proposal: openspec/changes/add-orchestrator-skills/proposal.md

## General Approach

Four new SKILL.md files are created as thin, standalone CLI entry points. Each file follows the established SKILL.md structure (trigger → process → rules) already used by all skills in `skills/`. The two orchestrator skills (`sdd-ff`, `sdd-new`) directly embed the sub-agent delegation pattern from CLAUDE.md — they use the Task tool themselves rather than delegating to another orchestrator. The two utility skills (`sdd-status`, `skill-add`) are read-only or file-manipulation operations with no sub-agent delegation.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|---------------|
| Orchestrator skills as self-contained SKILL.md | Embed full Task tool delegation pattern inline | Reference CLAUDE.md at runtime | SKILL.md is the runtime entry point Claude reads; it must be self-sufficient. CLAUDE.md is documentation, not an executable instruction set for subagents. |
| sdd-ff / sdd-new do NOT delegate to another orchestrator | Skills ARE the orchestrator; use Task tool directly | Have CLAUDE.md orchestrate them | Avoids infinite delegation loop. These skills replace the ad-hoc CLAUDE.md invocation; they become the first-class CLI entry points. |
| sdd-status reads filesystem only | Bash-style directory inspection of openspec/changes/ | Git log inspection | Simpler, faster, no git dependency. The proposal explicitly documents this as the expected behavior. |
| skill-add uses conceptual reference (Option A) as default | Add entry to project CLAUDE.md pointing to ~/.claude/skills/ | Copy files locally | Consistent with existing skill-creator behavior (Option A documented as default). Avoids duplication. Local copy (Option B) offered if user explicitly requests customization. |
| CLAUDE.md routing table update | Add `/sdd-ff`, `/sdd-new`, `/sdd-status` rows pointing to their own SKILL.md; update `/skill-add` to point to `skill-add/SKILL.md` instead of `skill-creator/SKILL.md` | Leave CLAUDE.md unchanged | Without this update, CLAUDE.md routes `/skill-add` to skill-creator, making the new skill-add skill unreachable. The routing table is the single source of truth for command → skill dispatch. |
| conventions.md addition | Add note that orchestrator skills (sdd-ff, sdd-new) use Task tool directly | No convention update | New pattern (skills using Task tool directly) must be documented to prevent future confusion about when Task tool delegation is appropriate inside a SKILL.md. |

## Data Flow

### sdd-ff flow

```
User: /sdd-ff <change-name>
      │
      ▼
Claude reads skills/sdd-ff/SKILL.md
      │
      ▼
Task tool → sdd-propose subagent
      │         reads: skills/sdd-propose/SKILL.md
      │         writes: openspec/changes/<name>/proposal.md
      │         returns: status + summary
      ▼ (wait)
Task tool × 2 (parallel):
  ├─→ sdd-spec subagent
  │       reads: skills/sdd-spec/SKILL.md + proposal.md
  │       writes: openspec/changes/<name>/specs/<domain>/spec.md
  │       returns: status + summary
  └─→ sdd-design subagent
          reads: skills/sdd-design/SKILL.md + proposal.md
          writes: openspec/changes/<name>/design.md
          returns: status + summary
      ▼ (wait for both)
Task tool → sdd-tasks subagent
      │         reads: skills/sdd-tasks/SKILL.md + spec.md + design.md
      │         writes: openspec/changes/<name>/tasks.md
      │         returns: status + summary
      ▼ (wait)
Claude presents complete summary to user
Claude asks: "Ready to implement with /sdd-apply?"
```

### sdd-new flow

```
User: /sdd-new <change-name>
      │
      ▼
Claude reads skills/sdd-new/SKILL.md
      │
      ▼
[OPTIONAL] Task tool → sdd-explore subagent
      │   (Claude asks user: "Do you want an exploration phase first?")
      │
      ▼ (same as sdd-ff from here)
... propose → (spec + design parallel) → tasks ...
      │
      ▼ (after tasks complete)
Claude presents full DAG status
Claude asks: "Ready to implement with /sdd-apply?"
Claude reminds user of remaining phases: apply → verify → archive
```

### sdd-status flow

```
User: /sdd-status
      │
      ▼
Claude reads skills/sdd-status/SKILL.md
      │
      ▼
Reads openspec/changes/ directory listing (excluding archive/)
      │
      ▼
For each change directory:
  checks presence of: exploration.md, proposal.md, specs/, design.md, tasks.md, verify-report.md
      │
      ▼
Renders table: change name | present artifacts | current phase
      │
      ▼
Reads openspec/changes/archive/ → counts archived entries
Appends: "N changes archived."
```

### skill-add flow

```
User: /skill-add <name>
      │
      ▼
Claude reads skills/skill-add/SKILL.md
      │
      ▼
Checks: ~/.claude/skills/<name>/SKILL.md exists?
  NO → lists similar available skills, suggests /skill-create <name>
  YES ▼
Checks: project has CLAUDE.md with Skills Registry section?
  NO → warns user; proceeds to add section if appropriate
  YES ▼
Adds entry to project CLAUDE.md:
  `~/.claude/skills/<name>/SKILL.md` — [description from skill's first line]
      │
      ▼
Confirms to user: "Skill <name> added to project registry."
Offers: "Want a local copy to customize? Run /skill-add <name> --copy"
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `skills/sdd-ff/SKILL.md` | Create (new directory) | Full sdd-ff orchestrator skill: triggers, 5-step process with Task tool delegation pattern, rules |
| `skills/sdd-new/SKILL.md` | Create (new directory) | Full sdd-new orchestrator skill: triggers, process with optional explore + full DAG + phase reminders, rules |
| `skills/sdd-status/SKILL.md` | Create (new directory) | Status read skill: triggers, directory scan process, table output format, rules |
| `skills/skill-add/SKILL.md` | Create (new directory) | Skill installer: triggers, verify-then-add process, Option A/B strategy, rules |
| `CLAUDE.md` | Modify | Routing table: add rows for sdd-ff, sdd-new, sdd-status; update skill-add row to point to `skill-add/SKILL.md`; Skills Registry: add 4 new entries under SDD Orchestrators subsection |
| `ai-context/conventions.md` | Modify | Add "Orchestrator skills" subsection under SKILL.md structure: note that sdd-ff and sdd-new use Task tool directly and are first-class orchestrators |

## Interfaces and Contracts

### Sub-agent prompt template (used inside sdd-ff and sdd-new)

```
Task tool:
  prompt: |
    You are a specialized SDD sub-agent.

    STEP 1: Read the file ~/.claude/skills/sdd-[PHASE]/SKILL.md
    STEP 2: Follow its instructions exactly

    CONTEXT:
    - Project: [absolute path of current project]
    - Change: [change-name from $ARGUMENTS]
    - Previous artifacts: [comma-separated list of artifact paths]

    TASK: Execute the [PHASE] phase for change "[change-name]".

    Return:
    - status: ok|warning|blocked|failed
    - summary: executive summary for decision-making
    - artifacts: files created/modified
    - next_recommended: next phases
    - risks: identified risks (if any)
```

### sdd-status output format

```
Active SDD changes (openspec/changes/ — excluding archive):

| Change              | explore | proposal | spec | design | tasks | verify |
|---------------------|---------|----------|------|--------|-------|--------|
| add-orchestrator-skills |   -     |    ✓     |  ✓   |   ✓    |   -   |   -    |
| ...                 |   ...   |   ...    | ...  |  ...   |  ...  |  ...   |

Current phase for each:
- add-orchestrator-skills: design (tasks not yet created)

Archived: N changes in openspec/changes/archive/
```

### skill-add CLAUDE.md registry entry format

```markdown
- `~/.claude/skills/<name>/SKILL.md` — [one-line description from skill header]
```

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Manual invocation | `/sdd-ff <change>` triggers propose then parallel spec+design then tasks | Claude Code CLI |
| Manual invocation | `/sdd-new <change>` offers explore, then runs full DAG | Claude Code CLI |
| Manual invocation | `/sdd-status` lists active changes with correct artifact presence | Claude Code CLI |
| Manual invocation | `/skill-add typescript` adds entry to project CLAUDE.md | Claude Code CLI |
| Integration | `/project-audit` after apply — score must not decrease | project-audit skill |
| Smoke test | All 4 SKILL.md files are findable at expected paths after `install.sh` | `ls ~/.claude/skills/{sdd-ff,sdd-new,sdd-status,skill-add}/SKILL.md` |

## Migration Plan

No data migration required. All four additions are net-new directories. No existing files are structurally changed — only CLAUDE.md (routing table + registry) and conventions.md (new subsection) receive additive modifications.

## Open Questions

None.
