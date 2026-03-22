# Proposal: Fix Archive Residue and Specs Loading

Date: 2026-03-21
Status: Draft

## Intent

Resolve three interconnected SDD system issues: silent source directory deletion failures in sdd-archive, unreliable spec discovery in all phase skills, and missing post-explore contradiction gates in sdd-ff.

## Motivation

The exploration phase identified three critical gaps in the SDD system that undermine reliability:

1. **Silent archive failures**: sdd-archive Step 4 moves the change folder but silently fails when deleting the source directory. No error is reported; the residue persists invisibly, causing confusion when users re-run archives or audit the filesystem.

2. **Missed specs**: Phase skills (sdd-explore through sdd-apply) implement stem-based directory matching that fails when domain keywords don't align with slug tokens. The index.yaml file exists with keyword arrays designed to fix this, but phase skills do not use it. As a result, relevant specs are not loaded, leaving users without critical behavioral contracts during spec writing and design.

3. **Incomplete contradiction handling**: sdd-ff does not implement a post-explore gate for UNCERTAIN contradictions (per ADR 023). When exploration detects a contradiction that is not yet resolvable, users proceed to propose and spec without surfacing the ambiguity, leading to incomplete requirements capture.

These three issues are interdependent: archive deletion must be verifiable before phase skills can trust their move operations; specs must be discoverable before phase skills can validate requirements; and contradictions must be surfaced before users commit to designs.

## Supersedes

None — this is a purely additive change that improves reliability and completeness of existing systems.

## Scope

### Included

1. **sdd-archive Step 4 — Deletion verification**
   - Add explicit verification that source directory is deleted after move operation
   - If deletion fails, emit WARNING + manual recovery instructions
   - Use bash directory check with fallback for Windows compatibility

2. **All 7 phase skills — Index-first spec loading**
   - sdd-explore, sdd-propose, sdd-spec, sdd-design, sdd-tasks, sdd-apply, sdd-verify
   - Implement Step 0c (Spec context preload) to check for index.yaml first
   - If index.yaml present: use keyword-based domain scoring (stem matching + explicit keyword lookup)
   - If index.yaml absent: fall back to directory-based stem matching with INFO log
   - Cap matches at 3 domains (consistent with feature file matching)

3. **sdd-ff post-explore gate**
   - After sdd-explore completes, check exploration.md for UNCERTAIN contradictions
   - If present: emit gate prompt asking user to clarify OR proceed at own risk
   - Document the gate implementation in sdd-ff Step 2a (post-explore, pre-propose)

4. **project-setup scaffolding**
   - Add Step 5 to project-setup: scaffold index.yaml if not present
   - Create minimal valid index.yaml with empty domains array
   - Include a comment explaining the file's purpose

5. **Governance and documentation updates**
   - Update CLAUDE.md Fast-Forward section to reference the post-explore gate
   - Update openspec/config.yaml to document the three-phase apply strategy

### Excluded (explicitly out of scope)

- Rewriting the entire index.yaml file (existing structure is good; only scaffolding is added)
- Changing how project-setup creates feature stub files (orthogonal to specs)
- Modifying the orchestrator's Intent Classification system
- Changes to the global CLAUDE.md beyond documentation of the post-explore gate

## Proposed Approach

This change is delivered as a **phased holistic fix** to ensure consistency:

**Phase 1 — Critical Infrastructure (low risk)**
- sdd-archive Step 4: Add deletion verification
- project-setup: Scaffold index.yaml
- These are the minimal blocking dependencies for later phases

**Phase 2 — Spec Discovery (moderate complexity, high impact)**
- Update all 7 phase skill Step 0c implementations
- Implement index-first algorithm with directory fallback
- All skills updated atomically to guarantee consistency

**Phase 3 — Contradiction Gates (independent feature)**
- Implement post-explore gate in sdd-ff
- Gate only fires when UNCERTAIN contradictions are detected
- Non-blocking: if exploration.md pre-exists, gate does not fire

This structure allows verification after Phase 1 (deletion is verifiable) before committing to Phase 2 (specs are now discoverable) and Phase 3 (gates are in place).

## Affected Areas

