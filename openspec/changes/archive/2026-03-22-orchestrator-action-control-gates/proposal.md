# Proposal: Orchestrator Action Control Gates

## Problem Statement

The orchestrator's control mechanisms are declarative but not enforced:

1. **No active-change detection**: recommends `/sdd-ff` without checking if a change is already in flight in `openspec/changes/`
2. **No spec drift check on Change Requests**: Step 8 (Spec-first Q&A) only applies to Questions — a Change Request that contradicts a spec reaches sdd-propose silently
3. **No scope-aware conflict warning**: starting a new cycle while one is incomplete is allowed without warning

## Proposed Solution

Add a **Pre-flight Check** step that runs before routing any Change Request:

### Pre-flight Check Sequence

1. **Active change scan**: list `openspec/changes/*/` (excluding `archive/`). If a change with semantic overlap exists (slug keyword overlap on substantive tokens — length > 3, skip stop words) → emit advisory: "You have `<change-name>` in progress. Do you want to continue that cycle or start a new one?"

2. **Spec drift advisory**: keyword-match the change description against `openspec/specs/index.yaml` domain names and keywords. If a matching domain is found → surface advisory: "Your change touches the `<domain>` domain — check the spec before proposing." **No spec file is read at this stage** — keyword match only. If `index.yaml` is absent or no domain matches, skip silently (graceful degradation).

Both checks are **advisory only** (non-blocking) — the user can proceed regardless.

### index.yaml Availability

`index.yaml` grows organically via existing tooling:
- `/project-setup` — creates it on initialization
- `sdd-spec` — creates it if absent when writing the first domain spec

**Runtime behavior**: if `index.yaml` is missing, the spec drift advisory is silently skipped. No error, no block. This matches the existing Step 8 graceful degradation pattern.

### Feedback Session (Rule 5)

Feedback session detection remains **user-initiated** (explicit declaration). Rule 5 enforcement is reinforced as a documented blocking gate in CLAUDE.md — not an auto-detection heuristic (too fragile, high false-positive risk).

## Success Criteria

- [ ] Pre-flight check section added to CLAUDE.md
- [ ] Active change scan defined with advisory prompt template
- [ ] Spec drift advisory defined with graceful degradation when index.yaml is absent
- [ ] Rule 5 enforcement documented as a blocking gate (user-initiated, not heuristic)
- [ ] `sdd-spec` creates `index.yaml` if absent when writing the first domain spec

## Files and Artifacts to Target

- `CLAUDE.md` — Pre-flight Check section, Rule 5 enforcement gate update
- `openspec/specs/orchestrator-behavior/spec.md` — new REQ entries for pre-flight gates
- `skills/sdd-spec/SKILL.md` — ensure index.yaml is created if absent

## Constraints

- Pre-flight checks must be fast — directory listing + keyword matching only, no spec file reads
- Active change scan must NOT block if the in-flight change has a different semantic slug
- Spec drift advisory is non-blocking — user can always proceed
- `index.yaml` absence must degrade gracefully (skip, not error)
- Feedback session heuristic is out of scope for this cycle

## Dependencies

- `2026-03-22-orchestrator-natural-language` (Cycle 3) must be applied first — CLAUDE.md must reflect the natural-language tone update before the Pre-flight Check section is inserted
- `openspec/specs/orchestrator-behavior/spec.md` must be present (it is)
- `openspec/specs/index.yaml` is NOT a hard dependency — spec drift advisory degrades gracefully when absent

## Rollback Plan

1. Revert `CLAUDE.md` to the pre-change commit (remove the Pre-flight Check section)
2. Revert `openspec/specs/orchestrator-behavior/spec.md` to remove added REQ entries
3. Revert `skills/sdd-spec/SKILL.md` if index.yaml creation was modified
4. Run `install.sh` to redeploy reverted files to `~/.claude/`
5. Verify: submit a Change Request — confirm no pre-flight advisory appears

No data migration or schema changes involved — revert is a clean file restore.

## Execution Order

**Cycle 4 of 5** — run after natural language (Cycle 3). Most complex and highest risk.
