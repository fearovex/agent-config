# Technical Design: project-claude-organizer-smart-migration

Date: 2026-03-04
Proposal: openspec/changes/project-claude-organizer-smart-migration/proposal.md

## General Approach

Extend the existing `project-claude-organizer` SKILL.md with a "Legacy Directory Intelligence" layer (Step 3b) inserted between the three-bucket classification (Step 3) and the dry-run plan presentation (Step 4). The layer iterates over items in the `UNEXPECTED` bucket; any item whose name matches one of 8 predefined patterns is reclassified into a new `LEGACY_MIGRATIONS` collection and removed from `UNEXPECTED`. Steps 4, 5, and 6 are each extended additively to render, apply, and report the legacy migrations. All writes remain strictly additive (copy/scaffold only). No new files or skills are created; the entire change is contained to one file: `skills/project-claude-organizer/SKILL.md`.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|---------------|
| Implementation location | Single SKILL.md modification — add Step 3b, extend Steps 4/5/6 | New companion skill; separate orchestrator | The existing skill's step structure is append-friendly. A companion skill would require orchestration authority this skill does not have. Keeping it in one file matches the project's single-responsibility convention for non-orchestrator skills. |
| Classification strategy | Pattern-table lookup — match `UNEXPECTED` item names against 8 known patterns before falling through | Regex scan, content analysis as primary signal | Name matching is deterministic, fast, and sufficient for the 8 well-defined patterns. Content analysis is used only secondarily (for `commands/` qualifying check and `project.md`/`readme.md` section routing). |
| `commands/` delegation model | Advisory only — organizer presents recommendation (skill name + trigger summary + format suggestion); user invokes `/skill-create` separately | Auto-invoke skill-creator from within organizer | Organizer does not have orchestration authority. Auto-invocation would introduce a skill-to-skill dependency that is not supported by the procedural executor pattern. Advisory model is reversible and consistent with the existing confirmation-gate design. |
| Merge strategy for `system/` and `project.md`/`readme.md` | Append to destination under a labeled section separator | Overwrite, merge/deduplicate | Overwrite violates the additive invariant. Deduplication introduces content-analysis complexity that is explicitly excluded from scope. Labeled append is the lightest-weight operation that adds value without risk. |
| `sops/` dual-destination presentation | Per-file or global-for-directory choice at confirmation time | Single hardcoded destination | SOPs legitimately belong in either `ai-context/conventions.md` or `docs/sops/`. Presenting the choice respects operator judgment without baking in a wrong default. |
| Step insertion point | Between Step 3 and Step 4 (new Step 3b) | Post-Step 4 reclassification; pre-Step 3 | Step 3b reads the `UNEXPECTED` set that Step 3 produced. Running it before Step 4 allows the dry-run plan to include legacy migrations in one coherent view rather than splitting them across two plan sections. |
| Per-category confirmation gate | Each legacy category shown in the dry-run plan; single "Apply this plan?" gate covers all categories together | Per-item confirmation; per-category individual gates | The existing skill already uses a single confirmation gate for all categories. Introducing per-category gates would be a behavioral regression from the user's perspective and would multiply the number of prompts for projects with many legacy patterns. |
| Pattern matching scope | Top-level `.claude/` items only (directories and root-level files) | Recursive scan | Existing skill design explicitly limits to one level deep. Recursive scanning is excluded from scope. |

## Data Flow

