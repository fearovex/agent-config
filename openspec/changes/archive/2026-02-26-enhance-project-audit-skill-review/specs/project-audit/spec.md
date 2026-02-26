# Spec: project-audit — Dimension 9

Change: enhance-project-audit-skill-review
Date: 2026-02-26

## Requirements

### Requirement: D9-1 — Detect and skip when no local skills directory exists

When `/project-audit` runs on a project that has no `.claude/skills/` directory, Dimension 9 MUST skip gracefully and note the absence without penalizing the score.

#### Scenario: No local skills directory present
- **GIVEN** a project whose `.claude/` directory does not contain a `skills/` subdirectory
- **WHEN** `/project-audit` runs Dimension 9
- **THEN** the Dimension 9 section in `audit-report.md` reads: `No .claude/skills/ directory found — Dimension 9 skipped.`
- **AND** the overall audit score is not deducted for the absence

---

### Requirement: D9-2 — Detect duplicate local skills against the global catalog

For each subdirectory in the project's `.claude/skills/`, Dimension 9 MUST check whether a skill with the same directory name exists in `~/.claude/skills/`. A match by name signals a possible redundant copy.

#### Scenario: Local skill duplicates a global skill
- **GIVEN** a project with `.claude/skills/typescript/SKILL.md`
- **AND** `~/.claude/skills/typescript/SKILL.md` also exists
- **WHEN** Dimension 9 runs
- **THEN** the audit report lists `typescript` under **Duplicates** with disposition `move-to-global` or `delete`
- **AND** the `FIX_MANIFEST.skill_quality_actions` block contains a `delete_duplicate` entry for `typescript` with `global_path: ~/.claude/skills/typescript/SKILL.md` and `local_path: .claude/skills/typescript/SKILL.md`

#### Scenario: Local skill does not duplicate any global skill
- **GIVEN** a project with `.claude/skills/my-custom-skill/SKILL.md`
- **AND** no `~/.claude/skills/my-custom-skill/` exists
- **WHEN** Dimension 9 runs
- **THEN** `my-custom-skill` is NOT listed under Duplicates

#### Scenario: Global catalog directory is inaccessible
- **GIVEN** `~/.claude/skills/` cannot be read (permissions, missing directory)
- **WHEN** Dimension 9 attempts the duplication check
- **THEN** the audit report notes: `Global catalog unreadable — duplicate check skipped` at INFO level
- **AND** the skill is assigned disposition `keep` by default

---

### Requirement: D9-3 — Check structural completeness of each local SKILL.md

Each local `SKILL.md` MUST be checked for three required sections:
1. Trigger definition: line matching `**Triggers**` or heading `## Triggers`
2. Process section: heading `## Process` or `### Step`
3. Rules section: heading `## Rules` or `## Execution rules`

Missing any of these sections results in disposition `update` and a `add_missing_section` action item.

#### Scenario: SKILL.md has all three required sections
- **GIVEN** a local `SKILL.md` that contains `**Triggers**`, `## Process`, and `## Rules`
- **WHEN** Dimension 9 checks structural completeness
- **THEN** no structural finding is emitted for this skill
- **AND** structural completeness is noted as PASS

#### Scenario: SKILL.md is missing the Rules section
- **GIVEN** a local `SKILL.md` that contains `**Triggers**` and `## Process` but no `## Rules` or `## Execution rules`
- **WHEN** Dimension 9 checks structural completeness
- **THEN** the skill is listed under **Structural Issues** with `missing_sections: ["Rules"]`
- **AND** disposition is `update`
- **AND** `FIX_MANIFEST.skill_quality_actions` contains an `add_missing_section` entry for that skill specifying `section: "Rules"`

#### Scenario: SKILL.md is missing all three sections
- **GIVEN** a local `SKILL.md` with no trigger, process, or rules sections
- **WHEN** Dimension 9 checks structural completeness
- **THEN** the skill is listed with `missing_sections: ["Triggers", "Process", "Rules"]`
- **AND** disposition is `update`
- **AND** one `add_missing_section` action item is emitted per missing section

#### Scenario: Local skill directory exists but has no SKILL.md
- **GIVEN** `.claude/skills/orphan-skill/` exists but contains no `SKILL.md` file
- **WHEN** Dimension 9 processes that directory
- **THEN** the audit report lists `orphan-skill` with finding: `No SKILL.md found in directory`
- **AND** disposition is `update`

---

### Requirement: D9-4 — Check language compliance of each local SKILL.md

Each local `SKILL.md` MUST be scanned for non-English prose. The heuristic reuses the same detection approach defined in Dimension 4e of the current audit: scanning for non-ASCII Unicode letter blocks (Latin Extended, Cyrillic, CJK, Arabic, etc.) in headings and body paragraphs (not in code blocks).

#### Scenario: SKILL.md contains only English content
- **GIVEN** a local `SKILL.md` with all headings and body text in English
- **WHEN** Dimension 9 runs the language compliance check
- **THEN** no language finding is emitted for this skill

