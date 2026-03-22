# Task Plan: fix-archive-residue-specs-loading

Date: 2026-03-21
Design: openspec/changes/2026-03-21-fix-archive-residue-specs-loading/design.md

## Progress: 17/17 tasks

---

## Phase 1: Critical Infrastructure — Archive Verification + Index Scaffolding

> Low risk. These two tasks are independent of each other and can be applied in either order.
> Phase 2 MUST NOT begin until all Phase 1 tasks are complete.

- [x] 1.1 Modify `~/.claude/skills/sdd-archive/SKILL.md` — insert Step 4 deletion verification block after the move/delete instruction
  Files: `~/.claude/skills/sdd-archive/SKILL.md` (MODIFY)
  What: After the source directory deletion command, add a two-branch verification block:
    Branch A (bash available): `test -d '<source>' && echo 'exists' || echo 'deleted'`
      — if result == "deleted": log `✓ Source directory deleted and verified: <path>` → status ok
      — if result == "exists": log WARNING with path + `rm -rf <path>` recovery command → status warning
    Branch B (bash unavailable): use `mcp__filesystem__list_directory(<source>)` as fallback:
      — if call fails (FileNotFoundError): source is deleted → log success
      — if call succeeds: source still exists → log WARNING + recovery instructions
    Verification is non-blocking; execution proceeds to Step 5 regardless of outcome.
  Acceptance: Step 4 block in SKILL.md includes both verification branches; WARNING block includes exact source path and manual recovery command; `status: warning` is set on unverified deletion; Step 5 is NOT blocked.
  Spec ref: sdd-archive-execution — Scenario: Deletion verification fails — WARNING is reported with recovery path

- [x] 1.2 Modify `~/.claude/skills/project-setup/SKILL.md` — add Step 5: scaffold `openspec/specs/index.yaml` if absent
  Files: `~/.claude/skills/project-setup/SKILL.md` (MODIFY)
  What: Add a new numbered step (Step 5 or the next sequential step) with the following behavior:
    1. Check if `openspec/specs/index.yaml` exists.
    2. If absent: create it with the minimal scaffold:
       ```yaml
       # openspec/specs/index.yaml
       # Maps spec domains to keywords for index-first spec context lookup.
       # Each phase skill reads this file in Step 0 to select relevant specs.
       # Format: domains is a flat list; each entry requires domain, summary, and keywords (3–8 terms).
       domains: []
       ```
    3. Log: `✓ openspec/specs/index.yaml scaffolded (empty domains list).`
    4. If already exists: log `INFO: openspec/specs/index.yaml already present — skipping scaffold.`
    Step is idempotent and non-blocking; failure to create file logs INFO, does not fail setup.
  Acceptance: Step 5 block exists in SKILL.md; if file absent it is created with correct YAML structure; if file present it is unchanged; log lines match spec; step is non-blocking.
  Spec ref: spec-context-discovery — project-setup scaffold requirement

---
⚠️ Phase 2 MUST NOT begin until all Phase 1 tasks are complete.
---

## Phase 2: Index-First Spec Loading — All 7 Phase Skills

> Moderate complexity. All 7 skills are updated to the same algorithm. Apply and verify each skill
> individually, then confirm all 7 pass before proceeding to Phase 3.

**Algorithm to insert in each skill's Step 0 sub-step (replace existing stem-only logic):**

```
STEP 1: Try index-first lookup
  IF openspec/specs/index.yaml exists:
    a) Parse index.yaml → read domains[] array (via grep/sed or YAML read)
    b) For each domain entry:
       - Extract domain.keywords[] and domain.domain
       - Score: EXACT (1.0) if any keyword matches case-insensitively in change_name tokens
                STEM (0.5) if any keyword is a substring of any change_name token (len > 1)
                SKIP if score == 0.0
    c) Collect scoring > 0, sort by (score desc, domain asc), cap at 3
    d) Load openspec/specs/<domain>/spec.md for each matched domain
    e) Log: "Spec context loaded from index: [domain/spec.md, ...]"
    f) Return (do not fall through to STEP 2)

  [If index present but no domain matched]: fall through to STEP 2
  [If index absent]: fall through to STEP 2

STEP 2: Stem-based directory matching (fallback)
  a) List subdirs in openspec/specs/
  b) Split change_name on "-" → stems; for each subdir, check if any stem (len > 1) appears
  c) Cap at 3 matches
  d) Load openspec/specs/<domain>/spec.md for each matched domain
  e) Log: "Spec context loaded from directory scan: [domain/spec.md, ...]"
  f) Log: "INFO: index.yaml not found or no index match — using fallback stem matching"

[If no match in either step]
  → Log: "INFO: No matching spec domains found for [change-name]"
  → Proceed without loaded specs (non-blocking)
```

