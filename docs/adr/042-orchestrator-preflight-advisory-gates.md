# ADR-042: Orchestrator Pre-flight Advisory Gates — Inline Two-Gate Architecture

## Status

Proposed

## Context

The orchestrator's Change Request routing has no pre-routing checks. Once a message is classified as a Change Request, the orchestrator applies Scope Estimation and recommends `/sdd-ff` or `/sdd-new` immediately — without checking whether a semantically overlapping cycle is already in progress or whether the change description touches a spec domain. This allows conflicting cycles to start silently and spec contradictions to reach `sdd-propose` undetected.

ADR-041 established that classification-critical logic must stay inline in CLAUDE.md (no file I/O at classification time). A companion change (Cycle 5: mandatory-new-session) will own hard-blocking behavior. This change owns the advisory-only pre-routing layer.

Two gate options were evaluated:
- **Skill delegation**: isolates pre-flight logic but violates ADR-041, adds latency, and is inconsistent with all other classification logic.
- **Inline CLAUDE.md section**: consistent with Scope Estimation and Ambiguity Heuristics patterns; fast (directory listing + keyword matching only, no spec file reads).

## Decision

We will add a **Pre-flight Check** section inline in `CLAUDE.md`, positioned between the Classification Decision Table and the Scope Estimation Heuristic, defining two sequential advisory gates:

1. **Gate 1 — Active Change Scan**: list `openspec/changes/` directories (excluding `archive/`), apply stop-word token filter, and emit a non-blocking advisory if any message token overlaps a substantive slug token.
2. **Gate 2 — Spec Drift Advisory**: if `openspec/specs/index.yaml` is present, keyword-match message tokens against domain entries and emit a non-blocking advisory naming the matched domain. If `index.yaml` is absent, skip silently (same graceful degradation as Step 8).

Both gates are advisory-only. The user always proceeds. Hard-blocking behavior is reserved for Cycle 5 (mandatory-new-session).

## Consequences

**Positive:**
- Users get early visibility into in-flight cycles before starting a potentially conflicting one.
- Spec domain relevance is surfaced at Change Request time, reducing the chance of spec contradictions reaching sdd-propose undetected.
- Consistent with ADR-041: no skill delegation, no file I/O at classification time.
- Graceful degradation when `index.yaml` is absent — no friction on new projects.

**Negative:**
- CLAUDE.md grows in size with each inline addition. Gate 1 and Gate 2 add approximately 20–30 lines.
- Stop-word list and token filter are hard-coded inline — any refinement requires a new SDD cycle.
- Advisory-only gates may be ignored by users — they do not prevent conflicting cycles from starting (by design, pending Cycle 5).
