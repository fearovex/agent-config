---
mode: agent
description: "SDD design phase — produces the technical design with architecture decisions, data flow, and a file change plan."
tools:
  - read_file
  - file_search
  - grep_search
  - semantic_search
  - create_file
---

# SDD Design

You are executing the **design phase** of SDD (Specification-Driven Development).

The design defines **HOW to implement** what the specs say the system must do. It is the bridge between requirements and code. It documents technical decisions and their justification.

## How to invoke

```
/sdd-design <change-name>
```

---

## Your Process

### Step 1 — Read prior artifacts

Required reads (in order):

1. `openspec/changes/<change-name>/proposal.md`
2. All `openspec/changes/<change-name>/specs/*/spec.md` files
3. `ai-context/architecture.md` — understand past decisions
4. `ai-context/conventions.md` — team code patterns

Then read real code:

- Entry points of affected areas
- Files that will be modified according to the proposal
- Existing patterns to follow (prefer consistency over novelty)
- Existing tests (they reveal current contracts)

### Step 2 — Design the technical solution

Evaluate the solution considering:

- Patterns already used in the project (prefer consistency)
- Minimal impact on existing code
- Testability
- Reversibility

Always respect the project's architecture layers as described in `ai-context/architecture.md`.

### Step 3 — Create design.md

Create `openspec/changes/<change-name>/design.md`:

```markdown
# Technical Design: [change-name]

Date: [YYYY-MM-DD]
Proposal: openspec/changes/[change-name]/proposal.md

## General Approach

[High-level description in 3-5 lines]

## Technical Decisions

| Decision   | Choice           | Discarded Alternatives | Justification |
| ---------- | ---------------- | ---------------------- | ------------- |
| [decision] | [what is chosen] | [alt A, alt B]         | [why]         |

## Data Flow

[ASCII diagram or step-by-step description]

## File Change Matrix

| File             | Action        | What is added/modified |
| ---------------- | ------------- | ---------------------- |
| `[path/to/file]` | Create/Modify | [description]          |

## Interfaces and Contracts

[Function signatures, object shapes, API contracts relevant to this change]

## Dependencies and Pre-conditions

- [What must already exist]

## Rollback Plan

[Concrete steps to revert: delete files, restore originals, etc.]
```

---

## Output

At the end:

1. Confirm `openspec/changes/<change-name>/design.md` was created
2. Present the File Change Matrix as a summary
3. Highlight the most critical technical decisions
4. Flag any design deviations from the project architecture
5. Recommend running `/sdd-tasks <change-name>` next
