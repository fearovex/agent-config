# Technical Design: claude-folder-audit-project-mode

Date: 2026-03-03
Proposal: openspec/changes/claude-folder-audit-project-mode/proposal.md

## General Approach

Extend the existing `claude-folder-audit` SKILL.md with a third execution mode (`project`) inserted
between `global-config` and `global` in the Step 2 priority chain. When active, project mode
replaces the five existing runtime checks with five project-specific checks (P1–P5) that audit
`.claude/CLAUDE.md` existence, Skills Registry registrations against deployed paths, orphaned
local skills, and scope-tier overlap. The report is written to `.claude/claude-folder-audit-report.md`
in the project root. All existing mode logic and check behavior remain unchanged.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|---------------|
| Mode detection signal | `.claude/` directory presence at CWD (not global-config) | Checking for `.claude/CLAUDE.md`; checking for `.git` presence | `.claude/` is the definitive signal of a project with Claude config. `.claude/CLAUDE.md` would fail P1 before mode is determined. `.git` is unrelated to Claude config. |
| Mode insertion point | Priority 2 — between global-config (1) and global (3) | Making it priority 3 (after global) | Projects with `.claude/` must be detected before falling through to the generic global mode; backwards compat requires global-config to remain highest priority. |
| Project checks architecture | Dedicated `MODE = project` branch in Step 3 with checks P1–P5 | Reusing existing checks 1–5 with conditional branches; creating a separate skill | A dedicated branch is the cleanest extension of the existing conditional pattern. Reusing checks 1–5 would require deep interleaving of project vs. global conditions. A separate skill would require users to know a different command. |
| Skills Registry parsing convention | Look for lines containing `~/.claude/skills/` or `.claude/skills/` path fragments under a `## Skills Registry` section header | Full YAML or Markdown table parser; regex on the entire CLAUDE.md | The Skills Registry section uses a stable, documented format. Path fragment matching on `~/.claude/skills/` vs `.claude/skills/` is a reliable discriminator for tier classification without introducing a parser library. |
| Report path (project mode) | `.claude/claude-folder-audit-report.md` (relative to CWD) | `./claude-folder-audit-report.md` (CWD root); `~/.claude/claude-folder-audit-report.md` (global, as in existing modes) | `.claude/` is the natural home for project-local Claude artifacts. CWD root would pollute the project root. The global path would produce a misleading report in a non-global context. |
| Scope of P1 failure impact | P1 failure is HIGH finding; P2–P5 still execute with degraded/empty input | Abort all checks if CLAUDE.md missing | The skill runs all checks even when earlier ones fail (existing invariant). P2–P5 handle empty input gracefully ("not found" findings). |
| Global-config and global modes | Zero changes | Any modification to simplify code | Strict backwards compatibility. These modes are already tested and documented. This change must not regress them. |

## Data Flow

```
/claude-folder-audit invoked
        │
        ▼
Step 1 — Resolve paths
  CLAUDE_DIR = $HOME/.claude (or $USERPROFILE/.claude on Windows)
  CWD_ROOT   = current working directory (absolute path)
  RUN_DATE   = ISO 8601 now
        │
        ▼
Step 2 — Detect execution mode
  ┌──────────────────────────────────────────────────────────────────┐
  │  install.sh AND skills/ both exist at CWD?                       │
  │  YES → MODE = global-config; SOURCE_ROOT = CWD                   │
  │  NO  → .claude/ directory exists at CWD?                         │
  │         YES → MODE = project; PROJECT_ROOT = CWD                 │
  │         NO  → MODE = global; SOURCE_ROOT = "Not detected"        │
  └──────────────────────────────────────────────────────────────────┘
        │
        ▼
Step 3 — Run checks (mode-specific, all run, no early abort)
        │
        ├── MODE = global-config → Checks 1–5 (unchanged)
        │
        ├── MODE = project → Checks P1–P5
        │     P1: .claude/CLAUDE.md exists + Skills Registry present
        │     P2: Global-path registrations (~/.claude/skills/<n>/) exist on disk
        │     P3: Local-path registrations (.claude/skills/<n>/) exist on disk
        │     P4: .claude/skills/*/SKILL.md files not in CLAUDE.md registry (orphans)
        │     P5: Skills present in both .claude/skills/ and ~/.claude/skills/ (overlap)
        │
        └── MODE = global → Checks 1–5 (unchanged)
        │
        ▼
Step 4 — Write report
  MODE = project  → .claude/claude-folder-audit-report.md (in PROJECT_ROOT)
  MODE = global-config / global → RUNTIME_ROOT/claude-folder-audit-report.md (unchanged)
        │
        ▼
Step 5 — Output summary to user
  (same structure as today; path in "Report written to:" line reflects mode)
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `skills/claude-folder-audit/SKILL.md` | Modify | (1) Step 2: insert `project` mode branch; (2) Step 3: add `MODE = project` check block with P1–P5; (3) Step 4: parameterize report path by mode; (4) frontmatter `description:` updated to mention project mode; (5) Step 5: report path reflects mode |

No other files are modified during implementation. The ADR (if generated) is a separate artifact.

## Interfaces and Contracts

### Mode variable contract

After Step 2, the skill has exactly one of three values:

```
MODE = global-config    SOURCE_ROOT = <absolute CWD>
MODE = project          PROJECT_ROOT = <absolute CWD>     (new variable)
MODE = global           SOURCE_ROOT = "Not detected"
```

`PROJECT_ROOT` is a new variable, scoped only to `MODE = project`. It is the absolute path to
the CWD where `.claude/` was detected.

### P1 parsing contract

Skills Registry detection is a two-phase scan of `.claude/CLAUDE.md`:

```
Phase A: Section presence
  Look for a line matching (case-insensitive): "## skills registry"
  If found: Skills Registry section EXISTS
  If not found: P1 HIGH finding — "CLAUDE.md has no Skills Registry section"

