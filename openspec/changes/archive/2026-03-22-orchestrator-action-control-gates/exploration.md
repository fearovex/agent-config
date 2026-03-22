# Exploration: Orchestrator Action Control Gates

## Handoff Context

**Decision that triggered the change**: The orchestrator's pre-routing enforcement is purely declarative. Rules exist (Rule 5 for feedback, Rule 6 for cross-session handoff) but no active checks run before a Change Request is routed — making it possible for the orchestrator to recommend `/sdd-ff` while a conflicting cycle is in progress, without surfacing spec contradictions, and without auto-detecting feedback sessions.

**Goal and success criteria (from proposal.md)**:
- Add a Pre-flight Check step that runs before routing any Change Request
- Active change scan: warn when a semantically overlapping change is in-flight in `openspec/changes/`
- Spec drift check: surface spec contradiction warning for Change Requests (currently Step 8 is Questions-only)
- Feedback session heuristic: auto-detect observational/complaint messages and enforce Rule 5
- Rule 5 enforcement as a blocking gate, not just prose

**Explore targets from proposal**:
- `CLAUDE.md` — Pre-flight Check section, Rule 5 enforcement update
- `openspec/specs/orchestrator-behavior/spec.md` — new REQ entries
- `openspec/specs/feedback-session/spec.md` — auto-detection requirement

**Constraints**:
- Pre-flight checks must be fast (directory listing + keyword matching only — no heavy file reads)
- Active change scan must NOT block if the in-flight change has a different semantic slug
- Spec drift warning is advisory, not blocking
- Feedback heuristic needs high precision (low false-positive rate)

---

## Current State

### CLAUDE.md classification pipeline

The orchestrator runs intent classification on every free-form message. The decision table structure is:

```
Meta-Command → execute
Change Request → Scope Estimation → Trivial/Moderate/Complex routing
Exploration → sdd-explore
Ambiguous → clarification gate
Question → direct answer (with optional Step 8 spec lookup)
```

**No pre-routing checks exist.** Once a message is classified as a Change Request, the orchestrator immediately applies Scope Estimation and recommends `/sdd-ff` or `/sdd-new` with no gate.

**Rule 5 — Feedback persistence** exists in the Unbreakable Rules section (line 229) as prose:
- "Feedback session (user shares observations/complaints/ideas): produce only `proposal.md` files"
- "MUST NOT start any implementation command in the same session"
- "Implementation happens in a separate session referencing the proposal"

**There is no detection logic** — Rule 5 only activates if the user explicitly declares it is a feedback session. The orchestrator has no heuristic to auto-detect observational language.

**Rule 6 — Cross-session ff handoff** is also opt-in: triggers only when user says "new session", "next chat", or "context reset."

**Step 8 (Spec-first Q&A)** is scoped to the Question pathway only. Change Requests that contradict a spec are not warned — they go straight to sdd-propose with the contradiction undetected at the orchestrator level.

### openspec/changes/ active directory

Currently two active (non-archived) change directories exist:
1. `2026-03-21-orchestrator-action-control-gates/` — this change (proposal only)
2. `2026-03-21-orchestrator-mandatory-new-session/` — companion proposal for mandatory new-session rule

### openspec/specs/orchestrator-behavior/spec.md

Large spec (>20K tokens). Key structural observations:
- Contains REQs for intent classification, four classes, routing rules, Scope Estimation
- Has a requirement for "Orchestrator never writes implementation code inline" (with Trivial tier exception added 2026-03-22)
- Does NOT contain any requirement for pre-flight checks or active cycle detection
- Step 8 spec lookup is defined as a Question-only pathway

### openspec/specs/feedback-session/spec.md

Defines four requirements:
1. Feedback items MUST be persisted as `proposal.md` before any SDD cycle
2. Each proposal.md MUST contain four sections (Intent, Motivation, Scope, Success Criteria)
3. Closing summary MUST be provided after a feedback session
4. Rule 5 MUST appear in CLAUDE.md Unbreakable Rules

**No auto-detection requirement exists** in `feedback-session/spec.md`. The spec treats feedback session detection as user-initiated ("when the user provides feedback"). This is a gap — the proposal wants heuristic auto-detection.

---

## Branch Diff

Files modified in current branch relevant to this change:

