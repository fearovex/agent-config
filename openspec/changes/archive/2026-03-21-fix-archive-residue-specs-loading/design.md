# Technical Design: fix-archive-residue-specs-loading

Date: 2026-03-21
Proposal: openspec/changes/2026-03-21-fix-archive-residue-specs-loading/proposal.md
Status: Draft

---

## General Approach

This design addresses three interconnected SDD system gaps through three independent but coordinated phases:

**Phase 1 (Critical Infrastructure):** Add explicit deletion verification to `sdd-archive` Step 4 and scaffold `index.yaml` in `project-setup`. These enable reliable file operations and spec discovery.

**Phase 2 (Spec Discovery Optimization):** Replace stem-only matching with index-first lookup across all 7 phase skills (`sdd-explore`, `sdd-propose`, `sdd-spec`, `sdd-design`, `sdd-tasks`, `sdd-apply`, `sdd-verify`). This uses `openspec/specs/index.yaml` keywords for precise domain scoring, falling back to directory stem matching when the index is absent.

**Phase 3 (Contradiction Gate):** Implement a post-explore gate in `sdd-ff` that fires when exploration.md contains UNCERTAIN contradictions, allowing users to clarify ambiguities before proposing.

All three phases are self-contained, backward-compatible, and non-blocking on failure (critical operations have fallback paths or warnings).

---

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|---------------|
| **Archive deletion verification** | Bash `ls` check + mcp__filesystem fallback for Windows | Assume success; skip verification | Deletion failures are silent in current code; verification catches residue early. Bash check is simple and direct; MCP fallback handles Windows constraints. |
| **Fallback for missing verification** | Log WARNING + recovery instructions; proceed with status warning | Block archive; require manual cleanup | Archive is already successful (files copied); forcing users to debug file system issues is poor UX. Non-blocking approach allows manual recovery path. |
| **Index-first lookup algorithm** | Exact keyword match (priority 1) → stem match (priority 2) → no match (priority 3) | Stem-only matching; exhaustive index load | Keyword matching captures domain intent better than stem-only. Prioritization ensures precise domains are selected first. Stem fallback preserves backward compatibility. |
| **Index scoring** | Exact match on domain keywords array; substring case-insensitive stem match on change_name tokens | Fuzzy search; token distance metrics | Exact matching is predictable and debuggable. Substring stems preserve the existing algorithm's simplicity. No need for ML-grade scoring. |
| **Index absence fallback** | Use existing stem-based directory matching algorithm | Fail with error; require index creation | Fallback is already implemented and tested. It's safe and non-breaking. `project-setup` now scaffolds index to prevent long-term fallback usage. |
| **Post-explore gate control flow** | Check exploration.md for CONTRADICTIONS section with UNCERTAIN entries; emit gate prompt if found; record user response in proposal.md | Silent merge (ignore contradictions); separate confirmation step | Contradictions in exploration are user-actionable. Gate surfaces them at the boundary before users invest in proposing. Recording response preserves intent context. |
| **Gate firing heuristic** | Only fire if exploration.md is newly created by sdd-explore (not pre-existing from prior session) | Always fire if contradictions present; fire on every invocation | New file = new exploration = new contradictions to surface. Pre-existing exploration.md means user already made a choice in a prior session — no need to re-gate. |
| **Windows compatibility (deletion verification)** | Use bash `test -d` + fallback to mcp__filesystem__move_file for verification | Use only Windows native calls | Bash is available in Git Bash on Windows. MCP fallback is available as a proven tool. No new tooling required. |
| **Index schema** | YAML flat list (one entry per domain); each entry has domain, summary, keywords, optional related | SQLite/FTS5; hierarchical YAML; normalized JSON | Flat YAML is human-readable, version-control friendly, and requires no external tools. 56 domains fits comfortably (migration trigger at 100+, documented in ADR 034). |
| **Spec loading integration point** | Step 0 sub-step in all 7 phase skills (Step 0c for propose/spec; named Step 0 sub-step for explore/design/tasks/apply/verify) | Orchestrator injection; centralized preload skill | Each skill's Step 0 is non-blocking by design. Self-selection prevents unnecessary context when the skill doesn't need it. Orchestrator injection would require changing 2 orchestrator skills and adds coupling. |
| **Gate prompt wording** | User-friendly three-option prompt: "Review contradiction", "Proceed anyway", "Edit proposal and retry" | Simple binary gate; open-ended response | Three options cover the main user intents: clarify before proceeding, proceed at risk, or backtrack. Matches SDD discipline of "decide before committing." |

