# Technical Design: claude-folder-audit

Date: 2026-03-03
Proposal: openspec/changes/claude-folder-audit/proposal.md

## General Approach

The skill follows the established `project-audit` pattern: a procedural SKILL.md that Claude reads and
executes step-by-step, performing file-system reads against both the source repo and the `~/.claude/`
runtime directory. It accumulates findings with severity levels (HIGH / MEDIUM / LOW), then writes a
Markdown report. No external tools or new infrastructure are required. The skill is self-contained: it
uses Claude's native file-read capability and the same path-normalization pattern already proven in
`install.sh`.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|---------------|
| Pattern for the new skill | Mirror `project-audit` procedural pattern — step-by-step checks, accumulate findings, write report | Extending project-audit with a D11 dimension; adding a separate agent/script | The `project-audit` pattern is the established, well-understood convention for read-only diagnostic skills. Extending it would violate single-responsibility and make runtime auditing dependent on project-context always being available. A standalone skill is independently invocable. |
| Report output location | `~/.claude/claude-folder-audit-report.md` (runtime artifact, never committed) | Project root `.claude/audit-report.md`; stdout only | Runtime artifacts from global-config tooling belong in `~/.claude/`. The file is transient and user-facing, not version-controlled. Mirrors `audit-report.md` convention. |
| OS path normalization | Inline path-detection step at skill start, replicating `install.sh` priority chain (`$HOME`, `USERPROFILE`, `HOMEDRIVE+HOMEPATH`) | Rely on shell `~` expansion; require user to set `CLAUDE_DIR` env var | `install.sh`'s detection strategy is already tested on Windows 11 / Git Bash. Reusing it avoids new conventions. Tilde expansion is unreliable in Claude-driven bash commands on Windows. |
| Drift detection signal | File modification-time comparison between repo skill files and `~/.claude/skills/` equivalents | Manifest file (`.installed-at`); git commit hash comparison | mtime is the only available signal without adding new infrastructure. Documented limitation: mtimes are approximate. A future `.installed-at` file remains an open improvement (noted as LOW finding if absent). |
| Scope tier compliance | Check: same skill name exists in both `~/.claude/skills/` AND a project-local `.claude/skills/` | Full content diff between tiers; lint for duplicated trigger text | Per ADR-008, duplication is a known and expected pattern for project-local overrides of global skills. The check only flags it; it does not enforce removal. Severity: MEDIUM. |
| Severity system | Three levels: HIGH (blocks install integrity), MEDIUM (risk of drift or confusion), LOW (informational best-practice gap) | Numeric scoring (like project-audit); pass/fail only | Numeric scoring is `project-audit`'s convention. `claude-folder-audit` is simpler; HIGH/MEDIUM/LOW with remediation hints is sufficient and keeps the report readable. |
| Global-config mode detection | Check if `install.sh` + `sync.sh` exist at the current project root; if yes, repo IS the config source | Always treat `~/.claude/` as external; require user flag | This is the exact detection used in `project-audit` D1. Reusing it maintains convention consistency. |

## Data Flow

```
User invokes /claude-folder-audit
          |
          v
Step 1 — Path normalization
  Detect OS (Windows / Linux / macOS)
  Resolve CLAUDE_DIR = ~/.claude/ (using install.sh priority chain)
  Resolve REPO_DIR = current project root (if global-config mode)
          |
          v
Step 2 — Mode detection
  IF install.sh + sync.sh exist at project root → mode: global-config
  ELSE                                          → mode: external-project
          |
          v
Step 3 — Audit checks (sequential)
  Check 1: Runtime structure   → findings[]
  Check 2: Skill deployment    → findings[]
  Check 3: Installation drift  → findings[]
  Check 4: Orphaned artifacts  → findings[]
  Check 5: Scope tier          → findings[]
          |
          v
Step 4 — Report generation
  Partition findings by severity (HIGH / MEDIUM / LOW)
  Write ~/.claude/claude-folder-audit-report.md
          |
          v
Step 5 — Summary output to user / orchestrator
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `skills/claude-folder-audit/SKILL.md` | Create | New skill: 5-check procedural audit of `~/.claude/` runtime folder |
| `CLAUDE.md` | Modify | Add new "System Audits" section in Skills Registry with entry for `claude-folder-audit` |
| `skills/project-onboard/SKILL.md` | Modify | Add non-blocking Check 7 (global-config mode only) with hint to run `/claude-folder-audit` when installation drift is suspected |
| `~/.claude/claude-folder-audit-report.md` | Create (runtime, not in repo) | Audit report — generated by running the skill; overwritten on each run; never committed |

## Interfaces and Contracts

### SKILL.md YAML frontmatter

```yaml
---
name: claude-folder-audit
description: >
  Audits the ~/.claude/ runtime folder for installation drift, skill deployment gaps,
  orphaned artifacts, and scope tier compliance. Read-only. Produces claude-folder-audit-report.md.
  Trigger: /claude-folder-audit, audit runtime, check installation drift, verify skill deployment.
format: procedural
---
```

### Audit finding schema (internal to SKILL.md prose)

```
Finding:
  severity: HIGH | MEDIUM | LOW
  check: 1..5
  title: short description
  detail: what was observed
  remediation: exact command or step to resolve
```

### Report output format

```markdown
# ~/.claude/ Audit Report

Date: [YYYY-MM-DD]
Mode: global-config | external-project
Repo: [absolute path, if global-config mode]

## Summary

| Severity | Count |
|----------|-------|
| HIGH     | N     |
| MEDIUM   | N     |
| LOW      | N     |

## Findings

### HIGH

- **[Check N] [Title]**
  Observed: [detail]
  Remediation: `[command]`

### MEDIUM

[same structure]

### LOW

[same structure]

## No findings

[Per-severity "No HIGH findings detected." when count is 0]
```

### project-onboard Check 7 contract (non-blocking, global-config mode only)

```
Check 7 — Runtime sync hint (global-config mode, non-blocking)

If mode == global-config:
  Append to any case diagnosis Warnings section:
    "- Run /claude-folder-audit to verify ~/.claude/ is in sync with this repo (installation drift check)."
  Do not change case assignment or stop processing.
```

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Manual / integration | Run skill on the claude-config repo — verify report contains at least one finding per severity category, or explicit "No findings" per category | Claude Code session + manual inspection |
| Manual | Introduce a known drift condition (rename a skill dir in `~/.claude/skills/`) — verify Check 2 surfaces it as HIGH | Manual filesystem manipulation |
| Manual | Verify no files are created, modified, or deleted other than the report | Directory diff before/after |
| Manual | Run on Windows 11 (Git Bash) — verify paths resolve without error and report is written to correct location | Git Bash session on the user's machine |

No automated test framework applies. Testing is done by executing the skill and inspecting outputs, consistent with how `project-audit` is tested.

## Migration Plan

No data migration required. This is a net-new skill with no changes to existing data structures, schemas, or persistent state.

## Open Questions

- Should `project-onboard` Check 7 (installation drift hint) apply in external-project mode (not just global-config)?
  Impact if not resolved: The hint fires only for the claude-config repo itself. External projects do not get the drift warning. Decision: keep it global-config mode only for V1 — external projects have no `install.sh` equivalent to run.

- Should a `.installed-at` timestamp file be created by `install.sh` to improve drift detection precision?
  Impact if not resolved: Drift detection remains mtime-based (approximate). Documented limitation in the report. Not blocking for V1 — note as a LOW finding when absent.
