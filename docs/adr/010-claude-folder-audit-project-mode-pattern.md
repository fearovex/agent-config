# ADR-010: Claude Folder Audit Project Mode Pattern

## Status

Proposed

## Context

The `claude-folder-audit` skill (ADR-009) was designed to audit the `~/.claude/` runtime
directory for installation drift, missing skills, and orphaned artifacts. Its original two modes
(`global-config` and `global`) both focus on the global runtime.

As the two-tier skill placement model (ADR-008) is adopted across projects, projects increasingly
have their own `.claude/` directories with a local CLAUDE.md and project-scoped skills. Running
`/claude-folder-audit` from such a project directory silently audits the global `~/.claude/`
instead — producing output entirely unrelated to the project's Claude configuration health.

There is no automated health check for the project-local Claude configuration tier: whether
`.claude/CLAUDE.md` exists, whether registered skills (global or local) are actually deployed,
whether local skill files have been orphaned from the registry, or whether skills overlap across
tiers. The Skills Registry in CLAUDE.md encodes this information, but no skill reads and
validates it.

Extending the existing `claude-folder-audit` skill with a `project` mode — activated when `.claude/`
is detected at the current working directory and no `install.sh`+`skills/` pair is present —
provides a consistent, single-command health check for the project-local tier without introducing
a new skill or changing the existing global modes.

## Decision

We will extend `skills/claude-folder-audit/SKILL.md` with a third execution mode (`project`)
inserted between `global-config` (priority 1) and `global` (priority 3) in the Step 2 mode
detection chain. The `project` mode activates when a `.claude/` directory exists at the current
working directory and the conditions for `global-config` mode are not met.

In `project` mode, the skill runs five project-specific checks (P1–P5) instead of the existing
five runtime checks:

- **P1**: `.claude/CLAUDE.md` existence and `## Skills Registry` section presence
- **P2**: Global-path registrations (`~/.claude/skills/<name>/`) verified against disk
- **P3**: Local-path registrations (`.claude/skills/<name>/`) verified against disk
- **P4**: Local skill directories in `.claude/skills/` not registered in CLAUDE.md (orphans)
- **P5**: Skills present in both `.claude/skills/` and `~/.claude/skills/` (scope tier overlap)

Skills Registry parsing uses path-fragment matching: lines containing `~/.claude/skills/`
classify as global-tier; lines containing `.claude/skills/` (without the leading `~/`) classify
as local-tier. The longer prefix (`~/`) is matched first to prevent misclassification.

The report is written to `<PROJECT_ROOT>/.claude/claude-folder-audit-report.md`. The existing
`global-config` and `global` modes remain entirely unchanged.

## Consequences

**Positive:**

- Projects using the two-tier skill placement model get a zero-friction health check via the
  same `/claude-folder-audit` command they already know.
- Skills Registry consistency (registrations vs. deployed files) is now automatically checkable
  without manual inspection of CLAUDE.md and disk contents.
- Mode detection is transparent: the report header always states `Mode: project`, `Mode: global-config`,
  or `Mode: global`, making it clear which audit was performed.
- Backwards compatibility is preserved: existing `global-config` and `global` modes are unchanged.

**Negative:**

- A user who wants a global audit from inside a project directory must `cd` to a neutral location
  first — the `project` mode takes priority over `global` whenever `.claude/` exists at CWD.
- Skills Registry parsing relies on path-fragment convention stability. If the CLAUDE.md Skills
  Registry format changes significantly (e.g., stops using path strings), the parser will need
  updating.
- The single SKILL.md file now contains three distinct code paths, increasing its length and
  the cognitive load of modifying it.