---

## Data Flow

### Phase 1: Archive Step 4 Deletion Verification

```
sdd-archive Step 4 enters (files copied to archive/)
  │
  ├─→ move_file(src, dst) completed
  │
  ├─→ VERIFY deletion:
  │   ├─→ bash: test -d <source> && echo "exists" || echo "deleted"
  │   │        (requires git bash on Windows)
  │   │
  │   └─→ [if bash unavailable/fails]
  │       └─→ fallback: mcp__filesystem__list_directory(<source>)
  │           ├─→ succeeds  → source still exists → WARNING
  │           └─→ fails      → source deleted → SUCCESS
  │
  ├─→ [if verified deleted]
  │   └─→ log "Source directory deleted: <path>"
  │       status: ok
  │
  └─→ [if verification fails]
      ├─→ log WARNING: "Source directory deletion could not be verified"
      ├─→ provide recovery instructions: "rm -rf <path>"
      └─→ status: warning (archive succeeded; cleanup is manual)
```

**Windows Git Bash compatibility:**
- Bash is available in native Git Bash environment
- `test -d` exits with 0 (success) if dir exists, 1 (failure) if not
- Exit code captured via `$?` in bash or ERRORLEVEL in PowerShell wrapper
- MCP fallback provides atomic cross-platform verification

---

### Phase 2: Index-First Spec Loading (in all 7 phase skills)

#### Algorithm: Spec Domain Selection

```
Input: change_name (slug)
Output: matched_domains (up to 3 items)

STEP 1: Try index-first lookup
  IF openspec/specs/index.yaml exists:
    a) Parse index.yaml → read domains[] array
    b) For each domain entry in index.yaml:
       - Extract domain.keywords[] array
       - Extract domain.domain (the directory name)
       c) Score the domain:
          - SCORE_EXACT = 1.0 if any keyword matches exactly in change_name
            (case-insensitive, full keyword must match one token)
          - SCORE_STEM = 0.5 if any keyword is a substring of any change_name token
            (case-insensitive, length > 1 required)
          - If neither: SCORE = 0.0 (skip this domain)
       d) Collect all domains with SCORE > 0.0, sorted by (SCORE desc, domain asc)
       e) Cap at 3 domains (hard limit)
       f) Log: "Spec context loaded from index: [domain/spec.md, domain2/spec.md, ...]"
       g) Load and return

    [If no domain matched]
    → fall through to STEP 2 (stem matching)

  ELSE [index.yaml absent]:
    → fall through to STEP 2 (stem matching)

STEP 2: Stem-based directory matching (fallback)
  a) List subdirectories in openspec/specs/
  b) For each subdirectory name:
     - Split on "-" → stems
     - If any stem (len > 1) appears in change_name OR
       the full dirname is a substring of change_name:
       → add to matches[]
  c) Cap at 3 matches
  d) Log: "Spec context loaded from directory scan: [domain/spec.md, ...]"
  e) Log: "INFO: index.yaml not found — using fallback stem matching"
  f) Load and return

[If no match found in either step]
  → Log: "INFO: No matching spec domains found for [change-name]"
  → Proceed without loaded specs (non-blocking)
```

#### Data Structure: Index Entry

