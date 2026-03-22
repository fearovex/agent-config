# Exploration: Fix Archive Residue and Specs Loading

## Handoff Context

None — no pre-seeded proposal.md found.

## Current State

### Issue 1: sdd-archive Step 4 — Silent Source Directory Deletion Failure

**Location:** `~/.claude/skills/sdd-archive/SKILL.md` Step 4 (lines 222–252)

**Current behavior:**
- After moving the change folder from `openspec/changes/<name>/` to `openspec/changes/archive/YYYY-MM-DD-<archive_slug>/`, the skill attempts to delete the source directory
- **Line 250–252:** "After ALL files are confirmed present at `openspec/changes/archive/<date>-<archive_slug>/`, I MUST delete `openspec/changes/<change-name>/` and all its contents... If confirmation fails, I halt and report an error without deleting the source."
- **Issue:** The code uses the `mcp__filesystem__move_file` tool for the move operation. When the source directory deletion silently fails (due to filesystem permissions, open file handles, or race conditions), execution continues to Step 5 without explicit error reporting. The warning path (lines 251–252) requires "confirmation fails", but in practice the move succeeds and deletion fails silently.
- **Gap:** No detection mechanism to verify that the source directory is actually deleted before continuing. The skip condition is file-confirmation failure, not deletion failure.

**Evidence from recent archive:**
- Commit `3c71a0e` ("fix(sdd-archive): resolve source directory deletion gap in Step 4") addresses this but the fix is not yet reflected in the published SKILL.md we just read. The commit message indicates the issue was recognized and partially fixed, but the detailed mechanism is not clear from the SKILL.md text alone.
- Recent archives show completed moves (specs synced, closure notes created), so the move itself works correctly — but residue may still exist in the source directory.

---

### Issue 2: Specs Not Loaded by Phase Skills — Mismatch Between Stem Matching and Index-Driven Selection

**Location:** Affects `sdd-explore` and all SDD phase skills (propose, spec, design, tasks, apply) Step 0c "Spec context preload"

**Current algorithm (in SKILL.md lines 78–86):**
```
stems = change_name.split("-").filter(s => s.length > 1)
matches = []
for domain in candidates:
  if domain in change_name OR any stem in domain:
    matches.append(domain)
matches = matches[:3]
```

**Problem:**
The algorithm is **backward** — it checks if domain names appear **in** the change slug or if any stem appears **in** the domain name. This works only when domain keywords happen to match slug tokens.

For the change `2026-03-21-fix-archive-residue-specs-loading`:
- **Stems:** `fix`, `archive`, `residue`, `specs`, `loading`
- **Domain to load:** `sdd-archive-execution` (defines how sdd-archive moves and deletes, directly relevant)
- **Match result:** The stem `archive` matches the domain name `sdd-archive-execution` — **works by accident**

However, another critical domain is `spec-context-discovery`:
- **Keywords:** `[spec-context, preload, stem-matching, phase-skills, context-loading, spec-files]`
- **Stem match:** The stem `specs` does NOT appear in the domain name `spec-context-discovery`. The stem-based algorithm **fails to match** this domain even though the keywords array explicitly contains `spec-context` and `phase-skills`.

**Root cause:**
The skill currently implements a **directory-based fallback** (Algorithm A in line 76: "list subdirectory names in `openspec/specs/`"). The `index.yaml` file exists and contains `keywords` arrays designed to address this exact gap (ADR 022, `openspec/specs/spec-index/spec.md`), but the phase skills **do not use the index** — they fall back to directory-based stem matching.

**Documented behavior vs. implemented behavior:**
- **Spec says:** ("docs/SPEC-CONTEXT.md" reference in SKILL.md line 94) SDD phases should use index-driven selection when `index.yaml` is present
- **Code says:** Step 0c lines 76 does **not** check for `index.yaml` first; it only lists directory names directly
- **What should happen:** Read `index.yaml`, tokenize change slug, score each domain by keyword overlap, select top 3

