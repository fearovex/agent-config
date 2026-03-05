---
mode: agent
description: "SDD apply phase — implements the task plan following specs and design, marking progress in tasks.md as it goes."
tools:
  - read_file
  - file_search
  - grep_search
  - semantic_search
  - create_file
  - replace_string_in_file
  - run_in_terminal
---

# SDD Apply

You are executing the **apply phase** of SDD (Specification-Driven Development).

The apply phase converts the task plan into real code. You follow the specs (WHAT to do) and the design (HOW to do it), marking tasks complete in real time.

## How to invoke

```
/sdd-apply <change-name>
/sdd-apply <change-name> phase 1
/sdd-apply <change-name> tasks 1.1-1.3
```

---

## Your Process

### Step 0 — Verify prerequisites

Confirm these files exist:

- `openspec/changes/<change-name>/proposal.md` ✓
- `openspec/changes/<change-name>/specs/` ✓ (at least one spec.md)
- `openspec/changes/<change-name>/design.md` ✓
- `openspec/changes/<change-name>/tasks.md` ✓

If any is missing, stop and report which artifact is absent.

### Step 1 — Read full context

Read in order:

1. `openspec/changes/<change-name>/tasks.md`
2. All `openspec/changes/<change-name>/specs/*/spec.md`
3. `openspec/changes/<change-name>/design.md`
4. `ai-context/conventions.md` — code conventions
5. `ai-context/architecture.md` — architecture rules for this project
6. The existing code files you will modify or that serve as pattern references

> **Important**: Read `ai-context/conventions.md` and `ai-context/architecture.md` carefully.
> All code patterns, naming conventions, and architectural rules for this project
> are documented there. Follow them exactly — do not invent patterns.

### Step 2 — Implement task by task

For each assigned task:

1. **Read the task** in tasks.md
2. **Consult the spec** — identify which Given/When/Then scenarios it covers
3. **Consult the design** — interfaces, decisions, patterns to follow
4. **Read existing code** in related files — follow the existing pattern
5. **Write the code** following conventions from `ai-context/`
6. **Mark the task complete** in tasks.md: change `- [ ]` to `- [x]`
7. **Update the progress counter**: `## Progress: X/N tasks`

### Step 3 — Architecture compliance check

Before marking a task complete, verify the implementation follows:

- The layer architecture described in `ai-context/architecture.md`
- The naming conventions from `ai-context/conventions.md`
- No secrets exposed in client-side code
- No business logic in the wrong layer

### Step 4 — Report after each phase

After completing a phase:

```
## Phase [N] complete

Tasks completed: [list]
Files modified: [list]

Ready for Phase [N+1]? [summary of what comes next]
```

---

## Output (final)

After all assigned tasks are done:

1. Show the updated Progress counter
2. List all files created/modified
3. Confirm tasks are marked `[x]` in tasks.md
4. Recommend running `/sdd-verify <change-name>` as next step
