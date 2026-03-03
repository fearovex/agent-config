# Verification Report: claude-folder-audit

Date: 2026-03-03
Verifier: sdd-verify

## Summary

| Dimension | Status |
|-----------|--------|
| Completeness (Tasks) | OK |
| Correctness (Specs) | OK |
| Coherence (Design) | OK |
| Testing | OK |
| Test Execution | SKIPPED |
| Build / Type Check | SKIPPED |
| Coverage | SKIPPED |
| Spec Compliance | OK |

## Verdict: PASS

---

## Detail: Completeness

### Completeness
| Metric | Value |
|--------|-------|
| Total tasks | 9 |
| Completed tasks [x] | 9 |
| Incomplete tasks [ ] | 0 |

All 9 tasks across 5 phases are marked complete. No incomplete tasks.

---

## Detail: Correctness

### Correctness (Specs)

#### folder-audit-execution spec

| Requirement | Status | Notes |
|-------------|--------|-------|
| Mode detection (global-config vs global) | Implemented | Step 2 checks for `install.sh` + `skills/` at cwd root |
| Path normalization ($HOME → $USERPROFILE → $HOMEDRIVE$HOMEPATH) | Implemented | Step 1 uses the same priority chain as install.sh |
| Path normalization failure → HIGH finding + halt | Implemented | Step 1 documents the halt behavior |
| Check 1 — Required directories (skills/, openspec/, ai-context/, memory/, hooks/) | Implemented | Check 1 block checks all 5 dirs + CLAUDE.md |
| Check 1 — CLAUDE.md absent → HIGH | Implemented | Explicit case in Check 1 |
| Check 2 — Skill deployment completeness (source → runtime) | Implemented | Check 2 lists source skills, verifies each in runtime |
| Check 2 — Missing SKILL.md → MEDIUM | Implemented | Second sub-case in Check 2 |
| Check 2 — Skipped in global mode → INFO | Implemented | Global-mode branch in Check 2 |
| Check 3 — Drift detection (mtime) | Implemented | Check 3 reads mtime of SOURCE_ROOT and RUNTIME_ROOT |
| Check 3 — Skipped in global mode → INFO | Implemented | Global-mode branch in Check 3 |
| Check 3 — mtime unreadable → INFO (not MEDIUM/HIGH) | Implemented | Documented fallback case |
| Check 3 — Severity cap: MEDIUM max | Implemented | Rules section reinforces this cap |
| Check 4 — Orphaned artifact detection (one level only) | Implemented | Check 4 reads top-level items and compares to expected set |
| Check 4 — openspec/changes/ subdirs → INFO not MEDIUM | Implemented | Explicit carve-out for WIP SDD artifacts |
| Check 4 — Severity cap: MEDIUM max | Implemented | Rules section reinforces this cap |
| Check 5 — No project-local .claude/skills/ → INFO + skip | Implemented | First branch of Check 5 |
| Check 5 — Skill in both tiers → LOW | Implemented | Case 1 in .claude/skills/ loop |
| Check 5 — Project-local skill missing from global catalog → MEDIUM | Implemented | Case 2 in .claude/skills/ loop |
| Read-only constraint: only report file is written | Implemented | Rules: "The ONLY file write permitted..." |
| Report overwrites on re-run | Implemented | Step 4 states "Overwrite any previous report (do not append)" |
| All 5 checks run regardless of earlier HIGH findings | Implemented | Rules: "never abort early" |

#### folder-audit-reporting spec

| Requirement | Status | Notes |
|-------------|--------|-------|
| Report written to ~/.claude/claude-folder-audit-report.md | Implemented | Step 4 writes to `RUNTIME_ROOT/claude-folder-audit-report.md` |
| Report path displayed to user at end | Implemented | Step 5 summary output includes "Report written to:" line |
| Report header: Run date, Mode, Runtime root, Source root, Summary | Implemented | Step 4 report format template matches all fields |
| Severity levels: exactly HIGH / MEDIUM / LOW / INFO | Implemented | All findings throughout use only these 4 labels |
| Each check section appears even when no findings | Implemented | Report template shows "No findings." placeholder |
| Every HIGH/MEDIUM/LOW finding includes Remediation: | Implemented | Rules: "HIGH, MEDIUM, and LOW findings MUST include one" |
| INFO may omit Remediation | Implemented | Rules: "INFO observations MAY omit the Remediation: line" |
| Findings Summary table before per-check sections | Implemented | Step 4 format has ## Findings Summary before ## Check 1 |
| Empty Findings Summary when no non-INFO findings | Implemented | Template includes the "No HIGH / MEDIUM / LOW findings" row |
| Recommended Next Steps section at end | Implemented | Step 4 template ends with ## Recommended Next Steps |
| HIGH findings → first step is install.sh | Implemented | Template shows "1. Run install.sh..." when HIGH > 0 |
| No HIGH/MEDIUM → "Runtime appears healthy" | Implemented | Template alternates between the two cases |
| CLAUDE.md Skills Registry: System Audits section | Implemented | Present in CLAUDE.md lines 380-381 |
| project-onboard: non-blocking Check 7 drift hint | Implemented | Check 7 added at lines 216-224 of project-onboard/SKILL.md |

