# Proposal: user-docs-and-onboard-skill

Date: 2026-02-26
Status: Draft

## Intent

Add user-facing onboarding documentation and an automated diagnostic skill (`/project-onboard`) that reads the live project state and guides new users to the right starting command — closing the gap between a functional SDD toolchain and users who do not know where to begin.

## Motivation

The SDD toolchain is functionally complete: `project-setup`, `memory-init`, `project-audit`, and `project-fix` all work. `ai-context/onboarding.md` documents the canonical four-step sequence. However, three gaps remain that prevent users from self-onboarding without direct guidance:

**Gap A — No case-based entry point.**
`onboarding.md` assumes users start from a known state ("brand new project") and run the four-step sequence in order. In practice, users arrive at projects in one of six distinct states (no Claude config, partial SDD, stale changes, local skill clutter, etc.). There is no document that matches a user's current situation to the correct first command. Users either run `project-setup` on a project that already has a partial SDD and produce duplicated content, or they run `project-audit` on a brand-new project and receive a confusing 0-point report with no remediation path.

**Gap B — No automated diagnostic.**
The only way to determine "which case am I in" is to manually inspect the project directory structure. There is no `/project-onboard` command that reads the project and says "you are in Case 3 — you have openspec/ but ai-context/ is empty; run these commands in order." The user must know what to look for before they know what to do.

**Gap C — No quick-reference for returning users.**
Experienced users who know the system still need to look up the full SDD flow diagram, command glossary, or the `/sdd-ff` vs `/sdd-new` distinction. This information exists only in CLAUDE.md (the orchestrator config), which is not designed to be read as a reference card. There is no `quick-reference.md` they can open in ten seconds.

**Gap D — User docs go stale silently.**
Both the new documents and `onboarding.md` will drift out of accuracy as skills evolve. There is currently no mechanism that prompts a reviewer to update user-facing docs when a skill changes. Without a self-maintenance hook, the documents will be accurate at creation and progressively less accurate with each subsequent change.

## Scope

### Included

- **`ai-context/scenarios.md`** — a case-based guide covering 6 project states. Each case has: recognizable symptoms the user can observe, the exact command sequence to run, expected outcome per command, and common failure modes with recovery steps.

- **`skills/project-onboard/SKILL.md`** — a new skill triggered by `/project-onboard`. It reads the live project file system (no user questions), detects which of the 6 cases applies, explains findings in plain language, and recommends the exact command sequence. It warns about specific issues: stale docs, orphaned changes, local skill problems. Detection logic reads real files — it does not hardcode case matches against a static list, ensuring it stays accurate as the system evolves.

- **`ai-context/quick-reference.md`** — a single-page compact reference containing: a "your situation → first command" table, an ASCII diagram of the full SDD flow, a one-line-per-command glossary, and guidance on `/sdd-ff` vs `/sdd-new`. Intended for users who already know the system and want a 10-second lookup.

- **Self-maintenance mechanisms** — four lightweight hooks that prevent the new documents from going stale:
  1. `project-audit` D2 extended: adds existence and freshness checks for `scenarios.md` and `quick-reference.md` (LOW severity if missing or last-verified date > 90 days).
  2. `sdd-archive` checklist: when archiving a change that touches skill behavior or workflows, the verify-report.md must include a checkbox: `[ ] Review user docs (scenarios.md / quick-reference.md / onboarding.md) if this change affects user-facing workflows`.
  3. `project-update` skill extended: detects stale user docs (last-verified date > 90 days) and offers to regenerate them as part of the update pass.
  4. `project-onboard` skill design: detection logic reads real file state — avoids hardcoded case logic — so it remains accurate without manual maintenance of case definitions.

- **Update `CLAUDE.md` Skills Registry**: add `project-onboard` to the meta-tools skill registry so it is discoverable from the orchestrator.

- **Update `ai-context/architecture.md`**: add `scenarios.md`, `quick-reference.md`, and `skills/project-onboard/SKILL.md` to the artifact and skill tables.

### Excluded (explicitly out of scope)

