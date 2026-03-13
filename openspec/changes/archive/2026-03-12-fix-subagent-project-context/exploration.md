# Exploration: Sub-Agent Project Context Issue

**Date**: 2026-03-12
**Change**: 2026-03-12-fix-subagent-project-context
**Status**: Complete

---

## Problem Statement

Sub-agents in the SDD orchestrator do not receive or respect project-level `CLAUDE.md` rules and constraints, whereas Copilot respects them. This creates an asymmetry where:

1. **Copilot** (via Cursor) receives `.cursor/rules/*.mdc` files (which are derivatives of CLAUDE.md)
2. **Sub-agents** receive only isolated prompts with file paths, no project governance context
3. **Result**: Sub-agents make decisions (naming, architecture, file organization) that don't reflect project conventions and architectural constraints

---

## Root Cause Analysis

### How Sub-Agents Are Currently Invoked

The orchestrator (`sdd-ff`, `sdd-new`, and other coordinators) launches sub-agents via the **Task tool** with a minimal prompt structure:

**Current prompt template** (from `skills/sdd-ff/SKILL.md`):

```
You are a specialized SDD sub-agent.

STEP 1: Read the file ~/.claude/skills/sdd-<phase>/SKILL.md
STEP 2: Follow its instructions exactly

CONTEXT:
- Project: [absolute path]
- Change: [change-slug]
- Previous artifacts: [list of paths]

TASK: Execute the [phase] phase for change "[slug]".

Return:
- status: ok|warning|blocked|failed
- summary: executive summary
- artifacts: files created/modified
- next_recommended: next phases
- risks: identified risks
```

**Key observation**: The prompt contains ONLY file paths and the SKILL.md instruction reference. It does NOT include:
- Project-level `CLAUDE.md` rules
- Architectural constraints from `ai-context/architecture.md`
- Naming conventions from `ai-context/conventions.md`
- Tech stack from `ai-context/stack.md`

### Sub-Agent Context Loading (Partial Mitigation)

The SDD phase skills (e.g., `sdd-propose`, `sdd-apply`, `sdd-spec`) **do include Step 0** that reads:

```
Step 0a — Load project context:
1. Read ai-context/stack.md
2. Read ai-context/architecture.md
3. Read ai-context/conventions.md
4. Read the project's CLAUDE.md and extract ## Skills Registry
```

**However, this Step 0 is:**
1. **Non-blocking** — failures do not halt execution
2. **Enrichment only** — loaded context informs but doesn't override explicit task directions
3. **Incomplete** — only reads 4 of the available governance files; doesn't read entire CLAUDE.md, only the Skills Registry section
4. **Late** — happens inside the sub-agent, after the sub-agent has already started; by that point the sub-agent has no priming from the orchestrator about what matters

### Why Copilot Works But Sub-Agents Don't

**Cursor/Copilot path**:
- Cursor reads `.cursor/rules/*.mdc` files at IDE startup
- These files are generated exports of CLAUDE.md + ai-context/
- Copilot receives full project governance before the user gives any instructions
- Result: Copilot is **primed with constraints from day 1**

**Sub-agent path**:
- Sub-agent starts with fresh context
- Only instruction is to "read SKILL.md and follow it"
- Sub-agent reads SKILL.md (which says "read ai-context/*.md in Step 0")
- Sub-agent constructs its plan based on proposal/design + enrichment, not based on pre-established constraints
- Result: Sub-agent **discovers governance late**, after forming initial assumptions

---

## Investigation Findings

### 1. Skill Resolution Process

**Location**: `docs/SKILL-RESOLUTION.md`, implemented in all phase skills

The orchestrator resolves skill paths before invoking sub-agents:

```
1. .claude/skills/<name>/SKILL.md      (project-local — highest priority)
2. openspec/config.yaml skill_overrides (explicit redirect)
3. ~/.claude/skills/<name>/SKILL.md    (global catalog — fallback)
```

This is working correctly. Sub-agents receive the resolved path in their prompt and can read the skill.

---

### 2. Prompt Structure Gaps

**Locations**:
- `skills/sdd-ff/SKILL.md` (Lines 77–96 for explore, 110–129 for propose, etc.)
- `openspec/agent-execution-contract.md` (Input Format section, Lines 13–36)

The current prompt template is minimal by design:
- Orchestrator passes only file paths, not contents
- Sub-agents are responsible for reading their own context
- Design rationale: "Context isolation" and "Replaceability"

