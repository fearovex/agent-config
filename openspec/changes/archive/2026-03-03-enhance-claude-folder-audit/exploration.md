# Exploration: enhance-claude-folder-audit

Date: 2026-03-03
Type: Enhancement to existing skill

---

## Current State

### What the skill does today

`claude-folder-audit` (at `skills/claude-folder-audit/SKILL.md`) is a 661-line procedural skill
that audits either a project's `.claude/` folder or the `~/.claude/` runtime depending on where it
is invoked. It has three execution modes:

| Mode | Trigger | Scope |
|------|---------|-------|
| `project` | Invoked from a project with `.claude/` | Audits `.claude/CLAUDE.md` and local skill registration |
| `global-config` | Invoked from the `claude-config` source repo | Audits `~/.claude/` runtime vs. source repo |
| `global` | Any other location | Audits `~/.claude/` runtime structure |

**Project mode (P1–P5) checks — what it currently audits:**

| Check | What it does |
|-------|-------------|
| P1 | CLAUDE.md presence + Skills Registry section existence |
| P2 | Global-path registrations point to existing `~/.claude/skills/<n>/SKILL.md` |
| P3 | Local-path registrations point to existing `.claude/skills/<n>/SKILL.md` |
| P4 | Orphaned local skills (on disk but not registered) |
| P5 | Scope tier overlap (skill in both local and global tier) |

**Global-config/global mode (1–5) checks:**

| Check | What it does |
|-------|-------------|
| 1 | Runtime structure (required top-level directories present) |
| 2 | Skill deployment completeness (source skills deployed to runtime) |
| 3 | Installation drift (mtime comparison, approximate) |
| 4 | Orphaned artifact detection (items in `~/.claude/` not from source) |
| 5 | Scope tier compliance (project-local vs. global overlap) |

### The problem the user identified

The audit ran on project `D:/Proyectos/Critical-Mass/AT&T/att-future-you-prototypes` and produced
only ONE finding — a LOW severity P5 scope tier overlap for `smart-commit`. The user states the
`.claude/` folder of that project had much more content that went entirely unanalyzed. The audit
is described as "too shallow."

**Root cause of shallowness — confirmed by reading the SKILL.md:**