- [x] 2.1 Modify `~/.claude/skills/sdd-explore/SKILL.md` — replace Step 0 sub-step stem-only matching with index-first algorithm
  Files: `~/.claude/skills/sdd-explore/SKILL.md` (MODIFY)
  What: Locate the existing Step 0 spec context preload sub-step; replace the candidate listing + stem loop with the two-branch algorithm above. Preserve all existing non-blocking behavior (any failure → INFO log, never blocked/failed). Update log line from existing format to "Spec context loaded from index:" or "from directory scan:".
  Acceptance: Step 0 sub-step contains index check before directory listing; both branches (index hit and fallback) are present; log lines match algorithm; non-blocking guarantee preserved.
  Spec ref: spec-context-discovery — REQ: Index-first lookup with stem fallback

- [x] 2.2 Modify `~/.claude/skills/sdd-propose/SKILL.md` — replace Step 0c stem-only matching with index-first algorithm
  Files: `~/.claude/skills/sdd-propose/SKILL.md` (MODIFY)
  What: Same algorithm substitution as 2.1. Location: Step 0c (spec context preload sub-step). Preserve all non-blocking guards and existing step numbering around it.
  Acceptance: Step 0c contains index-first algorithm; fallback present; log lines correct; non-blocking.
  Spec ref: spec-context-discovery — REQ: Integration point: sdd-propose Step 0c

- [x] 2.3 Modify `~/.claude/skills/sdd-spec/SKILL.md` — replace Step 0c stem-only matching with index-first algorithm
  Files: `~/.claude/skills/sdd-spec/SKILL.md` (MODIFY)
  What: Same algorithm substitution as 2.1. Location: Step 0c (spec context preload sub-step).
  Acceptance: Step 0c contains index-first algorithm; fallback present; log lines correct; non-blocking.
  Spec ref: spec-context-discovery — REQ: Integration point: sdd-spec Step 0c

- [x] 2.4 Modify `~/.claude/skills/sdd-design/SKILL.md` — replace Step 0 sub-step stem-only matching with index-first algorithm
  Files: `~/.claude/skills/sdd-design/SKILL.md` (MODIFY)
  What: Same algorithm substitution as 2.1. Location: Step 0 sub-step (spec context preload).
  Acceptance: Step 0 sub-step contains index-first algorithm; fallback present; log lines correct; non-blocking.
  Spec ref: spec-context-discovery — REQ: Integration point: sdd-design Step 0 sub-step

- [x] 2.5 Modify `~/.claude/skills/sdd-tasks/SKILL.md` — replace Step 0 sub-step stem-only matching with index-first algorithm
  Files: `~/.claude/skills/sdd-tasks/SKILL.md` (MODIFY)
  What: Same algorithm substitution as 2.1. Location: Step 0 sub-step (spec context preload). This is the current skill being updated; confirm that the spec preload section is updated consistently with all other skills.
  Acceptance: Step 0 sub-step contains index-first algorithm; fallback present; log lines correct; non-blocking.
  Spec ref: spec-context-discovery — REQ: Integration point: sdd-tasks Step 0 sub-step

- [x] 2.6 Modify `~/.claude/skills/sdd-apply/SKILL.md` — replace Step 0 sub-step stem-only matching with index-first algorithm
  Files: `~/.claude/skills/sdd-apply/SKILL.md` (MODIFY)
  What: Same algorithm substitution as 2.1. Location: Step 0 sub-step (spec context preload).
  Acceptance: Step 0 sub-step contains index-first algorithm; fallback present; log lines correct; non-blocking.
  Spec ref: spec-context-discovery — REQ: Integration point: sdd-apply Step 0 sub-step

