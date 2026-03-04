# Technical Design: feature-domain-knowledge-layer

Date: 2026-03-03
Proposal: openspec/changes/feature-domain-knowledge-layer/proposal.md

---

## General Approach

Extend the `ai-context/` memory layer with a `features/` subdirectory where each file is a
bounded-context knowledge document (`<domain>.md`). A canonical template (`_template.md`) defines
the six required sections. The new `feature-domain-expert` skill (format: `reference`) teaches
authoring and consumption. Four existing skills (`sdd-propose`, `sdd-spec`, `memory-init`,
`memory-update`) each gain one optional, non-blocking step that reads or writes to this new layer.
No existing behavior is removed; the feature layer is always opt-in.

---

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|---------------|
| Storage location for domain knowledge files | `ai-context/features/<domain>.md` | `openspec/specs/<domain>/spec.md` enrichment (Approach C); per-feature SKILL.md files (Approach B) | Extends the existing `ai-context/` memory pattern — lowest friction, natural integration with `memory-init` and `memory-update`. Avoids conflating observable behavior (spec format) with business context (feature doc). Approach B was deferred to V2 as explicitly scoped out in the proposal. |
| Domain matching heuristic (how a change maps to a feature file) | Filename-stem match: split change slug on hyphens and check whether any stem appears in the filename of an existing `ai-context/features/<domain>.md` | Explicit `domains:` frontmatter in `proposal.md`; full NLP extraction from proposal body | Simple, zero-config, convention-based matching that works immediately without requiring authors to annotate proposals. Miss rate is acceptable because preload is non-blocking — phases proceed normally when no match is found. Explicit `domains:` frontmatter is deferred to V2 when the heuristic proves insufficient in practice. |
| Placement tier for `feature-domain-expert` skill | Global (`skills/feature-domain-expert/SKILL.md` in `claude-config`, deployed to `~/.claude/skills/`) | Project-local placement in `.claude/skills/` | The skill is a meta-system authoring guide, not a project-specific skill. It belongs in the global catalog alongside other meta-tool skills (memory-init, memory-update, project-audit). Per ADR 008, project-local placement is the default for project-added skills; global placement is the explicit choice for system-level skills. |
| New template vs. reusing reference format for feature docs | New `ai-context/features/_template.md` with six fixed sections; no new SKILL.md format type | Adding a 4th `format:` value (`domain-knowledge`) to the format type system | Introducing a new `format:` value would require updates to `project-audit` D4b/D9-3 validators, `project-fix`, `skill-creator`, and `docs/format-types.md`. The template file approach achieves the same structural guidance without modifying the format type system. V2 can introduce a format type if structured audit enforcement is needed. |
| Ownership of writes to `ai-context/features/` | `memory-update` writes (session-acquired domain knowledge); `memory-init` scaffolds stubs (first-time only); `project-analyze` does NOT touch `features/` | `project-analyze` updating feature files alongside `[auto-updated]` sections | Clear single-writer ownership prevents conflict between the two update mechanisms. `project-analyze` is an observer skill — it describes what it sees. Feature files require domain expert judgment to author; they should not be auto-overwritten by a structural scan. Documented in `architecture.md` communication table. |
| architecture — introduction of a new cross-cutting memory sub-layer | `ai-context/features/` as a named subdirectory of the existing memory layer | Adding feature metadata to `ai-context/architecture.md` directly | Separation of concerns: system-level architectural decisions stay in `architecture.md`; feature-specific business context goes in `features/<domain>.md`. Avoids `architecture.md` growing into an unstructured dump as feature count grows. This is a cross-cutting system-wide convention that warrants an ADR. |

---

## Data Flow

### Domain context preload in `sdd-propose` (new Step 0)

```
/sdd-propose <change-name>
        │
        ▼
  Step 0: Domain context preload (NEW, non-blocking)
        │
        ├── List files in ai-context/features/  ←── exists?
        │         No → skip silently (no features/ dir)
        │         Yes ↓
        ├── Extract stems from <change-name> (split on "-")
        ├── Match stems against feature filenames
        │         No match → skip silently
        │         Match → read ai-context/features/<domain>.md
        │                 inject content as enrichment context
        ▼
  Step 1: Read prior context (existing)
        │   exploration.md, openspec/config.yaml, ai-context/architecture.md
        ▼
  Steps 2–5: (unchanged)
```

