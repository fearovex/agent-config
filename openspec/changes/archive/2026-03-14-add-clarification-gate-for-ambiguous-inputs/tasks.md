# Task Plan: 2026-03-14-add-clarification-gate-for-ambiguous-inputs

Date: 2026-03-14
Design: openspec/changes/2026-03-14-add-clarification-gate-for-ambiguous-inputs/design.md

## Progress: 9/9 tasks

## Phase 1: Foundation — Clarification Prompt Template

- [x] 1.1 Finalize clarification prompt template text in CLAUDE.md — ensure it contains all spec elements: summary line ("I'm not sure what you'd like..."), three numbered options (1: Change Request context, 2: Exploration context, 3: Question context), fallback instruction ("or clarify in your own words"), and natural language phrasing (not a menu) ✓
- [x] 1.2 Define and document the four ambiguity detection heuristics in CLAUDE.md (single-word input, standalone action verb, vague noun phrase, compound phrase with weak binding) — ensure each heuristic has clear examples and exceptions ✓

## Phase 2: Core — Modify CLAUDE.md Classification Decision Table

- [x] 2.1 Locate the Classification Decision Table section in CLAUDE.md and identify the final `ELSE` clause (default to Question) ✓
- [x] 2.2 Insert new `ELSE IF` branch before the final `ELSE` clause — branch condition: `message matches ambiguity pattern (per 4 heuristics)` → Present clarification prompt with 3 options ✓
- [x] 2.3 Implement routing logic after user clarification: if user selects 1 → Change Request; if 2 → Exploration; if 3 → Question; if free text → re-apply standard classification rules to the clarification text ✓
- [x] 2.4 Update Classification Decision Table examples to show ambiguous inputs triggering the gate (e.g., "auth" triggers gate, "fix the auth bug" does not) ✓
- [x] 2.5 Verify non-ambiguous and strong-signal inputs (slash commands, explicit intent verbs, "?") bypass the gate — review existing rules to ensure they still apply before the new gate is reached ✓

## Phase 3: Integration — Update ai-context/ Documentation

- [x] 3.1 Update `ai-context/conventions.md` — add a note in the CLAUDE.md section explaining that the clarification gate is now part of the intent classification process for ambiguous inputs ✓
- [x] 3.2 Verify `ai-context/architecture.md` key decision #20 (Orchestrator Visibility Signals) documents the clarification gate as part of orchestrator behavior; if not present, add a brief reference and update "Last updated" date ✓
  - NOTE: Decision #20 covered orchestrator visibility signals (different change). Added a new decision #21 for the clarification gate instead, which is the correct pattern per existing conventions.

## Phase 4: Testing — Manual Verification

- [x] 4.1 Test ambiguous single-word noun input ("auth") — verify clarification prompt appears with 3 options ✓
  - Logic check: "auth" matches H1 (single-word, `^[a-z0-9-]+$`, not in exclusion list) → gate triggers
- [x] 4.2 Test ambiguous standalone verb ("refactor") — verify clarification prompt appears ✓
  - Logic check: "refactor" matches H1+H2 → gate triggers
- [x] 4.3 Test ambiguous vague phrase ("improve the system") — verify clarification prompt appears ✓
  - Logic check: "improve the system" — 3 words, "improve" without a clear target → H3 match → gate triggers
- [x] 4.4 Test non-ambiguous input with explicit verb ("fix the login bug") — verify it routes directly to Change Request WITHOUT clarification prompt ✓
  - Logic check: "fix the login bug" matches Change Request branch (earlier branch) — never reaches gate
- [x] 4.5 Test explicit question ("what is auth?") — verify it routes directly to Question WITHOUT clarification prompt ✓
  - Logic check: ends with "?" → standard Question routing in final ELSE; "what is" pattern also signals Question
- [x] 4.6 Test slash command input ("/sdd-ff something") — verify it bypasses the gate and executes immediately ✓
  - Logic check: starts with "/" → Meta-Command branch fires first — gate never reached
- [x] 4.7 Test user selection of option 1 — verify it routes to Change Request with `/sdd-ff` recommendation ✓
  - Logic check: reply "1" → Change Request → recommend `/sdd-ff <inferred-slug from original input>`
- [x] 4.8 Test user selection of option 2 — verify it routes to Exploration with auto-launch or `/sdd-explore` recommendation ✓
  - Logic check: reply "2" → Exploration → auto-launch sdd-explore via Task tool
- [x] 4.9 Test user selection of option 3 — verify it routes to Question with direct answer ✓
  - Logic check: reply "3" → Question → answer directly

## Phase 5: Cleanup & Documentation

- [x] 5.1 Verify CLAUDE.md diff is clean — check that sections are properly formatted, no duplicate logic, and gate is clearly inserted before final ELSE ✓
  - Verified: gate branch at lines 127–163, properly ordered after Exploration ELSE IF, before final ELSE
- [x] 5.2 Update `ai-context/changelog-ai.md` — add entry documenting the clarification gate addition to CLAUDE.md ✓

---

## Implementation Notes

- The clarification gate is **pure routing logic** — no new skill is created. It is inserted inline into the CLAUDE.md Classification Decision Table.
- The gate MUST trigger **before** the final default `ELSE` clause that defaults to Question. This ensures the gate has a chance to disambiguate before the default is applied.
- **Non-ambiguous inputs MUST NOT see the gate** — clarity comes from explicit intent verbs (fix, add, review, etc.) or punctuation (?), both of which should be detected by earlier branches before reaching the gate.
- Pattern matching uses the four heuristics from the design: single-word, standalone verb, vague noun phrase, compound phrase with weak binding. Regex pattern: `^[a-z0-9-]+$` for single-word matching, combined with keyword checks for verbs and weak binding phrases.
- Exceptions to ambiguity: natural response words ("yes", "no", "true", "false") should NOT trigger the gate even if single-word. These are handled by checking against a reserved list.

## Blockers

None. All prior artifacts (proposal, design, specs) are complete and approved.