- [x] 2.7 Modify `~/.claude/skills/sdd-verify/SKILL.md` — replace Step 0 sub-step stem-only matching with index-first algorithm
  Files: `~/.claude/skills/sdd-verify/SKILL.md` (MODIFY)
  What: Same algorithm substitution as 2.1. Location: Step 0 sub-step (spec context preload).
  Acceptance: Step 0 sub-step contains index-first algorithm; fallback present; log lines correct; non-blocking.
  Spec ref: spec-context-discovery — REQ: Integration point: sdd-verify Step 0 sub-step

---
⚠️ Phase 3 MUST NOT begin until all Phase 2 tasks are complete.
---

## Phase 3: Post-Explore Contradiction Gate in sdd-ff

> Independent from Phases 1–2 functionally, but apply after Phase 2 to maintain sequencing discipline.

- [x] 3.1 Modify `~/.claude/skills/sdd-ff/SKILL.md` — insert Step 2a: post-explore contradiction gate between sdd-explore completion and sdd-propose launch
  Files: `~/.claude/skills/sdd-ff/SKILL.md` (MODIFY)
  What: After "Step 1: Launch sdd-explore → wait", insert "Step 2a: Post-Explore Contradiction Gate" with the following logic:
    PRECONDITION: Only execute gate if exploration.md was newly created by this sdd-ff invocation (check file was not pre-existing).
      — If pre-existing: log `INFO: exploration.md pre-exists — skipping gate` → continue to Step 2.
    IF newly created:
      a) Read `openspec/changes/<slug>/exploration.md`
      b) Search for `## Contradictions` section
      c) If section absent OR no UNCERTAIN entries: log `INFO: No contradictions detected — proceeding to propose` → continue to Step 2.
      d) If UNCERTAIN entries found: emit gate prompt (exact wording from design.md):
         ```
         EXPLORATION UNCOVERED UNCERTAINTIES

         The exploration found the following unresolved contradictions:

         [bulleted list of UNCERTAIN items from exploration.md Contradictions section]

         Your options:
           1. Review now — edit openspec/changes/<slug>/proposal.md to clarify intent,
              then re-run: /sdd-ff <slug>
           2. Proceed anyway — I'll continue with assumptions stated above

         Choose 1 or 2:
         ```
      e) If user responds 1 (Review): log exit message, exit sdd-ff gracefully (no error, no propose launch).
      f) If user responds 2 (Proceed): prepend to proposal.md (line 1):
         `> Gate decision: PROCEED_WITH_UNCERTAINTY at <ISO-8601 timestamp>`
         → continue to Step 2 (sdd-propose launch).
  Acceptance: Step 2a exists in SKILL.md between explore completion and propose launch; gate only fires on newly created exploration.md; gate skips if no UNCERTAIN entries; user option 1 exits cleanly; user option 2 records decision in proposal.md and continues; gate prompt wording matches design.md.
  Spec ref: sdd-orchestration — REQ: Post-explore contradiction gate firing rules; Gate prompt wording

---
⚠️ Phases 4 and 5 apply after all implementation phases are complete.
---

## Phase 4: Documentation Updates

- [x] 4.1 Modify `C:/Users/juanp/claude-config/CLAUDE.md` — add gate behavior note in the Fast-Forward (`/sdd-ff`) section
  Files: `C:/Users/juanp/claude-config/CLAUDE.md` (MODIFY)
  What: Locate the `## Fast-Forward (/sdd-ff)` section. After the step describing "Launch sdd-explore → wait", add a bullet or sub-item:
    `2a. (Gate) If exploration.md is newly created and contains UNCERTAIN contradictions: emit gate prompt and wait for user response (1 = Review, 2 = Proceed). Pre-existing exploration.md skips gate.`
  Acceptance: Fast-Forward section references the post-explore gate; wording is concise and accurate; no other sections modified in CLAUDE.md.

