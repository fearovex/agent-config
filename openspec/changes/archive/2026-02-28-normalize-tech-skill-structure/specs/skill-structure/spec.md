# Spec: skill-structure

Change: normalize-tech-skill-structure
Date: 2026-02-27

## Overview

This spec defines the observable structural requirements for technology skill SKILL.md files in the claude-config global catalog. It specifies the mandatory sections that every SKILL.md must contain so that the project-audit dimensions D9-3 (structural completeness) and D10-b (structural quality) pass.

---

## Requirements

### Requirement: Every tech skill SKILL.md MUST have a Triggers line in the Markdown body

A `**Triggers**` line MUST be present in the Markdown body (below the YAML frontmatter) of every technology skill SKILL.md. The line MUST match the pattern `**Triggers**: <text>` where `<text>` is a non-empty, comma-separated list of keywords or phrases that describe when the skill should be loaded.

The frontmatter `description` field alone does NOT satisfy this requirement. The body Markdown trigger line is the verifiable artifact.

#### Scenario: A tech skill has a Triggers line present in its body

- **GIVEN** a tech skill SKILL.md file (e.g., `skills/react-19/SKILL.md`)
- **WHEN** the file content below the closing `---` of the YAML frontmatter is read
- **THEN** at least one line matches the pattern `**Triggers**:` (case-sensitive, bold markdown syntax)
- **AND** that line contains at least one non-empty keyword or phrase after the colon

#### Scenario: A SKILL.md with Triggers only in frontmatter does NOT satisfy the requirement

- **GIVEN** a tech skill SKILL.md whose YAML frontmatter `description` field contains trigger text
- **AND** whose Markdown body has no `**Triggers**:` line
- **WHEN** D9-3 structural completeness check is evaluated
- **THEN** D9-3 marks this skill as failing the trigger-definition criterion
- **AND** the frontmatter description is not counted as a substitute

#### Scenario: grep command confirms Triggers presence across all tech skills

- **GIVEN** all 23 tech skill SKILL.md files have been updated
- **WHEN** `grep -r "^\*\*Triggers\*\*" ~/.claude/skills/` is executed
- **THEN** at least 23 lines are returned, one per tech skill
- **AND** every one of the 23 tech skill directories appears in the output

---

### Requirement: Every tech skill SKILL.md MUST have a Rules section

A `## Rules` section MUST be present in every technology skill SKILL.md. The section MUST contain at least 3 rules that are specific and actionable for the given technology.

Generic placeholder rules (e.g., "Use this skill appropriately") MUST NOT be the sole content. Rules MUST address at least one of: scope of use, prohibited patterns, required inputs, key constraints, or technology-specific best-practice invariants.

#### Scenario: A tech skill has a Rules section with substantive content

- **GIVEN** a tech skill SKILL.md file (e.g., `skills/typescript/SKILL.md`)
- **WHEN** the file is read end-to-end
- **THEN** a `## Rules` heading is present
- **AND** the section contains at least 3 bullet points or numbered items
- **AND** at least one rule mentions a technology-specific term, pattern, or constraint (not purely generic language)

#### Scenario: A SKILL.md without a Rules section fails D9-3

- **GIVEN** a tech skill SKILL.md that has a trigger definition and process steps but no `## Rules` section
- **WHEN** D9-3 evaluates structural completeness
- **THEN** D9-3 marks this skill as failing the rules-section criterion
- **AND** the finding appears in the D9 block of the audit report

#### Scenario: grep command confirms Rules section across all tech skills

- **GIVEN** all 23 tech skill SKILL.md files have been updated
- **WHEN** `grep -r "^## Rules" ~/.claude/skills/` is executed
- **THEN** at least 23 lines are returned, one per tech skill
- **AND** every one of the 23 tech skill directories appears in the output

---

### Requirement: The three post-import skills (claude-code-expert, excel-expert, image-ocr) MUST have a Rules section

The skills `claude-code-expert`, `excel-expert`, and `image-ocr` already have a `**Triggers**` line. They MUST additionally have a `## Rules` section with the same substantive-content criteria as all other tech skills.

#### Scenario: claude-code-expert has a Rules section after the change

- **GIVEN** `skills/claude-code-expert/SKILL.md` has been updated
- **WHEN** the file is read
- **THEN** a `## Rules` heading is present
- **AND** the section contains rules specific to Claude Code configuration and architecture

