# Proposal: enhance-claude-folder-audit

Date: 2026-03-03
Status: Draft

## Intent

Extend the `claude-folder-audit` skill's project mode from 5 shallow structural checks (P1–P5) to 8 meaningful audit dimensions that validate CLAUDE.md content quality, SKILL.md format compliance, the `ai-context/` memory layer, and the `.claude/` folder inventory.

## Motivation

The `claude-folder-audit` skill was reported as "too shallow" after running it on a real project that had significant `.claude/` content: only one LOW-severity finding (P5 scope tier overlap) was produced. Investigation confirmed that P1–P5 only verify *file and directory existence* plus *registration consistency* — no SKILL.md content is ever read, no `ai-context/` presence is checked, and nothing outside `CLAUDE.md` and `skills/` is inspected.

Three converging pressures make this enhancement necessary now:

1. **Unbreakable Rule 2 is not enforced.** CLAUDE.md mandates that every SKILL.md declare a valid `format:` field and satisfy its format's section contract (`**Triggers**`, `## Process`, `## Rules` for procedural; similar for reference and anti-pattern). The audit currently cannot detect a SKILL.md that violates these rules.

2. **ADR-015 V2 is due.** The feature-domain-knowledge-layer SDD change (merged 2026-03-03) explicitly deferred audit integration for `ai-context/features/` to a V2. That V2 is this change.

3. **The memory layer is invisible to the audit.** Projects using `ai-context/` get no quality feedback on whether the five core files exist or whether feature files conform to the six-section template.

## Scope

### Included

- **P1 extended** — CLAUDE.md content quality sub-checks: mandatory sections presence (`## Tech Stack`, `## Architecture`, `## Unbreakable Rules`, `## Plan Mode Rules`, `## Skills Registry`), minimum line count (>50), SDD command references (`/sdd-ff`, `/sdd-new`)
- **P2/P3 extended** — SKILL.md content sub-checks on all registered skills: YAML frontmatter presence, `format:` field validity (`procedural` | `reference` | `anti-pattern`), section contract compliance per format type (reading `docs/format-types.md` as the source of truth), and stub detection (<30 lines post-frontmatter)
- **P6 (new)** — `ai-context/` core files check: directory presence, five required files (`stack.md`, `architecture.md`, `conventions.md`, `known-issues.md`, `changelog-ai.md`), and minimum content length per file
- **P7 (new)** — `ai-context/features/` layer check (ADR-015 V2): directory presence, non-template file inventory, six-section completeness per feature file, stub detection
- **P8 (new)** — `.claude/` folder inventory: enumerate all items in `.claude/`, flag unknown items (not in expected set), check `hooks/` script non-emptiness if hooks directory is present
- **Orphan cleanup** — remove the empty directory `openspec/changes/claude-folder-audit-deep-inspection/` as part of the apply phase
- **Report format update** — group findings by check area with a two-level structure (check header → findings) to handle the increased check count readably

### Excluded (explicitly out of scope)

- **Global-config and global mode content quality checks** — Checks 1–5 in global/global-config modes will NOT receive equivalent content quality extensions in this change. Extending both modes simultaneously doubles the scope; global-mode quality checks are deferred to a follow-up.
- **`openspec/config.yaml` feature_docs block activation** — The `feature_docs:` block remains commented out. P7 will use directory-detection heuristics (presence of `ai-context/features/` with non-template `.md` files), not config-driven detection. Config-driven P7 is a follow-up.
- **Staleness detection for ai-context/ files** — Checking whether `ai-context/` files are outdated based on mtime or git log is out of scope. Only presence and content length are checked.
- **CLAUDE.md structural linting beyond section presence** — Verifying that Skills Registry entries are syntactically valid YAML or that command tables are well-formed is out of scope.
- **Automated fix application** — The audit is read-only; it reports findings and severities but does not apply corrections. Fixes remain the domain of `/project-fix`.

## Proposed Approach

The existing P1–P5 check logic will be preserved verbatim; no identifiers will change. Extensions are additive:

For P1: after confirming CLAUDE.md exists, the skill will read its content and scan for required section headings using simple line-prefix matching (`## Section Name` or `**Section Name**`). It will count total lines and search for SDD command strings.

For P2/P3: after confirming a SKILL.md file exists, the skill will read it and apply a two-stage check — first YAML frontmatter parsing (look for leading `---` block and extract `format:` value), then section-header scanning conditioned on the detected format type. The section contract rules come from `docs/format-types.md`.