- `CLAUDE.md` (modified + staged) — active modifications pending; classification table is the insertion target
- `openspec/specs/orchestrator-behavior/spec.md` (modified + staged) — active modification target
- `openspec/changes/2026-03-21-orchestrator-action-control-gates/proposal.md` (staged, new) — this change's seed artifact
- `openspec/changes/2026-03-21-orchestrator-mandatory-new-session/proposal.md` (staged, new) — companion proposal (related scope)

---

## Prior Attempts

Prior archived changes related to this topic:

- `2026-03-10-sdd-feedback-persistence`: COMPLETED (feedback-session spec created, Rule 5 added to CLAUDE.md)
- `2026-03-12-orchestrator-always-on`: COMPLETED (four intent classes, routing rules defined)
- `2026-03-14-add-clarification-gate-for-ambiguous-inputs`: COMPLETED (clarification gate added to classification table)
- `2026-03-14-orchestrator-classification-edge-cases`: COMPLETED (edge case routing refinements)
- `2026-03-14-orchestrator-visibility`: COMPLETED (response signal preamble added)
- `2026-03-19-feedback-sdd-cycle-context-gaps-p6`: COMPLETED (Step 8 scoped to Questions; spec-first Q&A defined)
- `2026-03-22-orchestrator-scope-estimation`: COMPLETED (Scope Estimation Heuristic added to Change Request routing)
- `2026-03-22-orchestrator-natural-language`: COMPLETED (natural language / teaching tone improvements)

No archived attempt directly addressed pre-flight checks, active cycle scanning, or Change Request spec drift detection.

---

## Contradiction Analysis

- **Item**: Step 8 scope (spec-first Q&A for Change Requests)
  Status: CERTAIN — proposal says "extend spec drift check to Change Requests"; existing spec and CLAUDE.md explicitly scope Step 8 to Questions only
  Severity: WARNING
  Resolution: New pre-flight step must be defined independently from Step 8 (not a modification to Step 8 which is well-defined for Questions). Recommend adding a distinct "Pre-flight Spec Drift Check" gate that mirrors Step 8's keyword matching but operates before routing Change Requests.

- **Item**: Feedback session auto-detection vs existing feedback-session spec
  Status: UNCERTAIN — `feedback-session/spec.md` has no auto-detection requirement; current spec treats it as user-initiated. Proposal adds a heuristic trigger that the spec does not cover.
  Severity: WARNING
  Resolution: The feedback-session spec needs a new REQ for auto-detection with the observational pattern list. Spec update is required alongside CLAUDE.md.

- **Item**: Active change scan blocking behavior
  Status: UNCERTAIN — the companion change `2026-03-21-orchestrator-mandatory-new-session` also defines blocking behavior for in-flight cycles. Overlap exists: both proposals scan `openspec/changes/` for active cycles.
  Severity: WARNING
  Resolution: Coordinate with the mandatory-new-session proposal (Cycle 5). This change (Cycle 4) should define the scan mechanism; the mandatory-new-session change defines the blocking policy. Keep these distinct: action-control-gates = warn/advisory; mandatory-new-session = hard block.

---

## Affected Areas

| File/Module | Impact | Notes |
|---|---|---|
| `CLAUDE.md` | High — new Pre-flight Check section | Inserted between classification decision and Scope Estimation |
| `openspec/specs/orchestrator-behavior/spec.md` | High — new REQ entries for 3 pre-flight gates | Active file with many recent modifications |
| `openspec/specs/feedback-session/spec.md` | Medium — new auto-detection REQ | Extend existing spec |
| `skills/sdd-ff/SKILL.md` | Low — no change needed at skill level | Pre-flight runs at orchestrator level, not inside sdd-ff |

---

## Analyzed Approaches

### Approach A: Pre-flight as inline CLAUDE.md section

**Description**: Add a "Pre-flight Check" procedure block inside CLAUDE.md, positioned immediately after intent classification but before Scope Estimation. The block defines three sequential checks: (1) active change scan via directory listing, (2) spec drift keyword match for Change Requests, (3) feedback session pattern detection.

**Pros**:
- Consistent with how Scope Estimation and Ambiguity Heuristics are defined (inline in CLAUDE.md)
- No skill file I/O required — classification-critical logic stays inline (per ADR-041)
- Fast: directory listing is O(n) where n = active changes; keyword matching is O(m) where m = spec domains

**Cons**:
- CLAUDE.md is already large and growing; adding another multi-step section increases cognitive load
- Feedback session heuristic pattern list needs precision — false positives are disruptive

**Estimated effort**: Medium
**Risk**: Medium (CLAUDE.md is the runtime brain — any mistake affects all sessions immediately)

