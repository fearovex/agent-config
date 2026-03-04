# Technical Design: project-claude-organizer-cleanup-after-migrate

Date: 2026-03-04
Proposal: openspec/changes/project-claude-organizer-cleanup-after-migrate/proposal.md

## General Approach

After each legacy migration category finishes its apply operations in Step 5.7, inject a
cleanup sub-step that conditionally prompts the user to delete the source files. The prompt
is only shown when: (a) the strategy is eligible (not `delegate`, not `section-distribute`),
and (b) at least one file in the category was successfully migrated. User confirmation is
required before any deletion. The report section is extended with a "Deleted from .claude/"
subsection. All changes are confined to a single file: `skills/project-claude-organizer/SKILL.md`.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|---------------|
| Cleanup prompt placement | Immediately after each 5.7.x sub-step (per-category) | Global cleanup at end of Step 5.7 (all categories at once) | Per-category prompting follows the existing confirmation-gate pattern established by the per-category migration prompts in 5.7; it is also safer because the user sees each migration's outcome before deciding on its cleanup |
| Eligible strategies | copy, append, scaffold, user-choice | All strategies including delegate and section-distribute | delegate writes zero files — there is nothing to clean up; section-distribute risks data loss if the source file contains undistributed sections |
| Deletion granularity | Individual successfully migrated files only; parent directory is NOT removed | Entire category directory removal | Removing the parent directory would delete files that were skipped (destination-exists) — those must be preserved |
| Confirmation model | yes/no per category, same interaction model as migration confirmation gate | Single global yes/no at end of all categories | Consistent with the skill's existing UX convention; reduces cognitive load by keeping cleanup prompt close to its corresponding migration outcome |
| Failed migrations excluded from deletion list | Unconditionally excluded | User decides per file | A failed migration means the file was NOT successfully transferred — deleting it would cause data loss |
| New Rule numbering | Inserted as Rule 5 (after existing Rule 4) | Replacing Rule 2 entirely | Rule 2 still applies (apply step is additive for directory/stub creation); the new rule clarifies the updated source-file invariant specifically for migration cleanup |

## Data Flow

```
Step 5.7 — Apply legacy migrations (per-category)
  │
  ├─ For each category in LEGACY_MIGRATIONS:
  │    │
  │    ├─ [existing] Present category files + destinations
  │    ├─ [existing] Prompt: Apply <category> migrations? (yes/no/all)
  │    ├─ [existing] Execute strategy (delegate / section-distribute / copy / append / scaffold / user-choice)
  │    │    └─ Record outcome per file: applied | skipped | failed | advisory | non-qualifying
  │    │
  │    └─ [NEW] Cleanup sub-step (5.7.x-cleanup):
  │         │
  │         ├─ Guard: is strategy in {copy, append, scaffold, user-choice}? → if NO, skip entirely
  │         ├─ Guard: count(outcome == applied/copied/appended/scaffolded) > 0? → if NO, skip
  │         ├─ Build WILL_DELETE list (outcome == success) and WILL_PRESERVE list (outcome == skipped/failed)
  │         ├─ Present both lists to user
  │         ├─ Prompt: Delete source files from .claude/<category>/? (yes/no)
  │         │
  │         ├─ yes → for each file in WILL_DELETE: delete source file; record deletion
  │         └─ no  → record: <category> — cleanup declined by user

Step 6 — Write report
  └─ [NEW] "Deleted from .claude/" subsection under Legacy migrations
       └─ List each deleted source path and each declined category
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `skills/project-claude-organizer/SKILL.md` | Modify | Add 5 cleanup sub-steps (one per eligible strategy sub-step: 5.7.3-cleanup, 5.7.4-cleanup, 5.7.5-cleanup, 5.7.6-cleanup, 5.7.7-cleanup) |
| `skills/project-claude-organizer/SKILL.md` | Modify | Extend Step 6 report format with "Deleted from .claude/" subsection |
| `skills/project-claude-organizer/SKILL.md` | Modify | Update frontmatter description — remove "Never deletes or moves files" language |
| `skills/project-claude-organizer/SKILL.md` | Modify | Add Rule 5: new source-file invariant governing cleanup deletion |

## Interfaces and Contracts

The cleanup sub-step operates on the outcome records already produced by each 5.7.x sub-step.
Each outcome record has the following structure (implicit in the existing skill):

```
OUTCOME_RECORD = {
  filename: string,          # e.g. "auth.md"
  source_path: string,       # e.g. ".claude/docs/auth.md"
  outcome: "applied" | "skipped" | "failed" | "advisory" | "non-qualifying",
  reason?: string            # optional: "destination exists", "copy error", etc.
}
```

The cleanup sub-step groups records by outcome:

```
WILL_DELETE  = records where outcome IN {"applied", "copied", "appended", "scaffolded"}
WILL_PRESERVE = records where outcome IN {"skipped", "failed", "excluded"}
```

Note: the skill uses natural-language outcome labels (not a strict enum). The cleanup sub-step
must recognize the following outcome language as "successful migration" eligibility:
- For copy strategy: "copied to ..."
- For append strategy: "appended to ..."
- For scaffold strategy: "scaffolded to ..."
- For user-choice strategy: "copied to ..." (Option B) or "appended to ..." (Option A)

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Manual / skill execution | Run skill on a test project with `.claude/docs/` containing two files; one succeeds, one is skipped; confirm prompt shows correct lists; confirm deletion | Manual invocation on Audiio V3 test project |
| Manual / skill execution | Confirm no deletion prompt appears for `commands/` (delegate) | Manual invocation |
| Manual / skill execution | Confirm no deletion prompt appears for `project.md` (section-distribute) | Manual invocation |
| Manual / skill execution | Confirm that declining a cleanup prompt leaves all source files intact | Manual invocation |
| Report inspection | Verify "Deleted from .claude/" subsection appears in report after confirmed deletion | Read report file after run |

## Migration Plan

No data migration required. This change modifies a SKILL.md instruction file only.
Run `install.sh` after apply to deploy the updated skill to `~/.claude/skills/project-claude-organizer/`.

## Open Questions

None.

---

## ADR Note

The Technical Decisions table above contains the term "convention" (cleanup prompt placement
and interaction model convention). An ADR is warranted to document the new source-file
deletion invariant as an architectural convention for this skill.