```yaml
# openspec/specs/index.yaml
domains:
  - domain: spec-context-discovery
    summary: "How to select relevant spec files for a change using index keywords"
    keywords: [spec, index, discovery, keywords, lookup, domain-selection]
    related: [spec-index, sdd-orchestration]
```

#### Integration Points (all 7 phase skills)

| Skill | Step Location | Integration Point |
|-------|---------------|------------------|
| sdd-explore | Step 0 sub-step | After project context load; before state analysis |
| sdd-propose | Step 0c | After project context load; before handoff context check |
| sdd-spec | Step 0c | After project context load; before template selection |
| sdd-design | Step 0 sub-step | After project context load; before Step 1 artifact reads |
| sdd-tasks | Step 0 sub-step | After project context load; before Step 1 proposal read |
| sdd-apply | Step 0 sub-step | After project context load; before diagnosis step |
| sdd-verify | Step 0 sub-step | After project context load; before evidence collection |

**Timing:** All spec loading occurs in Step 0, before any real work. Loaded specs are available as enrichment throughout the skill's execution.

---

### Phase 3: sdd-ff Post-Explore Contradiction Gate

```
sdd-ff workflow (new Step 2a inserted)

Step 1: Launch sdd-explore (unchanged)
  ├─→ exploration.md produced
  └─→ wait for completion

Step 2a: [NEW] Check for contradictions → GATE (new)
  │
  ├─→ Read exploration.md (just produced by explore)
  │
  ├─→ Search for "## Contradictions" section
  │   └─→ If found: look for "UNCERTAIN" entries
  │
  ├─→ [If UNCERTAIN contradictions found]
  │   │
  │   └─→ Emit gate prompt:
  │       ```
  │       EXPLORATION UNCOVERED UNCERTAINTIES
  │
  │       The exploration found the following unresolved contradictions:
  │
  │       [list UNCERTAIN items from exploration.md]
  │
  │       Your options:
  │         1. Review now and edit proposal.md — clarify intent before proposing
  │         2. Proceed anyway — I'll proceed to propose with assumptions stated above
  │
  │       Choose 1 or 2:
  │       ```
  │   │
  │   └─→ Wait for user response (1 or 2)
  │
  │   [If user chooses 1 (Review)]
  │   └─→ Instructions for user:
  │       "Edit openspec/changes/<slug>/proposal.md to clarify your intent,
  │       then run: /sdd-ff <slug> --continue-from gate"
  │       (exit gate gracefully; user re-runs ff)
  │
  │   [If user chooses 2 (Proceed)]
  │   └─→ Record decision in proposal.md (prepend line):
  │       "User gate decision: PROCEED_WITH_UNCERTAINTY at [ISO timestamp]"
  │       → continue to Step 2 (propose launch)
  │
  ├─→ [If NO contradictions found OR no UNCERTAIN entries]
  │   └─→ Log: "INFO: No contradictions detected — proceeding to propose"
  │       → continue to Step 2 (propose launch)
  │
  └─→ [If exploration.md pre-exists (not newly created)]
      └─→ Log: "INFO: exploration.md pre-exists — skipping gate"
          (user already made the choice in a prior session)
          → continue to Step 2 (propose launch)

Step 2: Launch sdd-propose (unchanged)
  └─→ [rest of sdd-ff workflow]
```

**Gate firing rules:**
1. Only fires when exploration.md is **newly created** by this sdd-ff invocation
2. Only fires if "## Contradictions" section found **AND** it contains UNCERTAIN entries
3. Pre-existing exploration.md skips gate entirely (user already decided)
4. Gate is non-blocking on proceed (user can accept risk)