For P6/P7/P8: three new numbered checks in project mode, each self-contained. P6 lists `ai-context/` contents. P7 lists `ai-context/features/` contents, excludes `_template.md`, and reads each non-template file to verify section presence. P8 lists all items in `.claude/` and compares against a known expected set.

Section detection uses the same pattern across all checks: match against `## Heading` (top-level markdown headings) and `**Heading**` (bold inline triggers). This pattern is consistent with how existing SKILL.md skills are authored.

## Affected Areas

| Area/Module | Type of Change | Impact |
|-------------|----------------|--------|
| `skills/claude-folder-audit/SKILL.md` | Modified — extend P1, P2, P3; add P6, P7, P8 | High |
| `docs/format-types.md` | Read-only reference | None (read, not modified) |
| `ai-context/features/_template.md` | Read-only reference | None (read, not modified) |
| `openspec/changes/claude-folder-audit-deep-inspection/` | Removed (empty orphan directory) | Low |
| `ai-context/architecture.md` | Modified — add new checks to audit inventory | Low |
| `docs/adr/README.md` | Modified — register new ADR if design determines one is warranted | Low |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Report length explosion on healthy projects | Medium | Low | Only emit detailed subsections for checks that have findings; collapse INFO-only checks into a one-line summary |
| False positives in section detection (header inside a code fence) | Low | Medium | Match only lines that START with `## ` or `**` (not lines inside fenced code blocks); document the matching rule in the skill |
| Scope creep from "ideal .claude/ folder" definition | Medium | Medium | Keep all new content-quality checks at MEDIUM or below severity; reserve HIGH only for pre-existing structural failures |
| P2/P3 extension reads large SKILL.md files per registered skill | Low | Low | Skills are markdown files typically under 700 lines; reading them adds negligible cost to an interactive audit command |
| Regression in P1–P5 behavior during the rewrite | Low | High | The apply phase must keep P1–P5 logic unchanged; the verify phase tests P1–P5 on a real project to confirm no regression |

## Rollback Plan

All changes are confined to `skills/claude-folder-audit/SKILL.md` and `ai-context/architecture.md`. If a regression is found post-deploy:

1. Revert `skills/claude-folder-audit/SKILL.md` to its pre-change state via `git revert` or `git checkout <prev-sha> -- skills/claude-folder-audit/SKILL.md`.
2. Run `bash install.sh` to redeploy the reverted skill to `~/.claude/`.
3. Revert `ai-context/architecture.md` if needed via the same `git checkout` pattern.
4. The orphan directory `openspec/changes/claude-folder-audit-deep-inspection/` cannot be restored from git (it was empty with no committed content); this is acceptable — no information is lost.

## Dependencies

- `docs/format-types.md` must exist and contain the section contracts for `procedural`, `reference`, and `anti-pattern` format types (confirmed present in current repo).
- `ai-context/features/_template.md` must exist and contain the six required section headers used to validate feature files (confirmed present in current repo).
- The existing P1–P5 checks in `skills/claude-folder-audit/SKILL.md` must remain unchanged in behavior — the apply phase must not refactor them.

## Success Criteria

- [ ] Running the audit on the `att-future-you-prototypes` project (the project that triggered this change) produces more than one finding and covers at least SKILL.md content quality and ai-context/ presence
- [ ] P1 sub-checks detect a CLAUDE.md missing `## Unbreakable Rules` or with fewer than 50 lines and report MEDIUM severity
- [ ] P2/P3 sub-checks detect a SKILL.md with no `format:` field in its frontmatter and report LOW severity
- [ ] P2/P3 sub-checks detect a SKILL.md missing a required section for its declared format type and report MEDIUM severity
- [ ] P6 reports MEDIUM when `ai-context/` is absent and LOW for each missing core file when `ai-context/` exists but is incomplete
- [ ] P7 reports LOW for each missing required section in a non-template feature file; INFO when `ai-context/features/` is absent entirely
- [ ] P8 reports MEDIUM for any unrecognized file or directory in `.claude/` that is not in the expected item set
- [ ] All existing P1–P5 checks produce identical findings on a project where no new gaps exist (no regression)
- [ ] `/project-audit` score on `claude-config` repo remains >= the pre-change score

## Effort Estimate

Medium (1–2 days) — the SKILL.md rewrite is the bulk of the work; the checks themselves are straightforward text-scanning logic applied to markdown files.
