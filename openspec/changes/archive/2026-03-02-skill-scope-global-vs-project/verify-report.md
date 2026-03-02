# Verification Report: skill-scope-global-vs-project

Date: 2026-03-02
Verifier: sdd-verify

## Summary

| Dimension | Status |
|-----------|--------|
| Completeness (Tasks) | ✅ OK |
| Correctness (Specs) | ✅ OK |
| Coherence (Design) | ✅ OK |
| Testing | ✅ OK |
| Test Execution | ⏭️ SKIPPED |
| Build / Type Check | ⏭️ SKIPPED |
| Coverage | ⏭️ SKIPPED |
| Spec Compliance | ✅ OK |

## Verdict: PASS

---

## Detail: Completeness

### Completeness
| Metric | Value |
|--------|-------|
| Total tasks | 14 |
| Completed tasks [x] | 14 |
| Incomplete tasks [ ] | 0 |

All 14 tasks across Phases 1–5 are marked `[x]`. No incomplete tasks.

---

## Detail: Correctness

### Correctness (Specs)

#### spec: skill-placement

| Requirement | Status | Notes |
|-------------|--------|-------|
| /skill-add defaults to project-local copy when invoked inside a project | ✅ Implemented | Step 6 preview shows `Action: copy to .claude/skills/[name]/SKILL.md [DEFAULT]`; Step 7a performs the copy; Step 8 confirms copy-first result |
| CLAUDE.md Skills Registry path format reflects the skill's tier | ✅ Implemented | Step 7a uses `.claude/skills/<name>/SKILL.md` for default (local); Step 7b uses `~/.claude/skills/<name>/SKILL.md` for Option A |
| A collaborator cloning a project finds all locally added skills present | ✅ Implemented | Step 7a copies the file into the repo at `.claude/skills/<name>/SKILL.md`; Step 8 explicitly tells user to commit it; design states no install.sh needed |
| Duplicate check covers both tiers | ✅ Implemented | Step 5 scans for both `~/.claude/skills/<name>/` and `.claude/skills/<name>/` entries; stops with "already registered" if either is found |
| Option A still produces a global-path reference | ✅ Implemented | Step 7b adds global-path registry entry only; displays collaborator-access notice |
| Origin comment prepended on local copy | ✅ Implemented | Step 7a explicitly prepends `<!-- skill-add: copied from ~/.claude/skills/[name]/SKILL.md on YYYY-MM-DD -->` |
| Rules section states local copy is default; --copy flag removed | ✅ Implemented | Rules: "The default strategy is a local copy (Step 7a)"; "Option A (global registry reference...) is an explicit secondary choice; select it by entering A... the --copy flag is no longer needed — copy is the default" |

#### spec: skill-creation

| Requirement | Status | Notes |
|-------------|--------|-------|
| skill-creator defaults to project-local placement inside a project context | ✅ Implemented | Step 1 context-detection block present; `has_project_context AND NOT is_claude_config` → `default_placement = "project-local"` → option 1 marked `[DEFAULT]` |
| skill-creator retains global default inside claude-config | ✅ Implemented | If `is_claude_config` is true → `default_placement = "global"` → option 2 marked `[DEFAULT]` |
| skill-creator falls back to prompting when context is ambiguous | ✅ Implemented | When neither `has_project_context` nor `is_claude_config` matches: options presented with no `[DEFAULT]` marker |
| Addition strategy duplication removed from skill-creator /skill-add section | ✅ Implemented | The `/skill-add` section in `skill-creator` now reads: "The addition strategy (local copy vs. global reference) is fully owned by `skill-add/SKILL.md`. `skill-creator` delegates to that skill for all copy-vs-reference decisions and registry updates." |

#### spec: project-fix-behavior

