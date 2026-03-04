<!-- _template.md — DO NOT load this file in SDD phases. Copy it to <domain>.md and fill in each section. -->

# Feature: <Domain Name>

> One-line description of this bounded context.

Last updated: YYYY-MM-DD
Related specs: openspec/specs/<domain>/spec.md

---

## Domain Overview

Write 2–4 sentences describing what this feature or bounded context does, who owns it, and what
core responsibility it holds within the larger system. Explain the problem it solves and its
primary role. Avoid implementation detail here — focus on purpose and scope.

---

## Business Rules and Invariants

List the always-true constraints this domain enforces regardless of code path. Each item should be
a declarative statement that holds in every state of the system. Examples of what to write:

- [Rule 1: state what is always true — e.g. "A refund cannot exceed the original payment amount"]
- [Rule 2: another invariant the domain guarantees]
- [Rule 3: edge-case constraint that distinguishes valid from invalid state]

Do not document implementation choices here — only rules that would remain true even if the
implementation were rewritten from scratch.

---

## Data Model Summary

Describe the key entities this domain owns, their relationships, and any critical field constraints.
This is NOT a full schema — write in plain prose or use a small table for the most important
entities. The goal is to orient a developer quickly, not to duplicate the database schema.

| Entity | Key Fields | Constraints |
|--------|------------|-------------|
| [EntityName] | [field1, field2] | [e.g. "field1 must be unique", "field2 is required"] |
| [EntityName] | [field1, field2] | [constraints] |

Add any relationship notes below the table (e.g. "Order has many OrderItems; an Order with zero
items is invalid").

---

## Integration Points

Document every external system, service, or domain that this bounded context depends on or exposes
an interface to. Include both inbound (things that call into this domain) and outbound (things this
domain calls or emits to).

| System / Service | Direction | Contract |
|-----------------|-----------|----------|
| [ServiceName] | inbound | [what it sends and what this domain expects] |
| [ServiceName] | outbound | [what this domain calls and what it expects back] |
| [OtherDomain] | inbound/outbound | [contract description] |

Add notes for async contracts (events, queues) or infrastructure dependencies (external APIs,
third-party providers) below the table.

---

## Decision Log

Record significant design or implementation decisions made for this domain, in chronological order.
Each entry answers: what was decided, why, and what it constrains going forward. Add entries as
decisions are made — never delete old entries.

### [YYYY-MM-DD] — [Decision name]

**Decision**: [What was decided — state it as a fact, e.g. "We use optimistic locking for
inventory updates rather than pessimistic locking."]

**Rationale**: [Why this decision was made — constraints, trade-offs, context at the time]

**Impact**: [What changed or what future changes are now constrained by this decision]

---

## Known Gotchas

List unexpected behaviors, operational hazards, historical defects, or non-obvious constraints that
a developer working in this domain MUST be aware of. Include things that caused bugs in the past,
edge cases that are easy to miss, and anything that tripped up previous contributors.

- [Gotcha 1: describe the non-obvious behavior and when it manifests]
- [Gotcha 2: describe another hazard, historical failure mode, or surprising constraint]