| Area/Module | Type of Change | Impact |
| --- | --- | --- |
| `~/.claude/skills/sdd-archive/SKILL.md` | Modified (Step 4 expansion) | HIGH — core archiving reliability |
| `~/.claude/skills/sdd-explore/SKILL.md` | Modified (Step 0c algorithm change) | HIGH — gate functionality depends on this |
| `~/.claude/skills/sdd-propose/SKILL.md` | Modified (Step 0c algorithm change) | MEDIUM — inherits from sdd-explore |
| `~/.claude/skills/sdd-spec/SKILL.md` | Modified (Step 0c algorithm change) | MEDIUM — inherits from sdd-explore |
| `~/.claude/skills/sdd-design/SKILL.md` | Modified (Step 0c algorithm change) | MEDIUM — inherits from sdd-explore |
| `~/.claude/skills/sdd-tasks/SKILL.md` | Modified (Step 0c algorithm change) | MEDIUM — inherits from sdd-explore |
| `~/.claude/skills/sdd-apply/SKILL.md` | Modified (Step 0c algorithm change) | MEDIUM — inherits from sdd-explore |
| `~/.claude/skills/sdd-verify/SKILL.md` | Modified (Step 0c algorithm change) | MEDIUM — inherits from sdd-explore |
| `~/.claude/skills/sdd-ff/SKILL.md` | Modified (new Step 2a gate) | MEDIUM — user-facing decision point |
| `~/.claude/skills/project-setup/SKILL.md` | Modified (new Step 5 scaffolding) | LOW — optional safety improvement |
| `openspec/specs/sdd-archive-execution/spec.md` | Modified (new or updated REQ entries) | MEDIUM — documents the deletion verification contract |
| `openspec/specs/spec-context-discovery/spec.md` | Modified (new or updated REQ entries) | MEDIUM — documents the index-first algorithm |
| `openspec/specs/sdd-orchestration/spec.md` | Modified (new or updated REQ entries) | MEDIUM — documents the post-explore gate |
| `openspec/config.yaml` | Modified (documentation only) | LOW — clarifies apply phase strategy |
| `CLAUDE.md` (project root) | Modified (documentation only) | LOW — clarifies post-explore gate behavior |

## Risks

| Risk | Probability | Impact | Mitigation |
| --- | --- | --- | --- |
| Multiple skill files modified simultaneously cause syntax errors | Medium | HIGH — all 7 skills fail to load | Strict code review per skill; test stem-matching algorithm in isolation before apply |
| index.yaml not present in existing user projects, causing fallback to unreliable matching | Medium | MEDIUM — specs not loaded, but no error | project-setup now scaffolds it; fallback is safe (logs INFO, does not block) |
| Post-explore gate fires unexpectedly in active cycles | Low | MEDIUM — users surprised by gate prompt | Gate only fires when exploration.md is newly created; pre-existing exploration.md is not re-gated |
| Bash deletion verification behaves differently on Windows + Git Bash | Medium | MEDIUM — deletion may not be reliably detected | Test with actual Windows environment; use mcp__filesystem tools as fallback if bash fails |
| Archive apply hangs waiting for manual recovery if deletion fails | Low | LOW — user can manually clean up or skip recovery | Deletion failure is non-blocking; apply proceeds with WARNING; manual cleanup path is documented |

## Rollback Plan

**If issues arise during or after apply:**

1. **Phase 1 rollback** (if deletion verification causes issues):
   - Revert the changes to sdd-archive Step 4 (restore original move + delete logic)
   - Remove index.yaml scaffolding from project-setup
   - Existing archives are not affected (archived files remain in archive directory)
   - Command: `git reset --hard <commit-before-phase-1>`

2. **Phase 2 rollback** (if spec loading causes issues):
   - Revert all 7 phase skill Step 0c changes (restore directory-based matching)
   - Existing specs are not affected (no specs are deleted or modified)
   - Command: `git reset --hard <commit-before-phase-2>`

3. **Phase 3 rollback** (if post-explore gate causes issues):
   - Revert sdd-ff Step 2a (remove post-explore gate code)
   - Existing exploration.md files are not affected
   - Command: `git reset --hard <commit-before-phase-3>`

4. **Full rollback**:
   - If all three phases need rollback: `git reset --hard <commit-before-this-change>`

**Recovery steps** (if some archives are left in residual state):

- Manual cleanup: `rm -rf openspec/changes/<change-name>/` (restore from git history if needed)
- Re-run sdd-archive on the change to properly move and delete

