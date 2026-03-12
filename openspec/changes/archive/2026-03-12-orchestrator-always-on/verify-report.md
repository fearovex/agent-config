# Verification Report: 2026-03-12-orchestrator-always-on

Date: 2026-03-12
Verifier: sdd-verify

## Summary

| Dimension            | Status         |
| -------------------- | -------------- |
| Completeness (Tasks) | ⚠️ WARNING     |
| Correctness (Specs)  | ✅ OK          |
| Coherence (Design)   | ✅ OK          |
| Testing              | ⚠️ WARNING     |
| Test Execution       | ⏭️ SKIPPED     |
| Build / Type Check   | ℹ️ INFO        |
| Coverage             | ⏭️ SKIPPED     |
| Spec Compliance      | ✅ OK          |

## Verdict: PASS WITH WARNINGS

---

## Detail: Completeness

### Completeness

| Metric               | Value |
| -------------------- | ----- |
| Total tasks          | 10    |
| Completed tasks [x]  | 9     |
| Incomplete tasks [ ] | 1     |

Incomplete tasks:

- [ ] 5.1 Run `/project-audit` to verify no new audit findings are introduced and score is >= previous baseline

**Severity**: WARNING — this is a validation/integration task, not core logic.

---

## Detail: Correctness

### Correctness (Specs)

| Requirement | Status | Notes |
| ----------- | ------ | ----- |
| Intent classification before every response | ✅ Implemented | `## Always-On Orchestrator — Intent Classification` section present in CLAUDE.md at line 12 |
| Four intent classes with clear routing rules | ✅ Implemented | All four classes (Meta-Command, Change Request, Exploration, Question) defined with trigger patterns and routing actions |
| Orchestrator never writes implementation code inline | ✅ Implemented | Unbreakable Rules section in the Always-On block explicitly states "I NEVER write implementation code, specs, or designs inline" |
| CLAUDE.md documents the Always-On Orchestrator behavior | ✅ Implemented | Dedicated section with heading, table, decision tree, and examples; positioned after `## Identity and Purpose` |
| Project-level CLAUDE.md can override intent classification | ✅ Implemented | `### Project-Level Override` subsection documents both `disabled` and `enabled_classes` mechanisms |

### Scenario Coverage

| Scenario | Status |
| -------- | ------ |
| Change request triggers SDD recommendation | ✅ Covered — routing table maps Change Request → "Recommend `/sdd-ff <inferred-slug>`"; Unbreakable Rule 1 prohibits inline code; decision table includes 3 positive examples and 2 negative cases |
| Exploration request routes to sdd-explore | ✅ Covered — routing table maps Exploration → "Auto-launch `sdd-explore` via Task tool"; decision table includes 3 positive examples and 1 negative case |
| Direct question is answered inline | ✅ Covered — routing table maps Question → "Answer directly — no SDD routing"; Unbreakable Rule 4 reinforces this |
| Slash command is executed normally | ✅ Covered — Meta-Command class defined as first priority in routing table; decision table opens with IF message starts with / |
| Change Request classification with keyword list | ✅ Covered — trigger keywords listed: fix, add, implement, create, build, update, refactor, remove, delete, migrate, deploy |
| Exploration classification with keyword list | ✅ Covered — trigger keywords: review, analyze, explore, examine, audit, investigate, "show me", "walk me through", "explain how it works" |
| Question classification | ✅ Covered — trigger patterns: "what is", "how does", "why does", "explain", "describe", ends with ? |
| Meta-Command classification (slash command) | ✅ Covered — trigger: starts with / |
| Change request results in SDD delegation, not inline code | ✅ Covered — Unbreakable Rule 1 + Unbreakable Rule 2 explicitly state no inline code and no auto-launch |
| Sub-agent writes the code, not the orchestrator | ✅ Covered — existing Delegation Pattern section retained; Step 0 reference added to `## How I Execute Commands` |
| Ambiguous request triggers clarification | ✅ Covered — Default (ambiguous) row in routing table: "Classify as Question and append: 'If you'd like me to implement this...'" |
| Section exists and is findable | ✅ Covered — heading `## Always-On Orchestrator — Intent Classification` present; positioned at line 12, immediately after Identity section |
| CLAUDE.md updated in global and project files | ⚠️ Partial — CLAUDE.md in repo is updated; `install.sh` deployment step (task 5.1 equivalent) not confirmed via tool execution |
| Project disables always-on classification | ✅ Covered — `intent_classification: disabled` override documented with example |
| Project restricts classification to specific classes | ✅ Covered — `enabled_classes: [Meta-Command, Change Request]` override documented with example |

