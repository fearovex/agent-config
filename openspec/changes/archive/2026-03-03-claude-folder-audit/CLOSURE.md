# Closure: claude-folder-audit

Start date: 2026-03-03
Close date: 2026-03-03

## Summary

Created the `claude-folder-audit` skill — a new read-only diagnostic tool that audits the `~/.claude/` runtime folder for installation drift, skill deployment gaps, orphaned artifacts, and scope tier compliance. The skill produces a structured Markdown report at `~/.claude/claude-folder-audit-report.md` and is registered in CLAUDE.md under a new "System Audits" section.

## Modified Specs

| Domain | Action | Change |
|--------|--------|--------|
| folder-audit-execution | Created | New master spec: 5-check execution behavior — mode detection, path normalization, Check 1–5 requirements, read-only constraint |
| folder-audit-reporting | Created | New master spec: report file location, header structure, severity levels, findings table, remediation hints, CLAUDE.md registration, project-onboard integration |

## Modified Code Files

- `skills/claude-folder-audit/SKILL.md` — created (new skill, format: procedural, 5 audit checks: runtime structure, skill deployment, drift detection, orphaned artifacts, scope tier compliance)
- `CLAUDE.md` — added `### System Audits` section to Skills Registry with entry for `~/.claude/skills/claude-folder-audit/SKILL.md`
- `skills/project-onboard/SKILL.md` — added non-blocking Check 7 (global-config mode only): drift hint to run `/claude-folder-audit`
- `docs/adr/009-claude-folder-audit-pattern.md` — created (architectural decision: standalone skill vs. D11 extension of project-audit)
- `docs/adr/README.md` — ADR-009 row appended

## Key Decisions Made

- **Standalone skill pattern** chosen over extending project-audit with a D11 dimension — single-responsibility, independently invocable from any context (not only from within a project with project-audit artifacts)
- **Report location `~/.claude/`** — runtime artifacts from global-config tooling belong in the runtime root, not the project directory or openspec/
- **mtime-based drift detection** — no `.installed-at` file exists yet; mtime is an imprecise proxy. Documented limitation. A future `install.sh` enhancement can add `.installed-at` for precise comparison.
- **V1 is read-only** — no auto-fix; companion `claude-folder-fix` skill deferred to a future SDD cycle
- **Mode detection via `install.sh` + `skills/` presence** — more robust than the `install.sh` + `sync.sh` criterion originally specified in design.md (sync.sh may not exist in all valid configurations); functional outcome identical for this repo
- **Check 4 false-positive noise is a known limitation** — 17 Claude Code internal runtime files (cache/, telemetry/, projects/, etc.) not in the expected-set allowlist generate MEDIUM findings; accepted for V1 with a note in the report; allowlist improvement deferred to V2

## Lessons Learned

- Design.md specified mode detection via `install.sh + sync.sh`; implementation used `install.sh + skills/` which is semantically stronger. The spec was updated correctly but design.md was not retroactively updated. Future cycles: when the implementation deviates from design (even for good reason), update design.md during the apply phase to avoid coherence warnings in verify.
- Check 4 (orphaned artifact detection) will produce noise on any standard Claude Code installation due to internal operational files. The allowlist must be pre-populated with known Claude Code runtime paths before deploying the skill in environments other than this repo. This is a V1 known limitation that should become V2 scope.
- The verify report lacked the "User Documentation" checkbox introduced in a recent SDD cycle update. The skill pre-dates the requirement for this checkbox, so it is ABSENT (not UNCHECKED) — no action required.

## User Docs Reviewed

N/A — change does not add new user-facing commands or workflows to scenarios.md, quick-reference.md, or onboarding.md. The skill is registered in CLAUDE.md (machine-readable registry) and project-onboard/SKILL.md (non-blocking hint), which are not user documentation files.
