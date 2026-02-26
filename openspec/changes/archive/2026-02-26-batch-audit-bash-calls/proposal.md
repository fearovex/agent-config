# Proposal: batch-audit-bash-calls

Date: 2026-02-26
Status: Draft

## Intent

Consolidate the dozens of separate read-only shell checks in the `/project-audit` skill into a single batched Bash script execution (plus pre-approved Bash permissions in settings.json), eliminating the 20+ individual user approval interruptions that make the audit unusable in default permission mode.

## Motivation

Currently, `/project-audit` executes its 9-dimension diagnostic by issuing dozens of individual Bash tool calls (ls, grep, cat, wc -l, find, etc.). In Claude Code's default permission mode, **every Bash call requires a user approval click**. A single audit run generates 20–40 approval prompts, making the workflow practically unusable without "allow all" mode.

The root cause is architectural: the skill's process is described as a series of human-readable checks, but each check maps to a separate shell invocation at execution time. There is no batching or aggregation strategy.

Two complementary fixes are needed:
1. **Skill-level**: Rewrite the audit's shell-check steps to emit a single self-contained shell script that runs all read-only discovery in one Bash call, returning structured output (JSON or key=value).
2. **Settings-level**: Add a `Bash` entry to the `permissions.allow` list in `settings.json` so that read-only Bash calls are pre-approved globally (complementing the existing `Read`, `Glob`, `Grep` entries).

Both fixes together ensure that running `/project-audit` on any project requires zero mid-run approval clicks.

## Scope

### Included
- Update `skills/project-audit/SKILL.md` to specify a single-script Bash execution strategy for all shell-based discovery (file existence, line counts, directory listings, grep searches, orphaned change detection)
- Add `Bash` to the `permissions.allow` array in `settings.json`
- Document in the skill's Execution Rules that Bash calls must be batched: all discovery in one call, all grep searches in a second call if needed, never more than 3 Bash calls per audit run
- Ensure the batched output format is defined so the skill can parse it deterministically

### Excluded (explicitly out of scope)
- Changing the audit's scoring logic, dimensions, or report format — those are separate concerns
- Adding new audit checks or modifying existing check criteria
- Modifying any other skill besides `project-audit`
- Changing the `alwaysThinkingEnabled`, `effortLevel`, or `model` fields in settings.json
- Adding MCP server permissions — only the Bash tool permission is added

## Proposed Approach

The skill's process will be restructured around a **two-phase Bash strategy**:

**Phase A — Discovery script** (1 Bash call): A shell script emitted inline by Claude collects all structural facts about the project: existence of key files, line counts, directory listings, content searches. It outputs `key=value` lines or a JSON object that Claude then reads and uses for all dimension checks.

**Phase B — Content reads** (Read tool, Glob tool, Grep tool — already pre-approved): Individual file reads using the already-approved tools (Read, Glob, Grep) for content analysis that requires seeing the actual text.

The `settings.json` change adds `Bash` to `permissions.allow` so the discovery script runs without a prompt. This aligns with the existing pattern (Read, Glob, Grep are already pre-approved) and is safe because: (a) the audit skill is explicitly read-only, (b) the Bash calls will not contain write operations.

The SKILL.md update will add an explicit **Execution Rules** entry stating: "All shell-based discovery MUST be consolidated into a single Bash script call. Never issue individual ls/grep/wc calls separately."

## Affected Areas

| Area/Module | Type of Change | Impact |
|-------------|----------------|--------|
| `skills/project-audit/SKILL.md` | Modified — add batching strategy section and update execution rules | High (changes how the skill executes) |
| `settings.json` | Modified — add `Bash` to `permissions.allow` | Medium (affects all Claude Code sessions globally) |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Batched script becomes too complex and Claude hallucinates output parsing | Medium | Medium | Define exact output format (key=value) in SKILL.md; include a concrete script template example |
| Adding `Bash` to global permissions allows destructive operations in other skills | Low | High | The permission covers tool-level approval only; skills that perform writes already require it; the audit skill's read-only rule is enforced by SKILL.md, not by permissions |
| SKILL.md update inadvertently breaks the report format or scoring logic | Low | Medium | The proposal is scoped to execution strategy only — no changes to dimensions, checks, or report format |
| Windows path differences in batched script | Low | Low | Script template should use cross-platform-compatible commands (test -f, wc -l, find with -maxdepth) or note Windows alternatives |

## Rollback Plan

1. **settings.json**: Remove `"Bash"` from `permissions.allow`. The file is version-controlled; `git checkout settings.json` restores the previous state.
2. **skills/project-audit/SKILL.md**: Revert to the previous version with `git checkout skills/project-audit/SKILL.md`.
3. Run `install.sh` to deploy the reverted files to `~/.claude/`.
4. Verify with a `/project-audit` run that the original (multi-call) behavior is restored.

No database migrations, no deployed artifacts, no external state to revert.

## Dependencies

- No external dependencies — both affected files are self-contained in the repo
- `install.sh` must be run after apply to deploy changes to `~/.claude/`
- The Audiio V3 project (D:/Proyectos/Audiio/audiio_v3_1) is available as the canonical test target

## Success Criteria

- [ ] Running `/project-audit` on the Audiio V3 project completes without any Bash approval prompts (0 mid-run interruptions)
- [ ] `settings.json` contains `"Bash"` in the `permissions.allow` array
- [ ] `skills/project-audit/SKILL.md` contains an explicit rule: shell discovery must be batched into a single Bash call
- [ ] The audit report produced after the change is structurally identical to reports produced before (same dimensions, same format)
- [ ] `/project-audit` run on claude-config itself scores >= the score recorded in the current `audit-report.md`

## Effort Estimate

Low (hours) — both changes are localized: one SKILL.md section addition + one JSON key addition.