### Approach B: Pre-flight as a lightweight skill delegation

**Description**: Define a pre-flight skill (`orchestrator-preflight`) that runs via Task tool before routing any Change Request. The orchestrator calls it, receives a go/warn/block signal, then routes accordingly.

**Pros**:
- Isolates pre-flight logic from the classification pipeline
- Easier to test and iterate without touching CLAUDE.md

**Cons**:
- Violates ADR-041: classification-critical content must be inline in CLAUDE.md (no file I/O at classification time)
- Adds latency: every Change Request triggers a sub-agent call
- Inconsistent with how all other classification logic is structured

**Estimated effort**: High
**Risk**: High (architectural mismatch with existing conventions)

### Approach C: Inline pre-flight with lazy spec drift (defer heavy lookup)

**Description**: Same as Approach A, but the spec drift check uses only the index.yaml keyword match (already in memory from Step 8's pattern) and does NOT read actual spec files during pre-flight. Instead, it surfaces: "Your change description matches the `orchestrator-behavior` domain — check spec before proposing." The full spec read happens at sdd-explore or sdd-propose time.

**Pros**:
- Satisfies the constraint: "no heavy file reads; use directory listing + keyword matching only"
- Spec drift warning remains advisory and fast
- Consistent with Approach A's inline placement
- Aligns with the proposal's constraint wording exactly

**Cons**:
- Weaker signal than reading the actual spec — may miss specific contradictions at pre-flight time
- User gets an advisory, not a concrete contradiction quote

**Estimated effort**: Low-Medium
**Risk**: Low

---

## Recommendation

**Approach C** (inline pre-flight with lazy spec drift) is recommended. It:
- Satisfies the proposal's constraint that pre-flight checks be fast (directory listing + keyword matching, no heavy reads)
- Is consistent with ADR-041 (classification-critical logic stays inline)
- Produces advisory warnings (not blocks) for spec drift, matching the proposal's intent
- Avoids architectural mismatch of skill delegation for classification logic

The Pre-flight Check section should be placed between "Intent Classification" and "Scope Estimation Heuristic" in CLAUDE.md, defining three sequential checks:

1. **Active change scan**: `ls openspec/changes/` (excluding `archive/`), extract slugs, compute keyword overlap with current change description. If overlap ≥ 1 substantive keyword: emit advisory.
2. **Spec drift advisory**: check change description tokens against `index.yaml` keywords (no file read). If match found: surface advisory naming the matched domain.
3. **Feedback session detection**: if message matches observational patterns (pattern list defined inline), classify as Feedback Session and enforce Rule 5 gate.

For the feedback-session spec, add a new REQ for auto-detection with the pattern list. This is a spec extension, not a contradiction.

---

## Identified Risks

- **CLAUDE.md size growth**: Every cycle adds inline content. Consider a future ADR to extract pre-flight logic to a reference section or companion file if it grows beyond ~50 lines.
- **Feedback heuristic false positives**: Patterns like "I notice that X" are observational but could also be phrased as Change Requests. Precision requirement is critical. Recommend requiring multiple signals (≥2 observational patterns) before auto-triggering Feedback Session mode.
- **Active change scan over-matching**: Short slug tokens (like "fix", "add") appear in many change names. The scan MUST skip stop words and require overlap of substantive tokens (length > 3, not common verbs).
- **Companion change conflict** (`2026-03-21-orchestrator-mandatory-new-session`): Both changes touch the same enforcement surface. They must be implemented in declared order (this change = Cycle 4, mandatory-new-session = Cycle 5). The boundary must be explicit: Cycle 4 defines advisory gates; Cycle 5 defines hard blocking.

---

## Open Questions

- What is the definitive list of observational/feedback patterns? The proposal gives examples ("I noticed that", "when X happens Y should") but no exhaustive list. This needs to be specified during sdd-spec.
- Should the active change scan emit a prompt ("continue that cycle or start a new one?") that requires a user response before routing, or should it be purely informational (non-blocking)?
- Does the spec drift advisory apply to all Change Requests, or only Moderate and Complex tier ones? (Trivial changes likely don't need spec checking.)

---

## Ready for Proposal

Yes — the existing `proposal.md` is sufficient. The exploration confirms the approach, identifies the spec gap in `feedback-session/spec.md`, clarifies the boundary with the companion change (mandatory-new-session), and establishes Approach C as the implementation path. The open questions about pattern lists and blocking behavior need to be resolved during `sdd-spec`.
