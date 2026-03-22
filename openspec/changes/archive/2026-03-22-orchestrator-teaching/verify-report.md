# Verification Report: 2026-03-21-orchestrator-teaching

Date: 2026-03-22
Verifier: sdd-verify

## Summary

| Dimension            | Status          |
| -------------------- | --------------- |
| Completeness (Tasks) | ✅ OK           |
| Correctness (Specs)  | ⚠️ WARNING      |
| Coherence (Design)   | ✅ OK           |
| Testing              | ⏭️ SKIPPED      |
| Test Execution       | ⏭️ SKIPPED      |
| Build / Type Check   | ⏭️ SKIPPED      |
| Coverage             | ⏭️ SKIPPED      |
| Spec Compliance      | ⚠️ WARNING      |

## Verdict: PASS WITH WARNINGS

---

## Detail: Completeness

| Metric               | Value |
| -------------------- | ----- |
| Total tasks          | 10    |
| Completed tasks [x]  | 10    |
| Incomplete tasks [ ] | 0     |

All 10 tasks across 8 phases are marked complete.

## Detail: Correctness

| Requirement | Status | Notes |
| ----------- | ------ | ----- |
| Teaching Principles section (5 rules, ≤15 lines) | ⚠️ Partial | 5 rules present and correct. However, `### New-User Detection` subsection under `## Teaching Principles` makes the total section exceed 15 lines (24 lines vs 15 limit). The 5 numbered rules alone are 5 lines — compliant if measured narrowly. |
| Why-framing on Change Request | ✅ Implemented | Line 98 of CLAUDE.md adds `— [1 sentence explaining what risk the SDD cycle prevents for this specific change]` to the Change Request routing action. |
| Teaching Principles does not alter classification | ✅ Implemented | No classification keywords, routing table entries, or ambiguity heuristics were modified. All changes are additive annotation. |
| Rule 7 educational gate | ✅ Implemented | Line 317 adds consequence sentence: "Confirming removal intent upfront prevents the SDD cycle from preserving behavior you want deleted." |
| Contradiction gate educational framing | ✅ Implemented | Line 189 of sdd-ff/SKILL.md adds: "Resolving contradictions now prevents the spec and design from making conflicting assumptions that would surface later during implementation." |
| Error reformulation in sdd-ff | ✅ Implemented | Lines 356-366 of sdd-ff/SKILL.md define the `### Error Reformulation` section with the template pattern. Applied to Steps 0, 1, 2, 3. Statuses ok/warning unaffected. |
| Post-cycle narrative in sdd-ff Step 4 | ✅ Implemented | Lines 394-395 of sdd-ff/SKILL.md add 1-paragraph narrative template after artifact list, before "Ready to implement?" prompt. Conditional on all phases completing successfully. |
| New-user detection | ✅ Implemented | Lines 337-353 of CLAUDE.md define `### New-User Detection` using `openspec/changes/archive/` directory listing (matches design decision). Once-per-session, not on Questions. |
| Master spec updated | ✅ Implemented | `openspec/specs/orchestrator-behavior/spec.md` contains all delta spec requirements with `(Added in: 2026-03-21 by change "2026-03-21-orchestrator-teaching")` annotations. Master spec correctly uses `archive/` (not `changelog-ai.md`). |
| architecture.md entry | ✅ Implemented | Decision #26 added for teaching principles layer. |
| changelog-ai.md entry | ✅ Implemented | Entry dated 2026-03-22 documenting all changes made. |

### Scenario Coverage

| Scenario | Status |
| -------- | ------ |
| Teaching Principles section exists and is complete | ⚠️ Partial — 5 rules present but total section exceeds 15-line limit due to New-User Detection subsection |
| Teaching Principles does not alter classification | ✅ Covered |
| Change Request response includes why-framing | ✅ Covered |
| Why-framing is specific, not generic | ✅ Covered (template requires domain-specific sentence) |
| Why-framing absent on Questions/Explorations | ✅ Covered (only in Change Request routing action) |
| Rule 7 removal confirmation educational framing | ✅ Covered |
| Contradiction gate educational framing | ✅ Covered |
| Sub-agent blocked status reformulation | ✅ Covered |
| Sub-agent failed status reformulation | ✅ Covered |
| Sub-agent ok/warning — no reformulation | ✅ Covered |
| Post-cycle narrative after artifact list | ✅ Covered |
| Post-cycle narrative references specific domain | ✅ Covered |
| Post-cycle narrative absent when cycle incomplete | ✅ Covered |
| New project (0 archived) — context note appears | ✅ Covered |
| Established project (1+ archived) — no note | ✅ Covered |
| Missing archive dir — treat as new user | ✅ Covered |
| Context note absent on Questions | ✅ Covered |
| Why-framing sentence limit (1 sentence) | ✅ Covered |
| Post-cycle narrative paragraph limit (1 paragraph) | ✅ Covered |
| New-user note limit (≤3 sentences) | ✅ Covered |
| Educational gate additions (1 sentence appended) | ✅ Covered |

## Detail: Coherence

| Decision | Followed? | Notes |
| -------- | --------- | ----- |
| Teaching Principles between Unbreakable Rules and Plan Mode Rules | ✅ Yes | Section at line 329, after Unbreakable Rules (ending ~327), before Plan Mode Rules (line 357) |
| New-user detection via `openspec/changes/archive/` directory | ✅ Yes | Implementation matches design decision; design explicitly rejected `changelog-ai.md` |
| Error reformulation scope: sdd-ff only | ✅ Yes | Only `skills/sdd-ff/SKILL.md` modified for error reformulation |
| Why-framing in Classification Decision Table | ✅ Yes | Added to Change Request routing action in the table |
| Post-cycle narrative in Step 4 (not new Step 5) | ✅ Yes | Added within Step 4 summary template |

