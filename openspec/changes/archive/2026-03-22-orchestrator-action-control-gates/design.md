# Technical Design: 2026-03-21-orchestrator-action-control-gates

Date: 2026-03-22
Proposal: openspec/changes/2026-03-21-orchestrator-action-control-gates/proposal.md

## General Approach

Add a **Pre-flight Check** section inline in `CLAUDE.md`, positioned between the Classification Decision Table and the Scope Estimation Heuristic. The section defines two sequential advisory gates: (1) an active change scan using directory listing of `openspec/changes/` with stop-word-filtered token overlap, and (2) a spec drift advisory using `index.yaml` keyword matching only — no spec file reads. Both gates are non-blocking. `sdd-spec` is updated to create `index.yaml` if absent when writing the first domain spec. Feedback session detection stays user-initiated (Rule 5 unchanged). The companion change (mandatory-new-session, Cycle 5) owns hard-blocking behavior; this change owns advisory-only gates.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|---|---|---|---|
| Pre-flight placement (architecture) | Inline in CLAUDE.md between Classification Decision Table and Scope Estimation | Skill delegation (Approach B), appended at end of CLAUDE.md | ADR-041 mandates classification-critical logic stays inline. Placement after classification but before Scope Estimation is the only coherent insert point — pre-flight informs routing before tier is computed. |
| Number of advisory gates | Two gates only: active change scan + spec drift advisory | Three gates including feedback session auto-detection | Feedback session auto-detection was scoped out per proposal.md decision — too many false positives. Two gates cover the agreed-upon requirements. |
| Spec drift advisory mechanism (convention) | Index.yaml keyword-only match — no spec file reads | Read spec files at pre-flight time | Proposal constraint: "pre-flight checks must be fast — directory listing + keyword matching only, no spec file reads." Matches Step 8's graceful-degradation pattern for missing index.yaml. |
| Active change scan token filter | Stop-word filter (skip tokens ≤ 3 chars or in stop-word list: fix, add, the, for, a, an, and, or, of, to, in, on, at) + require at least 1 overlapping substantive token | Exact slug match, simple substring match | Short tokens (fix, add) appear in most change names, causing false positives. Substantive token overlap (length > 3, not in stop-word list) avoids over-triggering. |
| Gate blocking policy (architecture) | Both gates advisory-only — user always proceeds | Active change scan blocks until user confirms | Boundary with Cycle 5 (mandatory-new-session): this change = advisory; Cycle 5 = hard blocking. Keeping Cycle 4 advisory avoids cross-change conflict. |
| index.yaml absence behavior | Skip spec drift advisory silently, no error | Emit warning if absent | Matches existing Step 8 graceful degradation pattern in CLAUDE.md. Consistent, predictable, no user friction when index is not yet populated. |
| sdd-spec index.yaml creation | sdd-spec creates index.yaml if absent before writing first domain spec | Leave index.yaml creation entirely to project-setup | Proposal success criterion explicitly requires it. sdd-spec already writes to openspec/specs/; index.yaml creation is a natural co-responsibility. |
| Feedback session detection | Remains user-initiated (Rule 5 prose unchanged) | Heuristic auto-detection via observational pattern list | Exploration phase flagged high false-positive risk. Proposal.md explicitly descopes heuristic auto-detection. Rule 5 remains Unbreakable Rule — no change needed. |

## Data Flow

```
User free-form message
        │
        ▼
┌─────────────────────────┐
│  Intent Classification  │
│  (Meta/Change/Explore/  │
│   Ambiguous/Question)   │
└────────────┬────────────┘
             │ Change Request detected
             ▼
┌─────────────────────────────────────────────────────┐
│             PRE-FLIGHT CHECK (new)                  │
│                                                     │
│  Gate 1: Active Change Scan                         │
│    list openspec/changes/* (exclude archive/)       │
│    extract slugs → tokenize (stop-word filter)      │
│    overlap with current message tokens?             │
│    ≥1 substantive match → emit advisory (non-block) │
│                                                     │
│  Gate 2: Spec Drift Advisory                        │
│    IF index.yaml present:                           │
│      match message tokens vs domain keywords        │
│      match found → emit advisory naming domain      │
│    ELSE: skip silently                              │
│                                                     │
│  (Both gates advisory — user proceeds regardless)   │
└────────────────────────┬────────────────────────────┘
                         │
                         ▼
              ┌──────────────────┐
              │  Scope Estimation│
              │  Heuristic       │
              │  (Trivial/Mod/   │
              │   Complex)       │
              └────────┬─────────┘
                       │
                       ▼
              Recommend /sdd-ff or /sdd-new
```

**sdd-spec index.yaml creation path:**