### Scenario Coverage

| Scenario | Status |
|----------|--------|
| global-config mode detected (install.sh + skills/ present) | COMPLIANT |
| global mode detected (no install.sh or skills/) | COMPLIANT |
| tilde expanded on Windows (USERPROFILE) | COMPLIANT |
| tilde expanded on Unix (HOME) | COMPLIANT |
| path normalization failure → HIGH + halt | COMPLIANT |
| Check 1: all dirs present — no finding | COMPLIANT |
| Check 1: missing dir → HIGH | COMPLIANT |
| Check 1: CLAUDE.md absent → HIGH | COMPLIANT |
| Check 2: all skills deployed — no finding | COMPLIANT |
| Check 2: source skill not in runtime → HIGH | COMPLIANT |
| Check 2: deployed skill missing SKILL.md → MEDIUM | COMPLIANT |
| Check 2: skipped in global mode → INFO | COMPLIANT |
| Check 3: source newer → MEDIUM | COMPLIANT |
| Check 3: runtime newer or equal — no finding | COMPLIANT |
| Check 3: mtime unreadable → INFO | COMPLIANT |
| Check 3: skipped in global mode → INFO | COMPLIANT |
| Check 4: no orphans — no finding | COMPLIANT |
| Check 4: unexpected item → MEDIUM (capped) | COMPLIANT |
| Check 4: openspec/changes/ WIP items → INFO not MEDIUM | COMPLIANT |
| Check 5: no project-local .claude/skills/ → INFO + skip | COMPLIANT |
| Check 5: skill in both tiers → LOW | COMPLIANT |
| Check 5: project-local skill not in global catalog → MEDIUM | COMPLIANT |
| report written to correct path | COMPLIANT |
| report path displayed in Step 5 output | COMPLIANT |
| report overwrites previous run | COMPLIANT |
| read-only constraint (no other file writes) | COMPLIANT |
| CLAUDE.md registry entry under System Audits | COMPLIANT |
| project-onboard Check 7 non-blocking drift hint | COMPLIANT |

---

## Detail: Coherence

### Coherence (Design)

| Decision | Followed? | Notes |
|----------|-----------|-------|
| Mirror project-audit procedural pattern — step-by-step checks, accumulate findings, write report | Yes | SKILL.md follows exact Steps 1–5 as designed |
| Report output: ~/.claude/claude-folder-audit-report.md | Yes | Step 4 writes to RUNTIME_ROOT/claude-folder-audit-report.md |
| Path normalization: replicate install.sh priority chain ($HOME, USERPROFILE, HOMEDRIVE+HOMEPATH) | Yes | Step 1 documents all three fallback levels |
| Drift detection: mtime comparison (not manifest) | Yes | Check 3 uses mtime with documented limitation |
| Scope tier compliance: detect same skill name in both tiers; flag as LOW | Yes | Check 5 case 1 produces LOW finding |
| Severity system: HIGH / MEDIUM / LOW / INFO (not numeric) | Yes | All 5 checks and the report use this exact system |
| Global-config mode detection: install.sh + sync.sh (design.md) / install.sh + skills/ (SKILL.md) | Minor deviation | Design.md says "install.sh + sync.sh"; SKILL.md implementation uses "install.sh + skills/" — both files are present in this repo, so functional outcome is identical. The skills/ check is more robust (does not depend on sync.sh existing) |
| openspec/changes/ WIP subdirs: INFO not MEDIUM | Yes | Check 4 has explicit carve-out |
| CLAUDE.md System Audits section: add if absent | Yes | Section was created; entry is present |
| project-onboard Check 7: non-blocking, global-config only | Yes | Implemented exactly as designed; does not alter case assignment |

---

## Detail: Testing

### Testing
| Area | Tests Exist | Scenarios Covered |
|------|-------------|-------------------|
| SKILL.md execution (all 5 checks) | Manual (Task 3.1) | Full skill run on claude-config repo; report verified to exist |
| Read-only constraint | Manual (Task 3.2) | Zero writes confirmed beyond report file |
| Windows path handling | Manual (Task 3.3) | Forward-slash paths; correct resolution to C:/Users/juanp/.claude |
| Skill deployment (install.sh) | Manual (Task 4.1) | install.sh run; skill present at ~/.claude/skills/claude-folder-audit/ |
| project-audit D1 + D4 | Manual (Task 4.2) | /project-audit confirmed passing |

