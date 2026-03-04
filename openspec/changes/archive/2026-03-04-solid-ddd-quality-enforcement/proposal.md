# Proposal: solid-ddd-quality-enforcement

Date: 2026-03-04
Status: Draft

## Intent

Introduce a `solid-ddd` skill with SOLID principles and DDD patterns, and strengthen `sdd-apply`'s code quality enforcement so sub-agents have explicit, verifiable acceptance criteria before marking any task complete.

## Motivation

The current SDD implementation system has a structural gap: technology skills (react-19, typescript, django-drf, etc.) teach framework patterns but contain no SOLID or DDD principles. Meanwhile, `sdd-apply`'s "Code Standards" section only tells sub-agents to "follow conventions" and "no over-engineering" — vague directives with no actionable checklist. This means a sub-agent can produce structurally unsound code (god classes, anemic domain models, leaky abstractions, violated SRP) and still mark a task `[x]` complete, because there is no explicit quality gate.

Additionally, tech skills ARE loaded in sdd-apply Step 0, but there is no instruction to treat their patterns as acceptance criteria before closing a task. The skill preload is informational, not enforcement-oriented.

The cumulative effect: code quality in SDD-driven projects depends entirely on the sub-agent's default behavior, with no repeatable standard anchored in the skill system.

## Scope

### Included

- New skill `skills/solid-ddd/SKILL.md` covering:
  - SOLID principles (SRP, OCP, LSP, ISP, DIP) with concrete do/don't examples
  - DDD tactical patterns: Entity, Value Object, Aggregate, Repository, Domain Service, Application Service, Ports & Adapters (Hexagonal)
  - Practical signals: what to look for when reviewing code for SOLID/DDD compliance
  - Anti-patterns to avoid (god class, anemic domain model, service as god object, etc.)
- Register `solid-ddd` in global CLAUDE.md Skills Registry under a new "Design Principles" section
- Strengthen `sdd-apply`'s "Code Standards" section with:
  - An explicit quality checklist (minimum 5 items) that MUST be checked before marking any code task `[x]`
  - Instruction to treat loaded technology skills AND solid-ddd (when loaded) as acceptance criteria, not just contextual reference
- Add `solid-ddd` to sdd-apply's Stack-to-Skill Mapping Table with a keyword that triggers its loading for non-documentation changes (keyword: `solid`, `ddd`, `domain driven`, or unconditional for all code changes)

### Excluded (explicitly out of scope)

- Modifying any existing technology skill (react-19, typescript, etc.) to embed SOLID/DDD — each skill has its own SDD cycle requirement; cross-cutting concerns belong in a dedicated skill
- Creating per-language SOLID/DDD skills — one language-agnostic skill covers the principles; tech skills provide the language-specific idioms
- Automated linting or static analysis integration — enforcement is knowledge-based, not tooling-based in V1
- Modifying `sdd-spec` or `sdd-design` to reference `solid-ddd` — design is the correct place to decide architecture; apply is the correct place to enforce it during writing
- Changes to `sdd-verify` — verify already checks spec compliance; quality checklist enforcement belongs at the apply phase (prevent vs. detect)

## Proposed Approach

1. **Author `solid-ddd` as a `reference` format skill** — it is a pattern catalog (do/don't), not a procedure. The `format: reference` declaration requires `## Patterns` or `## Examples` + `## Rules`, making it structurally consistent with other tech skills.

2. **Add `solid-ddd` to sdd-apply's preload mapping with an unconditional trigger for code changes** — unlike framework skills that are conditional on stack keywords, SOLID and DDD are universal design principles applicable to any code. The scope guard (docs-only exclusion) already handles the skip case. For all non-docs changes, `solid-ddd` is always loaded alongside any matched framework skills.

3. **Replace sdd-apply's vague Code Standards section with a structured Quality Gate** — a numbered checklist with 5–7 criteria covering: single responsibility verification, abstraction appropriateness, dependency direction, domain model integrity, and no silent over-engineering. The sub-agent MUST evaluate each criterion before marking a task complete. If one fails, the sub-agent reports a QUALITY_VIOLATION note (non-blocking by default, escalated to DEVIATION if it contradicts the spec).

## Affected Areas

| Area/Module | Type of Change | Impact |
|-------------|----------------|--------|
| `skills/solid-ddd/SKILL.md` | New | Medium — new skill, no breaking changes |
| `skills/sdd-apply/SKILL.md` | Modified | High — changes how sub-agents evaluate task completion |
| `CLAUDE.md` (global) | Modified | Low — registry entry only |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Quality checklist makes sdd-apply too rigid for simple/scripting tasks | Medium | Medium | Design checklist items to be self-evidently N/A for trivial tasks (e.g. "no domain model touched → DDD criteria N/A"); add "mark N/A with reason" option per item |
| solid-ddd unconditional preload adds token overhead for all code changes | Low | Low | Reference skill body is read once per task batch; token cost is justified by consistent quality output |
| Existing sdd-apply sub-agents (in active changes) may behave differently after the skill update | Low | Low | Change only affects future sdd-apply invocations; active in-progress changes are unaffected mid-flight |
| DDD patterns may conflict with existing hexagonal-architecture-java skill | Low | Medium | solid-ddd covers language-agnostic DDD; hexagonal-architecture-java covers Java-specific Hexagonal. Co-existence is intentional — one is principles, the other is Java implementation idioms. Explicitly document the relationship in solid-ddd |

## Rollback Plan

If the quality gate causes regressions or blocks legitimate tasks:

1. Revert `skills/sdd-apply/SKILL.md` to the pre-change version (available in git history)
2. Remove `solid-ddd` from the Stack-to-Skill Mapping Table in sdd-apply
3. Remove `skills/solid-ddd/SKILL.md` and its directory
4. Remove the registry entry from CLAUDE.md
5. Run `bash install.sh` to deploy the reverted state to `~/.claude/`
6. Verify with `/project-audit` that score is restored

The change is fully reversible via git. No database migrations or external state changes.

## Dependencies

- No prior changes are required before starting
- `skills/solid-ddd/SKILL.md` must be created BEFORE modifying `sdd-apply` (so the preload reference resolves correctly)
- `install.sh` must be run after apply to deploy both files to `~/.claude/`

## Success Criteria

- [ ] `skills/solid-ddd/SKILL.md` exists, passes `format: reference` section contract (`**Triggers**`, `## Patterns` or `## Examples`, `## Rules`), and body length >= 30 lines
- [ ] `sdd-apply`'s Code Standards section contains a numbered quality checklist with at least 5 criteria, each independently verifiable
- [ ] `sdd-apply` Stack-to-Skill Mapping Table includes an entry for `solid-ddd` that triggers for all non-documentation code changes
- [ ] `CLAUDE.md` Skills Registry contains an entry for `~/.claude/skills/solid-ddd/SKILL.md` under a "Design Principles" or equivalent section
- [ ] `/project-audit` score on `claude-config` is >= the pre-change score after apply
- [ ] `install.sh` runs without error and deploys `solid-ddd/SKILL.md` and the updated `sdd-apply/SKILL.md` to `~/.claude/skills/`
- [ ] A test sdd-apply run on a code-touching change confirms the quality checklist appears in the sub-agent output

## Effort Estimate

Medium (1–2 days) — authoring the solid-ddd skill requires substantive content; the sdd-apply modification is surgical but high-impact.