---

### Issue 3: index.yaml Is Not Required/Scaffolded

**Current state:**
- `index.yaml` exists in the repo at `openspec/specs/index.yaml` (confirmed present)
- Contains 56 domain entries with well-formed keywords arrays
- However, its presence is **optional** — `project-setup` does not create it
- **Fallback:** when `index.yaml` is absent, SDD phases revert to the buggy directory-based stem matching algorithm above

**Impact:**
On projects where `index.yaml` is never created (or accidentally deleted), all phase skills silently degrade to unreliable matching. No warning is issued; execution continues without loading critical specs.

---

### Issue 4: Contradiction Gates in sdd-ff

**Location:** CLAUDE.md Classification Decision Table + sdd-ff skill (lines 99–106 in CLAUDE.md)

**Current behavior:**
- Rule 7 in CLAUDE.md Unbreakable Rules states: when a user message includes removal/replacement language, the orchestrator MUST confirm intent before recommending `/sdd-ff`
- The confirmation pattern is: **acknowledge removal intent explicitly, then ask Ready to proceed?**
- **Gate implementation:** sdd-ff does NOT currently implement a pre-proposal contradiction gate

**Current sdd-ff flow (from CLAUDE.md Fast-Forward section):**
1. Detect `--opus`/`--power` flag (pre-process)
2. Infer slug and launch sdd-explore
3. Launch sdd-propose
4. Launch sdd-spec + sdd-design (parallel)
5. Launch sdd-tasks
6. Present summary, ask Ready for apply?

**Expected per ADR 023 (sdd-cycle-context-gaps):**
- sdd-propose MUST emit a mandatory `## Supersedes` section (REMOVED/REPLACED/CONTRADICTED)
- sdd-spec MUST validate: if delta spec preserves behavior marked REMOVED, emit MUST_RESOLVE warning
- **After sdd-explore completes:** if exploration.md contains UNCERTAIN contradictions, a gate should fire before launching sdd-propose to ask the user for clarification

**Gap:** The post-explore gate is not implemented in sdd-ff. If sdd-explore detects an UNCERTAIN contradiction, sdd-ff continues to sdd-propose without user confirmation.

---

## Branch Diff

No branch diff — working tree is clean.

---

## Prior Attempts

No prior attempts found in archive for "archive-residue" or "specs-loading" topics.

---

## Contradiction Analysis

No contradictions detected.

---

## Affected Areas

| File/Module | Impact | Notes |
| --- | --- | --- |
| `~/.claude/skills/sdd-archive/SKILL.md` | HIGH — Step 4 deletion logic | Silent failure pathway when filesystem delete operation fails; no recovery mechanism |
| `~/.claude/skills/sdd-explore/SKILL.md` | HIGH — Step 0c spec preload | Stem-based directory matching does not use index.yaml; fails to load keyword-matched domains |
| `~/.claude/skills/sdd-propose/SKILL.md` | MEDIUM — Step 0c (same as explore) | Inherits same spec loading issue |
| `~/.claude/skills/sdd-spec/SKILL.md` | MEDIUM — Step 0c (same as explore) | Inherits same spec loading issue |
| `~/.claude/skills/sdd-design/SKILL.md` | MEDIUM — Step 0c (same as explore) | Inherits same spec loading issue |
| `~/.claude/skills/sdd-tasks/SKILL.md` | MEDIUM — Step 0c (same as explore) | Inherits same spec loading issue |
| `~/.claude/skills/sdd-apply/SKILL.md` | MEDIUM — Step 0c (same as explore) | Inherits same spec loading issue |
| `~/.claude/skills/sdd-ff/SKILL.md` | MEDIUM — explore → propose gate | Post-explore contradiction gate not implemented; UNCERTAIN contradictions are not surfaced before propose |
| `openspec/specs/index.yaml` | MEDIUM — optional fallback | Exists but not used; needs explicit integration into phase skill Step 0c |
| `project-setup` skill | LOW — optional scaffolding | Does not create `index.yaml`; projects starting fresh miss this optimization |

