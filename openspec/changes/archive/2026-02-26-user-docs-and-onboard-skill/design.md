# Technical Design: user-docs-and-onboard-skill

Date: 2026-02-26
Proposal: openspec/changes/user-docs-and-onboard-skill/proposal.md

## General Approach

Eight files are touched: two new `ai-context/` documentation files, one new skill directory + `SKILL.md`, four surgical edits to existing `SKILL.md` files, and one edit to `CLAUDE.md`. Every artifact is a pure Markdown/YAML text file — no code dependencies, no external tools, no database changes. All new skill content follows the exact `SKILL.md` structural convention already in use (`# name`, `> one-liner`, `**Triggers**`, process sections, `## Rules`). Existing skill modifications are strictly additive: new steps or sub-checks are appended to existing step lists; no existing content is removed or reordered. After all files are written, `install.sh` propagates changes to `~/.claude/`.

---

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|---------------|
| Detection algorithm in `project-onboard` | Priority-order file-system checks (strict waterfall) | Heuristic scoring, ML-based classification | A strict priority order guarantees determinism and exactly one case assignment per run. Heuristic scoring risks ambiguous ties between cases. The six cases are mutually exclusive by design — waterfall logic is sufficient and far simpler to test. |
| Case assignment output format | Structured block followed by recommendation list | Prose paragraph, interactive question-answer | A structured block (header + bullet list) is machine-readable and consistent with how other skill outputs look (FIX_MANIFEST pattern). Prose is harder to parse if consumed by a downstream sub-agent. Interactive Q&A is excluded by the proposal's explicit out-of-scope rule. |
| `Last verified:` freshness field in new docs | Single header field `> Last verified: YYYY-MM-DD` (same pattern as `onboarding.md`) | Separate YAML front-matter, separate `metadata.yaml` per doc | `onboarding.md` already uses `> Last verified: YYYY-MM-DD`. Reusing the identical pattern keeps the D2 freshness check logic simple: one regex, one parsing rule, three files. Introducing YAML front-matter would require a new parsing convention. |
| D2 freshness check threshold | 90 days | 30 days, 60 days, 180 days | Proposal specifies 90 days explicitly. User-facing reference docs are stable enough that 90-day reviews are reasonable without being burdensome. |
| D2 freshness findings severity | LOW | HIGH, MEDIUM | Proposal specifies LOW. These are optional quality indicators, not SDD blockers. Score deduction is explicitly excluded in this iteration. |
| `sdd-archive` user-docs checkbox | Non-blocking (surfaced, not enforced) | Blocking (must be checked to proceed) | Proposal explicitly states the checkbox must be surfaced but must not block archive if left unchecked. Blocking would create friction for changes that have no user-facing impact. |
| `project-update` stale-doc regeneration | Offer as option, require confirmation before writing | Automatic regeneration | Proposal rule: regeneration is never automatic. Consistent with the existing `project-update` rule: "NEVER overwrite without showing what changes and asking for confirmation." |
| New files written in `ai-context/` (not `docs/ai-context/`) | `ai-context/` directly | `docs/ai-context/` | `project-audit` D2 already checks `ai-context/` as the canonical path. `onboarding.md` lives at `ai-context/onboarding.md`. Placing new files in the same directory avoids a second location in the D2 check. |

---

## Data Flow

### `/project-onboard` execution flow

```
User runs /project-onboard in a project
         │
         ▼
  Read project-onboard/SKILL.md
         │
         ▼
  Check 1: Does .claude/CLAUDE.md exist?
         │ NO → Case 1 (brand-new)
         │ YES ↓
  Check 2: Does openspec/config.yaml exist?
         │ NO → Case 2 (CLAUDE.md but no SDD)
         │ YES ↓
  Check 3: Does ai-context/ exist with ≥ 3 populated files?
         │ NO → Case 3 (partial SDD — openspec/ present, ai-context/ sparse)
         │ YES ↓
  Check 4: Does .claude/skills/ exist with any subdirectories?
         │ YES → Case 4 (local skill review needed — add to findings)
         │ (non-blocking — continues to check 5)
         ↓
  Check 5: Does openspec/changes/ contain folders missing tasks.md
           or verify-report.md (not in archive/)?
         │ YES → Case 5 (orphaned / stale changes)
         │ NO ↓
  Check 6: All present and healthy → Case 6 (fully configured)
         │
         ▼
  Emit diagnosis block
         │
         ▼
  Emit recommended command sequence
         │
         ▼
  Emit warnings (stale docs, orphaned changes, local skill issues)
```

Note: Check 4 is non-blocking — a project can simultaneously be in Case 6 (healthy SDD) AND have local skill issues. The skill surfaces both.

### `project-audit` D2 freshness check extension

```
D2 execution (existing)
         │
         ▼
  [existing file checks for stack.md, architecture.md, etc.]
         │
         ▼
  NEW — Check: does ai-context/scenarios.md exist?
         │ NO → emit LOW finding: "scenarios.md missing"
         │ YES → read first 5 lines, search for "> Last verified: YYYY-MM-DD"
                  │ NOT FOUND → emit LOW: "Last verified field absent"
                  │ FOUND → parse date, compare to today
                             │ > 90 days → emit LOW: "scenarios.md stale (N days)"
                             │ ≤ 90 days → no finding
         ↓
  NEW — Check: does ai-context/quick-reference.md exist?
         │ (same logic as above)
         ▼
  [continues to D3]
```

### `sdd-archive` verify-report template extension

