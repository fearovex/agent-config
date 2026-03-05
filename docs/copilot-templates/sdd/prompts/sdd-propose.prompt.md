---
mode: agent
description: "SDD propose phase — creates proposal.md defining the WHAT and WHY before any technical work begins."
tools:
  - read_file
  - file_search
  - grep_search
  - create_file
---

# SDD Propose

You are executing the **propose phase** of SDD (Specification-Driven Development).

The proposal defines the **WHAT and WHY** before entering technical details. It is the scope contract of the change. Without an approved proposal, no specs or design should be written.

## How to invoke

```
/sdd-propose <change-name>
```

`<change-name>` must be kebab-case. Example: `add-payment-flow`, `fix-auth-token-refresh`

---

## Your Process

### Step 1 — Read prior context

In order:

1. If `openspec/changes/<change-name>/exploration.md` exists → read it
2. If `openspec/config.yaml` exists → read project rules
3. If `ai-context/architecture.md` exists → read for coherence
4. If `ai-context/conventions.md` exists → read team patterns
5. Check `ai-context/features/` for any `.md` file whose name matches stems from `<change-name>`
   - Example: change `fix-auth-token` → stems `[fix, auth, token]` → read `features/auth.md` if it exists

### Step 2 — Understand the request

If the description is ambiguous, ask:

- What problem or need motivates this change?
- Are there known constraints (performance, compatibility, backward compat)?
- What is explicitly OUT of scope?

### Step 3 — Create the change directory

Create `openspec/changes/<change-name>/` if it does not exist.

### Step 4 — Write proposal.md

Create `openspec/changes/<change-name>/proposal.md`:

```markdown
# Proposal: [change-name]

Date: [YYYY-MM-DD]
Status: Draft

## Intent

[One clear sentence: what problem it solves or what need it covers]

## Motivation

[Why this is necessary now. Business or technical context.]

## Scope

### Included

- [deliverable 1]
- [deliverable 2]

### Excluded (explicitly out of scope)

- [what will NOT be done and why]

## Proposed Approach

[High-level description of the technical solution — no implementation details.
Explains "how" at a conceptual level.]

## Affected Areas

| Area/Module | Type of Change       | Impact          |
| ----------- | -------------------- | --------------- |
| [area]      | New/Modified/Removed | Low/Medium/High |

## Risks

| Risk   | Probability     | Impact          | Mitigation        |
| ------ | --------------- | --------------- | ----------------- |
| [risk] | Low/Medium/High | Low/Medium/High | [how to mitigate] |

## Rollback Plan

[Concrete steps to revert: which files, which commands, which steps]

## Dependencies

- [What must exist before starting this change]

## Success Criteria

- [ ] [measurable and verifiable criterion 1]
- [ ] [measurable and verifiable criterion 2]

## Effort Estimate

[Low (hours) / Medium (1-2 days) / High (several days)]
```

---

## Output

At the end:

1. Confirm `openspec/changes/<change-name>/proposal.md` was created
2. Present a brief summary of: intent, scope, top risks, success criteria
3. Recommend next steps:
   - Run `/sdd-spec <change-name>` and `/sdd-design <change-name>` (in sequence)
   - Or run `/sdd-ff <change-name>` to continue the full fast-forward cycle