---

## Analyzed Approaches

### Approach A: Incremental Fix — Solve Each Issue Separately (3 separate /sdd-ff cycles)

**Description:**
1. First cycle: Fix sdd-archive Step 4 deletion detection (use bash with explicit error checking)
2. Second cycle: Add index.yaml-first matching to all 7 phase skills (one cycle, parallel updates to 7 files)
3. Third cycle: Implement post-explore contradiction gate in sdd-ff

**Pros:**
- Lower risk per cycle — each change is isolated and independently testable
- Easier to roll back individual fixes if issues emerge
- Clearer commit history (each fix stands alone)
- Allows async testing and validation before moving to the next issue

**Cons:**
- Three separate SDD cycles = three archives, three closure notes, three spec merges
- Users hit the same symptoms multiple times (incomplete fix)
- Integration risk — fixes depend on each other (spec loading fixes later cycles that depend on correct archive)

**Estimated effort:** Medium (each cycle ~4–6 hours of SDD work)
**Risk:** Low per cycle, but HIGH if fixes interact unexpectedly

---

### Approach B: Holistic Fix — Single Integrated Change (1 comprehensive /sdd-ff cycle)

**Description:**
Create one unified SDD change that:
1. **sdd-archive:** Add explicit bash command to verify source deletion; if it fails, emit WARNING with manual recovery path
2. **All 7 phase skills:** Implement index-first spec preload:
   - Step 0c: Check for `index.yaml`
   - If present: load and score domains by keyword overlap (stem matching + explicit keyword lookup)
   - If absent: fall back to directory-based stem matching with INFO log
3. **sdd-ff:** Add post-explore gate:
   - If exploration.md contains UNCERTAIN contradictions, emit gate prompt before launching propose
   - User choice: clarify contradiction OR proceed at own risk
4. **project-setup:** Scaffold `index.yaml` if not present (create minimal version with empty domains list)

**Pros:**
- Single archive = single closure note, single spec merge
- Specs and phase skills are updated atomically — guarantees consistency
- All users get all fixes in one commit
- Addresses the root cause: specs are now discoverable and deletion is verifiable
- Strengthens the contradiction handling system (users see gates early)

**Cons:**
- Larger change surface = higher test burden
- More files modified (8 skill files + project-setup + optional project.yaml scaffolding)
- If any of the 8 skill files has an error, the entire archive is blocked
- Longer SDD cycle (more phases, more review points)

**Estimated effort:** High (one comprehensive cycle ~12–16 hours of SDD work)
**Risk:** Medium — large surface but well-scoped with clear spec requirements (ADR 023, 22)

---

### Approach C: Phased Holistic Fix (1 cycle, but with staged rollout)

**Description:**
Same as Approach B (all fixes in one SDD cycle), but structure the task phases to allow incremental rollout:
- **Phase 1 tasks:** sdd-archive Step 4 + project-setup scaffolding (critical fixes, low risk)
- **Phase 2 tasks:** 7 phase skills spec preload updates (moderate complexity, high impact)
- **Phase 3 tasks:** sdd-ff post-explore gate (orthogonal, can be tested independently)
- **Apply flow:** Apply phases sequentially, verify each, then proceed

**Pros:**
- Single archive event
- Allows validation after Phase 1 before committing to Phase 2
- Clear success criteria per phase: Phase 1 = deletion verified, Phase 2 = specs loaded, Phase 3 = gates fire
- Less risk than Approach B (can pause after Phase 1 if issues emerge)

**Cons:**
- Still high SDD work (same as Approach B)
- Requires discipline to not skip phases during apply
- Archive happens after all phases (no partial rollback if Phase 3 breaks)

**Estimated effort:** High (one comprehensive cycle, same as Approach B)
**Risk:** Medium-Low — staged validation reduces surprises