- **Interactive diagnostic wizard**: `/project-onboard` reads the file system and produces a diagnosis without asking the user any questions. A multi-turn interactive diagnostic (question-answer flow) is explicitly excluded — it adds complexity and the file-reading approach is sufficient.
- **Automated remediation in `/project-onboard`**: The skill diagnoses and recommends; it does not execute fix commands on behalf of the user. Execution remains with the user-initiated commands (`project-setup`, `memory-init`, etc.).
- **Translation of `onboarding.md` to other languages**: `onboarding.md` already exists in English. This change does not add multilingual variants — the unbreakable rule (English only) applies.
- **Modifying the 100-point audit scoring formula**: The D2 freshness checks for `scenarios.md` and `quick-reference.md` emit LOW severity findings only. They do not deduct from the existing score in this iteration.
- **Retroactive update of archived verify-reports**: The new `sdd-archive` checklist item applies to future archives only, not existing archived changes.

## Proposed Approach

**`ai-context/scenarios.md` structure:**

Each of the 6 cases follows a fixed template:
```
### Case N — [Label]
**Symptoms**: [what the user observes in the file system or CLI output]
**Command sequence**: [ordered list of commands]
**Expected outcome per command**: [one line each]
**Common failure modes**: [table with failure + recovery]
```

Cases:
1. Brand-new project — no `.claude/` or `CLAUDE.md` at all
2. Has CLAUDE.md but no SDD (`openspec/` or `ai-context/` absent)
3. Has partial SDD (`openspec/` exists but `ai-context/` is empty or missing files)
4. Has local `.claude/skills/` that need review (duplicates, outdated, non-English)
5. Has SDD but changes are orphaned or stale (`openspec/changes/` has entries without `tasks.md` or `verify-report.md`)
6. Fully configured — wants to start a new feature

**`skills/project-onboard/SKILL.md` detection algorithm:**

The skill checks real file-system state in this priority order:
1. Does `.claude/CLAUDE.md` exist? (If not → Case 1)
2. Does `openspec/config.yaml` exist AND does `ai-context/` exist with populated files? (Determines partial vs full SDD)
3. Does `.claude/skills/` exist with skill directories? (Triggers local skill review check using same heuristics as project-audit D9)
4. Does `openspec/changes/` contain directories missing `tasks.md` or `verify-report.md`? (Orphaned changes check)
5. If all present and healthy → Case 6

The skill emits a structured diagnosis block then a recommended command sequence. No hardcoded case IDs are embedded — the diagnosis is derived from the observed file state.

**`ai-context/quick-reference.md` structure:**

1. Situation table (5 rows): symptom → first command
2. SDD flow ASCII diagram (reused from CLAUDE.md)
3. Command glossary: one line per command, alphabetical
4. `/sdd-ff` vs `/sdd-new` decision rule

**Self-maintenance hooks:**

- `project-audit` D2 addition: two new sub-checks (existence of `ai-context/scenarios.md` and `ai-context/quick-reference.md`; freshness of their `Last verified:` date field). Findings emitted as `LOW`.
- `sdd-archive` SKILL.md: add a mandatory checkbox item to the verify-report template embedded in the skill.
- `project-update` SKILL.md: add a stale-doc detection step (read `Last verified:` from each doc, compare to today, offer regeneration if > 90 days).

## Affected Areas

