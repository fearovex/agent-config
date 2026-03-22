# Technical Design: 2026-03-21-orchestrator-natural-language

Date: 2026-03-22
Proposal: openspec/changes/2026-03-21-orchestrator-natural-language/proposal.md

## General Approach

Add a `## Communication Persona` section to CLAUDE.md that wraps the existing classification logic with natural language presentation rules. The section defines tone, forbidden mechanical phrases, natural response templates per intent class, adaptive formality, and a rewritten session banner. No routing logic or classification rules are modified — the persona is a presentation layer only.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
| -------- | ------ | ---------------------- | ------------- |
| Placement of Communication Persona section | Between Teaching Principles and Plan Mode Rules | Before Intent Classification; inside Intent Classification | Teaching Principles define *what* to say pedagogically; Communication Persona defines *how* to say it. Placing it after Teaching and before Plan Mode keeps behavioral layers contiguous without interleaving with classification logic. |
| Session banner rewrite strategy | In-place replacement of the existing blockquote | Separate "friendly banner" alongside original | A single banner avoids duplication; the spec constraint says the intent signal must be preserved, not the banner format. One warm banner replaces the mechanical one. |
| Forbidden phrases mechanism | Explicit deny-list with suggested replacements | Regex-based substitution rules; post-processing filter | A human-readable deny-list is simpler, auditable, and consistent with CLAUDE.md's declarative style. No runtime transformation needed — Claude reads the list as behavioral instruction. |
| Adaptive formality rule | Mirror-register heuristic (casual input → casual output; formal → formal) | Fixed formal tone; fixed casual tone | Matching the user's register feels natural without prescribing a single voice. Simple to state; Claude already has this capability implicitly — the rule makes it explicit. |
| Response template format | Prose examples per intent class (not tables) | Structured table with columns | The proposal explicitly requests "natural prose, not table format." Prose examples model the desired voice directly. |

## Data Flow

```
User message
      │
      ▼
Intent Classification (unchanged)
      │
      ▼
Teaching Principles (unchanged — adds why-framing, gates, etc.)
      │
      ▼
Communication Persona (NEW — presentation layer)
      │
      ├── Tone profile applied
      ├── Forbidden phrases filtered
      ├── Adaptive formality matched
      └── Natural template shapes final prose
      │
      ▼
Response to user
```

The Communication Persona section is read by Claude at session start (as part of CLAUDE.md) and applies as a behavioral constraint on all orchestrator-generated prose. It does not intercept or modify the classification pipeline — it shapes the *output text* after routing decisions are made.

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `CLAUDE.md` | Modify | Add `## Communication Persona` section (after Teaching Principles, before Plan Mode Rules); rewrite `### Orchestrator Session Banner` blockquote in natural tone |
| `openspec/specs/orchestrator-behavior/spec.md` | Modify | Add requirement: "Communication persona presentation layer" with scenarios for tone, forbidden phrases, adaptive formality, and banner rewrite |

## Interfaces and Contracts

No new interfaces or DTOs. The Communication Persona is a declarative behavioral section in CLAUDE.md with the following structure:

```markdown
## Communication Persona

### Tone Profile
[warm, direct, confident, pedagogical — defined in prose]

### Response Voice by Intent Class
[prose examples for Change Request, Exploration, Question, Ambiguous]

### Forbidden Mechanical Phrases
[deny-list table: Forbidden → Use Instead]

### Adaptive Formality
[mirror-register rule in 2-3 sentences]
```

## Testing Strategy

| Layer | What to test | Tool |
| ----- | ------------ | ---- |
| Manual | Read CLAUDE.md and verify Communication Persona section exists with all 4 subsections | human review |
| Manual | Verify session banner is rewritten in natural tone and preserves intent class descriptions | human review |
| Manual | Verify forbidden phrases list includes all items from proposal (Rule 7, routing, pre-flight) | human review |
| Structural | `/project-audit` passes — CLAUDE.md section headings and line count thresholds | /project-audit |

## Migration Plan

No data migration required. The change is purely additive Markdown content in CLAUDE.md and spec.md.

## Open Questions

None. The proposal constraints are clear: preserve the intent classification signal, preserve the Classification Decision Table, and ensure communication changes do not affect routing logic.
