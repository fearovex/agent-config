# Closure: enhance-claude-folder-audit

Start date: 2026-03-03
Close date: 2026-03-03

## Summary

Extended the `claude-folder-audit` skill's project mode from 5 shallow structural checks (P1–P5) to 8 meaningful audit dimensions: added CLAUDE.md content quality sub-checks to P1 (Phase C), added SKILL.md frontmatter and section contract sub-checks to P2 and P3 (Phase C), and added three new checks — P6 (ai-context/ memory layer), P7 (ai-context/features/ domain knowledge layer, ADR-015 V2), and P8 (.claude/ folder inventory). Report template extended to include P6/P7/P8 sections. ADR-016 created documenting the Phase C convention.

## Modified Specs

| Domain | Action | Change |
|--------|--------|--------|
| folder-audit-execution | Modified | Extended "checks MUST all execute" requirement from P1–P5 to P1–P8; added P1 Phase C (CLAUDE.md content quality), P2/P3 Phase C (SKILL.md frontmatter and section contract), P6 (ai-context/ memory layer), P7 (ai-context/features/ layer), P8 (.claude/ folder inventory) requirements |
| folder-audit-reporting | Modified | Extended "project-specific check section labels" requirement to cover P1–P8; added P6/P7/P8 section header requirements, report header summary requirement, Findings Summary table P6–P8 inclusion, Recommended Next Steps for new checks, INFO-only section collapsing requirement |

## Modified Code Files

- `skills/claude-folder-audit/SKILL.md` — main implementation: P1 Phase C added (CLAUDE.md content quality sub-checks), P2/P3 Phase C added (SKILL.md frontmatter + section contract sub-checks), P6 (ai-context/ core files check), P7 (ai-context/features/ layer check), P8 (.claude/ folder inventory); report template extended with P6/P7/P8 section blocks; Rules section extended with new severity caps and section detection rule
- `ai-context/architecture.md` — added "claude-folder-audit: Check Inventory (project mode)" section documenting all 8 checks with sub-phases, severity caps, and section detection rule; updated artifact table with memory-update auto-invocation note; added ADR-016 reference
- `docs/adr/016-enhance-claude-folder-audit-content-quality-convention.md` — created; documents the "content-quality-as-sub-phase" convention for extending audit checks
- `docs/adr/README.md` — ADR-016 row appended to the index table
- `openspec/changes/claude-folder-audit-deep-inspection/` — removed (empty orphan directory)

## Key Decisions Made

1. **Content quality checks are additive sub-phases, not new top-level checks** — Phase C is attached inside P1, P2, and P3 to avoid identifier breaking changes. Only fully new audit dimensions (memory layer, features layer, folder inventory) get new check numbers (P6, P7, P8). This is documented as the authoritative convention in ADR-016.
2. **All new content-quality findings capped at MEDIUM** — HIGH severity is reserved for failures that break Claude's ability to function (absent CLAUDE.md, deployed skill missing). Content quality gaps are advisory and degraded-state only.
3. **P7 features layer is strictly non-blocking** — per ADR-015's non-blocking design intent, absence of `ai-context/features/` produces INFO only. Feature file missing sections produce LOW at most. This is consistent with the voluntary authoring model.
4. **Section detection uses line-prefix matching (`## heading`)** — consistent with all other section-scanning in the system. `**Triggers**` bold pattern is accepted for the Triggers section specifically. Lines inside fenced code blocks are not exempt (low false-positive risk for markdown skill files).
5. **`name:` field NOT validated in P2/P3 frontmatter sub-checks** — the spec originally listed `name:` as a Stage 1 check; during tasks breakdown this was explicitly overridden (tasks.md 5.3) as non-essential for audit purposes. Only `format:` field validity is checked. The spec deviation is documented in verify-report.md and the skill's Rules section.

## Lessons Learned

- The verify phase correctly identified the tasks.md "15/17" stale header as a warning (not critical). Stale progress markers in tasks.md headers should be updated at task list finalization.
- The spec-vs-tasks deviation for `name:` field validation was caught during verify. Future SDD cycles should retroactively update the spec (or add a documented deviation note) during the apply phase rather than leaving it to be caught in verify.
- Orphan directory cleanup (`openspec/changes/claude-folder-audit-deep-inspection/`) was simple — empty directories tracked in git only if containing at least one file. Confirm emptiness before rmdir.

## User Docs Reviewed

N/A — pre-dates this requirement.