- [x] 4.2 Modify `C:/Users/juanp/claude-config/openspec/config.yaml` — add documentation comment clarifying the three apply phases for this change
  Files: `C:/Users/juanp/claude-config/openspec/config.yaml` (MODIFY)
  What: Add a comment block (YAML comment lines starting with `#`) documenting the three-phase apply strategy:
    ```yaml
    # Apply phase strategy for fix-archive-residue-specs-loading:
    #   Phase 1 (Critical): sdd-archive deletion verification + project-setup index.yaml scaffold
    #   Phase 2 (Spec):     Index-first spec loading in all 7 phase skills
    #   Phase 3 (Gate):     Post-explore contradiction gate in sdd-ff
    ```
  Acceptance: Comment block exists in config.yaml; no functional YAML keys are changed; file remains valid YAML.

---

## Phase 5: Post-Apply Verification

- [x] 5.1 Run `/project-audit` and verify score >= previous baseline
  Files: audit-report.md (generated)
  What: Execute `/project-audit` from the project root. Compare new score against the most recent prior audit-report.md. Score must not regress.
  Acceptance: audit-report.md generated; score >= previous; no new CRITICAL or HIGH findings introduced by this change.

- [x] 5.2 Run `install.sh` to deploy all changed skills to `~/.claude/` runtime
  Files: `~/.claude/skills/sdd-archive/`, `~/.claude/skills/project-setup/`, `~/.claude/skills/sdd-explore/`, `~/.claude/skills/sdd-propose/`, `~/.claude/skills/sdd-spec/`, `~/.claude/skills/sdd-design/`, `~/.claude/skills/sdd-tasks/`, `~/.claude/skills/sdd-apply/`, `~/.claude/skills/sdd-verify/`, `~/.claude/skills/sdd-ff/` (all DEPLOY via install.sh)
  What: Run `./install.sh` from the repo root. Confirm the script exits with code 0. All 10 skill files must be deployed to the `~/.claude/skills/` runtime.
  Acceptance: install.sh exits 0; all 10 skills exist in `~/.claude/skills/`; no deployment errors logged.

- [x] 5.3 Update `ai-context/changelog-ai.md` with a summary of changes made in this SDD cycle
  Files: `ai-context/changelog-ai.md` (MODIFY)
  What: Append a new entry summarizing: (a) sdd-archive deletion verification added, (b) 7 phase skills updated to index-first spec loading, (c) sdd-ff post-explore gate added, (d) project-setup index.yaml scaffolding added. Include date 2026-03-21 and change name.
  Acceptance: New entry exists in changelog-ai.md; entry is dated 2026-03-21; all four changes are mentioned.

---

## Implementation Notes

- **Algorithm consistency**: All 7 phase skill updates (tasks 2.1–2.7) must use identical algorithm text and log wording. Copy-paste the algorithm block from this tasks.md to ensure consistency. Do not paraphrase.
- **Non-blocking is mandatory**: Every change must preserve the non-blocking guarantee of Step 0 sub-steps. Any file-not-found, parse error, or missing directory MUST produce at most an INFO-level note — never `status: blocked` or `status: failed`.
- **Windows compatibility**: Task 1.1 must include both bash and mcp__filesystem branches. The mcp fallback is the safety net for Windows environments where `test -d` may behave unexpectedly.
- **Gate pre-existing detection**: Task 3.1 must clearly specify the detection method for "newly created" vs "pre-existing" exploration.md. The recommended approach: check if exploration.md existed BEFORE sdd-explore was launched (capture file existence at the start of sdd-ff Step 1, compare after explore completes).
- **CLAUDE.md is both the global and project CLAUDE.md**: The file at `C:/Users/juanp/claude-config/CLAUDE.md` is the project CLAUDE.md that gets deployed to `~/.claude/` via install.sh. Editing it here updates both.
- **Sequencing is enforced by sdd-apply**: Each apply sub-agent handles at most Phase 1 or Phase 2 (not both). The orchestrator must ask the user before advancing phases.

## Blockers

None. All open questions from the design are resolved with safe, non-blocking defaults. Implementation can begin immediately with Phase 1.
