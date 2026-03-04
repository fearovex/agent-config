# Delta Spec: folder-audit-reporting

Change: enhance-claude-folder-audit
Date: 2026-03-03
Base: openspec/specs/folder-audit-reporting/spec.md

---

## ADDED — New requirements

---

### Requirement: project mode report MUST use labeled section headers for all 8 checks (P1–P8)

The existing requirement covers P1–P5 section labels. This change extends the contract to
cover the three new checks P6, P7, and P8.

#### Scenario: project mode report includes section headers for P6, P7, and P8

- **GIVEN** execution mode is `project`
- **AND** the skill has completed all 8 checks
- **WHEN** the report is read
- **THEN** in addition to the existing P1–P5 section headers, the report contains:
  - `## Check P6 — Memory Layer (ai-context/)`
  - `## Check P7 — Feature Domain Knowledge Layer (ai-context/features/)`
  - `## Check P8 — .claude/ Folder Inventory`
- **AND** no section uses a label not in the set P1–P8

#### Scenario: each new check section appears even when it has no findings

- **GIVEN** execution mode is `project`
- **AND** Check P6, P7, or P8 produces zero findings of any severity
- **WHEN** the report is written
- **THEN** the section for the check still appears with the text "No findings"

---

### Requirement: report header summary line MUST reflect all 8 checks

When the report is written in project mode, the summary line in the header MUST count
findings from all 8 checks (P1 through P8), not just 5.

#### Scenario: header summary includes counts from P6, P7, P8

- **GIVEN** execution mode is `project`
- **AND** the skill has completed all 8 checks
- **WHEN** the report header is read
- **THEN** the `Summary:` line reflects the total finding counts from checks P1 through P8
- **AND** findings from P6, P7, and P8 are included in the HIGH/MEDIUM/LOW/INFO totals

---

### Requirement: project mode Findings Summary table MUST include P6, P7, and P8 findings

The existing Findings Summary table requirement covers all check findings without explicitly
restricting to P1–P5. This requirement makes the inclusion of P6–P8 explicit.

#### Scenario: Findings Summary table includes P6, P7, P8 rows when those checks produce findings

- **GIVEN** execution mode is `project`
- **AND** one or more of Checks P6, P7, P8 produced a non-INFO finding
- **WHEN** the "## Findings Summary" table is read
- **THEN** each non-INFO finding from P6, P7, P8 appears as a row in the table
- **AND** each row identifies the check (e.g., "P6", "P7", "P8") in the Check column

---

### Requirement: project mode Recommended Next Steps MUST reference new check remediations

When the highest-severity finding comes from P6, P7, or P8, the Recommended Next Steps
section MUST provide an appropriate first action that is specific to the finding source.

#### Scenario: P6 MEDIUM finding (ai-context/ absent) — first step references /memory-init

- **GIVEN** execution mode is `project`
- **AND** the highest-severity finding is a MEDIUM from Check P6 (ai-context/ directory absent)
- **AND** no HIGH findings exist
- **WHEN** the report's "## Recommended Next Steps" section is read
- **THEN** the first recommended action is: "Run /memory-init to generate the ai-context/ memory layer for this project"

#### Scenario: P8 MEDIUM finding (unexpected .claude/ item) — first step references manual review

- **GIVEN** execution mode is `project`
- **AND** the highest-severity finding is a MEDIUM from Check P8 (unexpected item in .claude/)
- **AND** no HIGH findings exist
- **WHEN** the report's "## Recommended Next Steps" section is read
- **THEN** the first recommended action references reviewing the unexpected .claude/ item manually

#### Scenario: no HIGH or MEDIUM findings across all 8 checks — healthy state confirmed

- **GIVEN** execution mode is `project`
- **AND** the report contains zero HIGH findings and zero MEDIUM findings across all 8 checks
- **WHEN** the report's "## Recommended Next Steps" section is read
- **THEN** the section contains: "Project Claude configuration appears healthy — no required actions detected"

---

### Requirement: report findings MUST collapse INFO-only check sections to a one-line summary

To prevent report length explosion on healthy projects, check sections that produce only
INFO observations MUST be collapsible — all INFO notes MUST appear under the check section
but MUST NOT be listed in the Findings Summary table (which shows only HIGH/MEDIUM/LOW).

#### Scenario: P7 section produces only INFO notes — not listed in Findings Summary

- **GIVEN** execution mode is `project`
- **AND** Check P7 produces only INFO notes (e.g., ai-context/features/ absent, or only template present)
- **WHEN** the report is read
- **THEN** the P7 section appears with the INFO observations listed under it
- **AND** no P7 row appears in the "## Findings Summary" table (which covers HIGH/MEDIUM/LOW only)

---

## MODIFIED — Modified requirements

### Requirement: project mode report MUST use project-specific check section labels

*(Base: openspec/specs/folder-audit-reporting/spec.md — Requirement: project mode report MUST use project-specific check section labels)*

Extended to include new check labels P6, P7, P8 in addition to P1–P5.

#### Scenario: project mode report uses P1–P8 section headers *(modified)*

- **GIVEN** execution mode is `project`
- **AND** the skill has completed all 8 checks
- **WHEN** the report is read
- **THEN** the per-check sections are labeled:
  - `## Check P1 — CLAUDE.md Presence and Skills Registry`
  - `## Check P2 — Global Skill Registrations Reachability`
  - `## Check P3 — Local Skill Registrations Reachability`
  - `## Check P4 — Orphaned Local Skills`
  - `## Check P5 — Scope Tier Overlap`
  - `## Check P6 — Memory Layer (ai-context/)`
  - `## Check P7 — Feature Domain Knowledge Layer (ai-context/features/)`
  - `## Check P8 — .claude/ Folder Inventory`
- **AND** no section uses any other label

### Requirement: each project-mode check section appears even when it has no findings

*(Base: openspec/specs/folder-audit-reporting/spec.md — identical requirement)*

Now applies to all 8 checks (P1–P8). The observable behavior is unchanged; the scope is extended.

#### Scenario: all 8 check sections appear in the report even when they have no findings *(modified)*

- **GIVEN** execution mode is `project`
- **AND** one or more of Checks P1–P8 produce zero findings of any severity
- **WHEN** the report is written
- **THEN** all 8 check sections appear in the report
- **AND** each section with no findings shows "No findings" under its header

---

## REMOVED — Removed requirements

*(None — all existing requirements are preserved.)*