```
Step 1: Resolve paths
        PROJECT_ROOT, PROJECT_CLAUDE_DIR, HOME_DIR
              |
Step 2: Enumerate one-level-deep items
        OBSERVED_ITEMS = [<name>, <name>/, ...]
              |
Step 3: Three-bucket classification
        MISSING_REQUIRED | UNEXPECTED | PRESENT
              |
Step 3b: Legacy Directory Intelligence (NEW)
        For each item in UNEXPECTED:
          match against LEGACY_PATTERN_TABLE
          → hit:  add to LEGACY_MIGRATIONS, remove from UNEXPECTED
          → miss: stays in UNEXPECTED ("review manually" — unchanged)

        LEGACY_PATTERN_TABLE (order: name match first, content analysis second):
          commands/     → SKILL_ADVISORY (content analysis for qualifying files)
          docs/         → AI_CONTEXT_FEATURES  (map *.md → ai-context/features/*.md)
          system/       → AI_CONTEXT_SYSTEM    (route by filename to architecture/stack)
          plans/        → OPENSPEC_CHANGES     (active → openspec/changes/<name>/,
                                                archived → openspec/changes/archive/<name>/)
          requirements/ → OPENSPEC_PROPOSALS   (scaffold → openspec/changes/<date>-<slug>/proposal.md)
          sops/         → DUAL_DEST_CHOICE     (conventions.md section vs docs/sops/)
          templates/    → DOCS_TEMPLATES       (copy → docs/templates/)
          project.md    → AI_CONTEXT_SECTIONS  (section routing, append strategy)
          readme.md     → AI_CONTEXT_SECTIONS  (section routing, append strategy)
              |
Step 4: Build and present dry-run plan
        Existing categories (MISSING_REQUIRED, DOCUMENTATION_CANDIDATES, UNEXPECTED)
        + NEW: "Legacy migrations" section (one entry per LEGACY_MIGRATIONS item)
              |
        "Apply this plan? (yes/no)" — existing gate
              |
Step 5: Apply plan (strictly additive)
        5.1–5.6: existing sub-steps (unchanged)
        5.7 NEW: Apply legacy migrations (per-strategy handlers)
              |
          5.7.1 SKILL_ADVISORY   → present advisory (no write)
          5.7.2 AI_CONTEXT_FEATURES → copy *.md → ai-context/features/*.md
                                      (skip if destination exists)
          5.7.3 AI_CONTEXT_SYSTEM   → append to ai-context/architecture.md
                                      or ai-context/stack.md under labeled separator
          5.7.4 OPENSPEC_CHANGES    → scaffold active plan directories;
                                      scaffold archive directories
          5.7.5 OPENSPEC_PROPOSALS  → scaffold proposal.md stubs
          5.7.6 DUAL_DEST_CHOICE    → present choice; user selects; copy/append
          5.7.7 DOCS_TEMPLATES      → copy files to docs/templates/
          5.7.8 AI_CONTEXT_SECTIONS → read headings; route sections; append
              |
Step 6: Write claude-organizer-report.md
        Existing sections (Created, Documentation copied, Unexpected, Already correct)
        + NEW: "Legacy migrations" subsection (outcomes per category)
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `skills/project-claude-organizer/SKILL.md` | Modify | Add Step 3b (Legacy Directory Intelligence layer): LEGACY_PATTERN_TABLE + classification loop + LEGACY_MIGRATIONS collection; extend Step 4 dry-run plan format with "Legacy migrations" section; add Step 5.7 with 8 sub-steps (5.7.1–5.7.8) for per-strategy apply handlers; extend Step 6 report format with "Legacy migrations" subsection |

## Interfaces and Contracts

```
# LEGACY_MIGRATIONS collection — each entry:
{
  source:       string   # absolute path to source item (dir or file)
  name:         string   # item name as observed (e.g. "commands/", "project.md")
  strategy:     enum     # SKILL_ADVISORY | AI_CONTEXT_FEATURES | AI_CONTEXT_SYSTEM |
                         # OPENSPEC_CHANGES | OPENSPEC_PROPOSALS | DUAL_DEST_CHOICE |
                         # DOCS_TEMPLATES | AI_CONTEXT_SECTIONS
  destinations: string[] # one or more candidate destination paths
  confirmation: required # always true — every migration requires user confirmation
}