### Domain context preload in `sdd-spec` (new Step 0)

```
/sdd-spec <change-name>
        │
        ▼
  Step 0: Domain context preload (NEW, non-blocking)
        │   (same matching logic as sdd-propose Step 0)
        │   Match → read ai-context/features/<domain>.md as enrichment
        ▼
  Step 1: Read prior artifacts (existing)
        │   proposal.md, openspec/specs/<domain>/spec.md, ai-context/architecture.md
        ▼
  Steps 2–4: (unchanged)
```

### Feature stub generation in `memory-init` (new Step 6, at end)

```
memory-init (after Steps 1–6 complete)
        │
        ▼
  Step 7: Feature discovery (NEW, non-blocking)
        │
        ├── Check: does ai-context/features/ already exist?
        │         Yes → skip entirely (avoid overwriting existing domain knowledge)
        │         No  ↓
        ├── Scan for bounded contexts:
        │     Priority 1: openspec/specs/ directories
        │     Priority 2: src/ or app/ top-level subdirectories (if any)
        │     Priority 3: skip if no signals found
        ├── For each detected context, copy _template.md → features/<domain>.md
        │   (fill only Domain Overview "stub" marker; all other sections are empty)
        ▼
  Report: "Generated N feature stubs in ai-context/features/ — fill in with domain knowledge"
```

### Feature file update in `memory-update` (new Step 3b, between Steps 3 and 4)

```
memory-update
        │
  Step 3: Update stack.md if applicable (existing)
        │
        ▼
  Step 3b: Update feature files (NEW, non-blocking)
        │
        ├── Were domains with existing ai-context/features/<domain>.md files
        │   involved in this session?
        │         No → skip silently
        │         Yes ↓
        ├── For each relevant domain file:
        │     - Add new Business Rules / Invariants discovered
        │     - Update Known Gotchas if failure modes were surfaced
        │     - Append Decision Log entry for session-made domain decisions
        │     - Leave sections unchanged if nothing session-relevant applies
        ▼
  Step 4: Update architecture.md if applicable (existing)
```

### Artifact communication (new entry in architecture.md table)

```
Producer           → Artifact                              → Consumer
────────────────────────────────────────────────────────────────────────
memory-init        → ai-context/features/<domain>.md       → sdd-propose (Step 0)
memory-update      → ai-context/features/<domain>.md       → sdd-spec (Step 0)
(human authors)    → ai-context/features/<domain>.md       → sdd-propose, sdd-spec
_template.md       → (copy) → features/<domain>.md         → human authors
```

---

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `ai-context/features/_template.md` | Create | Canonical template with 6 sections: Domain Overview, Business Rules and Invariants, Data Model Summary, Integration Points, Decision Log, Known Gotchas |
| `ai-context/features/sdd-meta-system.md` | Create | Worked example feature file for the SDD meta-system domain (demonstrates template in use) |
| `skills/feature-domain-expert/SKILL.md` | Create | New reference-format skill: authoring guide + usage reference for feature domain knowledge files |
| `skills/sdd-propose/SKILL.md` | Modify | Add Step 0 — Domain context preload (non-blocking, before existing Step 1) |
| `skills/sdd-spec/SKILL.md` | Modify | Add Step 0 — Domain context preload (non-blocking, before existing Step 1) |
| `skills/memory-init/SKILL.md` | Modify | Add Step 7 — Feature discovery (non-blocking, after existing Step 6) |
| `skills/memory-update/SKILL.md` | Modify | Add Step 3b — Feature file update path (non-blocking, between existing Steps 3 and 4) |
| `CLAUDE.md` | Modify | Add `ai-context/features/*.md` row to the memory layer table |
| `ai-context/architecture.md` | Modify | Add artifact entry for `ai-context/features/<domain>.md` to communication table; add key architectural decision entry for the new layer; update structure listing to include `features/` |

---

## Interfaces and Contracts

### Feature file canonical sections (enforced by `_template.md`)