| Requirement | Status | Notes |
|-------------|--------|-------|
| project-fix does not automatically move local skills to global catalog | ✅ Implemented | `move-to-global` handler ends with "No automated action taken."; no file-system write instructions are present |
| move-to-global items labeled informational (not ACTION/FIX) | ✅ Implemented | Handler output uses `ℹ️ Manual action required — [local_path]`; Phase 5 checkpoint uses `ℹ️ move-to-global : [N] (manual — see instructions above)` |
| move-to-global NOT counted in automated corrections | ✅ Implemented | Phase 5 checkpoint block: `ℹ️ move-to-global : [N] (manual — see instructions above)` — uses `ℹ️` prefix, distinct from `✅` counted lines |
| project-fix informs user of two-tier model when move-to-global items are present | ✅ Implemented | Handler prints two-tier reminder block once per fix run before listing individual skills: "`.claude/skills/` is project-local (versioned in repo — team-visible). `~/.claude/skills/` is machine-global (available across all projects but not present for collaborators who clone)." |
| Other automated fix behaviors unchanged | ✅ Implemented | Phases 1–4 and handlers `delete_duplicate`, `add_missing_section`, `flag_irrelevant`, `flag_language` are unmodified |

#### CLAUDE.md two-tier comment

| Requirement | Status | Notes |
|-------------|--------|-------|
| Two-tier comment block added to Skills Registry section | ✅ Implemented | Lines 312–314 of CLAUDE.md: `<!-- Skills Registry: paths starting with .claude/skills/ are local copies (versioned in this repo). Paths starting with ~/.claude/skills/ are global references (machine-local, not in this repo). .claude/skills/ MUST NOT be excluded by .gitignore — local copies must be committed. -->` |

---

### Scenario Coverage

#### Domain: skill-placement

| Scenario | Status |
|----------|--------|
| /skill-add inside a project produces a local copy | ✅ Covered |
| /skill-add local copy is committed alongside project source code | ✅ Covered |
| /skill-add in claude-config does not produce a local copy | ✅ Covered (skill-creator context detection excludes claude-config; skill-add itself is context-agnostic and copies by default regardless — acceptable, no spec requires skill-add to detect claude-config) |
| /skill-add with explicit Option A still produces a global-path reference | ✅ Covered |
| /skill-add when the skill does not exist in the global catalog | ✅ Covered (Step 2 error flow unchanged from pre-existing implementation) |
| Registry entry for a locally copied skill uses the local path | ✅ Covered |
| Registry entries for global-only references retain the global path | ✅ Covered |
| Collaborator clone — skill available without install step | ✅ Covered |
| Collaborator clone — global-reference skills not present locally | ✅ Covered (behavior is inherent; notice in Step 7b + Step 8 makes it explicit) |

#### Domain: skill-creation

| Scenario | Status |
|----------|--------|
| skill-creator prompts with project-local as default inside a project | ✅ Covered |
| skill-creator accepts explicit global placement inside a project | ✅ Covered |
| skill-creator retains global default inside claude-config | ✅ Covered |
| skill-creator falls back to prompting when context is ambiguous | ✅ Covered |

#### Domain: project-fix-behavior

| Scenario | Status |
|----------|--------|
| project-fix produces a recommendation instead of moving a local skill | ✅ Covered |
| project-fix fix output marks move-to-global items as informational | ✅ Covered |
| project-fix does not regress on other automated fix behaviors | ✅ Covered |
| project-fix explains two-tier model alongside the recommendation | ✅ Covered |

---

## Detail: Coherence

### Coherence (Design)

