---
mode: agent
description: "SDD fast-forward — executes propose → spec → design → tasks in sequence, then asks before apply."
tools:
  - read_file
  - file_search
  - grep_search
  - semantic_search
  - create_file
  - replace_string_in_file
---

# SDD Fast-Forward

You are executing the **fast-forward SDD cycle**.

Runs all planning phases sequentially (propose → spec → design → tasks) then asks for confirmation before implementing.

> Note: Unlike Claude Code (which runs spec+design in parallel via subagents), Copilot runs phases sequentially — same artifacts, no parallelism.

## How to invoke

```
/sdd-ff <change-name>
```

If `<change-name>` is missing:

```
Usage: /sdd-ff <change-name>
Example: /sdd-ff add-payment-flow
```

---

## Phase 1 — Propose

Follow the full sdd-propose process:

1. Read prior context files (`ai-context/`, `exploration.md` if exists)
2. Create `openspec/changes/<change-name>/proposal.md`

**Checkpoint:**

```
✅ Phase 1 complete: proposal.md created

Intent: [one line]
Scope: [in/out summary]
Top risk: [top risk]

Proceed to Spec + Design? [y/n]
```

Wait for confirmation.

---

## Phase 2 — Spec

Follow the full sdd-spec process:

1. Read `proposal.md` + existing master specs + `ai-context/features/`
2. Create `openspec/changes/<change-name>/specs/<domain>/spec.md`

---

## Phase 3 — Design

Follow the full sdd-design process:

1. Read `proposal.md` + all spec files + `ai-context/` + real code
2. Create `openspec/changes/<change-name>/design.md`

**Checkpoint after Spec + Design:**

```
✅ Phase 2+3 complete

Domains specced: [list]
Requirements: [N]
Files to change: [N]

Proceed to Tasks? [y/n]
```

Wait for confirmation.

---

## Phase 4 — Tasks

Follow the full sdd-tasks process:

1. Read `design.md` + all spec files
2. Create `openspec/changes/<change-name>/tasks.md`

---

## Final Summary

```
✅ SDD Fast-Forward complete for: [change-name]

Artifacts:
  📄 openspec/changes/[change-name]/proposal.md
  📄 openspec/changes/[change-name]/specs/[domain]/spec.md
  📄 openspec/changes/[change-name]/design.md
  📄 openspec/changes/[change-name]/tasks.md

  • [N] requirements, [N] tasks across [M] phases
  • Estimated effort: [Low/Medium/High]

Ready to implement?
  /sdd-apply [change-name]
  /sdd-apply [change-name] phase 1   (phase by phase)
```

## Rules

- Complete each phase fully before the next
- Do NOT skip the Propose checkpoint
- Do NOT auto-run `/sdd-apply` — always ask first
- If any phase fails, stop and report why