```
sdd-spec Step 3 — Write delta specs
        │
        ▼
  First domain spec being written?
        │ YES
        ▼
  openspec/specs/index.yaml absent?
        │ YES
        ▼
  Create index.yaml with header comment
  and empty domains: [] stub
        │
        ▼
  Continue writing spec as normal
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `CLAUDE.md` | Modify | Add "Pre-flight Check" section between Classification Decision Table and Scope Estimation Heuristic. Define Gate 1 (active change scan with token overlap algorithm + advisory template) and Gate 2 (spec drift advisory with index.yaml keyword match + graceful degradation). |
| `skills/sdd-spec/SKILL.md` | Modify | Add index.yaml creation step in Step 3 (Write delta specs): if writing first domain spec and index.yaml is absent, create it with canonical header comment and empty domains stub. |
| `openspec/specs/orchestrator-behavior/spec.md` | Modify | Add new REQ entries for: pre-flight check section existence, Gate 1 active change scan behavior, Gate 2 spec drift advisory behavior, advisory-only (non-blocking) constraint, index.yaml graceful degradation. |

## Interfaces and Contracts

**Pre-flight Check — Gate 1 algorithm (inline CLAUDE.md prose):**

```
Active Change Scan:
  1. List directories in openspec/changes/ excluding archive/
  2. Extract slug tokens: split each directory name on "-",
     discard tokens of length ≤ 3 and stop words
     (stop words: fix, add, the, for, and, or, of, to, in, on, at, a, an)
  3. Tokenize current message: split on spaces/punctuation,
     same filter applied
  4. IF any message token appears in any slug token set:
     EMIT advisory:
     "You have '<change-name>' in progress. Do you want to continue
      that cycle or start a new one?"
  5. Gate is non-blocking — user proceeds regardless of advisory
```

**Pre-flight Check — Gate 2 algorithm (inline CLAUDE.md prose):**

```
Spec Drift Advisory:
  1. IF openspec/specs/index.yaml absent: skip silently
  2. Read index.yaml domains[] array
  3. Tokenize current message (same stop-word filter as Gate 1)
  4. For each domain entry: check if any domain.keywords[] token
     appears in message tokens (case-insensitive)
  5. IF match found:
     EMIT advisory:
     "Your change touches the '<domain>' spec domain —
      review openspec/specs/<domain>/spec.md before proposing."
  6. Gate is non-blocking — user proceeds regardless of advisory
```

**sdd-spec index.yaml creation stub:**

```yaml
# openspec/specs/index.yaml
# Spec domain index — enables index-driven spec lookup for SDD phase skills.
# Each entry: domain (matches openspec/specs/<domain>/ directory name exactly),
# summary (one-line description), keywords (3-8 change-slug terms),
# related (optional list of co-relevant domain names in this index).
#
# Maintained by: sdd-archive (appends one entry per new spec domain created).
# Selection algorithm: see docs/SPEC-CONTEXT.md — "Using the spec index".
# Migration trigger: 100+ domains → consider SQLite/FTS5 (see ADR 034).

domains: []
```

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Manual — Gate 1 | Submit a Change Request while `2026-03-21-orchestrator-action-control-gates` is in `openspec/changes/`; confirm advisory appears for overlapping message | sdd-verify (manual prompt test) |
| Manual — Gate 1 non-trigger | Submit a Change Request with unrelated tokens (e.g., "add react skill"); confirm no advisory emitted | sdd-verify (manual prompt test) |
| Manual — Gate 2 | Submit "fix orchestrator routing" when index.yaml present with orchestrator-behavior domain; confirm advisory names the domain | sdd-verify (manual prompt test) |
| Manual — Gate 2 absent | Remove or rename index.yaml; submit Change Request; confirm no error and no advisory | sdd-verify (manual prompt test) |
| Manual — non-blocking | After advisory emitted for Gate 1 or Gate 2, proceed with recommendation; confirm /sdd-ff is still offered | sdd-verify (manual prompt test) |
| Manual — sdd-spec index creation | Run sdd-spec on a new change when index.yaml is absent; confirm index.yaml is created with empty domains stub | sdd-verify (file check) |

## Migration Plan

No data migration required. `CLAUDE.md` and `SKILL.md` are Markdown files deployed via `install.sh`. No schema changes, no data stores. `openspec/specs/orchestrator-behavior/spec.md` is additive (new REQ entries appended).

## Open Questions

- Should Gate 2 (spec drift advisory) apply to all Change Request tiers (Trivial/Moderate/Complex) or skip for Trivial? Proposal is silent. Current design applies to all tiers for simplicity — Trivial changes rarely reach here with a spec match anyway. If false positives emerge on Trivial, the filter can be added. **Impact if unresolved**: minor UX noise for trivial doc fixes that match a spec domain keyword.
