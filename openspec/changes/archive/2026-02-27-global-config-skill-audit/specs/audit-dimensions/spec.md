# Delta Spec: audit-dimensions

Change: global-config-skill-audit
Date: 2026-02-27
Base: openspec/specs/audit-dimensions/spec.md

## MODIFIED — Modified requirements

### Requirement: D10 detection phase — heuristic fallback *(modified)*

When `feature_docs` is absent from `openspec/config.yaml`, D10 MUST fall back to heuristic detection to discover features. The heuristic MUST resolve the effective local skills directory using the `LOCAL_SKILLS_DIR` variable emitted by the Phase A script — `skills/` when the repo is detected as global-config, `.claude/skills/` otherwise.

*(Before: the heuristic scanned `.claude/skills/` unconditionally for Source 1.)*

#### Scenario: D10 heuristic Source 1 uses LOCAL_SKILLS_DIR on a standard project *(modified)*

- **GIVEN** the target project is a standard (non-global-config) project
- **AND** the Phase A script has emitted `LOCAL_SKILLS_DIR=.claude/skills`
- **WHEN** D10 applies heuristic Source 1
- **THEN** it scans `.claude/skills/` for non-SDD skills as feature sources
- **AND** the behavior is identical to pre-change behavior for standard projects

#### Scenario: D10 heuristic Source 1 uses LOCAL_SKILLS_DIR on the global-config repo

- **GIVEN** the target project is the global-config repo (has `install.sh` + `sync.sh` at root, or `framework: "Claude Code SDD meta-system"` in `openspec/config.yaml`)
- **AND** the Phase A script has emitted `LOCAL_SKILLS_DIR=skills`
- **WHEN** D10 applies heuristic Source 1
- **THEN** it scans `skills/` (root) for non-SDD skill directories as feature sources
- **AND** does NOT scan `.claude/skills/` (which does not exist in this repo)

#### Scenario: D10 emits INFO and skips checks when no features are detected *(unchanged)*

- **GIVEN** the target project has no `feature_docs` configured AND heuristic detection finds zero features
- **WHEN** `/project-audit` runs D10
- **THEN** the D10 section in the report contains exactly one line: "No feature docs detected — D10 skipped"
- **AND** no coverage table is emitted for D10
- **AND** no D10 findings of any severity are added to the FIX_MANIFEST

---

## ADDED — New requirements

### Requirement: D9 uses LOCAL_SKILLS_DIR to determine the skills path

D9 (Project Skills Quality) MUST use `LOCAL_SKILLS_DIR` (emitted by the Phase A script) as the path to the local skills directory, instead of the hardcoded `.claude/skills/`.

#### Scenario: D9 skip condition checks LOCAL_SKILLS_DIR

- **GIVEN** the Phase A script has been executed and has emitted `LOCAL_SKILLS_DIR`
- **WHEN** D9 evaluates whether to skip
- **THEN** D9 checks whether the directory identified by `LOCAL_SKILLS_DIR` exists
- **AND** if `LOCAL_SKILLS_DIR` does NOT exist as a directory, D9 emits "No skills directory found — Dimension 9 skipped" and produces no further findings

#### Scenario: D9 runs on a standard project (LOCAL_SKILLS_DIR = .claude/skills)

- **GIVEN** the target project is a standard project
- **AND** the Phase A script emitted `LOCAL_SKILLS_DIR=.claude/skills`
- **AND** `.claude/skills/` exists in the project
- **WHEN** D9 runs
- **THEN** D9 audits the skills found in `.claude/skills/`
- **AND** the output is identical to pre-change behavior for standard projects

#### Scenario: D9 runs on the global-config repo (LOCAL_SKILLS_DIR = skills)

- **GIVEN** the target project is the global-config repo
- **AND** the Phase A script emitted `LOCAL_SKILLS_DIR=skills`
- **AND** `skills/` (root) exists and contains skill directories
- **WHEN** D9 runs
- **THEN** D9 does NOT emit "Dimension 9 skipped"
- **AND** D9 audits at least one skill directory from `skills/`
- **AND** the report includes a D9 section with at least one skill listed

#### Scenario: D9 duplicate detection when LOCAL_SKILLS_DIR = skills (global-config)

- **GIVEN** the global-config repo is the audit target
- **AND** D9's duplicate-detection logic compares local skills with the global catalog
- **WHEN** the comparison runs
- **THEN** skills found in `skills/` are compared against `~/.claude/skills/` (the deployed runtime)
- **AND** because the local skills ARE the global catalog, all skills are expected to have a matching global counterpart
- **AND** this is documented as expected behavior with a `keep` disposition — no WARNING findings are emitted solely because a local skill matches a global skill

### Requirement: D10-a and D10-d path references use LOCAL_SKILLS_DIR

When checking coverage (D10-a) and registry alignment (D10-d), the path used to locate a skill's SKILL.md MUST be derived from `LOCAL_SKILLS_DIR`.

#### Scenario: D10-a coverage check uses LOCAL_SKILLS_DIR path

- **GIVEN** D10 has detected a feature with `convention=skill`
- **AND** the Phase A script emitted `LOCAL_SKILLS_DIR=skills` (global-config)
- **WHEN** D10-a checks whether a documentation artifact exists for that feature
- **THEN** it looks for `skills/<feature_name>/SKILL.md`
- **AND** does NOT look for `.claude/skills/<feature_name>/SKILL.md`

#### Scenario: D10-d registry alignment check reads root CLAUDE.md (unchanged for global-config)

- **GIVEN** D10 is running against the global-config repo
- **WHEN** D10-d checks that a detected feature skill is listed in the CLAUDE.md Skills Registry
- **THEN** it reads the `CLAUDE.md` at the project root (not `.claude/CLAUDE.md`)
- **AND** this behavior is correct for both standard and global-config repos (no change in lookup target)

---

## Rules

- Observable behavior only: specs do not prescribe how `LOCAL_SKILLS_DIR` is implemented internally — only that D9 and D10 consume it and produce the outcomes above
- Standard project behavior MUST be regression-free: all pre-change scenarios for standard projects MUST continue to pass
- The global-config circular detection scenario (D9 duplicate detection) is a documented edge case, not a bug
