# Proposal: tech-skill-auto-activation

Date: 2026-03-03
Status: Draft

## Intent

Add a Step 0 to `sdd-apply` that reads `ai-context/stack.md` and automatically loads matching technology skills before implementation begins, replacing the current vague "etc." heuristic with an exhaustive, configuration-driven mapping table.

## Motivation

The claude-config skill catalog contains 21 technology skills (react-19, nextjs-15, typescript, zustand-5, zod-4, tailwind-4, ai-sdk-5, react-native, electron, django-drf, spring-boot-3, hexagonal-architecture-java, java-21, playwright, pytest, github-pr, jira-task, jira-epic, elixir-antipatterns, excel-expert, image-ocr). These skills exist to encode best practices for each technology, but the current `sdd-apply` SKILL.md only says:

> "If I am implementing in a specific stack, I load the corresponding skill: TypeScript → `~/.claude/skills/typescript/SKILL.md` if it exists, React → `~/.claude/skills/react-19/SKILL.md` if it exists, etc."

Three concrete problems with this approach:

1. **"etc." is not actionable** — no exhaustive mapping exists. A sub-agent implementing Django code has no authoritative rule that maps Django → django-drf skill.
2. **Detection is implicit** — each sub-agent must use its own judgment on which skills to load. Two agents implementing the same stack may load different skill subsets or none at all.
3. **No formal mechanism** — a sub-agent can silently skip tech skill loading with no audit trail or deviation report.

The result is that the 21 technology skills function as a passive catalog: they exist on disk but are not reliably activated during implementation. The investment in those skills does not reliably translate into better implementation output.

## Scope

### Included

- Add **Step 0 — Technology Skill Preload** to `skills/sdd-apply/SKILL.md` that runs before Step 1 (Read full context)
- Embed a **Stack-to-Skill Mapping Table** directly in `sdd-apply/SKILL.md` (self-contained, no external config dependency)
- Define **detection rules**: read `ai-context/stack.md` (primary) and `openspec/config.yaml` project stack section (secondary); match detected technologies against the mapping table
- Define **scope guard**: skip preload for purely documentational or config-only changes (no code files in the file change matrix)
- Produce a **detection report** line per skill loaded: `"Tech skill loaded: typescript (source: ai-context/stack.md)"`
- Skills that do not exist at their path are silently skipped (non-blocking)

### Excluded (explicitly out of scope)

- Modifying any technology SKILL.md files — this change only modifies `sdd-apply`
- Adding a `skill_overrides` key to `openspec/config.yaml` — the mapping lives in sdd-apply itself; config override is future work
- Auto-loading ALL 21 skills unconditionally — only skills whose technology is detected in the stack are loaded
- Changing how the orchestrator (CLAUDE.md or sdd-ff) works — this is an sdd-apply sub-agent concern
- Creating a separate skill for the detection logic — the Step 0 logic is inlined in sdd-apply for self-containment

## Proposed Approach

Insert a new **Step 0** block at the top of the `## Process` section in `skills/sdd-apply/SKILL.md`. This step:

1. Reads `ai-context/stack.md` for technology keywords
2. Reads `openspec/config.yaml` `project.stack` section as a secondary signal
3. Consults an inline **Stack-to-Skill Mapping Table** embedded in the same SKILL.md file
4. Loads each matching skill file (reads it; adds its content as implementation context)
5. Produces one detection report line per skill loaded or skipped
6. If the file change matrix (from design.md) contains only `.md` and `.yaml` files, the step is skipped with note: `"Tech skill preload: skipped (documentation-only change)"`

The mapping table covers all 21 technology skills and uses keyword matching (e.g., `"react"` in stack → load `react-19`, `"django"` in stack → load `django-drf`).

The existing "I load technology skills if applicable" paragraph in the `## Code standards` section is replaced by a forward reference to Step 0.

## Affected Areas

| Area/Module | Type of Change | Impact |
|-------------|----------------|--------|
| `skills/sdd-apply/SKILL.md` | Modified — add Step 0 + mapping table + scope guard | Medium — changes sub-agent behavior during every apply |
| `ai-context/conventions.md` | Possibly updated — record Step 0 convention | Low |
| `ai-context/changelog-ai.md` | Updated — log this change | Low |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Step 0 adds reading overhead per apply invocation | Medium | Low | Skills are read once; no network I/O; overhead is minimal |
| False positive detection (wrong skill loaded) | Low | Low | Keyword matching is per-technology; mismatch adds context overhead but does not break implementation |
| `ai-context/stack.md` absent in a project | Medium | Low | Step is non-blocking: if file is missing, skip with INFO note |
| Mapping table becomes stale as new skills are added | Low | Medium | The mapping table lives in sdd-apply/SKILL.md and is updated as part of any new technology skill addition |

## Rollback Plan

The change is confined to one file: `skills/sdd-apply/SKILL.md`.

To revert:
1. `git revert` the commit that introduced this change, or
2. Restore the previous version of `skills/sdd-apply/SKILL.md` from git history
3. Run `bash install.sh` to redeploy the reverted file to `~/.claude/`
4. No data migration or schema change is involved

## Dependencies

- `ai-context/stack.md` must be present in target projects for detection to work (non-blocking if absent)
- The 21 technology skills must be installed at `~/.claude/skills/` (non-blocking if individual files are absent)

## Success Criteria

- [ ] `sdd-apply/SKILL.md` contains a Step 0 block that appears before Step 1 in the `## Process` section
- [ ] Step 0 contains an exhaustive Stack-to-Skill Mapping Table covering all 21 catalog technology skills
- [ ] Step 0 reads `ai-context/stack.md` as the primary detection source
- [ ] Step 0 produces a detection report line for each skill loaded (e.g., `"Tech skill loaded: typescript"`)
- [ ] Step 0 has a scope guard that skips preload for documentation-only changes
- [ ] Skills absent from disk are silently skipped (non-blocking behavior)
- [ ] The old "etc." paragraph in `## Code standards` is replaced by a forward reference to Step 0
- [ ] `/project-audit` score on claude-config is >= previous score after apply

## Effort Estimate

Low (hours) — single file modification with well-defined content.
