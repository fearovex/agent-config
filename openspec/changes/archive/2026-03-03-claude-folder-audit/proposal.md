# Proposal: claude-folder-audit

Date: 2026-03-03
Status: Draft

## Intent

Create a new read-only skill that audits the `~/.claude/` runtime folder (or a project's `.claude/` folder) and generates a prioritized diagnostic report covering installation drift, skill deployment completeness, orphaned artifacts, and scope tier compliance.

## Motivation

The `claude-config` repo manages a runtime deployment of 44+ skills and configuration files into `~/.claude/` via `install.sh`. Currently there is no mechanism to verify:

- Whether the runtime `~/.claude/` is in sync with the source repo after repo updates
- Which skills from the catalog are deployed vs. missing vs. stale
- Whether orphaned or unexpected files have accumulated in the runtime folder
- Whether skills are placed in the correct scope tier (global `~/.claude/skills/` vs. project-local `.claude/skills/`) per ADR 008

`project-audit` audits project-level Claude configuration (CLAUDE.md, openspec/, ai-context/) but explicitly does NOT audit the runtime installation state. This gap means drift can go undetected indefinitely — users update the repo but forget to run `install.sh`, or manually edit `~/.claude/` directly (which violates the repo-authoritative rule).

The need is especially acute on the current Windows 11 environment where path normalization differences add an extra layer of drift risk.

## Scope

### Included

- New skill directory: `skills/claude-folder-audit/SKILL.md`
- Audit check 1: Runtime structure validation — verify required directories exist in `~/.claude/` (`skills/`, `openspec/`, `ai-context/`, `memory/`, `hooks/`)
- Audit check 2: Skill deployment completeness — for each skill in the source repo, verify a corresponding directory exists in `~/.claude/skills/`
- Audit check 3: Installation drift detection — compare repo vs. `~/.claude/` modification times to flag likely out-of-sync state
- Audit check 4: Orphaned artifact detection — identify files in `~/.claude/` not traceable to the source repo (signal: manual edits or stale files)
- Audit check 5: Scope tier compliance — detect skills duplicated across global and project-local tiers, or project-local skills missing from the repo
- Report generation: `~/.claude/claude-folder-audit-report.md` — human-readable, prioritized (HIGH / MEDIUM / LOW), with recommended remediation commands
- Windows path support: normalize `~` to `$HOME` / `%USERPROFILE%` at runtime; skill must be OS-aware
- Registration of the new skill in `CLAUDE.md` under a new "System Audits" section in the Skills Registry

### Excluded (explicitly out of scope)

- Auto-fix / auto-remediation — no file is created, moved, or deleted by this skill. That is the responsibility of a future `claude-folder-fix` skill (V2)
- Auditing project-level CLAUDE.md quality — already covered by `project-audit`
- Memory content validation — `memory/` is user-owned; only its presence is checked
- Network checks or remote validation of any kind
- A `--fix` flag or any interactive mode
- Modifications to `project-audit` dimensions (no new D11 dimension)

## Proposed Approach

The skill follows the established `project-audit` pattern: a procedural SKILL.md that Claude reads and executes step-by-step, collecting findings, then writing a structured report. No new tooling or external dependencies are required — Claude reads the filesystem directly.

The skill will:
1. Detect runtime mode (global: `~/.claude/` auditing from outside `claude-config`; global-config: auditing from inside the `claude-config` repo itself — the two overlap post-install)
2. Normalize OS-specific home paths at the start of execution
3. Run 5 audit checks sequentially, accumulating findings with severity levels
4. Emit a Markdown report with a summary scorecard, prioritized findings table, and per-finding remediation hints
5. Report location: `~/.claude/claude-folder-audit-report.md` (runtime artifact — never committed)

The report structure mirrors `audit-report.md` for consistency, but is intentionally simpler: no numeric scoring, just HIGH / MEDIUM / LOW findings with remediation commands.

## Affected Areas

| Area/Module | Type of Change | Impact |
|-------------|----------------|--------|
| `skills/claude-folder-audit/` | New | High — new capability |
| `CLAUDE.md` Skills Registry | Modified — add new entry | Low — additive only |
| `~/.claude/claude-folder-audit-report.md` | New (runtime artifact, not in repo) | Low — read-only output |
| `project-onboard/SKILL.md` | Modified — add non-blocking cross-reference to this skill | Low — informational hint only |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Drift detection is imprecise (uses mtime as proxy) | High | Low | Document limitation explicitly in the report; recommend running `install.sh` as the safe default when uncertain |
| User has manually customized files in `~/.claude/` | Medium | Medium | Report manual overrides as "preserve on next install.sh" — never suggest deletion; severity capped at MEDIUM |
| Windows path resolution failures | Medium | Medium | Normalize `~` at skill start using `$HOME` env var; test on Windows 11 explicitly |
| Scope tier compliance check generates false positives | Low | Low | Limit scope check to verifiable facts (same skill name in both tiers); document that intentional global overrides are expected for core skills |
| Report file grows unbounded across runs | Low | Low | Skill always overwrites (not appends) the report file on each run |

## Rollback Plan

This change is fully reversible:

1. Delete `skills/claude-folder-audit/` from the repo
2. Remove the Skills Registry entry from `CLAUDE.md`
3. Revert the `project-onboard/SKILL.md` cross-reference (if added)
4. Run `install.sh` to propagate deletions to `~/.claude/`
5. Optionally delete `~/.claude/claude-folder-audit-report.md` (runtime artifact — safe to delete at any time)

No data is modified by the skill itself, so there is no risk of data loss from the skill's operation. Rollback only requires reverting the skill definition files.

## Dependencies

- `install.sh` must be understood by the skill as the source-of-truth deployment mechanism (the skill reads it to understand the expected `~/.claude/` layout)
- ADR 008 (scope tier compliance rules) must be readable by the implementer — it is already in `docs/adr/`
- No new external tools required; Claude's native file-read capability is sufficient

## Success Criteria

- [ ] `skills/claude-folder-audit/SKILL.md` exists and passes `project-audit` D4 (format compliance: `procedural`, with `**Triggers**`, `## Process`, `## Rules`)
- [ ] Running the skill on the `claude-config` project produces `~/.claude/claude-folder-audit-report.md` with at least one finding in each severity category (HIGH, MEDIUM, LOW) or an explicit "No findings" message per category
- [ ] The report correctly identifies at least one known drift condition (e.g., a skill present in the repo but absent from `~/.claude/skills/`, or vice versa)
- [ ] The skill does NOT create, modify, or delete any file other than the report output
- [ ] The skill handles Windows paths without error (tilde expansion, backslash vs. forward slash)
- [ ] `CLAUDE.md` Skills Registry contains the new entry and `project-audit` D1 passes after `install.sh`
- [ ] `project-onboard/SKILL.md` includes a non-blocking hint to run `/claude-folder-audit` when installation drift is suspected

## Effort Estimate

Medium (1–2 days): The skill logic is well-bounded, the output format is established, but the 5-check audit implementation and Windows path handling require careful attention.