| Area/Module | Type of Change | Impact |
|-------------|----------------|--------|
| `ai-context/scenarios.md` | New file | Low |
| `ai-context/quick-reference.md` | New file | Low |
| `skills/project-onboard/SKILL.md` | New skill directory + file | Medium |
| `skills/project-audit/SKILL.md` | Modified — D2 extended with 2 sub-checks | Low |
| `skills/sdd-archive/SKILL.md` | Modified — verify-report template gets one checkbox | Low |
| `skills/project-update/SKILL.md` | Modified — stale-doc detection step added | Low |
| `CLAUDE.md` | Modified — Skills Registry adds project-onboard | Low |
| `ai-context/architecture.md` | Modified — artifact table updated | Low |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| `project-onboard` detection logic produces false case assignments (e.g., classifies a partial SDD as Case 1) | Medium | Medium | Use a strict priority-order check (not heuristic matching). Unit-test the logic against the six cases during verify phase using real project snapshots. |
| D2 freshness check rejects recently-created docs because the `Last verified:` field is absent or malformed | Low | Low | The check reads the field defensively — if absent, it emits a LOW finding with "field not found" rather than erroring. |
| `sdd-archive` checklist item is ignored in practice (checkbox remains unchecked) | Medium | Low | The archive skill must verify at least one checkbox is checked before proceeding. The new checkbox is additive — it does not block archive if left unchecked, but it is surfaced in the verify-report for review. |
| Stale-doc regeneration in `project-update` overwrites manually curated content | Low | High | Regeneration is offered as an option, never automatic. The skill must confirm with the user before overwriting. |
| Adding project-onboard to CLAUDE.md increases orchestrator file size and complexity | Low | Low | The entry is one table row in the Skills Registry. No structural change to the orchestrator logic. |

## Rollback Plan

All changes are new files or additive edits to existing SKILL.md files:

1. **Delete new files**: `rm ai-context/scenarios.md ai-context/quick-reference.md skills/project-onboard/SKILL.md` and `rmdir skills/project-onboard`.
2. **Revert modified skills**: `git checkout HEAD~1 -- skills/project-audit/SKILL.md skills/sdd-archive/SKILL.md skills/project-update/SKILL.md CLAUDE.md ai-context/architecture.md`.
3. **Run `sync.sh`** to propagate reverts to `~/.claude/`.
4. **Run `install.sh`** to confirm the runtime directory is clean.

No external dependencies, no database changes, no API keys. Rollback is a pure file operation completable in under 5 minutes.

## Dependencies

- `ai-context/onboarding.md` must exist (confirmed: created by the `enhance-project-audit-skill-review` archived change on 2026-02-26).
- `skills/project-audit/SKILL.md` must be at the D9-extended version (confirmed: archived `enhance-project-audit-skill-review` applied D9 additions).
- `skills/sdd-archive/SKILL.md` must exist (confirmed: present in skills catalog).
- `skills/project-update/SKILL.md` must exist (confirmed: present in skills catalog).
- The project-audit score on `claude-config` must be >= 75 before starting (confirm with `/project-audit` before applying).

## Success Criteria

- [ ] `ai-context/scenarios.md` exists with exactly 6 cases, each containing: symptoms, command sequence, expected outcome per command, and a failure modes table.
- [ ] `ai-context/quick-reference.md` exists with: a situation table, an SDD flow ASCII diagram, a command glossary, and a `/sdd-ff` vs `/sdd-new` decision rule.
- [ ] `skills/project-onboard/SKILL.md` exists and triggers on `/project-onboard`. Running it on a project that has `openspec/` but no `ai-context/` produces a Case 3 diagnosis with the correct command sequence (no user questions asked).
- [ ] Running `/project-onboard` on a brand-new project (no `.claude/CLAUDE.md`) produces a Case 1 diagnosis recommending `/project-setup` as the first command.
- [ ] Running `/project-audit` on `claude-config` after applying this change produces D2 findings for `scenarios.md` and `quick-reference.md` existence sub-checks (passes, since the files will exist).
- [ ] `skills/sdd-archive/SKILL.md` includes the new user-docs review checkbox in its verify-report template.
- [ ] `skills/project-update/SKILL.md` includes a stale-doc detection step that reads the `Last verified:` date field from `scenarios.md`, `quick-reference.md`, and `onboarding.md`.
- [ ] `/project-audit` on `claude-config` after applying returns score >= current score (no regression).
- [ ] `sync.sh` completes without errors after all changes are applied.

## Effort Estimate

Medium (1-2 days) — two new documentation files (low complexity), one new skill (medium complexity due to detection logic), and four surgical edits to existing skills (low-to-medium each). Integration testing requires running `/project-onboard` against at least two real project states.