---

## Recommendation

**Approach C (Phased Holistic Fix)**

**Rationale:**
1. **Root cause alignment:** The three issues are interdependent. Archive residue happens silently because deletion is not verified. Specs are not loaded because the index is not used. The contradiction gate fails because the post-explore validation is incomplete. Fixing one without the others leaves users in a worse state (they see partial fixes that don't work together).

2. **Consistency guarantee:** A single SDD archive means all three fixes hit the master specs at once. Future cycles will have all three guardrails in place.

3. **User experience:** After this change, users will see:
   - Archive operations verify deletion (no silent residue)
   - Exploration loads more relevant specs (better context)
   - Post-explore contradictions are surfaced with gates (clearer decision points)

4. **Test coverage:** Staged apply allows verification after the critical Phase 1 (sdd-archive deletion fix) before moving to Phase 2 (which all other skills depend on).

5. **Scope clarity:** Three clear phases with non-overlapping files (no merge conflicts in the same file across phases).

---

## Identified Risks

1. **Risk: Multiple skill files modified simultaneously**
   - **Impact:** If any of the 7 phase skill updates has a syntax error, all are blocked
   - **Mitigation:** Strict review of each skill file change; test the stem-matching algorithm in isolation before apply
   - **Severity:** Medium

2. **Risk: index.yaml not present in some user projects**
   - **Impact:** Phase 3 (gate implementation) depends on Phase 2 (index-first preload); if index is absent, gate still works but specs are not loaded
   - **Mitigation:** project-setup Step 5 (new) creates minimal index.yaml; fallback to directory-based matching with INFO log
   - **Severity:** Low (fallback is safe)

3. **Risk: Contradiction gate may fire unexpectedly in existing cycles**
   - **Impact:** sdd-ff now asks for clarification on UNCERTAIN contradictions; users in active cycles may be surprised
   - **Mitigation:** Gate only fires if exploration.md contains UNCERTAIN contradictions (rare); CERTAIN contradictions are already captured in proposal
   - **Severity:** Low (gate is informational, not blocking)

4. **Risk: bash deletion verification on Windows**
   - **Impact:** `mcp__filesystem__move_file` is used for the move; bash `rm -rf` may behave differently on Windows + Git Bash
   - **Mitigation:** Test deletion verification with actual Windows Git Bash; fall back to tool-based deletion if bash fails
   - **Severity:** Medium (platform-specific)

---

## Open Questions

1. **Should project-setup scaffold index.yaml?** Yes — for optimization and fallback safety. Include in Phase 1 (scaffolding task).

2. **How should the post-explore gate interact with existing proposals?** If proposal.md already exists (handoff from prior session), should the gate fire? Suggested: gate only fires if exploration.md is newly created by this invoke, not if it pre-existed (user already made the choice).

3. **What is the deletion verification mechanism in sdd-archive Step 4?**
   - Option A: Check if source directory exists after move (bash `[ -d ... ]` with `stat` fallback for Windows)
   - Option B: Count files in archive destination vs. source before deletion; if mismatch, halt
   - Recommendation: Option A (simpler, more direct); if deletion fails, emit WARNING + manual recovery path in output

4. **Should index.yaml be mandatory in project-setup, or optional scaffolding?** Suggested: Optional scaffolding — create if absent, but do not enforce (allows backward-compat with existing projects that ignore it).

---

## Ready for Proposal

**Yes** — All three issues are well-scoped, have clear root causes, and align with existing ADRs (022, 023, 029). The phased approach balances risk and completeness.

**Next step:** Launch `/sdd-ff fix-archive-residue-specs-loading` to start the SDD cycle.

---

**Exploration completed:** 2026-03-21T12:00:00Z
**Spec context loaded from:** `sdd-archive-execution` (archive move/delete behavior), `spec-context-discovery` (index-driven preload), `sdd-orchestration` (ff flow), `orchestrator-behavior` (contradiction gates)