---

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `~/.claude/skills/sdd-archive/SKILL.md` | Modify | Step 4: Add deletion verification block with bash + mcp__filesystem fallback; update output messaging |
| `~/.claude/skills/project-setup/SKILL.md` | Modify | Add Step 5: Scaffold index.yaml if not present (creates minimal YAML with empty domains array) |
| `~/.claude/skills/sdd-explore/SKILL.md` | Modify | Step 0 sub-step: Replace stem-only matching with index-first algorithm; update logging |
| `~/.claude/skills/sdd-propose/SKILL.md` | Modify | Step 0c sub-step: Replace stem-only matching with index-first algorithm; update logging |
| `~/.claude/skills/sdd-spec/SKILL.md` | Modify | Step 0c sub-step: Replace stem-only matching with index-first algorithm; update logging |
| `~/.claude/skills/sdd-design/SKILL.md` | Modify | Step 0 sub-step: Replace stem-only matching with index-first algorithm; update logging |
| `~/.claude/skills/sdd-tasks/SKILL.md` | Modify | Step 0 sub-step: Replace stem-only matching with index-first algorithm; update logging |
| `~/.claude/skills/sdd-apply/SKILL.md` | Modify | Step 0 sub-step: Replace stem-only matching with index-first algorithm; update logging |
| `~/.claude/skills/sdd-verify/SKILL.md` | Modify | Step 0 sub-step: Replace stem-only matching with index-first algorithm; update logging |
| `~/.claude/skills/sdd-ff/SKILL.md` | Modify | Add Step 2a (post-explore gate): Check exploration.md for contradictions; emit gate prompt; record decision |
| `openspec/specs/sdd-archive-execution/spec.md` | Create/Modify | Add new REQ entries for deletion verification mechanism, verification fallback, and error handling |
| `openspec/specs/spec-context-discovery/spec.md` | Create/Modify | Add new REQ entries for index-first algorithm, keyword matching, stem fallback, and spec loading integration |
| `openspec/specs/sdd-orchestration/spec.md` | Create/Modify | Add new REQ entries for post-explore contradiction gate, firing rules, and user gate prompt |
| `openspec/config.yaml` | Modify | Add documentation comment clarifying the three apply phases (Phase 1 Critical, Phase 2 Spec, Phase 3 Gate) |
| `CLAUDE.md` | Modify | Add note in Fast-Forward section referencing the post-explore contradiction gate; clarify gate behavior |

---

## Interfaces and Contracts

### Archive Step 4: Deletion Verification Interface

```pseudocode
function verify_source_deletion(source_path: string): {
  status: "success" | "warning"
  message: string
  error_detail?: string
}

// Pseudocode
verify_source_deletion(source_path) {
  // Try bash verification (preferred on Unix/GitBash)
  if bash_available:
    result = run_bash("test -d '$source_path' && echo 'exists' || echo 'deleted'")
    if result == "deleted":
      return { status: "success", message: "Source directory deleted: $source_path" }
    else:
      return { status: "warning", message: "Deletion verification failed", error_detail: path }

  // Fall back to mcp__filesystem__list_directory (works on all platforms)
  try:
    list = mcp__filesystem__list_directory(source_path)
    return { status: "warning", message: "Deletion verification failed", error_detail: path }
  except FileNotFoundError:
    return { status: "success", message: "Source directory deleted: $source_path" }
  except:
    return { status: "warning", message: "Deletion verification inconclusive", error_detail: error }
}
```

### Spec Loading Step 0: Index Lookup Interface