**However**, the prompt does NOT include:
- Resolved `CLAUDE.md` file path (unlike resolved SKILL.md path)
- Explicit list of `ai-context/` files to read
- Any directive to "read all of CLAUDE.md" (only SKILL.md)
- Reference to `.cursor/rules/` or equivalent exports

---

### 3. CLAUDE.md Content Not Passed

**Location**: Project root `CLAUDE.md`

The entire `CLAUDE.md` is ~600 lines covering:
- Intent classification rules
- Tech stack declarations
- Skill registry
- SDD workflow rules
- Project memory structure
- Unbreakable rules (5 categories)
- Feedback persistence rules
- Plan mode rules

**Current behavior**:
- Orchestrator does NOT pass or reference this file in sub-agent prompts
- Phase skills read only the `## Skills Registry` section (in Step 0a, line 48 of sdd-propose)
- Full CLAUDE.md is NOT made available to sub-agents by default

---

### 4. Project-Level Governance Files Available

Files that exist but are not passed to sub-agents in the prompt:

| File | Purpose | Currently passed? |
|------|---------|-------------------|
| `CLAUDE.md` | Project governance, unbreakable rules, conventions | No (Skills Registry section only) |
| `ai-context/stack.md` | Tech stack keywords | Partially (sub-agent Step 0a) |
| `ai-context/architecture.md` | Architectural decisions | Partially (sub-agent Step 0a) |
| `ai-context/conventions.md` | Naming, code style patterns | Partially (sub-agent Step 0a) |
| `ai-context/features/*.md` | Domain knowledge per bounded context | Partially (in sdd-propose via Step 0b heuristic) |
| `.cursor/rules/*.mdc` | Exported rules for Copilot | No |

---

### 5. Comparison: Copilot vs Sub-Agents

| Aspect | Copilot (Cursor) | Sub-Agents |
|--------|-----------------|-----------|
| **Startup context** | Reads `.cursor/rules/*.mdc` before any instruction | No priming; starts with fresh context |
| **Governance source** | MCP exports of CLAUDE.md + ai-context/ | SKILL.md only; reads governance in Step 0 |
| **Constraints visibility** | Always aware of project rules | Aware only after Step 0 executes |
| **Naming conventions** | Enforced from first keystroke | Applied during task execution |
| **Architectural constraints** | Visible from context load | Discovered during Step 0a |
| **File organization** | Guided by exported rules | Inferred from design.md File Change Matrix |

**Root difference**: Copilot is **synchronously primed** with all governance before work begins. Sub-agents **asynchronously discover** governance after startup.

---

### 6. Where CLAUDE.md Rules Should Be Injected

**Option A — Orchestrator-side**: Pass CLAUDE.md content or key excerpts in the sub-agent prompt
- Pros: Minimal sub-agent changes; immediate consistency
- Cons: Larger prompts; may exceed context budgets; duplicates content already in files

**Option B — Skill-side**: Enhance Step 0 in all SDD phase skills to read full CLAUDE.md
- Pros: Localized change; sub-agents take full responsibility for governance
- Cons: Requires updating all phase skills; rules are discovered late (after initial assumptions form)

**Option C — Hybrid**:
- Orchestrator passes critical governance rules (unbreakable rules, naming patterns) in prompt
- Sub-agent Step 0 reads full CLAUDE.md to validate and enrich

---

## Current Architecture Rationale

From `docs/ORCHESTRATION.md` (Lines 77–99, "Sub-Agent Launch Pattern"):

> The orchestrator resolves the skill path using the algorithm in `docs/SKILL-RESOLUTION.md`.

And from `openspec/agent-execution-contract.md` (Lines 118–125, "Context Isolation"):

> Each sub-agent invocation:
> - Starts with a fresh context window
> - Receives no shared state from the orchestrator (only file paths)
> - Communicates results only through filesystem artifacts and the return value
> - MUST NOT assume any prior conversation context

This design prioritizes:
1. **Isolation**: Sub-agents don't inherit orchestrator state
2. **Replaceability**: Any sub-agent can be replaced without orchestrator changes
3. **Minimalism**: Orchestrator passes only essential metadata (paths)

However, it sacrifices **governance visibility** and **early priming** that Copilot enjoys.

---

## Identified Gaps

### Gap 1: No Full CLAUDE.md Reference
Sub-agent prompts reference only `~/.claude/skills/sdd-<phase>/SKILL.md`. They do NOT reference the project's `CLAUDE.md`. This means sub-agents don't know about:
- Unbreakable rules (language, skill structure, SDD compliance, sync discipline, feedback persistence)
- Tech stack declarations
- Project-level intent classification rules
- Plan mode requirements

