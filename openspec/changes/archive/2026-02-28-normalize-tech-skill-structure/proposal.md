# Proposal: normalize-tech-skill-structure

Date: 2026-02-27
Status: Draft

## Intent

Add missing `**Triggers**` and `## Rules` structural sections to all tech skill SKILL.md files so they conform to the SDD convention and pass D9-3 (structural completeness) and D10-b (structural quality) audit dimensions.

## Motivation

The Gentleman-Skills catalog was imported as the technology skill set for claude-config. These skills were authored with a different convention than the SDD SKILL.md standard:

- They use YAML frontmatter `description` field (which includes trigger text) instead of a `**Triggers**` line in the body
- They have process/step sections but no `## Rules` section

The project-audit skill checks for:
- **D9-3**: Each skill SKILL.md has trigger definition + process steps + rules section
- **D10-b**: Feature docs (SKILL.md files) have required structural quality markers

With 20 out of 23 tech skills missing `**Triggers**` entirely, and all 23 missing `## Rules`, these dimensions fail for the entire tech skill catalog. This gap was formally detected during the `global-config-skill-audit` SDD cycle via D10 reporting.

Additionally, `claude-code-expert`, `excel-expert`, and `image-ocr` — three skills added after the initial import — already have `**Triggers**` but are also missing `## Rules`, so they need a partial fix.

## Scope

### Included

- Add a `**Triggers**` line (derived from the frontmatter `description` trigger text) to the SKILL.md body of all 20 tech skills that are missing it
- Add a `## Rules` section (with skill-appropriate constraints) to all 23 tech skills missing it
- Skills in scope: `ai-sdk-5`, `django-drf`, `electron`, `elixir-antipatterns`, `github-pr`, `hexagonal-architecture-java`, `java-21`, `jira-epic`, `jira-task`, `nextjs-15`, `playwright`, `pytest`, `react-19`, `react-native`, `smart-commit`, `spring-boot-3`, `tailwind-4`, `typescript`, `zod-4`, `zustand-5` (need both sections), plus `claude-code-expert`, `excel-expert`, `image-ocr` (need `## Rules` only)

### Excluded (explicitly out of scope)

- SDD phase skills (`sdd-propose`, `sdd-apply`, etc.) — already conformant, not touched
- Meta-tool skills (`project-audit`, `memory-manager`, etc.) — already conformant, not touched
- Changes to YAML frontmatter — the `description` field is not changed, only the Markdown body is augmented
- Process/step section rewrites — only additive changes, no content rewriting
- Updating `openspec/config.yaml` feature_docs configuration — separate concern

## Proposed Approach

For each affected tech skill SKILL.md:

1. **Triggers line**: Insert `**Triggers**: <trigger-text>` immediately after the title/description block at the top of the Markdown body, below the frontmatter. The trigger text is extracted from the existing frontmatter `description` field (the sentence following "Trigger:" if present, otherwise a short summary of the skill name).

2. **Rules section**: Append a `## Rules` section at the end of each SKILL.md with 3–5 skill-appropriate rules. Rules cover: scope of use, what the skill does/does not do, required inputs, and any key constraints or best-practice reminders specific to that technology.

The additions are **purely additive** — no existing content is modified or removed. The frontmatter is untouched.

## Affected Areas

| Area/Module | Type of Change | Impact |
|-------------|----------------|--------|
| `skills/ai-sdk-5/SKILL.md` | Modified (add Triggers + Rules) | Low |
| `skills/django-drf/SKILL.md` | Modified (add Triggers + Rules) | Low |
| `skills/electron/SKILL.md` | Modified (add Triggers + Rules) | Low |
| `skills/elixir-antipatterns/SKILL.md` | Modified (add Triggers + Rules) | Low |
| `skills/github-pr/SKILL.md` | Modified (add Triggers + Rules) | Low |
| `skills/hexagonal-architecture-java/SKILL.md` | Modified (add Triggers + Rules) | Low |
| `skills/java-21/SKILL.md` | Modified (add Triggers + Rules) | Low |
| `skills/jira-epic/SKILL.md` | Modified (add Triggers + Rules) | Low |
| `skills/jira-task/SKILL.md` | Modified (add Triggers + Rules) | Low |
| `skills/nextjs-15/SKILL.md` | Modified (add Triggers + Rules) | Low |
| `skills/playwright/SKILL.md` | Modified (add Triggers + Rules) | Low |
| `skills/pytest/SKILL.md` | Modified (add Triggers + Rules) | Low |
| `skills/react-19/SKILL.md` | Modified (add Triggers + Rules) | Low |
| `skills/react-native/SKILL.md` | Modified (add Triggers + Rules) | Low |
| `skills/smart-commit/SKILL.md` | Modified (add Triggers + Rules) | Low |
| `skills/spring-boot-3/SKILL.md` | Modified (add Triggers + Rules) | Low |
| `skills/tailwind-4/SKILL.md` | Modified (add Triggers + Rules) | Low |
| `skills/typescript/SKILL.md` | Modified (add Triggers + Rules) | Low |
| `skills/zod-4/SKILL.md` | Modified (add Triggers + Rules) | Low |
| `skills/zustand-5/SKILL.md` | Modified (add Triggers + Rules) | Low |
| `skills/claude-code-expert/SKILL.md` | Modified (add Rules only) | Low |
| `skills/excel-expert/SKILL.md` | Modified (add Rules only) | Low |
| `skills/image-ocr/SKILL.md` | Modified (add Rules only) | Low |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Triggers text is inaccurate or too generic | Low | Low | Derive triggers from frontmatter description; review each one during apply |
| Rules section content is too generic to be useful | Low | Low | Write skill-specific rules that reflect real constraints for that technology |
| A SKILL.md has an unusual structure that breaks insertion logic | Low | Medium | Read each file before editing; confirm structure manually |
| Changes to runtime ~/.claude/ not reflected (deploy forgotten) | Low | Medium | Rollback plan and install.sh step in success criteria |

## Rollback Plan

All changes are additive (no deletions, no rewrites of existing content). To revert:

1. Identify changed files via `git diff --name-only`
2. Run `git checkout -- skills/<skill-name>/SKILL.md` for each affected file
3. Run `install.sh` to redeploy the reverted files to `~/.claude/`
4. Verify with `/project-audit` that the score returns to the pre-change baseline

Because git tracks every change, rollback is a single `git revert <commit>` if committed as a single commit.

## Dependencies

- No prior SDD changes must be in-progress that modify the same SKILL.md files
- `install.sh` must be functional (deploy step after apply)

## Success Criteria

- [ ] All 23 tech skill SKILL.md files have a `**Triggers**` line in the Markdown body (or already had one)
- [ ] All 23 tech skill SKILL.md files have a `## Rules` section
- [ ] `grep -r "^\*\*Triggers\*\*" ~/.claude/skills/` returns at least 23 hits covering the tech skills
- [ ] `grep -r "^## Rules" ~/.claude/skills/` returns hits for all 23 tech skills
- [ ] `/project-audit` D9-3 passes (no structural completeness failures for tech skills)
- [ ] `/project-audit` D10-b passes or improves (structural quality of feature docs)
- [ ] `install.sh` runs successfully after apply
- [ ] `git commit` records the change with a descriptive message

## Effort Estimate

Low (hours) — 23 files, additive-only edits, no logic changes, no new files to design.
