# Agent Execution Contract

> Formal specification of the sub-agent I/O protocol used by the SDD orchestrator.

---

## Overview

Every SDD phase sub-agent MUST conform to this contract. The orchestrator (sdd-ff, sdd-new, or the main conversation) launches sub-agents via the Task tool and expects a structured return value. Non-conforming responses are treated as `status: failed`.

---

## Input Format

The orchestrator passes a structured prompt to each sub-agent via the Task tool:

```
You are a specialized SDD sub-agent.

STEP 1: Read the file <resolved-skill-path>
STEP 2: Follow its instructions exactly

CONTEXT:
- Project: <absolute-path-to-project-root>
- Project governance: <absolute-path-to-project-root>/CLAUDE.md
- Change: <change-slug>
- Previous artifacts: <comma-separated list of artifact paths, or "none">

TASK: <specific description of what this sub-agent should accomplish>

Return:
- status: ok|warning|blocked|failed
- summary: executive summary for decision-making
- artifacts: files created/modified
- next_recommended: next phases
- risks: identified risks (if any)
```

### Input fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `Project` | absolute path | yes | Root directory of the project being worked on |
| `Change` | string (slug) | yes | The change slug (e.g., `2026-03-12-agent-registry`) |
| `Previous artifacts` | list of paths | no | Artifacts from prior phases; `"none"` when this is the first phase |
| `Project governance` | absolute path | no | Path to the project's `CLAUDE.md`; absent when orchestrator does not inject it (non-breaking) |
| `TASK` | string | yes | Precise description of the work to be done |

---

## Return Contract

Sub-agents MUST return a response containing these fields:

### Required fields

| Field | Type | Values | Description |
|-------|------|--------|-------------|
| `status` | string | `ok` \| `warning` \| `blocked` \| `failed` | Execution outcome |
| `summary` | string | free text | 1–3 line executive summary for the orchestrator to present to the user |
| `artifacts` | list | file paths | Files created or modified (relative to project root) |
| `next_recommended` | list | skill names | Suggested next phases (e.g., `["sdd-spec", "sdd-design"]`) |
| `risks` | list | strings | Identified risks or warnings; empty list `[]` if none |

### Optional fields (sdd-verify only)

| Field | Type | Description |
|-------|------|-------------|
| `test_execution` | object | `{runner, command, exit_code, result}` |
| `build_check` | object | `{command, exit_code, result}` |
| `compliance_matrix` | object | `{total_scenarios, compliant, failing, untested, partial}` |
| `deviations` | list | Used by sdd-apply to report design deviations |
| `tdd_mode` | boolean | Used by sdd-apply to report TDD mode activation |

---

## Status Semantics

| Status | Meaning | Orchestrator behavior |
|--------|---------|----------------------|
| `ok` | Phase completed successfully | Continue to next phase |
| `warning` | Completed with non-blocking issues | Continue; surface warnings prominently to user |
| `blocked` | Cannot proceed — user input required | STOP; report blockers to user; do NOT continue |
| `failed` | Execution error — phase did not complete | STOP; report error to user; do NOT continue |

### Blocking rules

- `blocked` or `failed` from any phase → orchestrator MUST stop immediately
- `warning` → orchestrator continues but surfaces the warning
- Only the user can resume after a `blocked` state

---

## Artifact Contract

All artifact paths are relative to the project root unless otherwise noted.

### Standard artifact locations

```
openspec/changes/<slug>/exploration.md    ← sdd-explore
openspec/changes/<slug>/proposal.md       ← sdd-propose
openspec/changes/<slug>/prd.md            ← sdd-propose (optional)
openspec/changes/<slug>/specs/<domain>/spec.md  ← sdd-spec
openspec/changes/<slug>/design.md         ← sdd-design
docs/adr/<NNN>-<slug>.md                  ← sdd-design (optional)
openspec/changes/<slug>/tasks.md          ← sdd-tasks
openspec/changes/<slug>/verify-report.md  ← sdd-verify
openspec/changes/archive/<date>-<slug>/   ← sdd-archive
```

### Artifact access rules

- Sub-agents MUST only read from or write to their designated artifact locations
- Sub-agents MUST NOT read or write artifacts from other change slugs
- The orchestrator passes only file paths — sub-agents read the contents themselves

---

## Context Isolation

Each sub-agent invocation:
- Starts with a fresh context window
- Receives no shared state from the orchestrator (only file paths)
- Communicates results only through filesystem artifacts and the return value
- MUST NOT assume any prior conversation context

---

## Error Handling

Sub-agents MUST gracefully handle:

| Situation | Required behavior |
|-----------|------------------|
| Missing `ai-context/` files | Log INFO, continue (non-blocking) |
| Missing prior phase artifacts | Log WARNING, set `status: blocked` if required |
| Ambiguous proposal content | Ask clarifying question or mark `[Pending clarification]` |
| Design contradicts architecture | Set `status: blocked`, explain contradiction |
| File write error | Set `status: failed`, describe the error |

---

## Example Return Values

### Successful explore phase

```json
{
  "status": "ok",
  "summary": "Explored agent registry gap: 3 approaches analyzed. Recommend lightweight agents.md with no runtime coupling.",
  "artifacts": ["openspec/changes/2026-03-12-agent-registry/exploration.md"],
  "next_recommended": ["sdd-propose"],
  "risks": []
}
```

### Blocked tasks phase

```json
{
  "status": "blocked",
  "summary": "Cannot generate tasks: design.md is missing the File Change Matrix section.",
  "artifacts": [],
  "next_recommended": ["sdd-design — complete the File Change Matrix"],
  "risks": ["Design incomplete — tasks phase cannot proceed without file-level implementation plan"]
}
```

### Warning from apply phase

```json
{
  "status": "warning",
  "summary": "Implemented 4/5 tasks. Task 3.2 deviated from design: used HS256 instead of RS256 (documented in tasks.md).",
  "artifacts": [
    "src/auth/auth.service.ts — modified",
    "openspec/changes/2026-03-12-auth-refresh/tasks.md — updated"
  ],
  "deviations": ["DEVIATION task 3.2: RS256 → HS256 — library limitation"],
  "tdd_mode": false,
  "next_recommended": ["sdd-apply Phase 2", "/sdd-verify after all phases"],
  "risks": ["JWT algorithm deviation may affect security review"]
}
```

---

## Validation Checklist

Use this checklist when writing or reviewing a sub-agent skill:

- [ ] SKILL.md has YAML frontmatter with `name`, `description`, `format`, `model`
- [ ] Step 0 loads project context (non-blocking)
- [ ] Return value includes all 5 required fields
- [ ] `status` uses only the 4 defined values
- [ ] `artifacts` lists only files actually created/modified
- [ ] `next_recommended` uses skill names (not slash commands)
- [ ] Missing prior artifacts produce `status: blocked` (not silent failure)
- [ ] Non-blocking failures produce `status: ok` or `status: warning` (not `blocked`)

---

## See Also

- `agents.md` — canonical agent registry with per-agent I/O details
- `docs/SKILL-RESOLUTION.md` — skill path resolution rules
- `skills/README.md` — skill authoring guide
- `docs/ORCHESTRATION.md` — high-level architecture overview
