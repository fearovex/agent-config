# Agent Registry

> Canonical registry of all orchestrator skills and SDD phase sub-agents in this system.

Last updated: 2026-03-12

---

## Overview

The Claude Code SDD system uses an **orchestrator + sub-agent** model. The orchestrator (CLAUDE.md) never executes phase work directly — it delegates each phase to a specialized sub-agent via the Task tool. Sub-agents operate with fresh context, isolated from the orchestrator's state, and communicate exclusively through filesystem artifacts.

For skill resolution rules, see `docs/SKILL-RESOLUTION.md`.
For the sub-agent I/O contract, see `openspec/agent-execution-contract.md`.

---

## Orchestrator Skills

These skills are executed **by the orchestrator** (i.e., they run in the main conversation context and coordinate other sub-agents via Task tool).

| Skill | Format | Model | Description |
|-------|--------|-------|-------------|
| `sdd-ff` | procedural | haiku | Fast-forward cycle: explore → propose → spec+design (parallel) → tasks, then asks before apply |
| `sdd-new` | procedural | haiku | Full SDD cycle with user confirmation gates at each phase |
| `sdd-status` | procedural | haiku | Shows all active changes and artifact presence from openspec/changes/ |
| `project-setup` | procedural | haiku | Deploys SDD + memory structure in the current project |
| `project-onboard` | procedural | haiku | Diagnoses project state, detects which of 6 cases applies, recommends command sequence |
| `project-audit` | procedural | sonnet | Audits project Claude config across 10 dimensions — produces audit-report.md |
| `project-analyze` | procedural | sonnet | Deep codebase analysis — produces analysis-report.md, updates ai-context/ |
| `project-fix` | procedural | sonnet | Applies corrections from audit-report.md |
| `project-update` | procedural | haiku | Updates project CLAUDE.md to current user-level state |
| `skill-creator` | procedural | haiku | Creates new skills (generic or project-specific) |
| `skill-add` | procedural | haiku | Copies a global skill into the project and registers it in CLAUDE.md |
| `memory-init` | procedural | haiku | Generates all 5 ai-context/ files from scratch |
| `memory-update` | procedural | haiku | Updates ai-context/ with decisions from the current session |
| `codebase-teach` | procedural | sonnet | Analyzes bounded contexts, writes ai-context/features/ files |
| `project-claude-organizer` | procedural | haiku | Reads .claude/ folder, applies canonical reorganization after confirmation |
| `claude-folder-audit` | procedural | sonnet | Audits ~/.claude/ runtime for installation drift and scope compliance |

---

## SDD Phase Sub-Agents

These skills are invoked **as sub-agents** by orchestrators (sdd-ff, sdd-new) via the Task tool. Each runs with isolated context and communicates back via the standard return contract.

### sdd-explore

| Property | Value |
|----------|-------|
| Format | procedural |
| Model | haiku |
| Input | project path, change slug, optional topic |
| Output | `openspec/changes/<slug>/exploration.md` |
| Dependencies | none (reads codebase only) |
| Capabilities | Read files, search codebase — NO writes to project code |
| Produces | `status`, `summary`, `artifacts`, `next_recommended`, `risks` |

### sdd-propose

| Property | Value |
|----------|-------|
| Format | procedural |
| Model | haiku |
| Input | project path, change slug, `exploration.md` (optional) |
| Output | `openspec/changes/<slug>/proposal.md`, `openspec/changes/<slug>/prd.md` (optional) |
| Dependencies | sdd-explore (recommended, not required) |
| Capabilities | Read files, write openspec/changes/ |
| Produces | `status`, `summary`, `artifacts`, `next_recommended`, `risks` |

### sdd-spec

| Property | Value |
|----------|-------|
| Format | procedural |
| Model | sonnet |
| Input | project path, change slug, `proposal.md` |
| Output | `openspec/changes/<slug>/specs/<domain>/spec.md` (one per domain) |
| Dependencies | sdd-propose |
| Capabilities | Read files, write openspec/changes/ |
| Produces | `status`, `summary`, `artifacts`, `next_recommended`, `risks` |

### sdd-design

