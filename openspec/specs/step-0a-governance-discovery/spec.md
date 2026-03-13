# Delta Spec: Step 0a Governance Discovery

Change: 2026-03-12-fix-subagent-project-context
Date: 2026-03-12
Base: openspec/specs/sdd-context-loading/spec.md

---

## Overview

This delta extends the existing Step 0a (Load project context) block in all SDD phase skills to read and extract the full project CLAUDE.md file, not just its Skills Registry section. Sub-agents now load unbreakable rules, tech stack, and intent classification rules at startup, improving governance visibility.

---

## ADDED — New requirements

### Requirement: Step 0a reads full CLAUDE.md and extracts governance sections

Every SDD phase skill (`sdd-explore`, `sdd-propose`, `sdd-spec`, `sdd-design`, `sdd-tasks`, `sdd-apply`, `sdd-verify`) MUST expand Step 0a to read the complete project CLAUDE.md and extract three governance sections.

#### Scenario: Full CLAUDE.md is read during Step 0a

- **GIVEN** an SDD phase skill is invoked with the governance path provided by the orchestrator
- **WHEN** Step 0a executes
- **THEN** it MUST read the entire project CLAUDE.md file
- **AND** it MUST NOT limit itself to only the Skills Registry section as before

#### Scenario: Three governance sections are extracted and logged

- **GIVEN** the CLAUDE.md file has been read
- **WHEN** Step 0a processes the content
- **THEN** it MUST extract and log the following sections:
  1. `## Unbreakable Rules` — list all rule headings and their intent (e.g., "Rule 1: Language requirement (English-only)")
  2. `## Tech Stack` — summarize key technologies (language, framework, version control, testing approach)
  3. `## Always-On Orchestrator — Intent Classification` — summarize the four intent classes and whether classification is enabled or restricted

#### Scenario: Extracted governance is logged to execution output

- **GIVEN** Step 0a has extracted the governance sections
- **WHEN** the phase execution continues
- **THEN** the output MUST include a summary line such as:
  ```
  Loaded project governance: 5 unbreakable rules, tech stack: [language], intent classification: enabled
  ```
- **AND** the summary MUST be logged as part of the Step 0 completion note

#### Scenario: Governance extraction is non-blocking on missing sections

- **GIVEN** a CLAUDE.md file is present but lacks one or more sections (e.g., no `## Unbreakable Rules`)
- **WHEN** Step 0a attempts to extract sections
- **THEN** for each missing section an INFO-level note MUST be logged: `INFO: Section "## [section-name]" not found in CLAUDE.md — proceeding without it.`
- **AND** execution MUST continue without error (non-blocking)

#### Scenario: Governance extraction is non-blocking when CLAUDE.md is absent

- **GIVEN** a project lacks a CLAUDE.md file at the root
- **WHEN** Step 0a attempts to read it
- **THEN** an INFO-level note MUST be logged: `INFO: CLAUDE.md not found — proceeding with global defaults.`
- **AND** the phase MUST NOT set `status: blocked` or `status: failed`

---

### Requirement: Extracted governance informs subsequent phase decisions

The extracted governance rules MUST be available as enrichment context throughout the phase and MUST inform architectural coherence, naming consistency, and skill alignment decisions.

#### Scenario: Governance rules guide naming in generated output

- **GIVEN** Step 0a has loaded unbreakable rules stating "ALL content MUST be in English"
- **AND** a phase (e.g., `sdd-propose`) is generating proposal content
- **WHEN** the phase writes output files
- **THEN** all generated text MUST respect the English-only rule
- **AND** if a violation is detected, the phase MUST flag it in the output risks

#### Scenario: Tech stack informs design recommendations

- **GIVEN** Step 0a has loaded the tech stack showing "Language: Markdown + YAML + Bash"
- **AND** `sdd-design` is recommending tools or patterns
- **WHEN** design recommendations are written
- **THEN** recommendations MUST prioritize tools compatible with the declared tech stack
- **AND** recommendations for incompatible tools MUST be marked `[Note: outside declared tech stack; review before adopting]`

