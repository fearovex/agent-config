# Technical Design: global-config-skill-audit

Date: 2026-02-27
Proposal: openspec/changes/global-config-skill-audit/proposal.md

## General Approach

The fix is a surgical, single-file modification to `skills/project-audit/SKILL.md`. It extends the existing Phase A Bash script (Rule 8) with a new computed variable `LOCAL_SKILLS_DIR`, then replaces two hardcoded `.claude/skills/` path references in D9 and D10 with `$LOCAL_SKILLS_DIR`. No new Bash calls are added; the total remains ≤ 3. Global-config detection reuses the identical logic already established in Dimension 1 (Condition A + B).

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|---------------|
| Where to add detection logic | Phase A Bash script (Rule 8 template) | Phase B inline check per dimension | Detection must run once, before Phase B reads any dimension data. Centralizing in Phase A keeps Phase B stateless and avoids re-running detection per dimension. Phase B already consumes Phase A variables without issuing new Bash calls. |
| Variable name | `LOCAL_SKILLS_DIR` | `SKILLS_ROOT`, `EFFECTIVE_SKILLS_PATH` | `LOCAL_SKILLS_DIR` mirrors the existing pattern of `_EXISTS` / `_LINES` suffixes and is self-documenting: it's the local skills directory path, not the global `~/.claude/skills/`. |
| Detection condition | `INSTALL_SH_EXISTS=1 AND SYNC_SH_EXISTS=1` as primary; `openspec/config.yaml` framework string as fallback | New config key `global_config: true` | Reuses existing Condition A and Condition B from D1 verbatim. No new config schema changes. No risk of breaking existing projects. |
| Value of `LOCAL_SKILLS_DIR` when global-config detected | `"skills"` (relative, no trailing slash) | `"./skills"`, absolute path | Relative path with no trailing slash matches how other path strings are already emitted in Phase A (e.g., used in `[ -d "$PROJECT/$LOCAL_SKILLS_DIR" ]` patterns). |
| Default value (non-global-config) | `".claude/skills"` | `".claude/skills/"` (with slash) | No trailing slash, consistent with how Phase B references `.claude/skills/` in prose comparisons. |
| D9 change surface | Replace skip condition check path only | Rewrite all D9 hardcoded paths | The only hardcoded absolute path in D9 is the skip condition. The per-skill paths are already parameterizable: D9-2 through D9-5 operate on "each subdirectory under the local skills dir" which is conceptually parameterizable without changing prose that already says "local `.claude/skills/`". Prose update documents the parameterization. |
| D10 change surface | Source 1 heuristic check + D10-a and D10-d path references | Rewrite entire heuristic | Minimum change: only Source 1 uses `.claude/skills/` explicitly. D10-a's PASS condition for `convention=skill` references `.claude/skills/<feature_name>/SKILL.md` — must also be updated to `$LOCAL_SKILLS_DIR/<feature_name>/SKILL.md`. D10-d reads CLAUDE.md, already correct for global-config. |

## Data Flow

```
Phase A Bash script runs once
        │
        ├─ existing: INSTALL_SH_EXISTS, SYNC_SH_EXISTS (already emitted)
        │
        └─ NEW: LOCAL_SKILLS_DIR detection block
               if INSTALL_SH_EXISTS=1 AND SYNC_SH_EXISTS=1  →  LOCAL_SKILLS_DIR="skills"
               elif openspec/config.yaml contains 'Claude Code SDD meta-system'  →  LOCAL_SKILLS_DIR="skills"
               else  →  LOCAL_SKILLS_DIR=".claude/skills"
               echo "LOCAL_SKILLS_DIR=$LOCAL_SKILLS_DIR"
                    │
                    ▼
              Phase B reads LOCAL_SKILLS_DIR
                    │
          ┌─────────┴─────────┐
          ▼                   ▼
   Dimension 9            Dimension 10
   Skip condition:        Source 1 heuristic:
   [ -d "$PROJECT/        if $LOCAL_SKILLS_DIR exists
    $LOCAL_SKILLS_DIR" ]       │
          │                Source 1 paths resolved
          │                    │
          ▼                    ▼
   D9-2 through D9-5:    D10-a Coverage check:
   "for each subdir       $LOCAL_SKILLS_DIR/<feature>/SKILL.md
    under $LOCAL_SKILLS_DIR"   │
                               ▼
                         D10-d Registry alignment:
                         Reads root CLAUDE.md (unchanged)
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `skills/project-audit/SKILL.md` | Modify | Add `LOCAL_SKILLS_DIR` computation block to Phase A script template (Rule 8); add `LOCAL_SKILLS_DIR` to Phase A output key schema; update D9-1 skip condition to use `$LOCAL_SKILLS_DIR`; update D9 prose to document path parameterization; update D10 Source 1 to use `$LOCAL_SKILLS_DIR`; update D10-a PASS condition to use `$LOCAL_SKILLS_DIR`; update D10 output format section to reflect `LOCAL_SKILLS_DIR` |

Single file. No other files are modified.

## Interfaces and Contracts

Phase A output key additions to the existing schema:

```
# New key emitted by Phase A script
LOCAL_SKILLS_DIR    — string: "skills" (global-config detected) or ".claude/skills" (standard project)
```

Full updated Phase A Bash block (only the addition, inserted after the `SYNC_SH_EXISTS` line and before the `ORPHANED_CHANGES` block):

```sh
# Global-config detection for LOCAL_SKILLS_DIR
if [ "$INSTALL_SH_EXISTS" = "1" ] && [ "$SYNC_SH_EXISTS" = "1" ]; then
  LOCAL_SKILLS_DIR="skills"