1. **No content quality checks on SKILL.md files**: P1–P5 only verify *whether* files exist and
   *whether* they are registered. A SKILL.md that exists but is empty, has no frontmatter, missing
   `format:` field, missing required sections (`## Process`, `## Rules`, `**Triggers**`), or
   contains only placeholder text — is invisible to the current audit. The skill knows about
   `docs/format-types.md` (referenced in CLAUDE.md's unbreakable rules) but never reads it or
   applies its contracts.

2. **No frontmatter validation**: The `format:` field is a mandatory YAML frontmatter field per
   CLAUDE.md Unbreakable Rule 2. The audit never checks for its presence or valid values
   (`procedural` | `reference` | `anti-pattern`).

3. **No section contract enforcement**: Per `docs/format-types.md`, each format type has required
   sections:
   - `procedural`: requires `**Triggers**`, `## Process`, `## Rules`
   - `reference`: requires `**Triggers**`, `## Patterns` or `## Examples`, `## Rules`
   - `anti-pattern`: requires `**Triggers**`, `## Anti-patterns`, `## Rules`
   The audit never checks any of these.

4. **No `ai-context/` layer awareness in project mode**: When run on a project, the audit does not
   check whether `ai-context/` exists, has the core 5 files, or whether `ai-context/features/`
   exists and is populated with feature knowledge files. ADR-015 (feature-domain-knowledge-layer,
   just merged) defines `ai-context/features/` as a first-class memory artifact — the audit is
   blind to it.

5. **No `.claude/` file-level analysis**: The audit only checks the `CLAUDE.md` and the
   `skills/` subdirectory. Other content that may live in `.claude/` (hooks, openspec, settings
   files, audit reports, arbitrary files) is ignored in project mode.

6. **No CLAUDE.md content quality checks**: P1 only confirms that a Skills Registry section
   header exists. It does not check for mandatory sections (`## Tech Stack`, `## Architecture`,
   `## Unbreakable Rules`, `## Plan Mode Rules`), meaningful content length, or whether SDD
   commands are referenced.

7. **No `ai-context/features/` integration**: There is an explicit note in ADR-015 and in
   `ai-context/features/sdd-meta-system.md` that audit integration for feature files was deferred
   to V2. This change is V2 for that integration.

---

## Affected Areas

| File/Module | Impact | Notes |
|-------------|--------|-------|
| `skills/claude-folder-audit/SKILL.md` | High — primary artifact to rewrite | Add new checks; extend existing checks |
| `docs/format-types.md` | Read-only reference | The section contract source of truth for new content checks |
| `ai-context/features/_template.md` | Read-only reference | Six-section contract to validate feature files against |
| `skills/feature-domain-expert/SKILL.md` | Read-only reference | Consumption rules for the feature file preload system |
| `CLAUDE.md` | Low — possibly update audit skill description | May need a trigger update or description update |
| `docs/adr/README.md` | Low — new ADR needed | A significant architectural expansion warrants an ADR |
| `ai-context/architecture.md` | Low — update check inventory | Document the new checks in the artifact table |

---

## Analyzed Approaches

### Approach A: Incremental extension — add new checks while keeping P1–P5 intact

**Description**: Extend the existing P1–P5 check suite with new checks P6–P12 (or lettered
sub-checks like P1b, P4b, etc.). Each new check addresses one gap: CLAUDE.md quality, SKILL.md
frontmatter, section contracts, feature layer presence, file-level inventory of `.claude/`.

**Pros**:
- Backwards compatible — existing checks are unchanged in behavior
- Findingsidentifiers remain stable (no renamed checks)
- Lower risk of breaking behavior that already works correctly
- Easier to implement incrementally and verify

**Cons**:
- The existing check numbering (P1–P5) was designed for 5 checks; extending to P12 is inelegant
- Some new checks naturally belong inside existing checks (e.g., SKILL.md content quality is
  a natural extension of P3/P4, not an independent check)
- Risk of over-engineering: 12 checks with mixed sub-check depth may be harder to read

**Estimated effort**: Medium (1–2 days)
**Risk**: Low

---

### Approach B: Reorganize into named check groups (recommended)

**Description**: Restructure the project-mode checks into named groups rather than P1–P5:
- **Group A: Configuration Structure** — CLAUDE.md presence, content quality, Skills Registry
- **Group B: Skill Registration** — global and local registration verification (current P2/P3)
- **Group C: Skill Content Quality** — SKILL.md frontmatter + section contract per format type
- **Group D: Memory Layer** — `ai-context/` core files + `ai-context/features/` coverage
- **Group E: Folder Inventory** — unknown files in `.claude/`, hooks, orphaned artifacts

This approach restructures the check *taxonomy* — the check identifiers shift from P1–P5 to group
letters (or to a new alpha-numeric scheme like A1, A2, B1, B2, etc.).

**Pros**:
- Much more readable report structure
- New checks fit naturally in their groups
- The report tells a coherent story: config → skills → content → memory → inventory
- Easier to extend in future (just add to the right group)

**Cons**:
- Breaking change: check identifiers change (existing references to P1–P5 in CLAUDE.md
  unbreakable rules or docs would need updating)
- Larger rewrite surface — higher chance of introducing a regression in existing checks

**Estimated effort**: Medium-High (2–3 days)
**Risk**: Medium (identifier breaking change)

---

### Approach C: Add new checks with numeric extension (P6, P7, ...) — minimal restructure

**Description**: Keep P1–P5 exactly as they are. Add new numbered checks P6–P10 for the gaps:
- P6: CLAUDE.md content quality (section presence, length, SDD references)
- P7: SKILL.md content quality and format compliance (frontmatter + section contracts)
- P8: ai-context/ core files presence and completeness
- P9: ai-context/features/ layer presence and quality (feature file section completeness)
- P10: `.claude/` folder inventory (unexpected files, hooks presence/validity)

**Pros**:
- Minimal breaking change (P1–P5 identifiers preserved)
- Each new check is cleanly scoped
- P9 directly implements the deferred V2 from feature-domain-knowledge-layer ADR-015

**Cons**:
- P6–P10 are significantly more powerful than P1–P5 — the check numbering implies equal weight,
  which is misleading
- The report still has a flat list of 10 numbered checks rather than a meaningful hierarchy

**Estimated effort**: Medium (1–2 days)
**Risk**: Low

---

### Recommendation

**Approach C** is recommended for the apply phase, with one structural improvement: use
**labeled sub-checks** (e.g., `P1a`, `P1b`) to extend existing checks where content quality
clearly belongs within the existing check's scope, and **new numbered checks P6–P10** for
genuinely new audit dimensions.

Specifically:
- Extend **P1** with sub-checks for CLAUDE.md content quality (mandatory sections, SDD refs)
- Extend **P2/P3** with sub-checks for SKILL.md frontmatter + section contract validation
  (this belongs logically inside the "registration verification" checks)
- Add **P6** for ai-context/ core files (5 required files, substantive content)
- Add **P7** for ai-context/features/ layer (presence, file count, section completeness)
- Add **P8** for `.claude/` folder inventory (unknown files, hooks audit)

This gives 8 effective check groups (P1 extended, P2 extended, P3 extended, P4 unchanged, P5
unchanged, P6–P8 new) while preserving all existing identifiers and behavior.

---

## Detailed Gap Analysis

### Gap 1: CLAUDE.md content quality (currently unchecked)

**Current state**: P1 only checks that CLAUDE.md exists and has a `## Skills Registry` heading.

**What should be checked**:
- Mandatory sections: `## Tech Stack` (or `## Stack`), `## Architecture`, `## Unbreakable Rules`,
  `## Plan Mode Rules`, `## Skills Registry`
- Minimum content threshold: file should be >50 lines to be considered substantive
- SDD command references: CLAUDE.md should reference `/sdd-ff` and `/sdd-new` (or equivalents)
- Skills Registry entries are present (not just the section header)

**Severity mapping**:
- Missing mandatory section → MEDIUM
- File <30 lines → MEDIUM
- Missing SDD references → LOW (informational)

---

### Gap 2: SKILL.md frontmatter validation (currently unchecked)

**Current state**: P2/P3 only check that `SKILL.md` exists as a file. Content is not read.

**What should be checked** (per `docs/format-types.md`):
- YAML frontmatter is present (file starts with `---`)
- `name:` field is present in frontmatter
- `description:` field is present in frontmatter
- `format:` field is present with a valid value (`procedural`, `reference`, or `anti-pattern`)
- If `format:` is absent, skill defaults to `procedural` — this is acceptable but should be noted
  at INFO level

**Severity mapping**:
- Missing YAML frontmatter block → MEDIUM
- Missing `name:` field → LOW
- Missing `format:` field → LOW (defaults to procedural, per format-types.md)
- Unknown `format:` value → LOW (defaults to procedural with INFO finding)

---

### Gap 3: SKILL.md section contract validation (currently unchecked)

**Current state**: No content reading of SKILL.md files occurs.

**What should be checked** (per `docs/format-types.md` section contracts):

For `format: procedural` (or absent format):
- `**Triggers**` OR `## Triggers` present → if absent: MEDIUM
- `## Process` OR at least one `### Step N` heading present → if absent: MEDIUM
- `## Rules` OR `## Execution rules` present → if absent: MEDIUM

For `format: reference`:
- `**Triggers**` OR `## Triggers` present → if absent: MEDIUM
- `## Patterns` OR `## Examples` present → if absent: MEDIUM
- `## Rules` OR `## Execution rules` present → if absent: MEDIUM
- Absence of `## Process` is NOT a finding

For `format: anti-pattern`:
- `**Triggers**` OR `## Triggers` present → if absent: MEDIUM
- `## Anti-patterns` present → if absent: MEDIUM
- `## Rules` OR `## Execution rules` present → if absent: MEDIUM

Additional content quality signal:
- File <30 lines (after frontmatter) → LOW (likely a stub or placeholder)
- File contains "TODO:" in any required section → INFO (stub not yet filled in)

---

### Gap 4: ai-context/ core files (currently unchecked in project mode)

**Current state**: The project-mode audit makes no mention of `ai-context/` whatsoever.

**What should be checked**:
- `ai-context/` directory exists → if absent: MEDIUM (not HIGH — not every project uses this)
- If `ai-context/` exists, required files: `stack.md`, `architecture.md`, `conventions.md`,
  `known-issues.md`, `changelog-ai.md` → each missing file: LOW
- Each present file has substantive content (>20 lines) → file with <10 lines: INFO

**Severity mapping**:
- `ai-context/` absent entirely → MEDIUM
- Individual core file missing → LOW
- Individual file too short → INFO

---

### Gap 5: ai-context/features/ layer (deferred V2 from ADR-015)

**Current state**: The feature-domain-knowledge-layer SDD change (ADR-015, verify-report dated
2026-03-03) explicitly deferred audit enforcement to V2. The verify-report notes:
> "The `feature_docs:` block in openspec/config.yaml remains commented out (by design — V1
> activates the memory side only; audit integration deferred to V2)"