```markdown
# Feature: <Domain Name>

> One-line description of this bounded context.

Last updated: YYYY-MM-DD
Related specs: openspec/specs/<domain>/spec.md  ← optional link

---

## Domain Overview
[2-4 sentences: what this feature/bounded context does, who owns it, its core responsibility]

---

## Business Rules and Invariants
- [Rule 1: always-true constraint — e.g. "A payment cannot be refunded more than its original amount"]
- [Rule 2: ...]

---

## Data Model Summary
[Key entities, their relationships, and critical field constraints in plain prose or a small table]

| Entity | Key Fields | Constraints |
|--------|-----------|-------------|
| [name] | [fields]  | [invariants] |

---

## Integration Points
| System/Service | Direction | Contract |
|----------------|-----------|----------|
| [name]         | inbound/outbound | [what is expected] |

---

## Decision Log
### [YYYY-MM-DD] — [Decision name]
**Decision**: [what was decided]
**Rationale**: [why]
**Impact**: [what changed or was constrained]

---

## Known Gotchas
- [Gotcha 1: non-obvious behavior, known edge case, or historical failure mode]
- [Gotcha 2: ...]
```

### Domain name matching algorithm (used in `sdd-propose` Step 0 and `sdd-spec` Step 0)

```
Input:  change-name (kebab-case string)
Output: path to matching ai-context/features/<domain>.md OR null

Algorithm:
  1. List all files in ai-context/features/ (if directory absent → return null)
  2. Extract stems: split change-name on "-", discard single-char stems
  3. For each file f in features/:
       domain = filename stem of f (without .md)
       if domain appears in change-name OR any change-name stem appears in domain:
         return f
  4. If no match: return null (preload skipped silently)

Examples:
  change: "add-payments-gateway"    → stems: [add, payments, gateway]
                                      matches: features/payments.md ✓
  change: "auth-token-refresh"      → stems: [auth, token, refresh]
                                      matches: features/auth.md ✓
  change: "improve-project-audit"   → stems: [improve, project, audit]
                                      matches: features/sdd-meta-system.md? No.
                                      (no domain match → skipped) ✓
  change: "feature-domain-knowledge-layer" → stems: [feature, domain, knowledge, layer]
                                      matches: features/sdd-meta-system.md? No.
                                      (no match → skipped) ✓
```

---

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Template structure | `_template.md` contains all 6 required section headings | Manual review + `/project-audit` D10 (V2) |
| Skill format compliance | `feature-domain-expert/SKILL.md` passes D4b and D9-3 (`format: reference`, has `**Triggers**`, `## Patterns` or `## Examples`, `## Rules`) | `/project-audit` |
| Step 0 integration | `sdd-propose` and `sdd-spec` SKILL.md text includes the domain preload step description | Manual review |
| Feature stub generation | `memory-init` SKILL.md text includes Step 7 feature discovery | Manual review |
| Feature update path | `memory-update` SKILL.md text includes Step 3b feature update | Manual review |
| No regression | `/project-audit` on claude-config after apply yields score >= pre-apply score | `/project-audit` |
| Install | `bash install.sh` runs without error | Manual execution |
| Worked example | `ai-context/features/sdd-meta-system.md` exists with all 6 sections filled | Manual review |

---

## Migration Plan

No data migration required. This change is purely additive:
- No existing files are deleted or renamed.
- No existing skill behavior is removed.
- New `ai-context/features/` directory and files are created fresh.
- Existing `ai-context/` files are updated with new entries, not rewritten.

Deployment sequence after `sdd-apply`:
1. Run `bash install.sh` to deploy updated skills to `~/.claude/`.
2. Run `/project-audit` to confirm no score regression.
3. `git commit` with conventional commit prefix `feat(memory):`.

---

## Open Questions

None — all questions from the exploration were resolved in the proposal:

- Domain matching: filename-stem heuristic (V1). Explicit `domains:` frontmatter deferred to V2.
- Feature file generation: `memory-init` generates stubs; manual authoring is the quality gate. Auto-generation by `project-analyze` is explicitly excluded.
- Template sections: six sections confirmed (Domain Overview, Business Rules and Invariants, Data Model Summary, Integration Points, Decision Log, Known Gotchas).
- `openspec/config.yaml` `feature_docs:` block: remains commented out in V1 (audit integration deferred).
- Feature-expert skills (Approach B / Tier 2): explicitly out of scope for this change.