| Property | Value |
|----------|-------|
| Format | procedural |
| Model | sonnet + thinking |
| Input | project path, change slug, `proposal.md` |
| Output | `openspec/changes/<slug>/design.md`, optional `docs/adr/<NNN>-<slug>.md` |
| Dependencies | sdd-propose |
| Capabilities | Read files, write openspec/changes/, write docs/adr/ |
| Produces | `status`, `summary`, `artifacts`, `next_recommended`, `risks` |

### sdd-tasks

| Property | Value |
|----------|-------|
| Format | procedural |
| Model | haiku |
| Input | project path, change slug, `proposal.md`, `specs/`, `design.md` |
| Output | `openspec/changes/<slug>/tasks.md` |
| Dependencies | sdd-spec + sdd-design (both required) |
| Capabilities | Read files, write openspec/changes/ |
| Produces | `status`, `summary`, `artifacts`, `next_recommended`, `risks` |

### sdd-apply

| Property | Value |
|----------|-------|
| Format | procedural |
| Model | sonnet + thinking |
| Input | project path, change slug, `tasks.md`, `specs/`, `design.md`, assigned phase/tasks |
| Output | Modified project files, updated `tasks.md` |
| Dependencies | sdd-tasks |
| Capabilities | Read and write project files, run diagnostic commands |
| Produces | `status`, `summary`, `artifacts`, `deviations`, `next_recommended`, `risks` |

### sdd-verify

| Property | Value |
|----------|-------|
| Format | procedural |
| Model | sonnet |
| Input | project path, change slug, all change artifacts + implemented code |
| Output | `openspec/changes/<slug>/verify-report.md` |
| Dependencies | sdd-apply (all phases complete) |
| Capabilities | Read files, run tests via Bash, write verify-report.md |
| Produces | `status`, `summary`, `artifacts`, `test_execution`, `build_check`, `compliance_matrix`, `next_recommended`, `risks` |

### sdd-archive

| Property | Value |
|----------|-------|
| Format | procedural |
| Model | haiku |
| Input | project path, change slug |
| Output | Updated `openspec/specs/<domain>/spec.md`, archived change at `openspec/changes/archive/<date>-<slug>/`, `CLOSURE.md` |
| Dependencies | sdd-verify (recommended) |
| Capabilities | Read files, write openspec/, execute memory-update inline |
| Produces | `status`, `summary`, `artifacts`, `next_recommended`, `risks` |

---

## Capability Boundaries

| Agent | Can read project code | Can write project code | Can run shell commands | Can write openspec/ | Can write ai-context/ |
|-------|-----------------------|------------------------|------------------------|---------------------|------------------------|
| sdd-explore | ✅ | ❌ | ❌ | ❌ | ❌ |
| sdd-propose | ✅ | ❌ | ❌ | ✅ | ❌ |
| sdd-spec | ✅ | ❌ | ❌ | ✅ | ❌ |
| sdd-design | ✅ | ❌ | ❌ | ✅ | ✅ (ADR only) |
| sdd-tasks | ✅ | ❌ | ❌ | ✅ | ❌ |
| sdd-apply | ✅ | ✅ | ✅ (read-only diag) | ✅ (tasks.md only) | ❌ |
| sdd-verify | ✅ | ❌ | ✅ | ✅ | ❌ |
| sdd-archive | ✅ | ❌ | ❌ | ✅ | ✅ |

---

## Artifact Sharing

Agents communicate **exclusively through filesystem artifacts**. No in-memory state is shared between agents. The orchestrator passes only file paths to sub-agents — never file contents.

```
explore   → exploration.md
propose   → proposal.md, prd.md
spec      → specs/<domain>/spec.md
design    → design.md
tasks     → tasks.md
apply     → project files, tasks.md (updated)
verify    → verify-report.md
archive   → openspec/specs/ (updated), CLOSURE.md
```

---

## No Circular Dependencies

```
explore (no deps)
  └─ propose
       ├─ spec (parallel)
       └─ design (parallel)
            └─ tasks
                 └─ apply
                      └─ verify
                           └─ archive
```

No agent depends on an agent downstream of itself.

---

## See Also

- `docs/SKILL-RESOLUTION.md` — skill path resolution rules
- `skills/README.md` — skill authoring guide
- `openspec/agent-execution-contract.md` — I/O contract specification
- `docs/ORCHESTRATION.md` — high-level architecture overview