#### Scenario: excel-expert has a Rules section after the change

- **GIVEN** `skills/excel-expert/SKILL.md` has been updated
- **WHEN** the file is read
- **THEN** a `## Rules` heading is present
- **AND** the section contains rules specific to Excel file manipulation constraints

#### Scenario: image-ocr has a Rules section after the change

- **GIVEN** `skills/image-ocr/SKILL.md` has been updated
- **WHEN** the file is read
- **THEN** a `## Rules` heading is present
- **AND** the section contains rules specific to OCR tool selection and use constraints

---

### Requirement: Changes to SKILL.md files MUST be purely additive

No existing content in any affected tech skill SKILL.md MAY be modified, rewritten, or removed during this change. Only new content is inserted (Triggers line) or appended (Rules section).

The YAML frontmatter MUST remain unchanged. The existing process steps, code examples, and reference tables MUST remain intact.

#### Scenario: git diff shows only additions for each modified SKILL.md

- **GIVEN** all 23 tech skill SKILL.md files have been edited
- **WHEN** `git diff HEAD -- skills/<skill-name>/SKILL.md` is run for any affected skill
- **THEN** the diff contains only lines prefixed with `+` (additions)
- **AND** no lines are prefixed with `-` (deletions) except for blank lines that may have been adjusted at insertion points
- **AND** the total character count of the original content is preserved within the new file

#### Scenario: Frontmatter is unchanged after edit

- **GIVEN** a tech skill SKILL.md before and after the change
- **WHEN** the YAML block between the two `---` delimiters is compared
- **THEN** the frontmatter content is byte-for-byte identical
- **AND** no new keys have been added and no existing keys have been removed

---

### Requirement: The deployed runtime (~/.claude/skills/) reflects the changes after install.sh

The repo changes MUST be deployed to `~/.claude/skills/` via `install.sh` before the change is considered complete. The runtime files must match the repo files.

#### Scenario: install.sh succeeds after all SKILL.md edits

- **GIVEN** all 23 tech skill SKILL.md files in the repo have been updated
- **WHEN** `install.sh` is executed from the repo root
- **THEN** the script exits with code 0
- **AND** `~/.claude/skills/<skill-name>/SKILL.md` reflects the updated content for all 23 skills

#### Scenario: grep against ~/.claude/skills/ confirms deployment

- **GIVEN** install.sh has been run successfully
- **WHEN** `grep -r "^## Rules" ~/.claude/skills/` is executed
- **THEN** all 23 tech skill directories appear in the output
- **AND** `grep -r "^\*\*Triggers\*\*" ~/.claude/skills/` returns hits for all 23 tech skills

---

### Requirement: /project-audit D9-3 passes for all tech skills after the change

After applying this change and running install.sh, the D9-3 structural completeness sub-check MUST show no failures for any of the 23 tech skills.

#### Scenario: D9-3 passes with zero failures after the change

- **GIVEN** all 23 tech skill SKILL.md files have both a Triggers line and a Rules section
- **AND** install.sh has been run
- **WHEN** `/project-audit` is executed against the claude-config project
- **THEN** the D9 block in the audit report contains no structural-completeness findings for any tech skill
- **AND** the D9-3 row in the report shows PASS (or equivalent green status)

#### Scenario: /project-audit D10-b improves or passes after the change

- **GIVEN** the same post-change state
- **WHEN** `/project-audit` is executed
- **THEN** the D10-b (Structural Quality) row shows an equal or better status compared to the pre-change baseline
- **AND** no tech skill is flagged for missing structural markers in the D10-b findings

---

## Rules

- This spec describes OBSERVABLE BEHAVIOR only — it does not prescribe which words to use in the Rules sections, only that they be substantive and technology-specific
- Verification of the Triggers line uses `grep` on the deployed `~/.claude/skills/` path, not the repo path, as the canonical runtime source
- A skill that already has a Triggers line before this change (claude-code-expert, excel-expert, image-ocr) is considered compliant for that criterion and MUST NOT have its Triggers line modified
- D9-3 and D10-b pass criteria are the external audit signals that define whether this change was successful — they are the primary acceptance tests
- Rollback is defined by `git revert` of the change commit followed by `install.sh` re-deployment