Phase B: Line classification (only if Phase A passes)
  For each line in the file:
    if line contains "~/.claude/skills/"  → global-tier registration
    if line contains ".claude/skills/"    → local-tier registration
      (note: lines with "~/.claude/skills/" must be classified as global even if
       they also textually contain ".claude/skills/" — match the longer prefix first)
  Collect skill name from the path segment immediately after "skills/":
    e.g. "~/.claude/skills/sdd-ff/SKILL.md" → skill name = "sdd-ff"
         ".claude/skills/my-skill/SKILL.md"  → skill name = "my-skill"
```

### Finding schema (unchanged from existing)

```
severity:    HIGH | MEDIUM | LOW | INFO
check:       P1 | P2 | P3 | P4 | P5
title:       short description
detail:      what was observed
remediation: exact step to resolve (optional for INFO)
```

## Check Specifications (project mode only)

### P1 — CLAUDE.md Presence and Skills Registry

**Input**: `PROJECT_ROOT/.claude/CLAUDE.md`

| Condition | Severity | Title |
|-----------|----------|-------|
| `.claude/CLAUDE.md` absent | HIGH | `.claude/CLAUDE.md` missing — project Claude config not found |
| `.claude/CLAUDE.md` present but no `## Skills Registry` section | HIGH | `.claude/CLAUDE.md` has no Skills Registry section |
| Both present | No finding | — |

Remediation for HIGH: "Create `.claude/CLAUDE.md` with a Skills Registry section, or run `/project-setup` to initialize the project Claude config."

### P2 — Global-Path Skill Registration Verification

**Input**: global-tier skill names from P1 Phase B parsing; `CLAUDE_DIR/skills/` on disk

For each globally-registered skill name `<n>`:

| Condition | Severity | Title |
|-----------|----------|-------|
| `CLAUDE_DIR/skills/<n>/` does not exist | HIGH | Global skill `<n>` registered in CLAUDE.md but not deployed to `~/.claude/skills/` |
| `CLAUDE_DIR/skills/<n>/` exists but `CLAUDE_DIR/skills/<n>/SKILL.md` absent | MEDIUM | Global skill `<n>` directory present in `~/.claude/skills/` but SKILL.md missing |
| Both exist | No finding | — |

Remediation (HIGH): "Run `install.sh` from the claude-config repo or install the skill manually."
Remediation (MEDIUM): "Re-run `install.sh` or restore the SKILL.md file."

If P1 found no CLAUDE.md or no Skills Registry, P2 records one INFO: "P1 failed — global registration check skipped."

### P3 — Local-Path Skill Registration Verification

**Input**: local-tier skill names from P1 Phase B parsing; `PROJECT_ROOT/.claude/skills/` on disk

For each locally-registered skill name `<n>`:

| Condition | Severity | Title |
|-----------|----------|-------|
| `PROJECT_ROOT/.claude/skills/<n>/` does not exist | HIGH | Local skill `<n>` registered in CLAUDE.md but not found at `.claude/skills/<n>/` |
| `PROJECT_ROOT/.claude/skills/<n>/` exists but `SKILL.md` absent | MEDIUM | Local skill `<n>` directory present but SKILL.md missing |
| Both exist | No finding | — |

Remediation (HIGH): "Add the skill file at `.claude/skills/<n>/SKILL.md` or remove the registry entry."
Remediation (MEDIUM): "Restore SKILL.md at `.claude/skills/<n>/SKILL.md`."

