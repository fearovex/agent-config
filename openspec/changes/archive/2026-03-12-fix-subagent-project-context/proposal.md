# Proposal: Fix Sub-Agent Project Context Injection

**Date**: 2026-03-12
**Status**: Draft

---

## Intent

Sub-agents receive isolated skill instructions but lack access to project-level governance rules (CLAUDE.md), creating a governance asymmetry where project constraints (naming, architecture, organizational patterns) are not visible to SDD sub-agents in their initial context, unlike Copilot which receives full governance upfront.

---

## Motivation

**Current state:**
- **Copilot (via Cursor)** receives `.cursor/rules/*.mdc` files (exports of CLAUDE.md + ai-context/) at IDE startup, priming it with all project governance before any user instruction
- **Sub-agents** start with fresh context and a minimal prompt referencing only the SKILL.md path, causing them to discover project governance late (in Step 0 of phase skills) — after they've already formed initial assumptions

**Impact:**
This gap creates three concrete problems:
1. **Decision drift**: Sub-agents make architectural or organizational choices that don't reflect project conventions, later requiring rework
2. **Governance opacity**: The project's unbreakable rules (language requirements, SDD compliance rules, sync discipline, feedback persistence rules) are not visible to sub-agents at decision time
3. **Parity loss**: The SDD orchestrator claims to respect project governance, but sub-agents lack the same priming that Copilot enjoys, creating a gap between claimed behavior (orchestrator rules) and actual behavior (sub-agent decisions)

**Why now:**
The exploration artifact identifies a clear architectural gap in the sub-agent launch pattern. The fix is straightforward, non-breaking, and directly improves sub-agent decision quality without requiring changes to the skill resolution algorithm or artifact communication patterns.

---

## Scope

### Included

1. **Orchestrator-side (minimal change)**: Update the sub-agent prompt template in `skills/sdd-ff/SKILL.md` and `skills/sdd-new/SKILL.md` to pass the absolute path to the project's CLAUDE.md as an explicit CONTEXT field
2. **Skill-side (Phase skills Step 0 enhancement)**: Expand Step 0a in all SDD phase skills (`sdd-explore`, `sdd-propose`, `sdd-spec`, `sdd-design`, `sdd-tasks`, `sdd-apply`, `sdd-verify`) to read the full CLAUDE.md file (not just the Skills Registry section)
3. **Contract update**: Update `openspec/agent-execution-contract.md` to document the expanded context injection pattern
4. **Documentation**: Update `docs/sdd-context-injection.md` to reflect the full CLAUDE.md inclusion

### Excluded (explicitly out of scope)

- Passing CLAUDE.md content directly in the sub-agent prompt (unnecessary file duplication; sub-agents can read files)
- Reorganizing or splitting CLAUDE.md into multiple files
- Changes to the skill resolution algorithm (docs/SKILL-RESOLUTION.md) — sub-agents already resolve skills correctly
- Artifact communication changes — all inter-skill communication remains file-based
- Changes to the Phase DAG or orchestrator decision logic — this is purely a context injection fix

---

## Proposed Approach

### High-level technical solution

1. **Orchestrator prompts**: Both `sdd-ff` and `sdd-new` add a new line to the CONTEXT section of every sub-agent invocation:
   ```
   - Project governance: [project-root]/CLAUDE.md
   ```
   This makes the governance file path explicit and discoverable, allowing sub-agents to read it immediately.

2. **Phase skills Step 0a**: Expand the existing Step 0a block in all six phase skills to:
   - Read `ai-context/stack.md` (unchanged)
   - Read `ai-context/architecture.md` (unchanged)
   - Read `ai-context/conventions.md` (unchanged)
   - **NEW**: Read the full project `CLAUDE.md` (replacing the partial "Skills Registry only" approach)
   - Extract and log the unbreakable rules, tech stack, and intent classification rules

3. **Execution order**: Sub-agents perform Step 0 (governance loading) **before** Step 1 (reading prior phase artifacts). This ensures governance is loaded and available for all subsequent decision-making.

4. **Non-breaking**: The change is purely additive:
   - Step 0 remains non-blocking (failures emit INFO notes, execution continues)
   - Existing sub-agent behavior is unchanged if CLAUDE.md is absent
   - All subsequent steps are identical

### Why this approach

- **Minimal scope**: No changes to skill resolution, artifact format, or phase coordination
- **Symmetry with Copilot**: Sub-agents now receive governance priming similar to Copilot's upfront context load
- **Localized**: Changes are confined to orchestrator prompts and Step 0 of phase skills
- **Verifiable**: Sub-agents will log loaded governance rules, making the priming visible in their output

---

## Affected Areas