```
sdd-archive Step 1 — Verify it is archivable
         │
         ▼
  Read verify-report.md
         │
         ▼
  [existing critical-issue check]
         │
         ▼
  NEW — Surface user-docs checkbox to user:
  "verify-report includes user-docs review item —
   checked: [YES/NO/ABSENT]"
  (non-blocking — archive proceeds regardless)
         │
         ▼
  Step 2 — Confirm with user [unchanged]
```

### `project-update` stale-doc step

```
project-update Step 1 — Quick diagnosis (existing)
         │
         ▼
  NEW Step 1b — Stale-doc scan:
  Read "Last verified:" from:
    - ai-context/onboarding.md
    - ai-context/scenarios.md      (if exists)
    - ai-context/quick-reference.md (if exists)
  For each: compare date to today
    > 90 days → add to proposed changes as "REFRESH"
    file absent → skip (not in scope of project-update)
         │
         ▼
  Step 2 — Change plan (includes stale-doc items if any)
         │
         ▼
  Step 3 — Execution (offer regeneration; confirm before writing)
```

---

## File Change Matrix

| File | Action | What is added / modified |
|------|--------|--------------------------|
| `ai-context/scenarios.md` | Create | New file — 6-case onboarding guide with fixed template per case |
| `ai-context/quick-reference.md` | Create | New file — situation table, SDD flow ASCII, command glossary, `/sdd-ff` vs `/sdd-new` decision rule |
| `skills/project-onboard/SKILL.md` | Create (new dir) | New skill — triggered by `/project-onboard`; 5-check waterfall detection algorithm; structured diagnosis + recommendation output |
| `skills/project-audit/SKILL.md` | Modify | D2 section: add 2 sub-checks (existence + freshness of `scenarios.md` and `quick-reference.md`); LOW severity |
| `skills/sdd-archive/SKILL.md` | Modify | Step 1: add user-docs review checkbox surface step (non-blocking); Step 5 (closure note template): add `User Docs Reviewed` field |
| `skills/project-update/SKILL.md` | Modify | Step 1: add stale-doc scan sub-step; Step 2: change plan includes stale-doc items; Step 3: offer regeneration with confirmation |
| `CLAUDE.md` | Modify | Skills Registry meta-tools table: add one row for `project-onboard` |
| `ai-context/architecture.md` | Modify | Artifact table: add `scenarios.md`, `quick-reference.md`, `skills/project-onboard/SKILL.md` rows |

---

## Interfaces and Contracts

### `project-onboard` SKILL.md output contract

The skill emits a structured diagnosis block in this format:

```
## Diagnosis

Project state: [Case N — Label]

Detected:
- [observation 1]
- [observation 2]

Warnings:
- [warning if any, e.g. "stale docs", "orphaned changes", "local skill issues"]

## Recommended Command Sequence

1. [command] — [one-line reason]
2. [command] — [one-line reason]
...

## Notes
[Any caveats or context the user should know before running]
```

### `ai-context/scenarios.md` per-case template

```markdown
### Case N — [Label]

**Symptoms**: [what the user observes in the file system or CLI output]

**Command sequence**:
1. `/command-1`
2. `/command-2`
...

**Expected outcome per command**:
- `/command-1`: [one line]
- `/command-2`: [one line]

**Common failure modes**:
| Failure | Recovery |
|---------|----------|
| [failure description] | [recovery step] |
```

### `ai-context/quick-reference.md` structure contract

```markdown
# Quick Reference — Claude Code SDD

> Last verified: YYYY-MM-DD

## Your Situation → First Command
| Situation | First Command |
|-----------|--------------|
| ...       | ...          |

## SDD Flow
[ASCII diagram]

## Command Glossary
| Command | What it does |
|---------|-------------|
| ...     | ...         |

## /sdd-ff vs /sdd-new
[Decision rule]
```

### `Last verified:` field contract (all user docs)

- Location: second line of file, immediately after the `# Title` heading
- Format: `> Last verified: YYYY-MM-DD` (exact string, Markdown blockquote)
- Parser regex used by D2 and `project-update`: `^> Last verified: (\d{4}-\d{2}-\d{2})$`
- Files that must carry this field: `onboarding.md`, `scenarios.md`, `quick-reference.md`

---

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Manual functional | Run `/project-onboard` on a real project with `openspec/` but no `ai-context/` — verify Case 3 diagnosis with correct command sequence | Manual CLI run |
| Manual functional | Run `/project-onboard` on a project directory with no `.claude/CLAUDE.md` — verify Case 1 diagnosis recommending `/project-setup` | Manual CLI run |
| Manual functional | Run `/project-audit` on `claude-config` after applying — verify D2 emits passing sub-checks for `scenarios.md` and `quick-reference.md` | `/project-audit` |
| Manual integration | Run `sync.sh` after all changes — verify no errors and `~/.claude/` reflects all new/modified files | `bash sync.sh` |
| Regression | Re-run `/project-audit` on `claude-config` — verify score >= score before this change | `/project-audit` |
| Manual review | Open `ai-context/scenarios.md` and verify all 6 cases follow the fixed template | Visual review |
| Manual review | Open `ai-context/quick-reference.md` and verify all 4 required sections are present | Visual review |

No automated test framework is used — this repo's "test suite" is `/project-audit` itself, which is the verification oracle for the SDD meta-system.

---

## Migration Plan

No data migration required. All changes are new files or strictly additive edits to existing SKILL.md files. No existing data is restructured, renamed, or removed.

---

## Open Questions

None.

All design decisions are directly derivable from the proposal, from the existing conventions in `ai-context/conventions.md`, and from the structural patterns observed in existing SKILL.md files. No blocking ambiguities remain.