### Gap 2: Incomplete Step 0 in Phase Skills
Phase skills (e.g., `sdd-propose`, `sdd-apply`) have Step 0a that reads only 4 governance files and only the Skills Registry from CLAUDE.md. They don't read:
- Full `CLAUDE.md` unbreakable rules
- `.cursor/rules/` equivalents
- `ai-context/known-issues.md` (which sdd-apply should respect)
- `ai-context/changelog-ai.md` (which informs recent decisions)

### Gap 3: No Explicit File Path Injection
The orchestrator prompt template does NOT include the path to the project's `CLAUDE.md`. Unlike the skill path (which is explicit), the CLAUDE.md path must be inferred (`project_root + "/CLAUDE.md"`).

### Gap 4: Governance Discovery Happens Late
Sub-agents read `ai-context/stack.md`, `architecture.md`, and `conventions.md` in Step 0a, which is AFTER:
- They've started processing
- They've read the SKILL.md
- They're about to read prior phase artifacts

By contrast, Copilot reads all governance upfront, before any coding begins.

---

## Recommendations (Forward)

### Priority 1: Include Project CLAUDE.md Path in Sub-Agent Prompt
**Where**: `skills/sdd-ff/SKILL.md` (and equivalent in `sdd-new`)
**Change**: Add to the CONTEXT section of all sub-agent prompts:
```
CONTEXT:
- Project: [absolute path]
- Change: [change-slug]
- Previous artifacts: [list of paths]
- Project governance: [absolute path to CLAUDE.md]
```

**Benefit**: Sub-agents know where to find full governance without guessing. Enables Step 0a to read the entire file.

### Priority 2: Expand Step 0a in All Phase Skills
**Where**: All SDD phase skills (sdd-propose, sdd-spec, sdd-design, sdd-tasks, sdd-apply, sdd-verify)
**Change**: In Step 0a, read the full `CLAUDE.md` (not just Skills Registry) and extract:
- Unbreakable Rules section
- Tech Stack section
- Intent Classification rules (for decision-making consistency)
- Feedback persistence rules (for proposal validation)

**Benefit**: Sub-agents become aware of project governance early, before making architectural or organizational decisions.

### Priority 3: Enhance Sub-Agent Prompt with Governance Summary
**Where**: `skills/sdd-ff/SKILL.md` and `openspec/agent-execution-contract.md`
**Change**: Orchestrator could optionally include a governance summary in the prompt:
```
GOVERNANCE:
- Language: [from CLAUDE.md]
- Primary tech stack: [from ai-context/stack.md]
- Unbreakable rule violations will be flagged
```

**Benefit**: Immediate visibility of critical constraints without reading files (faster startup, better priming).

---

## Success Criteria (For Implementation)

1. **Sub-agents receive explicit path to project CLAUDE.md** in all orchestrator prompts
2. **Step 0 in all phase skills reads full CLAUDE.md** (not just Skills Registry)
3. **Sub-agents report governance rules in Step 0 output** so orchestrator can verify visibility
4. **No project-level convention violations** in artifacts from sub-agent execution (to be verified by sdd-apply)
5. **Parity with Copilot behavior**: Sub-agents respect naming, architecture, and organizational constraints the same way Copilot does

---

## Artifacts Created

This exploration document: `openspec/changes/2026-03-12-fix-subagent-project-context/exploration.md`

---

## Related Documentation

- `docs/ORCHESTRATION.md` — Sub-agent launch pattern (Lines 79–99)
- `openspec/agent-execution-contract.md` — Context isolation rules (Lines 118–125)
- `docs/SKILL-RESOLUTION.md` — How skills are resolved
- `skills/sdd-ff/SKILL.md` — Orchestrator prompt templates
- `skills/sdd-apply/SKILL.md` — Example of Step 0a context loading
- `CLAUDE.md` — Project governance (full file)
- `.cursor/rules/*.mdc` — Copilot rule exports (for comparison)

---

## Next Steps

This exploration identifies the gap and its root causes. The proposal phase should:
1. Confirm the severity (is sub-agent governance drift a real problem in practice?)
2. Choose the implementation approach (Priority 1, 2, 3, or hybrid)
3. Define the file change matrix and task breakdown
4. Plan the rollout order (which skills to update first)

