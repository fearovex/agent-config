# Technical Design: enhance-claude-folder-audit

Date: 2026-03-03
Proposal: openspec/changes/enhance-claude-folder-audit/proposal.md

---

## General Approach

The existing `skills/claude-folder-audit/SKILL.md` will be extended in-place: the project-mode
check block (currently "Checks P1–P5") will gain content-quality sub-phases for P1, P2, and P3,
and three fully new numbered checks (P6, P7, P8) will be appended to the project-mode section.
No changes are made to the `global-config` / `global` mode block (Checks 1–5). All new checks
are additive — they accumulate findings into the same findings list consumed by Step 4 (report
generation). The report template section headers for P6–P8 are appended to the existing
project-mode report format block.

---

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|---------------|
| Approach for extending P1–P5 | Additive sub-phases within existing check blocks; new numbered checks P6–P8 for new audit dimensions | (A) Full restructure into named groups (A/B/C/D/E); (B) Pure flat extension P6–P10 with no sub-phase labeling | Sub-phases (P1a/P1b pattern from proposal) attach new content checks to their logical home (P1 owns CLAUDE.md quality; P2/P3 own SKILL.md quality) while avoiding the identifier breaking change of a full restructure (Approach A). Pure flat P6–P10 extension was discarded because content quality checks belong inside their structural parent, not as sibling checks. |
| Section detection pattern across all checks | Match lines that START with `## ` or `**` (first two characters/pattern on the line) | Regex with lookahead for code-fence exclusion; AST-based YAML parsing | Line-prefix matching is consistent with how all other existing skill-reading in this system works (project-audit uses the same approach). Code-fence false positives are low-probability in SKILL.md files because required sections are at top level. Full AST parsing is over-engineering for a markdown text-scanning skill. |
| YAML frontmatter extraction | Text scan: look for leading `---` block; extract `format: <value>` line inside it via simple line matching | Full YAML parser | Skills are authored by hand in a consistent format; the frontmatter is always the first block. A text scan is reliable here and consistent with the project convention of "clean and readable over clever." |
| Severity caps for new content-quality checks | All new checks capped at MEDIUM; feature file missing section → LOW; `ai-context/` absent → MEDIUM; unknown `.claude/` item → MEDIUM | HIGH for missing ai-context/; HIGH for missing feature section | HIGH should be reserved for failures that block Claude from functioning (CLAUDE.md absent, skill not deployed). Content-quality gaps are advisory — they degrade quality but do not break functionality. This is also consistent with the philosophy in ADR-006 (new dimensions default to informational until explicitly promoted). |
| Report format for new checks | Append new `## Check P6`, `## Check P7`, `## Check P8` sections to the existing project-mode report template | New grouped report format with two-level hierarchy | The two-level hierarchy (Approach B from exploration) was considered but discarded to minimize report format breaking change. The three new sections are each self-contained and readable. The flat section approach is consistent with the existing report format. |
| ADR generation for this change | Create ADR-016 for the pattern "audit content quality checks as an additive convention" | No ADR; add decision inline to ai-context/architecture.md only | This change introduces a new cross-cutting convention: how content quality checks are attached to structural checks in project mode. This is an architecture decision that will affect future extensions of the audit skill (e.g., global-mode content quality in V2). ADR-016 documents the convention so future sessions respect it. |
| Orphan directory removal | Remove `openspec/changes/claude-folder-audit-deep-inspection/` in the apply phase via filesystem delete | Leave it; archive it | The directory is confirmed empty (no artifacts). Leaving it creates noise in the changes listing. It cannot be archived (nothing to preserve). `rmdir` (not `rm -rf`) is the safe operation since it fails if the directory is non-empty. |

---

## Data Flow

```
/claude-folder-audit (invoked from project with .claude/)
          │
          ▼
    Step 1: Resolve paths
          │
          ▼
    Step 2: Detect MODE = project
          │
          ▼
    Step 3: Run project-mode checks
          │
    ┌─────┴──────────────────────────────────────────┐
    │                                                 │
    P1-Phase A: CLAUDE.md presence                    │
    P1-Phase B: Skills Registry section + path parse  │
    P1-Phase C (new): CLAUDE.md content quality       │
        - mandatory section presence (5 headers)      │
        - minimum line count (>50)                    │
        - SDD command references                      │
          │                                           │
    P2: Global-path registration verification         │
    P2-Phase C (new): SKILL.md content quality        │
        for each global-registered skill:             │
        - YAML frontmatter present                    │
        - format: field presence + valid value        │
        - section contract per format type            │
        - stub detection (<30 lines post-frontmatter) │
          │                                           │
    P3: Local-path registration verification          │
    P3-Phase C (new): SKILL.md content quality        │
        (same sub-checks as P2-Phase C)               │
          │                                           │
    P4: Orphaned local skills (unchanged)             │
          │                                           │
    P5: Scope tier overlap (unchanged)                │
          │                                           │
    P6 (new): ai-context/ core files                  │
        - directory presence                          │
        - 5 required files                            │
        - content length per file (>10 lines)         │
          │                                           │
    P7 (new): ai-context/features/ layer              │
        - directory presence                          │
        - non-template file inventory                 │
        - 6-section completeness per feature file     │
        - stub detection (<30 lines)                  │
          │                                           │
    P8 (new): .claude/ folder inventory               │
        - enumerate .claude/ items                    │
        - flag unknown items (not in expected set)    │
        - hooks/ non-empty script check               │
          │                                           │
    └────────────────────────────────────────────────┘
          │
          ▼
    Step 4: Generate report
        - Adds ## Check P6, P7, P8 sections
        - Finding summary table includes new findings
          │
          ▼
    Step 5: Output summary to user
```

