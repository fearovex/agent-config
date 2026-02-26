# Technical Design: batch-audit-bash-calls

Date: 2026-02-26
Proposal: openspec/changes/batch-audit-bash-calls/proposal.md

## General Approach

The change targets two files: `skills/project-audit/SKILL.md` and `settings.json`. In `settings.json`, `"Bash"` is appended to the existing `permissions.allow` array (which already contains `"Read"`, `"Glob"`, `"Grep"`). In `SKILL.md`, a new **Execution Rules — Bash batching** section is inserted inside the existing `## Execution Rules` block, defining a mandatory two-phase script strategy and providing a concrete shell script template. No other section of the skill (dimensions, report format, scoring) is touched.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|---------------|
| Where to add the Bash permission | `settings.json` `permissions.allow` array | Per-skill `.claude/settings.json`; hooks; `alwaysAllowTools` | `permissions.allow` is the existing pattern for the three already-approved tools (Read, Glob, Grep). Consistency; no new mechanism needed. |
| Output format of the discovery script | `key=value` lines (shell-friendly) | JSON blob; CSV; env file | `key=value` is parseable with simple `grep "^KEY="` pattern — no `jq` dependency, works on Windows Git Bash and Unix equally. Claude can read the output as plain text without a parser library. |
| Number of allowed Bash calls per audit run | Maximum 2 (1 discovery + 1 extended grep if needed) | 1 absolute; 3; unlimited | 1 discovery call covers all `test -f`, `wc -l`, `find`, `ls` checks. A second call for heavy `grep` scans (D7 violations) is realistic without multiplying prompts. Setting the cap at 2 matches the spirit of the proposal while being practical. |
| Location of the new rule in SKILL.md | Appended as a new numbered rule inside existing `## Execution Rules` | Separate top-level section; inline comment in each dimension | The `## Execution Rules` section is already where Claude looks for operational constraints. Adding a rule there is the least disruptive change and follows the established pattern. |
| Script template style | Inline shell snippet in SKILL.md | External file; reference to a helper script | SKILL.md must be self-contained — Claude reads only `SKILL.md`. An inline template is the only approach that gives Claude the exact commands without a second file read. |

## Data Flow

```
/project-audit invoked
        │
        ▼
[Phase A — single Bash call]
  Shell discovery script emitted by Claude
  Collects: file existence (test -f), line counts (wc -l),
            directory listings (ls/find), content searches (grep -c)
  Output: key=value pairs printed to stdout
        │
        ▼
[Claude reads stdout]
  Parses key=value lines for dimension checks:
    D1: CLAUDE_MD_EXISTS=1, CLAUDE_MD_LINES=312, ...
    D2: STACK_MD_EXISTS=1, STACK_MD_LINES=55, ...
    D3: OPENSPEC_EXISTS=1, CONFIG_YAML_EXISTS=1, ...
    D3: ORPHANED_CHANGES=name1,name2 (or NONE)
    D8: ARCHIVE_WITHOUT_VERIFY=name1 (or NONE)
        │
        ▼
[Phase B — Read/Glob/Grep tools (already pre-approved)]
  File content reads for qualitative checks:
    Read CLAUDE.md, ai-context/*.md, openspec/config.yaml
    Grep for patterns inside skill files
    Glob for directory structures
        │
        ▼
[Claude runs all 9 dimensions using Phase A + B data]
        │
        ▼
[Write audit-report.md]
  Single Write call to .claude/audit-report.md
        │
        ▼
[Notify user]
  "Report saved. Run /project-fix to apply corrections."
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `skills/project-audit/SKILL.md` | Modify | Add rule 8 to `## Execution Rules`: mandatory two-phase Bash batching strategy with output format definition and a concrete script template |
| `settings.json` | Modify | Add `"Bash"` to `permissions.allow` array |

## Interfaces and Contracts

### Discovery script output contract (`key=value`)

The script Claude emits in Phase A must produce lines conforming to this schema:

```sh
# File existence (1 = exists, 0 = absent)
CLAUDE_MD_EXISTS=1
OPENSPEC_EXISTS=1
CONFIG_YAML_EXISTS=1
STACK_MD_EXISTS=1
ARCH_MD_EXISTS=1
CONV_MD_EXISTS=1
ISSUES_MD_EXISTS=1
CHANGELOG_MD_EXISTS=0
INSTALL_SH_EXISTS=1
SYNC_SH_EXISTS=1

# Line counts (integer)
CLAUDE_MD_LINES=312
STACK_MD_LINES=55

# Orphaned changes (comma-separated names, or NONE)
ORPHANED_CHANGES=NONE

# Archive items without verify-report.md (comma-separated, or NONE)
ARCHIVE_WITHOUT_VERIFY=NONE

# Dimension-specific counts
SDD_SKILLS_PRESENT=8          # count of present sdd-* SKILL.md files
CHANGES_ACTIVE=1              # count of active (non-archived) change dirs
```

### Reference script template (to be embedded in SKILL.md)

```sh
#!/usr/bin/env bash
# project-audit discovery — Phase A
# Usage: bash <(echo "$SCRIPT") [project_root]
PROJECT="${1:-.}"
f() { [ -f "$PROJECT/$1" ] && echo 1 || echo 0; }
d() { [ -d "$PROJECT/$1" ] && echo 1 || echo 0; }
lc() { [ -f "$PROJECT/$1" ] && wc -l < "$PROJECT/$1" || echo 0; }

echo "CLAUDE_MD_EXISTS=$(f .claude/CLAUDE.md)"
echo "ROOT_CLAUDE_MD_EXISTS=$(f CLAUDE.md)"
echo "OPENSPEC_EXISTS=$(d openspec)"
echo "CONFIG_YAML_EXISTS=$(f openspec/config.yaml)"
echo "INSTALL_SH_EXISTS=$(f install.sh)"
echo "SYNC_SH_EXISTS=$(f sync.sh)"
echo "STACK_MD_EXISTS=$(f ai-context/stack.md)"
echo "ARCH_MD_EXISTS=$(f ai-context/architecture.md)"
echo "CONV_MD_EXISTS=$(f ai-context/conventions.md)"
echo "ISSUES_MD_EXISTS=$(f ai-context/known-issues.md)"
echo "CHANGELOG_MD_EXISTS=$(f ai-context/changelog-ai.md)"
echo "CLAUDE_MD_LINES=$(lc CLAUDE.md)"
echo "STACK_MD_LINES=$(lc ai-context/stack.md)"

# Orphaned changes (dirs in changes/ not in archive/, modified >14 days ago)
ORPHANED=""
if [ -d "$PROJECT/openspec/changes" ]; then
  for dir in "$PROJECT/openspec/changes"/*/; do
    name=$(basename "$dir")
    [ "$name" = "archive" ] && continue
    [ -z "$(find "$dir" -maxdepth 0 -not -newer "$PROJECT/openspec/changes" -mtime +14 2>/dev/null)" ] || \
      ORPHANED="${ORPHANED:+$ORPHANED,}$name"
  done
fi
echo "ORPHANED_CHANGES=${ORPHANED:-NONE}"

# SDD phase skills present
SDD_COUNT=0
for phase in explore propose spec design tasks apply verify archive; do
  [ -f "$HOME/.claude/skills/sdd-$phase/SKILL.md" ] && SDD_COUNT=$((SDD_COUNT+1))
done
echo "SDD_SKILLS_PRESENT=$SDD_COUNT"
```

### settings.json — after change

```json
{
  "alwaysThinkingEnabled": true,
  "effortLevel": "medium",
  "model": "sonnet",
  "permissions": {
    "allow": [
      "Read",
      "Glob",
      "Grep",
      "Bash"
    ]
  },
  ...
}
```

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Manual — smoke | Run `/project-audit` on Audiio V3 project (`D:/Proyectos/Audiio/audiio_v3_1`) in default permission mode; count Bash approval prompts | Human observation |
| Manual — regression | Compare report structure against a pre-change audit-report.md (same dimensions, same format) | Human diff |
| Manual — self-audit | Run `/project-audit` on claude-config itself; verify score >= 96 (current baseline) | Human check |
| Artifact check | Verify `settings.json` contains `"Bash"` in `permissions.allow` | `grep "Bash" settings.json` |
| Artifact check | Verify SKILL.md contains the batching rule text | `grep "single Bash" skills/project-audit/SKILL.md` |

No automated test runner — this is a Markdown/YAML repo. Tests are manual execution and human observation.

## Migration Plan

No data migration required. Both files (`settings.json`, `skills/project-audit/SKILL.md`) are version-controlled text files with no associated data or external state. After apply, run `install.sh` to deploy to `~/.claude/`.

## Open Questions

None.