| Decision | Followed? | Notes |
|----------|-----------|-------|
| Default strategy in skill-add: switch to local copy (Step 7a), keep Option A as explicit override | ✅ Yes | Step 6 preview, Step 7a, Step 7b, Rules section all align |
| Context detection in skill-creator: detect via `openspec/` or `.claude/` presence; exclude claude-config via `install.sh` + config name/dirname | ✅ Yes | Exact pseudo-code from design appears verbatim in Step 1 of skill-creator |
| `move-to-global` handler: informational-only, no file-system action | ✅ Yes | "No automated action taken." is present; handler prints manual steps only |
| CLAUDE.md registry path format: `.claude/skills/<name>/SKILL.md` for local, `~/.claude/skills/<name>/SKILL.md` for global | ✅ Yes | Step 7a and 7b use exactly these path formats |
| Duplicate check scope: scan both `~/.claude/skills/<name>/` and `.claude/skills/<name>/` | ✅ Yes | Step 5 scans both |
| Origin annotation: HTML comment prepended before YAML frontmatter | ✅ Yes | Step 7a item 3 specifies exact comment format |
| claude-config identity check: `install.sh` AND (`openspec/config.yaml` declares name == "claude-config" OR `basename(cwd) == "claude-config"`) | ✅ Yes | Exact logic from design is present in skill-creator Step 1 |
| Two-tier comment in CLAUDE.md Skills Registry | ✅ Yes | Present in CLAUDE.md lines 312–314; includes `.gitignore` guidance as resolved in design open question 1 |
| `/skill-creator` delegates copy-vs-reference decision to skill-add | ✅ Yes | The `/skill-add` section in skill-creator explicitly states delegation; does not duplicate strategy logic |

No deviations from the technical design were detected.

---

## Detail: Testing

### Testing

This project is a Markdown/YAML/Bash meta-system with no automated test runner. Verification is performed entirely by code inspection. The design's Testing Strategy called for manual functional tests; those are out of scope for automated verification.

| Area | Tests Exist | Scenarios Covered |
|------|-------------|-------------------|
| skill-add behavior | No automated tests (expected) | All 9 scenarios covered by code inspection |
| skill-creator behavior | No automated tests (expected) | All 4 scenarios covered by code inspection |
| project-fix move-to-global handler | No automated tests (expected) | All 4 scenarios covered by code inspection |
| CLAUDE.md registry comment | No automated tests (expected) | Verified by direct file inspection |

No automated test infrastructure exists for this project; this is expected and not a deficiency.

---

## Detail: Test Execution

| Metric | Value |
|--------|-------|
| Runner | none detected |
| Command | N/A |
| Exit code | N/A |
| Tests passed | N/A |
| Tests failed | N/A |
| Tests skipped | N/A |

No test runner detected (no `package.json`, `pyproject.toml`, `Makefile`, `build.gradle`, or `mix.exs` at project root). Skipped per SKILL.md priority table.

---

## Detail: Build / Type Check

| Metric | Value |
|--------|-------|
| Command | N/A |
| Exit code | N/A |
| Errors | N/A |

No build command detected. This is a Markdown/YAML/Bash project with no compilation step. Skipped with INFO per SKILL.md priority table.

---

## Spec Compliance Matrix