## Dependencies

- **ADR 022 (spec-context-discovery)**: Defines how specs should be discovered via index.yaml keywords
- **ADR 023 (sdd-cycle-context-gaps)**: Defines the Supersedes section and contradiction handling gates
- **ADR 029 (sdd-archive-execution)**: Defines the archive move and deletion contract
- **Existing index.yaml**: Must be present in openspec/specs/ (already exists; project-setup now scaffolds it if absent)
- **No external dependencies**: All changes are self-contained in the SDD system; no new libraries or tools required

## Success Criteria

- [ ] After Phase 1 apply: sdd-archive Step 4 verifies source directory deletion and logs verification status (SUCCESS or WARNING with manual recovery path)
- [ ] After Phase 1 verify: /project-audit runs without new failures; no archive residue left behind in test projects
- [ ] After Phase 2 apply: All 7 phase skills implement index-first spec loading; Step 0c logs "Spec context loaded from: [index.yaml]" when index is present
- [ ] After Phase 2 verify: Exploration.md generated by sdd-explore includes specs matched from index.yaml keywords (verified by running sdd-explore on a test change that has index-keyword-matching specs)
- [ ] After Phase 3 apply: sdd-ff implements post-explore gate; if exploration.md contains UNCERTAIN contradictions, gate emits prompt before launching sdd-propose
- [ ] After Phase 3 verify: Running sdd-ff on a change with an UNCERTAIN contradiction fires the gate and waits for user confirmation (tested manually or with integration test)
- [ ] Rollback plan verified: Each phase can be independently rolled back without affecting archived changes or project integrity
- [ ] All 3 phases pass /project-audit with score >= previous (minimum 75)
- [ ] install.sh and sync.sh work correctly after all changes (deploy and capture work as expected)

## Effort Estimate

**High (12–16 hours of SDD work)**

- Exploration (completed): 2 hours
- Proposal (this document): 1 hour
- Spec (3 domains + 2 design docs): 3–4 hours
- Design (3 phases, ~8 modified files): 3–4 hours
- Tasks breakdown (Phase 1 ~3 tasks, Phase 2 ~5 tasks, Phase 3 ~2 tasks): 1 hour
- Apply Phase 1: 2–3 hours (deletion verification + scaffolding)
- Apply Phase 2: 3–4 hours (7 skill updates + testing)
- Apply Phase 3: 1–2 hours (post-explore gate)
- Verify (archive, test on real project): 2–3 hours

**Rationale**: Large surface area (8 skill files modified) but well-scoped changes. Spec and design work is straightforward because the root causes are clearly identified. Apply is staged to allow validation between phases.

## Context

### Explicit Intents

- **Holistic fix intent**: All three issues must be fixed in a single SDD cycle to guarantee consistency and prevent users from seeing partial fixes.
- **Phased apply intent**: Apply stages are ordered to allow validation after Phase 1 (critical deletion verification) before committing to later phases.
- **Windows compatibility**: Deletion verification must work on Windows + Git Bash (not just Unix).
- **Backward compatibility**: Fallback to directory-based matching when index.yaml is absent (safe default).

### Documented Constraints

- No changes to the global orchestrator (no Intent Classification modifications)
- No rewriting of index.yaml content (only scaffolding is added)
- Post-explore gate is non-blocking (user can proceed at own risk)
- Deletion verification is non-blocking (archive proceeds with WARNING if deletion fails)

### Open Design Questions Resolved

1. **Should project-setup scaffold index.yaml?** **Yes** — Include in Phase 1 for safety and optimization.
2. **How should the post-explore gate interact with pre-existing explorations?** **Only fire on newly created exploration.md** — if exploration.md pre-exists, gate does not fire (user already made the choice in a prior session).
3. **What is the deletion verification mechanism in sdd-archive Step 4?** **Option A: Bash directory check with mcp__filesystem fallback** — simpler and more direct; logs WARNING if deletion fails.
4. **Should index.yaml be mandatory or optional?** **Optional scaffolding** — project-setup creates it if absent; fallback is safe (logs INFO, does not block).

---

**Proposal approved for spec + design phases.**

Next step: `/sdd-spec fix-archive-residue-specs-loading` and `/sdd-design fix-archive-residue-specs-loading` (run in parallel).
