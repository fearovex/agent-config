---
mode: agent
description: "SDD spec phase — writes functional requirements with Given/When/Then scenarios for a change."
tools:
  - read_file
  - file_search
  - grep_search
  - create_file
  - replace_string_in_file
---

# SDD Spec

You are executing the **spec phase** of SDD (Specification-Driven Development).

Specs define **WHAT the system must do** from the perspective of observable behavior. They do not say how to implement it. They are the source of truth for verification.

**Key concept — Delta Specs**: Specs are changes on top of what already exists.

- No existing spec → write a complete spec
- Spec already exists → write ADDED/MODIFIED/REMOVED sections

## How to invoke

```
/sdd-spec <change-name>
```

---

## Your Process

### Step 1 — Read prior artifacts

Required reads (in order):

1. `openspec/changes/<change-name>/proposal.md` — the WHAT and WHY
2. `openspec/specs/<domain>/spec.md` if it exists — current domain spec (delta mode)
3. `ai-context/architecture.md` — understand current system
4. `ai-context/features/<domain>.md` if it exists — domain business rules and invariants

### Step 2 — Identify affected domains

From the proposal, extract the domains that need specs. One domain = one coherent functional area.
Each domain has its own spec file.

### Step 3 — Write delta specs

For each affected domain, create or update:
`openspec/changes/<change-name>/specs/<domain>/spec.md`

#### Format when NO existing spec (full spec):

```markdown
# Spec: [Domain]

Change: [change-name]
Date: [YYYY-MM-DD]

## Requirements

### Requirement: [Descriptive name]

[Description using RFC 2119 keywords: MUST, SHOULD, MAY, MUST NOT]

#### Scenario: [Happy path name]

- **GIVEN** [precondition — system state]
- **WHEN** [action — what happens]
- **THEN** [observable result — what must happen]
- **AND** [additional result, if applicable]

#### Scenario: [Edge case / error case]

- **GIVEN** [...]
- **WHEN** [...]
- **THEN** [...]
```

#### Format when spec ALREADY EXISTS (delta):

```markdown
# Delta Spec: [Domain]

Change: [change-name]
Date: [YYYY-MM-DD]
Base: openspec/specs/[domain]/spec.md

## ADDED — New requirements

### Requirement: [Name]

[New requirement with scenarios]

## MODIFIED — Changed requirements

### Requirement: [Existing name] (MODIFIED)

[Updated version — include the full new text]

## REMOVED — Deleted requirements

### Requirement: [Existing name] (REMOVED)

Reason: [Why this requirement is removed]
```

---

## Output

At the end:

1. List all spec files created/updated with their paths
2. Summarize: how many requirements per domain, how many scenarios total
3. Highlight any ambiguities found
4. Recommend running `/sdd-design <change-name>` next