# LEGACY_PATTERN_TABLE — ordered match list (pseudo-YAML):
patterns:
  - name: "commands/"
    match: directory named "commands"
    strategy: SKILL_ADVISORY
    destinations: []   # advisory only; user invokes /skill-create
    content_analysis: true  # read each *.md; detect reusable workflow markers

  - name: "docs/"
    match: directory named "docs"
    strategy: AI_CONTEXT_FEATURES
    destinations: ["PROJECT_ROOT/ai-context/features/<filename>.md"]
    for_each: "*.md files at docs/ top level"

  - name: "system/"
    match: directory named "system"
    strategy: AI_CONTEXT_SYSTEM
    routing:
      architecture.md: "PROJECT_ROOT/ai-context/architecture.md"
      database.md:     "PROJECT_ROOT/ai-context/stack.md"
      api-overview.md: "PROJECT_ROOT/ai-context/stack.md"
    merge: append-under-labeled-separator

  - name: "plans/"
    match: directory named "plans"
    strategy: OPENSPEC_CHANGES
    routing:
      active:   "PROJECT_ROOT/openspec/changes/<plan-name>/"
      archived: "PROJECT_ROOT/openspec/changes/archive/<plan-name>/"

  - name: "requirements/"
    match: directory named "requirements"
    strategy: OPENSPEC_PROPOSALS
    destinations: ["PROJECT_ROOT/openspec/changes/<YYYY-MM-DD>-<slug>/proposal.md"]
    idempotency: "scaffold only — skip if destination exists"

  - name: "sops/"
    match: directory named "sops"
    strategy: DUAL_DEST_CHOICE
    destinations:
      A: "PROJECT_ROOT/ai-context/conventions.md (append section)"
      B: "PROJECT_ROOT/docs/sops/<filename>.md (copy)"
    user_choice: "per-file or global-for-directory"

  - name: "templates/"
    match: directory named "templates"
    strategy: DOCS_TEMPLATES
    destinations: ["PROJECT_ROOT/docs/templates/<filename>"]

  - name: "project.md"
    match: root-level file named "project.md" (case-insensitive)
    strategy: AI_CONTEXT_SECTIONS
    destinations:
      stack_sections:        "PROJECT_ROOT/ai-context/stack.md"
      architecture_sections: "PROJECT_ROOT/ai-context/architecture.md"
      known_issues_sections: "PROJECT_ROOT/ai-context/known-issues.md"
    per_section_confirmation: true

  - name: "readme.md"
    match: root-level file named "readme.md" (case-insensitive)
    strategy: AI_CONTEXT_SECTIONS
    destinations:
      stack_sections:        "PROJECT_ROOT/ai-context/stack.md"
      architecture_sections: "PROJECT_ROOT/ai-context/architecture.md"
      known_issues_sections: "PROJECT_ROOT/ai-context/known-issues.md"
    per_section_confirmation: true

# Section heading routing heuristic (AI_CONTEXT_SECTIONS):
STACK_HEADING_SIGNALS    = ["## Tech Stack", "## Stack", "## Dependencies", "## Tools"]
ARCH_HEADING_SIGNALS     = ["## Architecture", "## System Design", "## Overview"]
ISSUES_HEADING_SIGNALS   = ["## Known Issues", "## Issues", "## Gotchas", "## Limitations"]
```

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Manual walkthrough | Run `/project-claude-organizer` against a test project that has each of the 8 legacy directories present — confirm migration suggestions appear and no "review manually" flag is emitted for known patterns | Manual (operator) |
| Regression | Run `/project-claude-organizer` against a project with an unknown directory (e.g. `misc/`) — confirm it still falls through to UNEXPECTED with "review manually" (pattern 5 from success criteria) | Manual (operator) |
| Advisory check | Confirm `commands/` pattern produces an advisory naming the recommended skill and suggesting `/skill-create` — confirm no file is auto-created | Manual (operator) |
| Additive invariant | After running the skill and confirming, verify all source files still exist at their original locations | Manual (operator) |
| Report format | Inspect `claude-organizer-report.md` for presence of "Legacy migrations" subsection after a run that triggered at least one migration | Manual (operator) |

No automated test framework applies — this is a Markdown SKILL.md; tests are procedural walkthroughs.

## Migration Plan

No database or external data migration required. The change modifies only `skills/project-claude-organizer/SKILL.md`, which is a text file versioned in Git.

Deployment sequence after apply:
1. Edit `skills/project-claude-organizer/SKILL.md` in repo
2. `bash install.sh` — deploys updated skill to `~/.claude/skills/project-claude-organizer/SKILL.md`
3. `git commit` — commits the single changed file

## Open Questions

- **`plans/` active vs. archived classification**: The proposal says "route active plans → `openspec/changes/<name>/`" but does not define the signal that distinguishes an active plan from an archived one. Implementation should treat all `plans/` content as requiring user confirmation on a per-item basis, with the user deciding active vs. archived per item.

- **`commands/` content analysis heuristic**: The proposal says "detect reusable workflow markers". The implementation should define these markers concretely. Proposed markers: presence of step-numbered headings (`### Step N`), slash-command references (`/command`), or trigger keywords (`## Process`, `**Triggers**`). These three signals are already used by the SKILL.md format contract — reusing them is consistent and requires no new convention.
