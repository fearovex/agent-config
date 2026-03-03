# Exploration: claude-folder-audit

## Current State

The claude-config repo is a **global configuration meta-system** for Claude Code with 44 skills deployed
to `~/.claude/` via `install.sh`. There is currently **no skill that audits the runtime `~/.claude/` folder itself**.

`project-audit` (10 dimensions) audits **project-level configuration** (CLAUDE.md, openspec/, ai-context/,
project-local skills). It does NOT validate:
- Whether `~/.claude/` is in sync with the source repo
- Installation drift after repo updates
- Orphaned or stale files in the runtime folder
- Global skill catalog integrity
- Scope tier compliance (global vs. project-local skill placement — ADR 008)

## Affected Areas

| File/Module | Impact | Notes |
|-------------|--------|-------|
| `skills/project-audit/SKILL.md` | Complement with cross-reference suggestion | D1–D6 failures may indicate install drift |
| `skills/project-onboard/SKILL.md` | Add non-blocking Check 7 | Detect runtime out-of-sync |
| `CLAUDE.md` Skills Registry | New entry under "System Audits" | Register new skill |
| `~/.claude/` (runtime) | Primary audit target | Read-only analysis |
| `install.sh` | Reference for deployment source of truth | Skill reads it to understand expected layout |

## Analyzed Approaches

### Approach A: `claude-folder-audit` — Read-only diagnostic skill

**Description**: A procedural skill that reads `~/.claude/` and the repo, compares them, and generates
a human-readable report with prioritized recommendations. No auto-fix — outputs to `~/.claude/claude-folder-audit-report.md`.

**Pros**:
- Safe (read-only, non-destructive)
- Composable with existing workflow (run before `install.sh`, after `project-audit` failures)
- Follows exact pattern of `project-audit`
- Can be used for both global-config and any project with `.claude/` local skills

**Cons**:
- Requires a companion `claude-folder-fix` skill to auto-remediate (not in scope now)
- Drift detection is approximate (uses file mtimes as proxy for "last install run")

**Estimated effort**: Medium

**Risk**: Low

### Approach B: Extend `project-audit` with D11 — runtime validation dimension

**Description**: Add an 11th dimension to project-audit that validates runtime installation state.

**Pros**:
- Single command covers everything
- No new skill to learn

**Cons**:
- project-audit already has complex scope; adding runtime auditing increases surface area
- Runtime audit has different target (`~/.claude/`) vs. project audit (project root)
- Hard to run runtime audit independently
- Violates single-responsibility principle

**Estimated effort**: Low (but wrong architecture)

**Risk**: Medium (increases project-audit complexity)

### Approach C: `claude-folder-audit` + auto-fix mode

**Description**: Same as A but with a `--fix` flag that auto-applies safe corrections (re-run install.sh,
delete stale artifacts, etc.).

**Pros**:
- More powerful — one step diagnosis + remediation

**Cons**:
- Higher risk of destroying user customizations in `~/.claude/`
- Harder to implement safely — requires careful classification of "safe to auto-fix" vs "needs human review"
- Scope creep for V1

**Estimated effort**: High

**Risk**: Medium-High

## Recommendation

**Approach A** — a standalone read-only `claude-folder-audit` skill — is the right V1 approach.
It follows the established `project-audit` pattern, is safe, and fills a clear gap in the meta-system.
Auto-fix can be added later as `claude-folder-fix` (same pattern as `project-audit` + `project-fix`).

## Process Steps

1. **Detect mode**: project vs. global-config (adjust expected layout accordingly)
2. **Validate `~/.claude/` structure**: required dirs (skills/, openspec/, ai-context/, memory/, hooks/)
3. **Audit skill deployment**: for each skill in source → check deployed state, compare versions
4. **Scan stale artifacts**: files >90 days old, orphans not matching expected artifact types
5. **Detect installation drift**: compare repo mtime vs. `~/.claude/` mtime
6. **Scope tier compliance**: detect skill duplication across global + project-local tiers
7. **Generate report**: write `~/.claude/claude-folder-audit-report.md` with prioritized recommendations

## Output Artifact

`~/.claude/claude-folder-audit-report.md` — runtime artifact, not committed to repo.

## Identified Risks

- **Scope creep**: Keep V1 strictly read-only. Document `claude-folder-fix` as V2.
- **User customizations in `~/.claude/`**: Report manual overrides as "preserve on next install.sh" — never auto-delete.
- **Global-config mode**: When the current project IS the claude-config repo, `~/.claude/skills/` and `skills/` are equivalent post-deployment. Skill must detect and document this.
- **install.sh tracking**: No metadata file tracks "last deploy time". Use `~/.claude/` dir mtime as proxy. Consider adding `~/.claude/.installed-at` as future improvement.
- **Orphaned openspec/ changes**: Report as "work-in-progress" — never delete.

## Open Questions

- Should the report live at `~/.claude/` or `.claude/` (project-root subfolder)?
  Recommendation: `~/.claude/` (runtime artifact, not committed).
- Should the skill handle Windows paths for `~/.claude/` (e.g., `C:\Users\juanp\.claude\`)?
  Recommendation: Yes — detect OS and normalize paths. User is on Windows 11.
- Should there be a `claude-folder-fix` companion in this same SDD cycle or separately?
  Recommendation: Separately, after V1 is stable.

## Ready for Proposal

Yes — the gap is clear, the approach is defined, and the scope is well-bounded.