| Area/Module | Type of Change | Impact |
|-----------|----------------|--------|
| `skills/sdd-ff/SKILL.md` | Modified | Add CLAUDE.md path to sub-agent prompt template (3 locations: explore, propose, spec/design/tasks batches) |
| `skills/sdd-new/SKILL.md` | Modified | Add CLAUDE.md path to sub-agent prompt template (same 3 locations) |
| `skills/sdd-explore/SKILL.md` | Modified | Expand Step 0a to read full CLAUDE.md and log governance rules |
| `skills/sdd-propose/SKILL.md` | Modified | Expand Step 0a to read full CLAUDE.md and log governance rules |
| `skills/sdd-spec/SKILL.md` | Modified | Expand Step 0a to read full CLAUDE.md and log governance rules |
| `skills/sdd-design/SKILL.md` | Modified | Expand Step 0a to read full CLAUDE.md and log governance rules |
| `skills/sdd-tasks/SKILL.md` | Modified | Expand Step 0a to read full CLAUDE.md and log governance rules |
| `skills/sdd-apply/SKILL.md` | Modified | Expand Step 0a to read full CLAUDE.md and log governance rules |
| `skills/sdd-verify/SKILL.md` | Modified | Expand Step 0a to read full CLAUDE.md and log governance rules |
| `openspec/agent-execution-contract.md` | Modified | Document the new "Project governance" field in CONTEXT section |
| `docs/sdd-context-injection.md` | Modified | Update to reflect full CLAUDE.md inclusion in Step 0a |

---

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| Sub-agent prompt becomes too large | Low | Increased token usage per sub-agent invocation | The governance file path adds <200 bytes; impact negligible |
| CLAUDE.md absent in project | Medium | Sub-agents log INFO note and continue; no breakage | Non-blocking by design; fallback behavior unchanged |
| Sub-agents misread or over-interpret unbreakable rules | Low | Incorrect decisions despite rule visibility | Governance rules are self-documenting; sub-agents are instructed to log extracted rules; any misreading will be visible in sub-agent output |
| Existing sub-agent implementations break | Low | Old sub-agents crash on expanded Step 0 | All six phase skills are maintained by this project; no external sub-agents affected. Tested before archive. |
| Retroactive expectation that all historical projects had governance | Low | Confusion about why old projects didn't have sub-agent context | No external commitment made; context injection is opt-in (CLAUDE.md is optional) |

---

## Rollback Plan

**Fully reversible in 3 steps:**

1. **Remove governance path from orchestrator prompts**: Revert changes to `skills/sdd-ff/SKILL.md` and `skills/sdd-new/SKILL.md` (delete the "Project governance:" CONTEXT line)
2. **Revert Step 0a in phase skills**: Return to the original Step 0a that reads only the Skills Registry section of CLAUDE.md
3. **Revert documentation**: Revert `openspec/agent-execution-contract.md` and `docs/sdd-context-injection.md` to pre-change state

**Git workflow:**
```bash
git revert <commit-hash-of-apply> --no-edit
git push origin master
```

No data loss; all artifacts remain untouched. Sub-agents will function normally without the governance context (Step 0a failures are non-blocking).

---

## Dependencies

- **None explicit**: The CLAUDE.md file is already present in all agent-config projects
- **Implicit**: Projects relying on this change assume CLAUDE.md exists; absent governance file is non-blocking
- **External systems**: No changes required to user projects, Copilot, or other external systems

---

## Success Criteria

- [ ] **Orchestrator prompts include explicit governance path**: All sub-agent invocations in `sdd-ff` and `sdd-new` contain the CONTEXT field "Project governance: [path]"
- [ ] **Phase skills load full CLAUDE.md**: Step 0a in all six phase skills (`sdd-explore`, `sdd-propose`, `sdd-spec`, `sdd-design`, `sdd-tasks`, `sdd-apply`, `sdd-verify`) reads and logs the unbreakable rules, tech stack, and intent classification rules
- [ ] **Sub-agents report governance visibility**: Step 0 output in each phase skill includes a summary of loaded governance (e.g., "Loaded 5 unbreakable rules, tech stack: [language], intent classification: [enabled/disabled]")
- [ ] **Parity with Copilot**: Sub-agent decision-making now reflects the same governance constraints Copilot receives (as verified by manual code review of a sample sdd-apply task execution)
- [ ] **No governance drift in artifacts**: Output files from sub-agents respect project naming conventions, architectural constraints, and organizational patterns (verified by audit report scoring >= previous score)
- [ ] **Rollback succeeds cleanly**: Reverting all changes via git revert produces no conflicts and leaves the system in a functioning state

---

## Effort Estimate

**Low (4-6 hours of implementation)**

Breakdown:
- Orchestrator prompt updates: 20 min (straightforward text additions)
- Phase skills Step 0a expansion: 2-3 hours (repetitive changes across 7 files, minimal logic change)
- Documentation updates: 30 min (contract + context injection docs)
- Testing and verification: 1.5-2 hours (manual test with a real SDD cycle on a test project; verify audit score)

---

## Notes

This proposal addresses the core governance visibility gap identified in the exploration artifact while remaining non-breaking and minimal in scope. The change preserves the "isolation" principle (sub-agents remain independent) while improving the "priming" principle (governance is available at startup, not discovered late).

The proposal is **fully reversible** and introduces **no new external dependencies**. All changes are internal to the skills catalog and orchestration layer.