Evidence from runtime report (C:/Users/juanp/.claude/claude-folder-audit-report.md):
- Header: Run date, Mode: global-config, Runtime root, Source root — all present
- Findings Summary table — present
- All 5 Check sections — present
- Recommended Next Steps — present
- Report written to correct path: `C:/Users/juanp/.claude/claude-folder-audit-report.md`
- Skill present at runtime: `C:/Users/juanp/.claude/skills/claude-folder-audit/SKILL.md` confirmed

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

No test runner detected. Project uses Markdown + YAML + Bash; no automated test framework applies. This is consistent with the design's testing strategy ("No automated test framework applies"). Skipped.

---

## Detail: Build / Type Check

| Metric | Value |
|--------|-------|
| Command | N/A |
| Exit code | N/A |
| Errors | N/A |

No build command detected (no package.json, pyproject.toml, Makefile, or equivalent). Project is a Markdown/YAML skill catalog. Skipped.

---

## Spec Compliance Matrix

| Spec Domain | Requirement | Scenario | Status | Evidence |
|-------------|-------------|----------|--------|----------|
| folder-audit-execution | Mode detection | global-config mode detected by install.sh + skills/ | COMPLIANT | Step 2 in SKILL.md checks both; runtime report shows "Mode: global-config" |
| folder-audit-execution | Mode detection | global mode detected when install.sh or skills/ absent | COMPLIANT | Step 2 else-branch sets MODE=global and SOURCE_ROOT="Not detected" |
| folder-audit-execution | Path normalization | tilde expanded on Windows (USERPROFILE) | COMPLIANT | Step 1 priority: $HOME → $USERPROFILE → $HOMEDRIVE$HOMEPATH; report uses forward slashes |
| folder-audit-execution | Path normalization | tilde expanded on Unix (HOME) | COMPLIANT | Step 1 $HOME case; design mirrors install.sh behavior |
| folder-audit-execution | Path normalization | normalization failure → HIGH + halt | COMPLIANT | Step 1 else-branch records HIGH and stops |
| folder-audit-execution | Check 1 | all required dirs present — no finding | COMPLIANT | Runtime report Check 1: "No findings." |
| folder-audit-execution | Check 1 | missing dir → HIGH | COMPLIANT | Check 1 block: HIGH per missing dir; remediation: "Run install.sh" |
| folder-audit-execution | Check 1 | CLAUDE.md absent → HIGH | COMPLIANT | Explicit sub-case in Check 1 |
| folder-audit-execution | Check 2 | all skills deployed — no finding | COMPLIANT | Runtime report: "All other 44 source skills are correctly deployed" |
| folder-audit-execution | Check 2 | source skill not in runtime → HIGH | COMPLIANT | Runtime report: HIGH for claude-folder-audit not yet deployed at time of first run |
| folder-audit-execution | Check 2 | deployed skill missing SKILL.md → MEDIUM | COMPLIANT | Sub-case in Check 2 with MEDIUM severity |
| folder-audit-execution | Check 2 | skipped in global mode → INFO | COMPLIANT | Global-mode branch writes single INFO note |
| folder-audit-execution | Check 3 | source newer → MEDIUM (capped) | COMPLIANT | Check 3 MEDIUM finding with ISO timestamps; Rules enforce MEDIUM cap |
| folder-audit-execution | Check 3 | runtime newer or equal — no finding | COMPLIANT | Runtime report Check 3: "No findings." (runtime was newer) |
| folder-audit-execution | Check 3 | mtime unreadable → INFO | COMPLIANT | Fallback INFO case documented in Check 3 |
| folder-audit-execution | Check 3 | skipped in global mode → INFO | COMPLIANT | Global-mode branch writes single INFO note |
| folder-audit-execution | Check 4 | no orphans — no finding | COMPLIANT | Logic: items in expected set → no finding |
| folder-audit-execution | Check 4 | unexpected item → MEDIUM (severity capped) | COMPLIANT | Runtime report: 17 MEDIUM findings from Claude Code internal files |
| folder-audit-execution | Check 4 | openspec/changes/ WIP → INFO not MEDIUM | COMPLIANT | Explicit carve-out: "not classified as orphaned artifacts" |
| folder-audit-execution | Check 5 | no project-local .claude/skills/ → INFO + skip | COMPLIANT | Runtime report Check 5: INFO note; global tier listed |
| folder-audit-execution | Check 5 | skill in both tiers → LOW | COMPLIANT | Case 1 in .claude/skills/ loop |
| folder-audit-execution | Check 5 | project-local skill not in global catalog → MEDIUM | COMPLIANT | Case 2 in .claude/skills/ loop |
| folder-audit-execution | Read-only | skill creates only the report file | COMPLIANT | Task 3.2 confirmed; Rules: "ONLY file write permitted" |
| folder-audit-execution | Read-only | report overwrites on re-run | COMPLIANT | Step 4: "Overwrite any previous report" |
| folder-audit-reporting | Report location | written to ~/.claude/claude-folder-audit-report.md | COMPLIANT | Runtime file confirmed at C:/Users/juanp/.claude/claude-folder-audit-report.md |
| folder-audit-reporting | Report location | path displayed to user at end | COMPLIANT | Step 5 summary output: "Report written to: ..." |
| folder-audit-reporting | Report header | Run date, Mode, Runtime root, Source root, Summary | COMPLIANT | All 5 fields present in generated report |
| folder-audit-reporting | Severity levels | exactly HIGH / MEDIUM / LOW / INFO | COMPLIANT | All findings in report use only these labels |
| folder-audit-reporting | Per-check sections | section appears even with no findings — "No findings" | COMPLIANT | Check 1, 3 in report show "No findings." |
| folder-audit-reporting | Remediation | every HIGH/MEDIUM/LOW includes Remediation: | COMPLIANT | All 18 findings in runtime report have Remediation lines |
| folder-audit-reporting | Findings Summary | table appears before per-check sections | COMPLIANT | ## Findings Summary precedes ## Check 1 in report |
| folder-audit-reporting | Findings Summary | empty table row when no non-INFO findings | COMPLIANT | Template row: "No HIGH / MEDIUM / LOW findings" |
| folder-audit-reporting | Next Steps | present at end of report | COMPLIANT | ## Recommended Next Steps at end of report |
| folder-audit-reporting | Next Steps | HIGH → install.sh is first step | COMPLIANT | Runtime report: "1. Run install.sh from..." |
| folder-audit-reporting | Next Steps | no HIGH/MEDIUM → "Runtime appears healthy" | COMPLIANT | Template implements this case |
| folder-audit-reporting | CLAUDE.md registry | entry under System Audits section | COMPLIANT | CLAUDE.md lines 380-381: ### System Audits + entry |
| folder-audit-reporting | project-onboard | non-blocking Check 7 drift hint | COMPLIANT | Check 7 in project-onboard/SKILL.md lines 216-224 |

