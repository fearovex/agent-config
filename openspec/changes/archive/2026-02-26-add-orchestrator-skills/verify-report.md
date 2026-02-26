# Verify Report: add-orchestrator-skills

Date: 2026-02-26
Agent: Claude Sonnet 4.6

---

## Verification Criteria

### sdd-ff skill

- [x] `skills/sdd-ff/SKILL.md` exists and has all required sections: trigger, process steps, rules
- [x] Argument validation present — fails early with usage if change name missing
- [x] propose phase launched first (Step 2) before spec+design
- [x] spec and design sub-agents launched in parallel (Step 3) — both Task calls in same step
- [x] tasks sub-agent launched only after both parallel phases complete (Step 4)
- [x] Final summary presented to user with all phase results and artifacts (Step 5)
- [x] Does NOT auto-invoke `/sdd-apply` — ends with confirmation prompt
- [x] Stops on `blocked` or `failed` — documented in rules
- [x] Sub-agent prompt includes project path, change name, previous artifacts — template in each step

### sdd-new skill

- [x] `skills/sdd-new/SKILL.md` exists and has all required sections
- [x] Argument validation present — fails early with usage if change name missing
- [x] Optional explore phase with explicit user consent gate (Step 2)
- [x] Confirmation gate after propose (Step 3) — stops gracefully if user declines
- [x] Confirmation gate after spec+design (Step 4) — stops gracefully if user declines
- [x] spec and design launched in parallel (Step 4)
- [x] Full remaining phases reminder in final summary (Step 6)
- [x] Does NOT auto-invoke `/sdd-apply`
- [x] Graceful stop instructions at each gate — tells user which command resumes

### sdd-status skill

- [x] `skills/sdd-status/SKILL.md` exists and has all required sections
- [x] Handles missing `openspec/changes/` gracefully — reports and suggests `/sdd-new`
- [x] Handles empty active changes (archive-only) gracefully
- [x] Checks presence of all 6 artifact types: exploration.md, proposal.md, specs/, design.md, tasks.md, verify-report.md
- [x] Phase inference table documented (Step 4)
- [x] Output table format defined (Step 5) with ✓/- indicators
- [x] Archived count appended — reads `openspec/changes/archive/`
- [x] Filesystem-only rule enforced — no git inspection

### skill-add skill

- [x] `skills/skill-add/SKILL.md` exists and has all required sections
- [x] Clear distinction from `/skill-create` documented at top
- [x] Argument validation present — fails early with usage
- [x] Checks `~/.claude/skills/<name>/SKILL.md` existence before proceeding
- [x] Partial match search when exact name not found
- [x] Duplicate detection — stops if entry already exists in registry
- [x] Preview shown BEFORE any write operation — user must confirm (Step 6)
- [x] Creates `## Skills Registry` section if absent — never fails due to missing section
- [x] Option A (reference) default, Option B (copy) offered as follow-up

### CLAUDE.md routing table

- [x] Row `/sdd-ff` → `~/.claude/skills/sdd-ff/SKILL.md` present
- [x] Row `/sdd-new` → `~/.claude/skills/sdd-new/SKILL.md` present
- [x] Row `/sdd-status` → `~/.claude/skills/sdd-status/SKILL.md` present
- [x] Row `/skill-add` updated from `skill-creator/SKILL.md` to `skill-add/SKILL.md`

### CLAUDE.md Skills Registry

- [x] `### SDD Orchestrator Skills` subsection added
- [x] All 3 orchestrator skills listed: sdd-ff, sdd-new, sdd-status
- [x] `skill-add` added under Meta-tool Skills with description

### conventions.md

- [x] `### Orchestrator skills` subsection added under SKILL.md structure
- [x] Table distinguishing orchestrator vs executor skills present
- [x] "When to use Task tool delegation" guidance documented
- [x] "When NOT to use Task tool" guidance documented

### Smoke test (filesystem)

- [x] `~/.claude/skills/sdd-ff/SKILL.md` exists — confirmed via `ls` command
- [x] `~/.claude/skills/sdd-new/SKILL.md` exists — confirmed
- [x] `~/.claude/skills/sdd-status/SKILL.md` exists — confirmed
- [x] `~/.claude/skills/skill-add/SKILL.md` exists — confirmed
- [x] `install.sh` executed successfully (MCP "already exists" warning is non-fatal)

---

## Deviations from spec

None. All requirements implemented as specified.

---

## Result

PASS — all criteria met. Ready to archive.