#### Scenario: SKILL.md contains non-English prose
- **GIVEN** a local `SKILL.md` with a heading or paragraph in Spanish (or any non-English language)
- **WHEN** Dimension 9 runs the language compliance check
- **THEN** the skill is listed under **Language Violations** with `language_issue: true`
- **AND** disposition for that skill is `update` (at minimum)
- **AND** a `flag_language_violation` finding is added to `FIX_MANIFEST.skill_quality_actions`

#### Scenario: SKILL.md has non-English content only inside fenced code blocks
- **GIVEN** a local `SKILL.md` where non-English characters appear only within ` ``` ` fenced code blocks
- **WHEN** Dimension 9 runs the language compliance check
- **THEN** no language violation is emitted (code blocks are excluded from the heuristic)

---

### Requirement: D9-5 — Check stack relevance of each local SKILL.md

Each local `SKILL.md` SHOULD be scanned for technology references (framework names, version strings). If a referenced technology does not appear in `ai-context/stack.md` AND does not appear in `package.json`/`pyproject.toml`, it MAY be flagged as potentially irrelevant.

The stack relevance check MUST use a conservative heuristic: only flag a skill when a technology is explicitly named in the SKILL.md trigger or title AND is absent from both `stack.md` and the package manifest. Emit findings at INFO level, not WARNING.

#### Scenario: Skill references a technology present in the project stack
- **GIVEN** a local `SKILL.md` for `react-19` and the project's `package.json` lists `"react": "^19.0.0"`
- **WHEN** Dimension 9 checks stack relevance
- **THEN** no irrelevance finding is emitted for this skill

#### Scenario: Skill references a technology absent from the project stack
- **GIVEN** a local `SKILL.md` titled `# spring-boot-3` and the project has no Java or Spring dependencies
- **AND** `ai-context/stack.md` does not mention Spring
- **WHEN** Dimension 9 checks stack relevance
- **THEN** the skill is listed under **Possibly Irrelevant Skills** at INFO level with disposition `keep` (for user review)
- **AND** a `flag_irrelevant` entry is added to `FIX_MANIFEST.skill_quality_actions`
- **AND** the finding is NOT promoted to WARNING or ERROR

#### Scenario: No stack information is available (no stack.md, no package.json)
- **GIVEN** the project has neither `ai-context/stack.md` nor `package.json` nor `pyproject.toml`
- **WHEN** Dimension 9 attempts the stack relevance check
- **THEN** the check is skipped for all skills
- **AND** the audit report notes: `Stack relevance check skipped — no stack source found`

---

### Requirement: D9-6 — Emit Dimension 9 section in audit-report.md

The results of all D9 sub-checks MUST be written as a new `## Dimension 9 — Project Skills Quality` section in `audit-report.md`, following the established format of other dimension sections.

#### Scenario: Findings across multiple sub-checks
- **GIVEN** a project with 3 local skills: one duplicate, one missing Rules, one with non-English content
- **WHEN** Dimension 9 completes
- **THEN** `audit-report.md` contains a `## Dimension 9 — Project Skills Quality` section
- **AND** the section contains three subsections: **Duplicates**, **Structural Issues**, **Language Violations**
- **AND** each skill entry shows its name, findings, and disposition recommendation
- **AND** the section is placed after Dimension 8 and before Required Actions

#### Scenario: No findings (all local skills pass)
- **GIVEN** a project where all local skills pass every D9 sub-check
- **WHEN** Dimension 9 completes
- **THEN** the Dimension 9 section reads: `All local skills pass quality checks.`

---

### Requirement: D9-7 — Populate FIX_MANIFEST with skill_quality_actions

The `FIX_MANIFEST` YAML block MUST include a new top-level key `skill_quality_actions` when at least one D9 action item exists. This key MUST be additive — it MUST NOT break or modify existing keys (`required_actions`, `missing_global_skills`, `orphaned_changes`, `violations`).

#### Scenario: FIX_MANIFEST receives skill_quality_actions entries
- **GIVEN** Dimension 9 found one duplicate and one missing-section skill
- **WHEN** the report is written
- **THEN** the `FIX_MANIFEST` YAML contains:
  ```yaml
  skill_quality_actions:
    - id: "d9-[skill-name]-duplicate"
      type: "delete_duplicate"
      local_path: ".claude/skills/[skill-name]"
      global_path: "~/.claude/skills/[skill-name]"
    - id: "d9-[skill-name]-missing-rules"
      type: "add_missing_section"
      target: ".claude/skills/[skill-name]/SKILL.md"
      section: "Rules"
  ```
- **AND** existing FIX_MANIFEST keys remain unchanged

#### Scenario: No D9 findings
- **GIVEN** all local skills pass every D9 check
- **WHEN** the report is written
- **THEN** `skill_quality_actions` is either absent from the FIX_MANIFEST or is an empty list

---

### Requirement: D9-8 — Dimension 9 does not deduct from the 100-point score

In this first iteration, Dimension 9 findings MUST NOT deduct points from the existing 100-point scoring system. The dimension is informational and additive.

#### Scenario: Project has multiple D9 violations
- **GIVEN** a project with 5 local skills, all failing D9 checks
- **WHEN** `/project-audit` completes
- **THEN** the overall score is calculated the same as if Dimension 9 did not exist
- **AND** the score table row for Dimension 9, if shown, displays `N/A` for points
