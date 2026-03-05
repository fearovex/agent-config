---
mode: agent
description: "SDD archive phase — syncs delta specs to master specs and moves the completed change to archive/. Irreversible — confirms with user first."
tools:
  - read_file
  - file_search
  - create_file
  - replace_string_in_file
  - run_in_terminal
---

# SDD Archive

You are executing the **archive phase** of SDD (Specification-Driven Development).

Archiving is the **final, irreversible step** of the SDD cycle. It integrates delta specs into the master specs and moves the change to history. **Always confirm with the user before executing.**

## How to invoke

```
/sdd-archive <change-name>
```

---

## Your Process

### Step 1 — Verify it is archivable

Read `openspec/changes/<change-name>/verify-report.md` if it exists.

If CRITICAL issues are unresolved:

```
❌ Cannot archive — [N] critical issue(s) remain unresolved.
Run /sdd-verify <change-name> again after fixing them.
```

Stop here.

If no verify-report.md: warn the user and ask "Proceed anyway? [y/n]"

### Step 2 — Confirm with the user

```
⚠️ Archive is IRREVERSIBLE. Confirm?

Change: [change-name]
Verification: [PASS / PASS WITH WARNINGS / not run]

Actions:
1. Merge delta specs → openspec/specs/<domain>/spec.md
2. Move openspec/changes/[name]/ → openspec/changes/archive/[YYYY-MM-DD]-[name]/

Continue? [y/n]
```

Stop and wait for confirmation.

### Step 3 — Sync delta specs to master specs

For each delta spec in `openspec/changes/<change-name>/specs/<domain>/spec.md`:

- **If master exists** (`openspec/specs/<domain>/spec.md`): apply the delta (ADDED → append, MODIFIED → replace, REMOVED → delete with audit comment)
- **If master does not exist**: create `openspec/specs/<domain>/spec.md` as a clean full spec

### Step 4 — Move change to archive

```powershell
# Windows
Move-Item "openspec/changes/<change-name>" "openspec/changes/archive/$(Get-Date -Format 'yyyy-MM-dd')-<change-name>"
```

```bash
# Unix
mv openspec/changes/<change-name> openspec/changes/archive/$(date +%Y-%m-%d)-<change-name>
```

### Step 5 — Update ai-context/changelog-ai.md

Append:

```markdown
## [YYYY-MM-DD] — [change-name]

**Type**: [Feature / Fix / Refactor / Docs]
**Status**: Archived

### Summary

[1-2 sentence summary]

### Files Changed

[Key files created/modified]
```

---

## Output

1. Confirm archive path
2. List master spec files updated
3. Confirm `ai-context/changelog-ai.md` was updated
4. State: "SDD cycle for **[change-name]** is complete ✅"
