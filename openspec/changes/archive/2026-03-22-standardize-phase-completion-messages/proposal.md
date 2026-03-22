# Proposal: Standardize Phase Completion Messages to Natural Language

Date: 2026-03-22
Status: Draft

## Intent

Standardize all SDD phase skill completion messages to use natural language confirmation gates instead of command-as-gate patterns, ensuring a consistent user experience across the entire SDD cycle.

## Motivation

After implementing natural language gates in sdd-apply and sdd-ff Step 4, the remaining phase skills (sdd-verify, sdd-archive, and potentially others) still use the old pattern:

  "Ready to archive. Run: /sdd-archive <slug>"

This creates an inconsistent UX where some phases ask naturally ("Continue? Reply yes") and others require the user to copy-paste a command. The goal is a uniform experience across all phase boundaries.

## Supersedes

None — this is a purely additive change. The command references are not removed, only demoted to secondary references beneath the natural language gate.

## Scope

### Included

- `skills/sdd-verify/SKILL.md` — replace final "Run: /sdd-archive <slug>" with natural language gate
- `skills/sdd-archive/SKILL.md` — replace any command-as-gate completion messages with natural language gate
- Audit all other phase skills (sdd-explore, sdd-propose, sdd-spec, sdd-design, sdd-tasks) for the same pattern and fix any found

### Excluded (explicitly out of scope)

- sdd-apply: already updated (natural language gate in place)
- sdd-ff Step 4: already updated (natural language gate in place)
- Changes to phase logic, output format, or behavioral contracts — wording only
- Spec domain changes — no behavioral requirements are altered

## Proposed Approach

For each affected skill, replace command-as-gate completion messages:

  "Ready to proceed. Run: /sdd-<next-phase> <slug>"

With a two-line natural language pattern:

  "Continue with <next phase>? Reply **yes** to proceed or **no** to pause."
  "(Manual: /sdd-<next-phase> <slug>)"

The command remains visible as a secondary reference — not removed, only demoted. This maintains discoverability for users who prefer explicit commands while making the default interaction conversational.

## Affected Areas

| Area/Module | Type of Change | Impact |
| ----------- | -------------- | ------ |
| skills/sdd-verify/SKILL.md | Modified | Low |
| skills/sdd-archive/SKILL.md | Modified | Low |
| skills/sdd-explore/SKILL.md | Modified (if pattern found) | Low |
| skills/sdd-propose/SKILL.md | Modified (if pattern found) | Low |
| skills/sdd-spec/SKILL.md | Modified (if pattern found) | Low |
| skills/sdd-design/SKILL.md | Modified (if pattern found) | Low |
| skills/sdd-tasks/SKILL.md | Modified (if pattern found) | Low |

## Risks

| Risk | Probability | Impact | Mitigation |
| ---- | ----------- | ------ | ---------- |
| Inconsistent wording across phases after edit | Low | Medium | Define exact template string and apply uniformly |
| Users who prefer commands find them harder to spot | Low | Low | Commands remain as "(Manual: ...)" secondary reference |

## Rollback Plan

Revert the specific lines changed in each SKILL.md file via `git checkout HEAD~1 -- skills/sdd-*/SKILL.md` and redeploy with `bash install.sh`.

## Dependencies

- None — all target files already exist and the pattern to apply is already proven in sdd-apply and sdd-ff

## Success Criteria

- [ ] All phase completion messages use natural language gate pattern ("Continue with X? Reply **yes** to proceed or **no** to pause.")
- [ ] Commands remain as secondary references ("(Manual: /sdd-<phase> <slug>)") — not removed
- [ ] Consistent wording across all phases — same template string
- [ ] sdd-apply and sdd-ff Step 4 remain unchanged (already correct)

## Effort Estimate

Low (hours) — wording-only changes across 5-7 SKILL.md files.

## Context

Recorded from conversation at 2026-03-22:

### Explicit Intents

- **Standardization**: user observed sdd-verify still shows "Ready to archive. Run: /sdd-archive <slug>" after sdd-apply was already updated
- **Companion cleanup**: this change follows the orchestrator-natural-language change already archived

### Provisional Notes

- **Audit scope**: the exact set of affected files depends on the audit — sdd-explore, sdd-propose, sdd-spec, sdd-design, and sdd-tasks need to be checked for the pattern before confirming which ones require changes
