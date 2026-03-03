# Proposal: claude-folder-audit-project-mode

Date: 2026-03-03
Status: Draft

## Intent

Add a `project` execution mode to the `claude-folder-audit` skill so that running `/claude-folder-audit` from a project directory with a `.claude/` folder audits that project's Claude configuration instead of the unrelated global `~/.claude/` runtime.

## Motivation

The `claude-folder-audit` skill currently has two execution modes:
- `global-config`: triggered when CWD is the `claude-config` source repo (install.sh + skills/ present)
- `global`: triggered in all other locations — always audits `~/.claude/`

When a user runs `/claude-folder-audit` from a project directory (e.g., `D:/Proyectos/Audiio/audiio_v3`) that has a `.claude/` folder, the skill silently audits the global `~/.claude/` runtime. This produces output that is entirely unrelated to what the user intended — they want to know if their project's Claude configuration (CLAUDE.md, registered skills, local skill files) is correct and consistent.

The two-tier skill placement model (ADR: skill-scope-global-vs-project) means that projects increasingly have their own `.claude/skills/` directories and a local CLAUDE.md with a Skills Registry. There is currently no automated health check for this project-local configuration tier.

## Scope

### Included

- Detection logic: new `project` mode activates when CWD has a `.claude/` directory but is NOT the global-config repo
- Check P1: `.claude/CLAUDE.md` exists and contains a Skills Registry section
- Check P2: Global-path skill registrations (`~/.claude/skills/<name>/`) — verify the SKILL.md is actually deployed at that runtime path
- Check P3: Local-path skill registrations (`.claude/skills/<name>/`) — verify the SKILL.md file exists on disk relative to CWD
- Check P4: Local skills on disk (`.claude/skills/*/SKILL.md`) that are NOT registered in CLAUDE.md (orphaned local skills)
- Check P5: Scope tier compliance — same logic as current Check 5 (overlap between `.claude/skills/` and `~/.claude/skills/`), adapted to project context
- Report: written to `.claude/claude-folder-audit-report.md` in the project root (NOT to `~/.claude/`)
- Mode detection update in Step 2 of the existing process
- `global-config` and `global` modes remain unchanged in behavior

### Excluded (explicitly out of scope)

- Auto-fix of any findings — the skill remains strictly read-only
- Auditing nested or multi-level `.claude/` structures — only the top-level `.claude/` at CWD is examined
- Validating the content of CLAUDE.md beyond Skills Registry section presence — that is `project-audit`'s job
- Modifying the global audit report path or structure for `global-config` and `global` modes
- Adding a `project` mode to `project-audit` — that skill is already project-aware
- Any changes to `install.sh`, `sync.sh`, or other deployment scripts

## Proposed Approach

Extend Step 2 (mode detection) of the existing `claude-folder-audit` process with a third branch: if `.claude/` exists at CWD and neither `install.sh` nor `skills/` are present at CWD root, set `MODE = project`. The five existing checks are replaced with five project-specific checks (P1–P5). The report is written to `.claude/claude-folder-audit-report.md` instead of `~/.claude/claude-folder-audit-report.md`.

Mode priority order becomes:
1. `global-config` — both `install.sh` and `skills/` present at CWD root
2. `project` — `.claude/` directory present at CWD (and not global-config)
3. `global` — all other locations

This preserves full backwards compatibility: both existing modes are unmodified and activates only when the new precondition (`.claude/` at CWD) is true.

## Affected Areas

| Area/Module | Type of Change | Impact |
|-------------|----------------|--------|
| `skills/claude-folder-audit/SKILL.md` | Modified — Step 2 + new project checks | High (core skill logic) |
| Report output path | Modified — project mode writes to `.claude/` instead of `~/.claude/` | Medium |
| Mode detection branching | Modified — adds a third branch with priority ordering | Medium |
| `global-config` and `global` modes | Unchanged | None |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| False positive for `project` mode when user intends `global` audit from a project dir | Low | Medium | Document the mode priority in the report header; user can cd to a neutral dir to force `global` mode |
| `.claude/` exists but has no CLAUDE.md — P1 fails and subsequent checks are degraded | Medium | Low | P1 records a HIGH finding; P2–P5 still execute with appropriate "not found" handling |
| Skills Registry parsing is fragile if CLAUDE.md format varies | Medium | Medium | Parser looks for the section header `## Skills Registry` or a `~/.claude/skills/` / `.claude/skills/` path pattern — both are stable signals |
| Report path `.claude/claude-folder-audit-report.md` may confuse users who expect the global path | Low | Low | Report header explicitly states mode and report location |

## Rollback Plan

The change affects only `skills/claude-folder-audit/SKILL.md`. To revert:
1. `git revert` the commit that introduced this change, or
2. Restore the previous `SKILL.md` content from git history: `git checkout <previous-sha> -- skills/claude-folder-audit/SKILL.md`
3. Run `install.sh` to re-deploy the reverted skill to `~/.claude/skills/claude-folder-audit/`
4. Verify with `/claude-folder-audit` from `claude-config` repo root that `global-config` mode still works

No other files are affected. No database migrations, schema changes, or external service calls are involved.

## Dependencies

- The two-tier skill placement model must be operational (it is — ADR: skill-scope-global-vs-project, deployed)
- `~/.claude/skills/claude-folder-audit/SKILL.md` must be redeployed via `install.sh` after the change

## Success Criteria

- [ ] Running `/claude-folder-audit` from a project directory with `.claude/` activates `project` mode (confirmed in report header: `Mode: project`)
- [ ] Running `/claude-folder-audit` from the `claude-config` repo root still activates `global-config` mode (no regression)
- [ ] Running `/claude-folder-audit` from a directory with no `.claude/` and no `install.sh`+`skills/` still activates `global` mode (no regression)
- [ ] P1 detects a missing `.claude/CLAUDE.md` with a HIGH finding
- [ ] P2 detects a globally-registered skill whose SKILL.md is absent from `~/.claude/skills/` with a HIGH finding
- [ ] P3 detects a locally-registered skill whose SKILL.md is absent from `.claude/skills/` with a HIGH finding
- [ ] P4 detects a local `.claude/skills/*/SKILL.md` file not registered in CLAUDE.md with a MEDIUM finding
- [ ] P5 reports scope tier overlap (skill in both `.claude/skills/` and `~/.claude/skills/`) with a LOW finding
- [ ] In `project` mode, the report is written to `.claude/claude-folder-audit-report.md`, not `~/.claude/claude-folder-audit-report.md`
- [ ] The skill remains strictly read-only — no files are created or modified except the report

## Effort Estimate

Low (hours) — the change is confined to a single SKILL.md file. The new checks follow the same structural pattern as the existing checks. No new tooling, dependencies, or external integrations are required.
