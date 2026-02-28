# Delta Spec: audit-execution

Change: global-config-skill-audit
Date: 2026-02-27
Base: openspec/specs/audit-execution/spec.md

## MODIFIED — Modified requirements

### Requirement: Batched shell discovery *(modified — Phase A script output extended)*

The Phase A discovery script MUST emit a `LOCAL_SKILLS_DIR` key in addition to all keys already required by the base spec. All other batching constraints (≤ 3 Bash calls, single script, no per-dimension calls) remain unchanged.

*(Before: the Phase A script did not emit `LOCAL_SKILLS_DIR`.)*

#### Scenario: Discovery script output includes LOCAL_SKILLS_DIR key

- **GIVEN** Claude is executing `/project-audit` on any project
- **WHEN** the Phase A discovery Bash call completes
- **THEN** its stdout includes a line `LOCAL_SKILLS_DIR=<value>` where `<value>` is either `skills` or `.claude/skills`
- **AND** this line appears in the output regardless of whether the project is a global-config repo or a standard project
- **AND** the key is always present and never conditionally absent

#### Scenario: LOCAL_SKILLS_DIR resolves to "skills" on global-config repo

- **GIVEN** the target project has both `install.sh` and `sync.sh` at its root
- **AND** the Phase A script has already emitted `INSTALL_SH_EXISTS=1` and `SYNC_SH_EXISTS=1`
- **WHEN** the `LOCAL_SKILLS_DIR` assignment logic executes within the same Phase A script
- **THEN** `LOCAL_SKILLS_DIR` is set to `skills`
- **AND** the output line reads `LOCAL_SKILLS_DIR=skills`

#### Scenario: LOCAL_SKILLS_DIR resolves to "skills" via config.yaml fallback

- **GIVEN** the target project does NOT have both `install.sh` and `sync.sh` at root
- **AND** `openspec/config.yaml` contains the text `Claude Code SDD meta-system`
- **WHEN** the `LOCAL_SKILLS_DIR` assignment logic executes
- **THEN** `LOCAL_SKILLS_DIR` is set to `skills`
- **AND** the output line reads `LOCAL_SKILLS_DIR=skills`

#### Scenario: LOCAL_SKILLS_DIR resolves to ".claude/skills" on a standard project

- **GIVEN** the target project does NOT have both `install.sh` and `sync.sh` at root
- **AND** `openspec/config.yaml` either does not exist or does not contain `Claude Code SDD meta-system`
- **WHEN** the `LOCAL_SKILLS_DIR` assignment logic executes
- **THEN** `LOCAL_SKILLS_DIR` is set to `.claude/skills`
- **AND** the output line reads `LOCAL_SKILLS_DIR=.claude/skills`

#### Scenario: LOCAL_SKILLS_DIR computation depends on INSTALL_SH_EXISTS and SYNC_SH_EXISTS

- **GIVEN** the Phase A script is being read
- **WHEN** the `LOCAL_SKILLS_DIR` assignment block is reached
- **THEN** `INSTALL_SH_EXISTS` and `SYNC_SH_EXISTS` have already been computed earlier in the same script
- **AND** the `LOCAL_SKILLS_DIR` block uses those variables without re-issuing separate Bash calls to check them

#### Scenario: Total Bash call count still does not exceed 3

- **GIVEN** the Phase A script has been extended with the `LOCAL_SKILLS_DIR` logic
- **WHEN** `/project-audit` runs end-to-end on any project
- **THEN** the total number of Bash tool calls does not exceed 3
- **AND** adding `LOCAL_SKILLS_DIR` does not introduce a new Bash call — it is part of the existing Phase A script block

---

## Rules

- The `LOCAL_SKILLS_DIR` computation MUST be self-contained within the existing Phase A Bash call — no new Bash calls are permitted
- `LOCAL_SKILLS_DIR` MUST be deterministic: given the same project state, it MUST always produce the same value
- These specs describe observable outputs of the Phase A script, not internal implementation — the exact conditional logic may differ as long as the emitted values match the scenarios above