```typescript
type SpecDomain = {
  domain: string          // e.g., "spec-context-discovery"
  summary: string         // one-line description
  keywords: string[]      // 3-8 terms
  related?: string[]      // optional cross-reference domains
}

type SpecIndex = {
  domains: SpecDomain[]
}

interface SpecLoadResult {
  matched_domains: string[]  // e.g., ["spec-context-discovery", "sdd-orchestration"]
  algorithm_used: "index" | "fallback"
  log_line: string
  loaded_specs: { [domain: string]: string }  // content of each spec.md
}

function load_spec_context(change_name: string): SpecLoadResult {
  // Attempt index lookup
  if index_file_exists("openspec/specs/index.yaml"):
    result = index_lookup(change_name)
    if result.matched_domains.length > 0:
      return result

  // Fall back to stem matching
  return stem_matching_fallback(change_name)
}

function index_lookup(change_name: string): {
  matches: { domain: string, score: number }[] = []

  for each domain_entry in index.domains:
    score = 0
    for each keyword in domain_entry.keywords:
      if keyword matches exactly in change_name (case-insensitive):
        score = max(score, 1.0)
      else if keyword is substring of any token in change_name:
        score = max(score, 0.5)

    if score > 0:
      matches.append({ domain: domain_entry.domain, score })

  // Sort by score desc, then domain asc
  matches.sort()

  // Cap at 3 and load specs
  matched_domains = matches[0:3].map(m => m.domain)

  loaded_specs = {}
  for each domain in matched_domains:
    loaded_specs[domain] = read("openspec/specs/{domain}/spec.md")

  return {
    matched_domains,
    algorithm_used: "index",
    log_line: "Spec context loaded from index: " + matched_domains.join(", "),
    loaded_specs
  }
}
```

### sdd-ff Post-Explore Gate Interface

```pseudocode
type GateDecision = "REVIEW" | "PROCEED_WITH_UNCERTAINTY"

interface GatePrompt {
  prompt_text: string
  uncertain_items: string[]
  accepts: "1" | "2"
}

interface GateResult {
  decision: GateDecision
  user_response: "1" | "2"
  timestamp: string  // ISO 8601
  recorded_in: "proposal.md"  // location where decision is stored
}

function post_explore_gate(exploration_md: string): GateResult | null {
  // Check if exploration.md is newly created (not pre-existing)
  if exploration_md_preexists:
    return null  // Skip gate entirely

  // Parse exploration.md for contradictions
  contradictions_section = parse_section(exploration_md, "## Contradictions")
  if !contradictions_section:
    return null  // No contradictions → no gate

  uncertain_items = extract_uncertain_entries(contradictions_section)
  if uncertain_items.length == 0:
    return null  // No UNCERTAIN → no gate

  // Emit gate prompt
  prompt = {
    prompt_text: """
      EXPLORATION UNCOVERED UNCERTAINTIES

      The exploration found the following unresolved contradictions:

      [list uncertain_items]

      Your options:
        1. Review now — edit proposal.md to clarify intent
        2. Proceed anyway — I'll continue with assumptions stated above

      Choose 1 or 2:
    """,
    uncertain_items,
    accepts: ["1", "2"]
  }

  user_response = wait_for_input(["1", "2"])

  if user_response == "1":
    log("User chose REVIEW — exit gate. Edit proposal.md then re-run /sdd-ff")
    return null  // Exit gracefully; user re-invokes ff

  else if user_response == "2":
    decision = "PROCEED_WITH_UNCERTAINTY"
    record_decision_in_proposal(change_name, decision, now_iso8601())
    return {
      decision,
      user_response,
      timestamp: now_iso8601(),
      recorded_in: "proposal.md"
    }
}
```

---

## Testing Strategy