---

## Detail: Coherence

### Coherence (Design)

| Decision | Followed? | Notes |
| -------- | --------- | ----- |
| Inline rules in CLAUDE.md (no separate skill) | ✅ Yes | No new skill created; classification logic is entirely within CLAUDE.md |
| Placement after `## Identity and Purpose`, before `## Tech Stack` | ✅ Yes | `## Always-On Orchestrator — Intent Classification` is at line 12; `## Tech Stack` begins at line 89 |
| 4-category decision table (SLASH_CMD, CHANGE_REQUEST, EXPLORE_REQUEST, QUESTION) | ✅ Yes | All four categories present in routing table and decision code block |
| Change requests → recommend (not auto-launch) | ✅ Yes | Unbreakable Rule 2: "I NEVER auto-launch `/sdd-ff` or `/sdd-new` without user confirmation" |
| Exploration → auto-launch sdd-explore via Task tool | ✅ Yes | Routing table and Unbreakable Rule 3 confirm auto-launch behavior |
| Questions → answer directly | ✅ Yes | Routing table and Unbreakable Rule 4 confirm direct answer |
| Ambiguous → default to Question + SDD hint | ✅ Yes | Default row in routing table matches design recommendation |
| Step 0 reference in `## How I Execute Commands` | ✅ Yes | Line 237: "> **Step 0 — Intent Classification**: Before executing any command..." |
| ADR-029 created with Nygard format | ✅ Yes | ADR contains Status, Context, Decision, Consequences sections |
| ADR-029 indexed in docs/adr/README.md | ✅ Yes | Row [029] present in ADR Index table with status Accepted and date 2026-03-12 |

---

## Detail: Testing

### Testing

| Area | Tests Exist | Notes |
| ---- | ----------- | ----- |
| Intent classification rules | ❌ No automated tests | Design explicitly states: "No automated test infrastructure exists for CLAUDE.md behavioral rules — validation is manual" |
| CLAUDE.md section structure | ✅ Manual inspection | Section present with all required sub-sections confirmed by code inspection |
| ADR format compliance | ✅ Manual inspection | Nygard sections (Status, Context, Decision, Consequences) all present in ADR-029 |

**Severity**: WARNING — the absence of automated tests is expected and by design for this project type; however it means behavioral correctness relies entirely on manual session testing, which has not been documented as completed.

---

## Tool Execution

| Command | Exit Code | Result |
|---------|-----------|--------|
| — | — | Test Execution: SKIPPED — no test runner detected |

No `package.json`, `pyproject.toml`, `Makefile`, `build.gradle`, or `mix.exs` found in project root. No `verify_commands` configured in `openspec/config.yaml`.

---

## Detail: Test Execution

| Metric        | Value                  |
| ------------- | ---------------------- |
| Runner        | none detected          |
| Command       | N/A                    |
| Exit code     | N/A                    |
| Tests passed  | N/A                    |
| Tests failed  | N/A                    |
| Tests skipped | N/A                    |

No test runner detected. Skipped.

---

## Detail: Build / Type Check

| Metric    | Value                                      |
| --------- | ------------------------------------------ |
| Command   | N/A                                        |
| Exit code | N/A                                        |
| Errors    | N/A                                        |

No build command detected. Skipped. (INFO — project is Markdown/YAML/Bash; no compilation step exists.)

---

## Spec Compliance Matrix

