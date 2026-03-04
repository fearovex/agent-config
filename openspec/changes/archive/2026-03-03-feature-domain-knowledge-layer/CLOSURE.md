# Closure: feature-domain-knowledge-layer

Start date: 2026-03-03
Close date: 2026-03-03

## Summary

Added a Feature Intelligence Layer (`ai-context/features/`) to the SDD system, enabling domain knowledge (business rules, invariants, integration points, decision logs, known gotchas) to be captured once per bounded context and automatically preloaded into relevant SDD phases instead of being rediscovered from code on every cycle.

## Modified Specs

| Domain | Action | Change |
|--------|--------|--------|
| feature-domain-knowledge | Created | New master spec — template structure, naming conventions, new feature-domain-expert skill requirements, worked example requirement |
| memory-management | Created | New master spec — memory-init feature discovery step, memory-update feature file update path |
| sdd-phase-context-loading | Created | New master spec — optional domain context preload for sdd-propose and sdd-spec |
| system-documentation | Created | New master spec — CLAUDE.md memory table update, Skills Registry entry, architecture.md artifact table, install.sh coverage |

## Modified Code Files

- `ai-context/features/_template.md` — created (canonical six-section template)
- `ai-context/features/sdd-meta-system.md` — created (worked example feature file)
- `skills/feature-domain-expert/SKILL.md` — created (new reference-format skill)
- `skills/sdd-propose/SKILL.md` — Step 0 domain context preload inserted
- `skills/sdd-spec/SKILL.md` — Step 0 domain context preload inserted
- `skills/memory-init/SKILL.md` — Step 7 feature discovery block appended
- `skills/memory-update/SKILL.md` — Step 3b feature file update path added
- `CLAUDE.md` — memory layer table row added, Skill Overlap table updated, Skills Registry entry added
- `ai-context/architecture.md` — artifact communication table row added for `ai-context/features/*.md`

## Key Decisions Made

- Storage at `ai-context/features/<domain>.md` — extends the existing memory layer pattern; avoids conflating observable behavior (openspec/specs/) with business context (feature docs)
- Domain matching heuristic: filename-stem match (split change slug on hyphens, match if domain slug appears in change name or vice versa) — zero-config, convention-based, non-blocking on miss
- `feature-domain-expert` placed in global tier (`skills/`) not project-local — it is a meta-system authoring guide, not a project-specific skill
- Write ownership is strictly `memory-update` (session) + `memory-init` (scaffold); `project-analyze` explicitly does NOT write to `ai-context/features/`
- New template file approach instead of a new `format:` value — avoids cascading changes to project-audit, project-fix, skill-creator, and docs/format-types.md
- V1 activates memory side only; audit integration (D10 `feature_docs:` config hook) deferred to V2

## Lessons Learned

- The self-referential nature of this repo (claude-config is both the SDD meta-system and the project under SDD) makes D3f conflict detection trigger when multiple changes modify CLAUDE.md in the same cycle. The conflict resolved naturally when the earlier change (config-export) was archived first.
- Verification was straightforward because all artifacts were created before the verify step — the spec scenarios mapped directly onto verifiable file paths.

## User Docs Reviewed

N/A — this change adds internal SDD infrastructure (ai-context/features/ layer and skill updates). It does not add, remove, or rename user-facing commands, change onboarding workflows for external projects, or introduce new top-level `/command` entries. No update to scenarios.md, quick-reference.md, or onboarding.md was required.
