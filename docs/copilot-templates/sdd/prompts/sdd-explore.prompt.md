---
mode: agent
description: "SDD explore phase — research and analyze a topic before committing to changes. Pure read-only investigation."
tools:
  - read_file
  - file_search
  - grep_search
  - semantic_search
  - create_file
---

# SDD Explore

You are executing the **explore phase** of SDD (Specification-Driven Development).

This phase is **read-only research**. You analyze the codebase, document findings, and evaluate approaches — but you make no code changes.

## How to invoke

```
/sdd-explore <change-name>
/sdd-explore <topic>
```

---

## Your Process

### Step 1 — Understand the request

Classify the exploration type:

- **New feature**: What already exists? Where would it fit?
- **Bug**: Where is the problem? What is the root cause?
- **Refactor**: What code is affected? What are the risks?
- **Integration**: What exists to connect? What is missing?

### Step 2 — Read context files

1. `ai-context/architecture.md` — understand past decisions
2. `ai-context/conventions.md` — understand team patterns
3. Any relevant `ai-context/features/*.md` that matches the topic

### Step 3 — Investigate the codebase

Read real code following this hierarchy:

1. Entry points of the affected area
2. Files related to the functionality
3. Existing tests (they reveal expected behavior)
4. Relevant configurations

### Step 4 — Analyze approaches

For each possible approach, produce a comparison table:

| Approach | Pros | Cons | Effort          | Risk            |
| -------- | ---- | ---- | --------------- | --------------- |
| Option A | ...  | ...  | Low/Medium/High | Low/Medium/High |
| Option B | ...  | ...  | ...             | ...             |

### Step 5 — Identify risks and dependencies

- Code that would break with the change
- Dependencies that would need to be updated
- Tests that would fail
- Non-obvious side effects

### Step 6 — Save exploration.md

If a change name was provided, create:
`openspec/changes/<change-name>/exploration.md`

```markdown
# Exploration: [topic]

Date: [YYYY-MM-DD]

## Current State

[What currently exists in the codebase]

## Affected Areas

| File/Module | Impact          | Notes |
| ----------- | --------------- | ----- |
| ...         | Low/Medium/High | ...   |

## Analyzed Approaches

[Comparison table]

## Risks

[List of identified risks]

## Recommendation

[Which approach to take and why]

## Next Step

Ready for: /sdd-propose <change-name>
```

---

## Output

At the end, report:

- What you found in the codebase
- The recommended approach with justification
- Key risks to be aware of
- Recommend running `/sdd-propose <change-name>` as next step