If P1 found no CLAUDE.md or no Skills Registry, P3 records one INFO: "P1 failed — local registration check skipped."

### P4 — Orphaned Local Skills

**Input**: all `PROJECT_ROOT/.claude/skills/*/SKILL.md` files on disk; local-tier skill names from P1

For each `<n>` found in `.claude/skills/` on disk but NOT in the P1 local-tier set:

| Condition | Severity | Title |
|-----------|----------|-------|
| Skill on disk but not in registry | MEDIUM | Local skill `<n>` found at `.claude/skills/` but not registered in CLAUDE.md Skills Registry |

Remediation: "Register the skill in the CLAUDE.md Skills Registry, or remove the directory if no longer needed."

If `.claude/skills/` does not exist: record INFO "No `.claude/skills/` directory found — orphan check skipped."
If `.claude/skills/` exists but is empty: record INFO "`.claude/skills/` is empty — no local skills to check."

### P5 — Scope Tier Overlap

**Input**: local-tier skill names from P1; `CLAUDE_DIR/skills/` on disk

For each skill name present in BOTH the local-tier P1 set AND in `CLAUDE_DIR/skills/` on disk:

| Condition | Severity | Title |
|-----------|----------|-------|
| Name present in both tiers | LOW | Skill `<n>` exists in both `.claude/skills/` (local) and `~/.claude/skills/` (global) |

Detail: "This is expected for intentional global overrides; verify the intended tier is active."
Remediation: "Confirm which tier is authoritative for this project; consult ADR-008."

If P1 found no Skills Registry, P5 records one INFO: "P1 failed — scope tier overlap check skipped."

## Report Format (project mode)

The project-mode report follows the same Markdown structure as the existing report, with these
differences:

```markdown
# .claude/ Project Audit Report

Run date: <RUN_DATE>
Mode: project
Project root: <PROJECT_ROOT>
CLAUDE.md: <PROJECT_ROOT>/.claude/CLAUDE.md
Summary: <N> HIGH, <N> MEDIUM, <N> LOW, <N> INFO

---

## Findings Summary

| Severity | Check | Description | Remediation |
|----------|-------|-------------|-------------|
...

---

## Check P1 — CLAUDE.md Presence and Skills Registry

[findings or "No findings."]

---

## Check P2 — Global-Path Registration Verification

[findings or "No findings."]

---

## Check P3 — Local-Path Registration Verification

[findings or "No findings."]

---

## Check P4 — Orphaned Local Skills

[findings or "No findings."]

---

## Check P5 — Scope Tier Overlap

[findings or "No findings."]

---

## Recommended Next Steps

[standard HIGH/MEDIUM/LOW/INFO guidance]
```

Written to: `<PROJECT_ROOT>/.claude/claude-folder-audit-report.md`

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Manual — mode detection | Run `/claude-folder-audit` from `claude-config` repo root → confirm `Mode: global-config` in report | Human verification |
| Manual — mode detection | Run `/claude-folder-audit` from a project dir with `.claude/` → confirm `Mode: project` in report | Human verification |
| Manual — mode detection | Run `/claude-folder-audit` from a neutral dir (no `.claude/`, no `install.sh`) → confirm `Mode: global` | Human verification |
| Manual — P1 | Run from project dir where `.claude/CLAUDE.md` is absent → confirm HIGH finding | Human verification |
| Manual — P2 | Register a non-existent global skill in CLAUDE.md → confirm HIGH finding for that skill | Human verification |
| Manual — P3 | Register a non-existent local skill in CLAUDE.md → confirm HIGH finding for that skill | Human verification |
| Manual — P4 | Add a `.claude/skills/orphan/SKILL.md` not in registry → confirm MEDIUM finding | Human verification |
| Manual — P5 | Have a skill in both `.claude/skills/` and `~/.claude/skills/` → confirm LOW finding | Human verification |
| Regression — global-config | Run audit from `claude-config` root and compare report structure to pre-change baseline | Human comparison |
| Regression — global | Run audit from a dir with no `.claude/` → confirm unchanged global-mode report | Human comparison |

No automated test framework is available for this repo (`/project-audit` is the integration test).

## Migration Plan

No data migration required. The change is confined to `skills/claude-folder-audit/SKILL.md`.
After implementation:
1. Run `bash install.sh` from `claude-config` root to deploy the updated skill to `~/.claude/skills/claude-folder-audit/`
2. Verify `global-config` mode still works from `claude-config` root
3. Verify `project` mode works from a project directory with `.claude/`

## Open Questions

None. All design decisions have been resolved above. The proposal explicitly excludes auto-fix,
multi-level `.claude/` structures, and CLAUDE.md content validation beyond Skills Registry
section presence — no open questions remain on those boundaries.