#### Scenario: Intent classification rules inform phase behavior

- **GIVEN** Step 0a has loaded intent classification rules showing "enabled_classes: [Meta-Command, Change Request]" (Exploration disabled)
- **AND** `sdd-explore` is executing in this project
- **WHEN** the phase completes
- **THEN** it SHOULD emit a note: `NOTE: Exploration is not enabled in project intent classification; results may differ from typical behavior.`
- **AND** the phase MUST still execute (not blocked by governance rules)

---

### Requirement: Dual-block structure in sdd-propose and sdd-spec is preserved

The existing dual-block variant (Step 0a global context + Step 0b domain feature preload) MUST remain unchanged in structure. The governance discovery addition applies only to Step 0a.

#### Scenario: Step 0a and 0b coexist without conflict

- **GIVEN** `sdd-propose` or `sdd-spec` is invoked
- **WHEN** Step 0a loads global governance AND Step 0b loads domain features
- **THEN** both blocks MUST execute in order without conflict
- **AND** both sets of context MUST be available for subsequent steps

---

## MODIFIED — Modified requirements

### Requirement: Step 0a context-file list is expanded

*Before:* Step 0a reads `ai-context/stack.md`, `ai-context/architecture.md`, `ai-context/conventions.md`, and project CLAUDE.md Skills Registry section.

*After:* Step 0a reads the same four files plus the full project CLAUDE.md (not just Skills Registry).

#### Scenario: Read order is unchanged

- **GIVEN** Step 0a executes its context-loading sequence
- **WHEN** files are read
- **THEN** the order MUST remain:
  1. `ai-context/stack.md`
  2. `ai-context/architecture.md`
  3. `ai-context/conventions.md`
  4. Project CLAUDE.md (now full file, not just Skills Registry section)
- **AND** any failures at steps 1–3 do NOT prevent step 4 from executing

#### Scenario: Staleness detection applies to CLAUDE.md

- **GIVEN** Step 0a reads the CLAUDE.md file
- **WHEN** it checks the file's metadata
- **THEN** if the file lacks a "Last updated:" date, a NOTE SHOULD be logged (advisory, not blocking)
- **AND** if a "Last updated:" date is present and older than 7 days, a NOTE MUST be logged: `NOTE: CLAUDE.md last updated [date] — governance may be stale.`

---

## Rules

- Governance extraction MUST be non-blocking in all cases (missing files, missing sections)
- Extracted governance MUST NOT override explicit content in prior phase artifacts (same rule as existing context enrichment)
- Governance rules are self-documenting; sub-agents are instructed to log extracted rules; any misreading will be visible in phase output
- The governance summary line MUST appear in Step 0 completion output for all phases
- If CLAUDE.md is absent and the phase cannot proceed without governance validation (rare), the phase MUST emit a NOTE (not set status: blocked)
- The three extracted sections (Unbreakable Rules, Tech Stack, Intent Classification) are the minimum viable governance snapshot; future changes MAY extend this list

---

## Validation Criteria

- [ ] Step 0a in all seven phase skills (`sdd-explore`, `sdd-propose`, `sdd-spec`, `sdd-design`, `sdd-tasks`, `sdd-apply`, `sdd-verify`) reads the full CLAUDE.md
- [ ] Extracted sections include Unbreakable Rules, Tech Stack, and Intent Classification
- [ ] Governance summary is logged in Step 0 completion output
- [ ] Missing sections are handled gracefully with INFO-level notes
- [ ] Dual-block structure in sdd-propose and sdd-spec is preserved
- [ ] Read order is consistent across all phases
- [ ] Staleness detection applies to CLAUDE.md
- [ ] Extracted governance informs phase decisions without overriding explicit artifacts