---

## Issues Found

### CRITICAL (must be resolved before archiving):
None.

### WARNINGS (should be resolved):
- **Design coherence minor deviation**: `design.md` specifies mode detection via `install.sh + sync.sh`; the implementation uses `install.sh + skills/`. The skills/ check is more semantically correct (validates the source repo structure, not a sync utility) and the functional outcome is identical for this repo. Recommend updating design.md in a follow-up to reflect the as-built decision, or noting the deviation in an ADR addendum. This does not affect correctness.
- **Check 4 false-positive noise**: The skill flags 17 Claude Code internal operational files (cache/, telemetry/, projects/, etc.) as MEDIUM orphaned artifacts. These are legitimate Claude Code runtime files not covered by the known-safe allowlist in the implementation. The spec allows for this (severity is capped at MEDIUM and remediation says "Review manually"). A future improvement would add these to the expected-set allowlist. This is a known limitation acknowledged in the runtime report itself.

### SUGGESTIONS (optional improvements):
- Add Claude Code internal directories (cache, telemetry, projects, history.jsonl, statsig, ide, plans, plugins, tasks, todos, backups, debug, file-history, paste-cache, shell-snapshots, stats-cache.json, mcp-needs-auth-cache.json) to the expected-item allowlist in Check 4 to eliminate false-positive MEDIUM findings on normal Claude Code installations.
- Update design.md to reflect the as-built mode detection criterion (`install.sh + skills/` rather than `install.sh + sync.sh`).
- Add `.installed-at` file creation to `install.sh` to enable precise drift detection in Check 3 (noted as future improvement in design.md).

---

## Acceptance Criteria from Proposal

| Criterion | Status |
|-----------|--------|
| [x] `skills/claude-folder-audit/SKILL.md` exists and passes project-audit D4 (format compliance: procedural, Triggers, Process, Rules) | Passed — confirmed by Task 4.2 |
| [x] Running the skill on claude-config produces `~/.claude/claude-folder-audit-report.md` with findings or "No findings" per severity | Passed — report exists and was inspected |
| [x] Report correctly identifies at least one known drift condition | Passed — Check 2 found claude-folder-audit not yet deployed (the new skill itself, pre-install.sh) |
| [x] Skill does NOT create, modify, or delete any file other than the report | Passed — Task 3.2 confirmed |
| [x] Skill handles Windows paths without error | Passed — Task 3.3 confirmed; report uses C:/Users/juanp/.claude/... |
| [x] CLAUDE.md Skills Registry contains the new entry; project-audit D1 passes after install.sh | Passed — Task 4.2 confirmed |
| [x] project-onboard/SKILL.md includes non-blocking hint to run /claude-folder-audit | Passed — Check 7 confirmed present |
