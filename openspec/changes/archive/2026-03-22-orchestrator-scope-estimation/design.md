# Technical Design: orchestrator-scope-estimation

Date: 2026-03-22
Proposal: openspec/changes/2026-03-21-orchestrator-scope-estimation/proposal.md

## General Approach

Add a `### Scope Estimation Heuristic` subsection under the existing `## Always-On Orchestrator — Intent Classification` section in CLAUDE.md, following the structural pattern established by the Ambiguity Detection Heuristics subsection. The Classification Decision Table's Change Request branch gains a single cross-reference line that triggers scope estimation after intent classification. Unbreakable Rule 1 gains a parenthetical exception clause for Trivial tier inline apply. The orchestrator-behavior master spec gains new REQ scenarios for the three tiers.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
| -------- | ------ | ---------------------- | ------------- |
| Section placement | New `### Scope Estimation Heuristic` subsection inside `## Always-On Orchestrator` | Inline in decision table (Approach A); separate skill (Approach C) | Matches the Ambiguity Detection Heuristics pattern — separate subsection referenced from the decision table. Keeps the decision table readable while making tier definitions independently locatable. |
| Trivial bypass mechanism | Orchestrator applies change directly (formal Rule 1 exception) | Lightweight sub-agent delegation; full SDD cycle for all tiers | User confirmed inline apply means orchestrator-direct. Sub-agent delegation adds latency for genuinely trivial changes (typo, comment). Rule 1 exception is explicitly documented, not silent. |
| Scope signal format | Keyword lists per tier (Trivial signals, Complex signals) with Moderate as default | Numeric scoring; file-count analysis; AST-based detection | Keyword matching is consistent with intent classification (also keyword-based). Numeric scoring and AST analysis are over-engineering for an orchestrator heuristic. |
| Default tier | Moderate (never Trivial) | Trivial as default; no default (require explicit classification) | Safety net — ambiguous scope always routes through standard SDD. Prevents false-trivial classification of impactful changes. |
| Scope tier in response signal | Include tier in signal: `**Intent classification: Change Request (Trivial)**` | Keep tier implicit; separate line for tier | Extending the existing signal format is minimal cognitive overhead and provides immediate transparency. Follows the visibility principle established by orchestrator-visibility. |
| Trivial tier artifact policy | Artifact-free — no proposal.md, no verify-report.md | Minimal verify-report.md for traceability | Trivial changes are by definition low-risk and single-file. Requiring artifacts defeats the purpose of the bypass. Git history provides sufficient traceability. |

## Data Flow

```
User message
    │
    ▼
Intent Classification (existing)
    │
    ├── Meta-Command → execute immediately
    ├── Exploration → sdd-explore
    ├── Question → answer directly
    └── Change Request
            │
            ▼
    Scope Estimation (NEW)
            │
            ├── Trivial signals matched + single-file scope
            │       │
            │       ▼
            │   Offer: "Apply directly or use /sdd-ff?"
            │       ├── Direct → orchestrator applies inline (Rule 1 exception)
            │       └── SDD → /sdd-ff <slug>
            │
            ├── Complex signals matched OR multi-domain scope
            │       │
            │       ▼
            │   Recommend: /sdd-new <slug>
            │
            └── Default (no clear signal / ambiguous)
                    │
                    ▼
                Moderate → Recommend: /sdd-ff <slug>
```

## File Change Matrix

| File | Action | What is added/modified |
| ---- | ------ | ---------------------- |
| `CLAUDE.md` | Modify | New `### Scope Estimation Heuristic` subsection with tier definitions, signal lists, routing rules, and examples |
| `CLAUDE.md` | Modify | Classification Decision Table Change Request branch: add scope estimation cross-reference line after intent classification, before routing |
| `CLAUDE.md` | Modify | Unbreakable Rule 1: add parenthetical exception clause for Trivial tier |
| `CLAUDE.md` | Modify | Orchestrator Session Banner: add brief mention of scope-aware routing |
| `openspec/specs/orchestrator-behavior/spec.md` | Modify | New requirement: "Scope estimation for Change Requests" with Trivial/Moderate/Complex scenarios |

## Interfaces and Contracts

No code interfaces — this change is pure Markdown configuration. The "contract" is the heuristic definition:

```yaml
# Scope Estimation Tier Contract (conceptual)

Trivial:
  signals:
    - typo, typos, spelling, wording, comment, comments
    - whitespace, formatting, punctuation
    - doc fix, documentation fix, readme
    - rename (single file context only)
  constraints:
    - ALL signals must be present (not just one)
    - Single-file scope implied or stated
    - No logic change, no behavior change
  routing: offer inline apply OR /sdd-ff (user chooses)
  response_signal: "**Intent classification: Change Request (Trivial)**"

Complex:
  signals:
    - rearchitect, redesign, overhaul, rewrite
    - multi-domain, cross-cutting, system-wide
    - migration, migrate (data or schema)
    - breaking change, backwards-incompatible
    - "multiple files", "across modules", "all services"
  constraints:
    - ANY signal triggers Complex classification
    - Multi-file or multi-domain scope implied or stated
  routing: recommend /sdd-new <slug>
  response_signal: "**Intent classification: Change Request (Complex)**"

Moderate:
  signals: (default — no signal match needed)
  constraints:
    - Neither Trivial nor Complex signals matched
    - OR ambiguous scope
  routing: recommend /sdd-ff <slug> (existing behavior)
  response_signal: "**Intent classification: Change Request**" (no tier suffix)
```

## Testing Strategy

| Layer | What to test | Tool |
| ----- | ------------ | ---- |
| Manual | Classification examples from the decision table | Human walkthrough in a Claude Code session |
| Audit | `/project-audit` score >= previous after apply | `/project-audit` |
| Structural | CLAUDE.md section presence and format | `/project-audit` D4 dimension |

## Migration Plan

No data migration required. The change is purely additive to CLAUDE.md and the master spec. Existing behavior (all Change Requests route to `/sdd-ff`) is preserved as the Moderate tier default.

## Open Questions

- **Signal list completeness**: The Trivial and Complex signal lists are starter sets. Should they be validated against historical change descriptions from `openspec/changes/archive/` before finalizing in the spec phase? Impact: if lists are too narrow, most changes stay Moderate (safe but reduces value); if too broad, false classifications increase.
- **Teaching principle interaction**: Should Trivial tier skip the why-framing sentence (Teaching Principle 1)? Current design leaves this unspecified — the teaching principles apply uniformly regardless of tier. Impact: minor UX inconsistency if a trivial change gets a risk explanation.

None of these are blocking — both can be refined post-apply via feedback cycles.