**What should be checked** (V2 activation):
- If `ai-context/features/` exists: inventory present feature files (excluding `_template.md`)
- For each feature file (non-template): check that all six required sections exist:
  1. `## Domain Overview`
  2. `## Business Rules and Invariants`
  3. `## Data Model Summary`
  4. `## Integration Points`
  5. `## Decision Log`
  6. `## Known Gotchas`
- Missing section → LOW (feature files are authored voluntarily; missing sections are quality
  signals, not structural failures)
- Feature file < 30 lines → INFO (likely a stub not yet filled)
- `ai-context/features/` directory absent → INFO only (not MEDIUM — projects without domain
  boundaries don't need feature files; ADR-015 confirms non-blocking is the intent)
- `_template.md` existence → INFO (presence of template is a positive quality signal)

**Severity mapping** (conservative, per ADR-015 non-blocking design intent):
- Missing required section in a feature file → LOW
- Feature file is a stub (<30 lines) → INFO
- `ai-context/features/` absent → INFO (not MEDIUM — still voluntary in V2)

---

### Gap 6: .claude/ folder inventory (currently unchecked)

**Current state**: The audit does not enumerate what lives in `.claude/` beyond `CLAUDE.md` and
`skills/`. Other recognized sub-items (hooks, openspec, settings) are not validated.

**What should be checked**:
- Known expected items in `.claude/`: `CLAUDE.md`, `skills/`, `audit-report.md`,
  `claude-folder-audit-report.md`, `settings.json`, `settings.local.json`, `openspec/`
- Unknown items in `.claude/` not in the expected set → MEDIUM (possible manual edit, stale file)
- `hooks/` directory presence: if present, check that any `.js` or `.sh` files in it are
  non-empty → empty hook script → LOW

---

## Synergy with feature-domain-knowledge-layer

ADR-015 (feature-domain-knowledge-layer, Proposed 2026-03-03) explicitly calls out that audit
integration for `ai-context/features/` was deferred to V2:

> "Feature files are free-form Markdown with no automated structural validation in V1 — quality
> depends on author discipline and the template."
> "No automated staleness detection is included in V1."

Gap 5 above directly implements this V2 promise. The integration is well-defined:

1. The six required sections are already documented in `ai-context/features/_template.md`
2. The exclusion rule (`_template.md` is never audited) is already specified
3. The severity philosophy is consistent: feature file quality is advisory (LOW/INFO), not
   blocking (HIGH/MEDIUM)

The `feature-domain-expert/SKILL.md` also explicitly mentions:
> "The `feature_docs:` block in `openspec/config.yaml` is reserved for V2 audit integration."
This is the hook point: the audit should read `openspec/config.yaml`'s `feature_docs:` block
(when uncommented) to know which feature files are expected, or fall back to directory detection.

---

## Identified Risks

- **Report length explosion**: Adding 5 new check groups could make the report very long for
  healthy projects. Mitigation: group findings by area; collapse INFO findings into a summary;
  only emit detailed sections for checks that have findings.

- **False positives on SKILL.md section detection**: Section presence checking via line scanning
  is fast but could miss edge cases (section inside a code fence, indented headers, etc.). Mitigation:
  match against top-level `## Section` and inline bold `**Section**` patterns; document the
  matching rule explicitly in the skill.

- **Scope creep from "ideal structure" enforcement**: Defining what an "ideal .claude/ folder"
  looks like risks becoming prescriptive about content that varies legitimately by project.
  Mitigation: keep all new content-quality checks at MEDIUM or below; reserve HIGH for structural
  failures that block usability (CLAUDE.md missing, SKILL.md missing a registered entry).

- **Empty claude-folder-audit-deep-inspection change directory**: An empty directory already
  exists at `openspec/changes/claude-folder-audit-deep-inspection/`. This appears to be an orphan
  from a previous exploration that was not started. It should either be used as the home for this
  change or deleted. The SDD cycle for the current change is being started under
  `enhance-claude-folder-audit` — the empty directory should be removed in the apply phase.

- **Interaction with global-config and global modes**: This exploration focuses on project mode
  (P1–P8). The global-config and global mode checks (1–5) also have gaps (no skill content quality
  checks in those modes). However, extending both modes simultaneously doubles the scope. Recommend
  focusing this change on project mode and noting global-mode content quality as a follow-up.

---

## Open Questions

1. **Should global-config mode also get content quality checks (Checks 6–8 parallel to P6–P8)?**
   Global-config mode is used on the `claude-config` source repo itself. Adding equivalent skill
   content quality checks there would catch issues before deployment. This is out of scope for the
   current change but should be noted as a logical follow-up.

2. **How strict should `ai-context/features/` section detection be?** The six sections are
   required per the template, but ADR-015 is explicit that V1 is voluntary. Should a missing
   section be LOW (quality advisory) or INFO (observation only)? Recommendation: LOW.

3. **Should the `claude-folder-audit-deep-inspection` orphan directory be cleaned up in this
   change's apply phase?** It is an empty directory with no artifacts. Answer: yes, the apply
   phase should remove it using `rmdir` (not delete if non-empty — it is confirmed empty).

4. **Should the report format change for the new checks?** Currently the report has a flat
   per-check section structure. With 8+ checks, a two-level structure (group header → individual
   checks) would improve readability. This is a cosmetic concern but affects skill length.

---

## Ready for Proposal

Yes — the exploration has identified:
- All 6 gaps in the current skill
- Clear severity mappings for each new check
- A concrete recommended approach (Approach C with sub-checks)
- Synergy points with the feature-domain-knowledge-layer ADR-015 (V2 activation)
- Risk mitigation strategies
- No blocking unknowns