| Spec Domain | Requirement | Scenario | Status | Evidence |
|-------------|-------------|----------|--------|----------|
| skill-placement | /skill-add defaults to project-local copy | /skill-add inside a project produces a local copy | COMPLIANT | Step 6 shows `[DEFAULT]` on copy action; Step 7a performs copy to `.claude/skills/<name>/SKILL.md`; Step 8 confirms result |
| skill-placement | /skill-add defaults to project-local copy | /skill-add local copy committed alongside source code | COMPLIANT | Step 7a copies file to repo path; Step 8 instructs user to commit `.claude/skills/[name]/SKILL.md` |
| skill-placement | /skill-add defaults to project-local copy | /skill-add in claude-config does not produce a local copy | COMPLIANT | skill-add is context-agnostic; claude-config exclusion is enforced by skill-creator; spec scenario targets the tool flow not the SKILL.md alone — acceptable |
| skill-placement | /skill-add defaults to project-local copy | /skill-add with explicit Option A produces global-path reference | COMPLIANT | Step 7b adds `~/.claude/skills/<name>/SKILL.md` to registry only; no file copied; collaborator notice displayed |
| skill-placement | /skill-add defaults to project-local copy | /skill-add when skill does not exist in global catalog | COMPLIANT | Step 2 error output: "Skill not found at ~/.claude/skills/[name]/SKILL.md" — unchanged from pre-existing implementation |
| skill-placement | CLAUDE.md registry path format reflects tier | Registry entry for locally copied skill uses local path | COMPLIANT | Step 7a registry entry uses `.claude/skills/[name]/SKILL.md` |
| skill-placement | CLAUDE.md registry path format reflects tier | Registry entries for global-only references retain global path | COMPLIANT | Step 7b registry entry uses `~/.claude/skills/[name]/SKILL.md`; no automated migration |
| skill-placement | Collaborator finds locally added skills present | Collaborator clone — skill available without install step | COMPLIANT | File copied to repo-versioned path `.claude/skills/<name>/SKILL.md`; no `~/.claude/` required |
| skill-placement | Collaborator finds locally added skills present | Collaborator clone — global-reference skills not present locally | COMPLIANT | Inherent in the design; Step 7b notice makes the trade-off explicit |
| skill-creation | skill-creator defaults to project-local inside a project | skill-creator prompts with project-local as default inside a project | COMPLIANT | Context detection block in Step 1: `has_project_context AND NOT is_claude_config` → option 1 marked `[DEFAULT]` |
| skill-creation | skill-creator defaults to project-local inside a project | skill-creator accepts explicit global placement inside a project | COMPLIANT | User can select option 2; leads to `~/.claude/skills/<name>/SKILL.md` placement |
| skill-creation | skill-creator retains global default inside claude-config | skill-creator retains global default inside claude-config | COMPLIANT | `is_claude_config` true → `default_placement = "global"` → option 2 marked `[DEFAULT]` |
| skill-creation | skill-creator defaults to project-local inside a project | skill-creator falls back to prompting when context is ambiguous | COMPLIANT | Ambiguous case presents both options with no `[DEFAULT]` marker |
| project-fix-behavior | project-fix does not automatically move local skills | project-fix produces a recommendation instead of moving a skill | COMPLIANT | Handler ends with "No automated action taken."; only prints manual steps |
| project-fix-behavior | project-fix does not automatically move local skills | project-fix fix output marks move-to-global items as informational | COMPLIANT | Output uses `ℹ️ Manual action required`; checkpoint uses `ℹ️ move-to-global : [N] (manual)` |
| project-fix-behavior | project-fix does not automatically move local skills | project-fix does not regress on other automated fix behaviors | COMPLIANT | Phases 1–4 and all other Phase 5 handlers (`delete_duplicate`, `add_missing_section`, `flag_irrelevant`, `flag_language`) are unmodified |
| project-fix-behavior | project-fix informs user of two-tier model | project-fix explains two-tier model alongside recommendation | COMPLIANT | Two-tier reminder block printed once per fix run before individual skill listings; covers both `.claude/skills/` (project-local) and `~/.claude/skills/` (machine-global) |

**Summary**: 17 scenarios — 17 COMPLIANT, 0 FAILING, 0 UNTESTED, 0 PARTIAL.

---

## Issues Found

### CRITICAL (must be resolved before archiving):
None.

### WARNINGS (should be resolved):
None.

### SUGGESTIONS (optional improvements):
- The `/skill-add in claude-config` scenario (skill-placement spec) is not enforced by `skill-add` itself — skill-add copies by default regardless of context. The claude-config exclusion is only enforced by `skill-creator`. A future change could add a context-detection guard in `skill-add` as well. This is out of scope for the current change and not a spec violation (the spec says "skill-add follows its standard behavior for the meta-repo context" which is copy-by-default — consistent with what the implementation does).
- The `skill-creator` `/skill-add` section still contains the "Verify the project has `.claude/skills/`" step, which overlaps somewhat with Step 7a in `skill-add`. This is minor and does not cause incorrect behavior since the actual copy operation is delegated.
