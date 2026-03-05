---
mode: agent
description: "SDD tasks phase — breaks the design into an atomic, ordered, verifiable task plan stored in tasks.md."
tools:
  - read_file
  - file_search
  - create_file
---

# SDD Tasks

You are executing the **tasks phase** of SDD (Specification-Driven Development).

The task plan converts the design into an **executable work list**. Each task is atomic (one thing), concrete (has a file path), and verifiable (can be marked done or not).

This is the input for `sdd-apply`. Without an approved tasks file, nothing gets implemented.

## How to invoke

```
/sdd-tasks <change-name>
```

---

## Your Process

### Step 1 — Read prior artifacts

Required reads:

1. `openspec/changes/<change-name>/design.md` — file matrix and technical approach
2. All `openspec/changes/<change-name>/specs/*/spec.md` — success criteria
3. `openspec/config.yaml` if it exists — project rules

### Step 2 — Analyze task dependencies

Identify the natural implementation order:

- Types/interfaces before their usage
- Services before their consumers
- DB schemas/migrations before the code using them
- Unit tests alongside the code (not at the end)

### Step 3 — Organize into phases

```
Phase 1 — Foundation: types, interfaces, schemas, configuration
Phase 2 — Core: main business logic
Phase 3 — Integration: connect with the rest of the system
Phase 4 — Testing: tests covering spec scenarios
Phase 5 — Cleanup: remove temporary code, update docs
```

### Step 4 — Create tasks.md

Create `openspec/changes/<change-name>/tasks.md`:

```markdown
# Task Plan: [change-name]

Date: [YYYY-MM-DD]
Design: openspec/changes/[change-name]/design.md

## Progress: 0/[total] tasks

---

## Phase 1: [Phase Name]

- [ ] 1.1 [Concrete action with exact file path] — [what is added/changed]
- [ ] 1.2 [Concrete action with exact file path] — [what is added/changed]

## Phase 2: [Phase Name]

- [ ] 2.1 [Concrete action with exact file path] — [what is added/changed]

## Phase 3: [Phase Name]

- [ ] 3.1 [Concrete action with exact file path] — [what is added/changed]

## Phase 4: Testing

- [ ] 4.1 Create `[test file path]` — unit tests for [module]
- [ ] 4.2 Verify scenario coverage from spec

## Phase 5: Cleanup

- [ ] 5.1 Update `ai-context/changelog-ai.md` with this change
- [ ] 5.2 Update `ai-context/architecture.md` if structural changes were made

---

## Spec Coverage Map

| Spec Scenario   | Covered by Task |
| --------------- | --------------- |
| [Scenario name] | [task number]   |
```

Each task MUST: contain an exact file path, describe one atomic action, be independently verifiable.

---

## Output

At the end:

1. Confirm `openspec/changes/<change-name>/tasks.md` was created
2. Show total task count per phase
3. Confirm Spec Coverage Map covers all spec scenarios
4. Recommend running `/sdd-apply <change-name>` next
