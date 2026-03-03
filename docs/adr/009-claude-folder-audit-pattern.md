# ADR-009: Claude Folder Audit Pattern

## Status

Proposed

## Context

The `claude-folder-audit` skill needs to audit the `~/.claude/` runtime folder for installation
drift, skill deployment completeness, orphaned artifacts, and scope tier compliance. The project
already has a well-established pattern for read-only diagnostic skills: `project-audit`. The
question was whether to create a new standalone skill following that pattern, or to extend
`project-audit` with an additional dimension (D11) covering runtime state.

Extending `project-audit` would combine two different audit targets (`~/.claude/` runtime vs.
project-level configuration) into a single skill, increasing its surface area and making runtime
auditing dependent on project context always being available. A standalone skill is independently
invocable and preserves single-responsibility.

## Decision

We will implement `claude-folder-audit` as a standalone procedural SKILL.md following the existing
`project-audit` pattern: sequential checks that accumulate findings, followed by a structured
Markdown report. The skill is read-only. It uses the same path-normalization strategy as
`install.sh` (priority chain: `$HOME`, `USERPROFILE`, `HOMEDRIVE+HOMEPATH`) to handle Windows,
WSL, and Linux/macOS uniformly. The output report is written to `~/.claude/claude-folder-audit-report.md`
(a runtime artifact, never committed). Severity levels are HIGH / MEDIUM / LOW (not numeric scores),
consistent with the simpler scope of this audit.

## Consequences

**Positive:**

- The skill is independently invocable without requiring a project-level CLAUDE.md or openspec/ structure
- Single-responsibility is maintained: `project-audit` covers project configuration; `claude-folder-audit` covers runtime installation state
- Reusing the `install.sh` path-normalization pattern keeps OS-handling consistent and avoids a new convention
- A companion `claude-folder-fix` skill can be added later using the same `project-audit` / `project-fix` pairing pattern

**Negative:**

- Drift detection relies on file modification times (mtime), which is an imprecise proxy for "last install run" — requires a documented limitation in the report
- A `claude-folder-fix` companion skill (auto-remediation) is out of scope for V1, so the audit is diagnosis-only
- Users must run the skill manually; there is no automated trigger (no hook integration in V1)