| Layer | What to test | Tool | Success Criteria |
|-------|--------------|------|------------------|
| Unit | Deletion verification with missing source file | bash + fallback mcp call in isolation | Both methods detect deletion; fallback works when bash unavailable |
| Unit | Index lookup algorithm with keyword scoring | Python/bash script simulating YAML parse | Exact keyword matches score 1.0; stem matches score 0.5; capped at 3 domains |
| Unit | Stem fallback matching when index absent | Directory listing + stem split logic | Fallback reproduces existing stem behavior exactly |
| Unit | Gate firing heuristic (pre-existing file detection) | Bash file existence check | Gate skips when exploration.md pre-exists; fires when newly created |
| Integration | sdd-archive Step 4 with deletion verification | Run /sdd-archive on a test change; verify source deleted and warning logged if fallback used | Archive completes with status ok/warning; source directory cleanup verified |
| Integration | sdd-explore Step 0 with index lookup | Run /sdd-explore on a change with matching index domains | exploration.md includes specs from matched domains; fallback used if index absent |
| Integration | sdd-ff post-explore gate with UNCERTAIN contradictions | Run /sdd-ff on a change with contradictory proposal; respond to gate prompt | Gate fires; user response recorded in proposal.md; continue to propose or exit cleanly |
| End-to-end | Full Phase 1–3 cycle on test project | Create test project with index.yaml; run /sdd-ff → /sdd-apply → /sdd-verify → /sdd-archive | All phases work together; specs loaded; gate operates; deletion verified |
| Regression | Existing stem matching still works when index absent | Test all 7 phase skills on project without index.yaml | Specs loaded via fallback; no errors; behavior identical to pre-change |
| Windows | Deletion verification on Git Bash | Run /sdd-archive on Windows Git Bash environment | Bash verification works; MCP fallback available as backup |

---

## Migration Plan

**No data migration required.** All changes are:
- **Backward-compatible:** Missing index.yaml triggers safe fallback
- **Additive:** Deletion verification and gate are extra checks; archive/propose flow unchanged
- **Non-destructive:** No specs, proposals, or archived changes are modified by this change

**Deployment order (enforced by apply phases):**
1. Phase 1 first → Archive and project-setup ready with deletion verification and index scaffolding
2. Phase 2 after Phase 1 verified → All 7 phase skills updated simultaneously (atomic consistency)
3. Phase 3 independent → sdd-ff gate added; works with or without Phase 1–2 deployed

---

## Open Questions

**1. Should index.yaml creation be idempotent in project-setup?**
   - **Impact:** If project-setup runs multiple times, should it skip if index.yaml exists?
   - **Resolution:** Yes, idempotent. Check for file existence; only create if absent. Non-blocking if creation fails.

**2. How should the gate behave if exploration.md is partially written?**
   - **Impact:** If explore crashes mid-write, sdd-ff might read incomplete exploration.md.
   - **Resolution:** Gate checks for a valid "## Contradictions" section. Malformed YAML or missing section = no gate (safe default). sdd-apply enforces prior-artifact completion check before this phase.

**3. What if a domain has 0 keywords in index.yaml?**
   - **Impact:** If sdd-archive creates an index entry without keywords (malformed), lookup will always fail for that domain.
   - **Resolution:** Step 3a in sdd-archive requires keywords array (3–8 terms). Validation during creation prevents empty arrays. If pre-existing entry has empty keywords, it is treated as non-matching (score 0.0).

**4. Should the gate allow users to edit proposal.md inline or must they exit?**
   - **Impact:** UX — seamless inline editing vs. round-trip re-invocation.
   - **Resolution:** Non-blocking exit on user option 1 (Review). User edits proposal.md in their editor, then re-runs `/sdd-ff <slug>`. Inline editing adds complexity; clean exit is simpler and preserves SDD discipline.

**None of these are blockers.** All questions have simple, safe resolutions that do not affect Phase 1, 2, or 3 implementation.

---

## Architecture Decisions

### ADR Candidate: Deletion Verification as Non-Blocking Safety Gate

**Decision:** Archive Step 4 deletion verification is non-blocking (warns on failure, does not block). This differs from strict enforcement.

**Rationale:**
- Archive is already successful at Step 4 (move completed)
- Deletion is a cleanup operation, not a core contract
- Forcing users to debug file system issues is poor UX
- Manual recovery path (documented) is acceptable fallback
- Aligns with SDD discipline: explicit warnings preserve user awareness

This decision may warrant a brief ADR documenting the "non-blocking safety gate" pattern for future system improvements.

### ADR Candidate: Index-First Lookup with Stem Fallback