## Detail: Testing

| Area | Tests Exist | Scenarios Covered |
| ---- | ----------- | ----------------- |
| All changes | N/A | Manual validation only — markdown/YAML config project |

No automated tests exist for this project (markdown + YAML meta-system). Testing strategy is "audit-as-integration-test" per config.yaml.

## Tool Execution

Test Execution: SKIPPED — no test runner detected (project is markdown + YAML configuration, testing strategy is manual via /project-audit)

## Detail: Test Execution

| Metric        | Value          |
| ------------- | -------------- |
| Runner        | none detected  |
| Command       | N/A            |
| Exit code     | N/A            |
| Tests passed  | N/A            |
| Tests failed  | N/A            |
| Tests skipped | N/A            |

No test runner detected. Skipped.

## Detail: Build / Type Check

| Metric    | Value          |
| --------- | -------------- |
| Command   | N/A            |
| Exit code | N/A            |
| Errors    | none           |

No build command detected. Skipped.

## Spec Compliance Matrix

| Spec Domain | Requirement | Scenario | Status | Evidence |
| ----------- | ----------- | -------- | ------ | ------- |
| orchestrator-behavior | Teaching Principles section (5 rules, ≤15 lines) | Section exists and is complete | PARTIAL | 5 rules present at lines 331-335; total section is 24 lines including New-User Detection subsection (exceeds 15-line limit if measured as full section) |
| orchestrator-behavior | Teaching Principles section | Does not alter classification | COMPLIANT | No routing/classification logic modified — code inspection confirms additive-only changes |
| orchestrator-behavior | Why-framing on Change Request | Response includes why-framing | COMPLIANT | Line 98 CLAUDE.md includes why-sentence template in routing action |
| orchestrator-behavior | Why-framing on Change Request | Specific to change, not generic | COMPLIANT | Template requires domain-specific risk sentence |
| orchestrator-behavior | Why-framing on Change Request | Absent on Questions/Explorations | COMPLIANT | Only added to Change Request routing — not present in other intent classes |
| orchestrator-behavior | Educational gates | Rule 7 removal confirmation | COMPLIANT | Line 317 CLAUDE.md includes consequence sentence |
| orchestrator-behavior | Educational gates | Contradiction gate | COMPLIANT | Line 189 sdd-ff/SKILL.md includes consequence sentence |
| orchestrator-behavior | Error reformulation in sdd-ff | Blocked status | COMPLIANT | Lines 356-366 sdd-ff/SKILL.md define reformulation template |
| orchestrator-behavior | Error reformulation in sdd-ff | Failed status | COMPLIANT | Same template covers failed status |
| orchestrator-behavior | Error reformulation in sdd-ff | ok/warning — no reformulation | COMPLIANT | Line 366 explicitly excludes ok/warning |
| orchestrator-behavior | Post-cycle narrative | After artifact list | COMPLIANT | Lines 394-395 sdd-ff/SKILL.md in Step 4 template |
| orchestrator-behavior | Post-cycle narrative | References specific change | COMPLIANT | Template says "reference the specific change domain" |
| orchestrator-behavior | Post-cycle narrative | Absent when incomplete | COMPLIANT | Template says "only when all phases completed successfully, not when halted" |
| orchestrator-behavior | New-user detection | 0 archived changes — note appears | COMPLIANT | Lines 342-348 CLAUDE.md |
| orchestrator-behavior | New-user detection | 1+ archived — no note | COMPLIANT | Lines 351-352 CLAUDE.md |
| orchestrator-behavior | New-user detection | Missing archive dir — treat as new | COMPLIANT | Line 342 "does not exist OR contains 0 subdirectories" |
| orchestrator-behavior | New-user detection | No note on Questions | COMPLIANT | Line 349 "does NOT appear on Questions" |
| orchestrator-behavior | Conciseness constraints | Why-framing 1 sentence | COMPLIANT | Template specifies "1 sentence" |
| orchestrator-behavior | Conciseness constraints | Narrative 1 paragraph | COMPLIANT | Template specifies "1-paragraph" |
| orchestrator-behavior | Conciseness constraints | New-user note ≤3 sentences | COMPLIANT | Note is 3 sentences |
| orchestrator-behavior | Conciseness constraints | Gate additions 1 sentence | COMPLIANT | Both gates add exactly 1 sentence |

---

## Issues Found

### CRITICAL (must be resolved before archiving):

None.

### WARNINGS (should be resolved):

- **Teaching Principles section line count**: The delta spec and task 1.1 require the Teaching Principles section to not exceed 15 lines (excluding heading). The 5 numbered rules are only 5 lines, but the `### New-User Detection` subsection (task 6.1) was placed inside the same `## Teaching Principles` section, bringing the total to ~24 lines. This is a spec compliance question: if "section" means just the 5 rules, it passes; if it means everything under `## Teaching Principles` before the next `##` heading, it exceeds the limit. Consider moving `### New-User Detection` to its own `##` section or adjusting the spec limit.

- **Delta spec vs implementation discrepancy (non-blocking)**: The delta spec for new-user detection references `ai-context/changelog-ai.md` as the detection source, but the design document and actual implementation correctly use `openspec/changes/archive/`. The master spec was correctly merged using the design's `archive/` approach. The delta spec artifact retains the stale wording — this is cosmetic since delta specs are superseded by the master spec after merge.

### SUGGESTIONS (optional improvements):

None.