elif grep -q 'Claude Code SDD meta-system' "$PROJECT/openspec/config.yaml" 2>/dev/null; then
  LOCAL_SKILLS_DIR="skills"
else
  LOCAL_SKILLS_DIR=".claude/skills"
fi
echo "LOCAL_SKILLS_DIR=$LOCAL_SKILLS_DIR"
```

D9-1 updated skip condition (replaces current hardcoded `.claude/skills/` check):

```
Check whether $LOCAL_SKILLS_DIR exists in the target project.

If it does NOT exist:
  No [value of $LOCAL_SKILLS_DIR] directory found — Dimension 9 skipped.
No score deduction. Do not add `skill_quality_actions` to FIX_MANIFEST.

If it exists, proceed with D9-2 through D9-5 for each subdirectory found.
```

D10 Source 1 updated block (replaces `.claude/skills/` with `$LOCAL_SKILLS_DIR`):

```
# Source 1: non-SDD skills in $LOCAL_SKILLS_DIR
if $LOCAL_SKILLS_DIR exists:
    for each subdirectory name in $LOCAL_SKILLS_DIR:
        if name does NOT start with: sdd-, project-, memory-, skill-:
            add to heuristic_sources as type=skill
```

D10-a updated PASS condition for `convention=skill`:

```
If convention=skill: PASS (✅) if $LOCAL_SKILLS_DIR/<feature_name>/SKILL.md exists; FAIL (⚠️) otherwise
```

D9 report output format updated header:

```
**Local skills directory**: [value of $LOCAL_SKILLS_DIR] — [N skills found | not found — skipped]
```

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Functional — global-config | Run `/project-audit` against `C:/Users/juanp/claude-config`; verify D9 lists skills (not "skipped") | Manual — run audit, read output |
| Functional — global-config D10 | Same run; verify D10 lists features (not "skipped") | Manual — read D10 section of audit-report.md |
| Regression — standard project | Run `/project-audit` against any project with `.claude/skills/`; verify D9 and D10 behavior unchanged | Manual — run audit on Audiio V3 or equivalent |
| Regression — project with no skills | Run `/project-audit` against a project without either `skills/` or `.claude/skills/`; verify D9 still emits "skipped" | Manual |
| Score non-regression | Compare audit score before and after on claude-config; D9 and D10 are informational (N/A) so score must not decrease | Manual — compare audit-report.md score line |

## Migration Plan

No data migration required.

This is a prose/script change to a single SKILL.md. No data is stored, no schemas are changed, no DB exists. The `LOCAL_SKILLS_DIR` variable is computed fresh on every audit run.

After applying:
1. Run `bash install.sh` from `C:/Users/juanp/claude-config` to deploy the updated SKILL.md to `~/.claude/skills/project-audit/SKILL.md`.
2. Run `/project-audit` against `C:/Users/juanp/claude-config` to verify D9 and D10 are no longer skipped.
3. Commit the change.

## Open Questions

None.

The detection conditions are well-defined (reuse of D1 Condition A + B), the variable propagation path is clear (Phase A → Phase B), and all affected prose locations are identified. Implementation can proceed directly.