| Spec Domain | Requirement | Scenario | Status | Evidence |
| ----------- | ----------- | -------- | ------ | -------- |
| orchestrator-behavior | Intent classification before every response | Change request triggers SDD recommendation | COMPLIANT | CLAUDE.md line 21: routing table entry for Change Request; Unbreakable Rule 1 prohibits inline code; decision table includes positive/negative examples |
| orchestrator-behavior | Intent classification before every response | Exploration request routes to sdd-explore | COMPLIANT | CLAUDE.md line 22: routing table entry for Exploration; Unbreakable Rule 3 confirms auto-launch behavior |
| orchestrator-behavior | Intent classification before every response | Direct question is answered inline | COMPLIANT | CLAUDE.md line 23: routing table entry for Question; Unbreakable Rule 4 confirms direct answer |
| orchestrator-behavior | Intent classification before every response | Slash command is executed normally | COMPLIANT | CLAUDE.md line 20: Meta-Command is first row in routing table; decision table opens with slash-command check |
| orchestrator-behavior | Four intent classes with clear routing rules | Change Request classification | COMPLIANT | Routing table row present; keywords listed; positive and negative examples in decision table |
| orchestrator-behavior | Four intent classes with clear routing rules | Exploration classification | COMPLIANT | Routing table row present; keywords listed; positive and negative examples in decision table |
| orchestrator-behavior | Four intent classes with clear routing rules | Question classification | COMPLIANT | Routing table row present; trigger patterns listed; examples in decision table |
| orchestrator-behavior | Four intent classes with clear routing rules | Meta-Command classification | COMPLIANT | Routing table row present; trigger is `/` prefix; slash commands bypass classification confirmed |
| orchestrator-behavior | Orchestrator never writes implementation code inline | Change request results in SDD delegation, not inline code | COMPLIANT | Unbreakable Rule 1 + Rule 2 state this explicitly; design confirmed no inline code path |
| orchestrator-behavior | Orchestrator never writes implementation code inline | Sub-agent writes the code, not the orchestrator | COMPLIANT | Existing Delegation Pattern retained in full; Step 0 added without altering sub-agent pattern |
| orchestrator-behavior | Orchestrator never writes implementation code inline | Edge case — clarification for ambiguous intent | COMPLIANT | Default row in routing table: classify as Question + append SDD hint |
| orchestrator-behavior | CLAUDE.md documents the Always-On Orchestrator behavior | Section exists and is findable | COMPLIANT | Heading `## Always-On Orchestrator — Intent Classification` at line 12; all four intent classes present with routing actions and "never inline code" rule |
| orchestrator-behavior | CLAUDE.md documents the Always-On Orchestrator behavior | CLAUDE.md updated in global and project files | PARTIAL | Repo CLAUDE.md confirmed updated; `install.sh` deployment not confirmed via tool execution (task 5.1 pending) |
| orchestrator-behavior | Project-level CLAUDE.md can override intent classification | Project disables always-on classification | COMPLIANT | `### Project-Level Override` subsection documents `intent_classification: disabled` with example snippet |
| orchestrator-behavior | Project-level CLAUDE.md can override intent classification | Project restricts classification to specific intent classes | COMPLIANT | `### Project-Level Override` subsection documents `enabled_classes` array with example |

**Matrix totals**: 15 scenarios — 14 COMPLIANT, 1 PARTIAL, 0 FAILING, 0 UNTESTED.

---

## Issues Found

### CRITICAL (must be resolved before archiving):

None.

### WARNINGS (should be resolved):

- **Task 5.1 not executed**: `/project-audit` was not run to confirm the audit score is >= the previous baseline. This is the project's primary integration test gate. Manual confirmation required — no tool output available.
- **install.sh deployment not confirmed**: The CLAUDE.md update has not been confirmed as deployed to `~/.claude/CLAUDE.md` via `install.sh`. This means the always-on behavior is not yet live in the runtime environment.
- **No automated behavioral tests**: Intent classification correctness relies entirely on manual session testing. No evidence of manual session testing has been provided (no test log or session transcript recorded as an artifact).

### SUGGESTIONS (optional improvements):

- Consider adding a `verify_commands` entry to `openspec/config.yaml` that runs a lightweight linting or structure check (e.g., confirming the Always-On Orchestrator section heading is present in CLAUDE.md) so future verifications can confirm structural integrity automatically.
- The ADR-029 `Alternatives` section described in tasks.md (Reactive post-response check, guided hybrid, ML-based classification) is not present in the created ADR — the ADR only has Context, Decision, and Consequences sections. Adding an Alternatives section would make the ADR more complete per Nygard extended format, though not required by the project's ADR template.