---

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `skills/claude-folder-audit/SKILL.md` | Modify | Add P1-Phase C (CLAUDE.md content quality); add P2-Phase C and P3-Phase C (SKILL.md frontmatter + section contract checks); add Check P6 (ai-context/ core files); add Check P7 (ai-context/features/ layer); add Check P8 (.claude/ folder inventory); extend project-mode report format template to include P6/P7/P8 sections; extend Rules section with new severity caps and detection rules |
| `openspec/changes/claude-folder-audit-deep-inspection/` | Remove | Empty orphan directory — delete via `rmdir` in apply phase |
| `ai-context/architecture.md` | Modify | Add entry to audit inventory documenting new P1-Phase C, P2-Phase C, P3-Phase C, P6, P7, P8 checks; update check count |
| `docs/adr/016-enhance-claude-folder-audit-content-quality-convention.md` | Create | New ADR documenting the content-quality-as-sub-phase convention |
| `docs/adr/README.md` | Modify | Append ADR-016 row to the index table |

---

## Interfaces and Contracts

### Section detection function (inline logic, not a separate file)

Used in P1-Phase C, P2-Phase C, P3-Phase C, and P7. The matching rule is identical across all uses:

```
function has_section(file_content, heading_text):
  for each line in file_content:
    if line starts with "## " + heading_text → return true
    if line starts with "**" + heading_text  → return true
  return false
```

This matches:
- `## Tech Stack` (top-level markdown heading)
- `**Triggers**` (bold inline convention for triggers)

It does NOT match:
- `### Tech Stack` (subheading — intentional; required sections are top-level)
- `    ## Tech Stack` (indented heading — intentional; avoid matching inside code blocks)

### YAML frontmatter extraction (inline logic)

```
function extract_frontmatter_format(file_content):
  if not file_content starts with "---" → return null (no frontmatter)
  find the closing "---" line
  within the block, find line matching: format: <value>
  extract and trim <value>
  if <value> not in ["procedural", "reference", "anti-pattern"] → return "unknown:<value>"
  return <value>
```

### P6 — ai-context/ required files set

```
REQUIRED_CORE_FILES = [
  "stack.md",
  "architecture.md",
  "conventions.md",
  "known-issues.md",
  "changelog-ai.md"
]
```

### P7 — Feature file required sections

```
REQUIRED_FEATURE_SECTIONS = [
  "Domain Overview",
  "Business Rules and Invariants",
  "Data Model Summary",
  "Integration Points",
  "Decision Log",
  "Known Gotchas"
]
```

Source of truth: `ai-context/features/_template.md` (confirmed present; these are the H2 headings in the template).

### P8 — Expected .claude/ item set

```
EXPECTED_PROJECT_CLAUDE_ITEMS = [
  "CLAUDE.md",
  "skills/",
  "audit-report.md",
  "claude-folder-audit-report.md",
  "settings.json",
  "settings.local.json",
  "openspec/"
]
```

Items not in this set that are found directly under `.claude/` → MEDIUM finding.

---

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Manual (verify phase) | Run `/claude-folder-audit` on `att-future-you-prototypes` project after apply; confirm more than one finding including SKILL.md and ai-context/ coverage | Manual invocation |
| Manual (verify phase) | Run `/claude-folder-audit` on `claude-config` repo after apply; confirm P1–P5 findings are identical to pre-change run and no regression appears | Manual invocation |
| Manual (verify phase) | Confirm the verify-report.md success criteria checklist from `proposal.md` has all items checked | Checklist review |
| Smoke test | Run `/project-audit` on `claude-config` repo; confirm score >= pre-change baseline | `/project-audit` skill |

No automated test harness exists for SKILL.md skills in this repo. All testing is done via manual invocation (this is the standard approach per `ai-context/conventions.md`).

---

## Migration Plan

No data migration required.

The orphan directory `openspec/changes/claude-folder-audit-deep-inspection/` will be removed with `rmdir` (safe: confirmed empty). No committed artifacts are lost.

---

## Open Questions

None.

All decisions are resolved by the proposal, exploration, and available reference materials:
- Section detection pattern: confirmed from exploration Gap analysis
- Required feature file sections: confirmed from `ai-context/features/_template.md`
- P8 expected item set: confirmed from exploration Gap 6
- ADR warranted: confirmed — "convention" keyword present in Technical Decisions table