**Decision:** Spec loading uses index.yaml first (keyword scoring) with directory stem matching as fallback. No requirement for index.yaml to exist.

**Rationale:**
- Index provides precise domain selection via keywords
- Fallback preserves backward compatibility (existing systems without index work unchanged)
- Scoring prioritizes exact matches over stem matches (predictable)
- project-setup now scaffolds index to encourage adoption over time
- Non-blocking index absence allows graceful degradation

This pattern (optional index, safe fallback) may warrant an ADR documenting "graceful feature adoption with fallbacks."

---

## Platform Compatibility Notes

### Windows + Git Bash Deletion Verification

**Constraint:** `test -d` is a bash builtin; not available in native PowerShell.

**Solution:** Check for bash availability before invoking `test -d`. Fallback uses `mcp__filesystem__list_directory()`, which is cross-platform.

**Testing:** Must verify on:
- Windows 11 + Git Bash (expect bash check to succeed)
- Windows 11 + native PowerShell (expect bash check to fail, mcp fallback used)
- macOS + bash (expect bash check to succeed)
- Linux + bash (expect bash check to succeed)

### Index.yaml YAML Parsing

**Constraint:** YAML parsing must work in bash/shell context (no Python/Node available in skill context).

**Solution:** Use `grep` and `sed` for simple key-value extraction from YAML. Complex parsing delegated to sdd-archive's index creation step (more flexible environment). Phase skill reads pre-validated index.yaml created by sdd-archive.

**Format constraint:** Index schema is frozen (no changes to YAML structure). sdd-archive Step 3a creates entries that conform to the schema exactly. Parsing uses simple string matching, not a full YAML parser.

---

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| Multiple skill file modifications cause syntax errors | Medium | HIGH — all 7 skills fail to load | Strict code review per skill; test each skill's Step 0 in isolation before full apply |
| Index.yaml absent in existing user projects causes fallback to unreliable matching | Medium | MEDIUM — specs not loaded, but no error | project-setup now scaffolds it; fallback is safe (logs INFO, does not block); users benefit gradually as projects are re-setup |
| Post-explore gate fires unexpectedly in active cycles | Low | MEDIUM — users surprised by gate prompt | Gate only fires when exploration.md is newly created; pre-existing exploration.md skips gate entirely (user already decided) |
| Bash deletion verification behaves differently on Windows + Git Bash | Medium | MEDIUM — deletion may not be reliably detected | Test with actual Windows + Git Bash environment; mcp__filesystem fallback available as verified backup |
| Archive apply hangs waiting for manual recovery if deletion fails | Low | LOW — user can manually clean up or skip recovery | Deletion failure is non-blocking; apply proceeds with WARNING; manual cleanup path documented in log output |
| Index lookup algorithm performance degrades with 100+ domains | Low | LOW — lookup O(n) linear scan; acceptable below 100 | ADR 034 documents SQLite/FTS5 migration path for projects reaching 100+ domains; current implementation is simple and maintainable |
| Gate prompt wording unclear to users; confusing response options | Low | MEDIUM — users make wrong decision | Three-option prompt is explicit and includes context (list uncertain items). User option 1 (Review) allows no-penalty exit. Clear instructions provided. |

---

## Summary

This design delivers three coordinated phases to fix silent archive failures, improve spec discovery, and surface contradictions before proposing. All changes are backward-compatible, non-blocking, and safely degrade when optional components (index.yaml, contradiction detection) are absent.

**Phase 1** adds critical deletion verification to sdd-archive Step 4 and scaffolds index.yaml in project-setup.

**Phase 2** enhances all 7 phase skills with index-first spec loading, replacing unreliable stem-only matching.

**Phase 3** adds a post-explore contradiction gate to sdd-ff, allowing users to clarify ambiguities before committing to designs.

Implementation proceeds through staged apply (Phase 1 → verify → Phase 2 → verify → Phase 3), allowing validation and rollback at each step.

