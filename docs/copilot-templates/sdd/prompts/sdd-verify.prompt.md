---
mode: agent
description: "SDD verify phase — validates that the implementation complies with specs, design, and task plan. Produces verify-report.md."
tools:
  - read_file
  - file_search
  - grep_search
  - create_file
---

# SDD Verify

You are executing the **verify phase** of SDD (Specification-Driven Development).

Verification is the **quality gate** before archiving. It objectively validates that what was implemented meets what was specified. You fix nothing — you only report.

## How to invoke

```
/sdd-verify <change-name>
```

---

## Your Process

### Step 1 — Load all artifacts

Read:

1. `openspec/changes/<change-name>/tasks.md`
2. All `openspec/changes/<change-name>/specs/*/spec.md`
3. `openspec/changes/<change-name>/design.md`
4. The actual code files created/modified (from the File Change Matrix in design.md)

### Step 2 — Completeness Check (Tasks)

```markdown
### Completeness

| Metric         | Value |
| -------------- | ----- |
| Total tasks    | N     |
| Completed [x]  | M     |
| Incomplete [ ] | K     |
```

Severity: incomplete core tasks → **CRITICAL**. Incomplete cleanup/docs → **WARNING**.

### Step 3 — Correctness Check (Specs)

For each requirement and each Given/When/Then scenario:

```markdown
### Correctness (Specs)

| Requirement | Status             | Notes            |
| ----------- | ------------------ | ---------------- |
| [Req name]  | ✅ Implemented     |                  |
| [Req name]  | ⚠️ Partial         | [what's missing] |
| [Req name]  | ❌ Not implemented | [what's missing] |

### Scenario Coverage

| Scenario | Status               |
| -------- | -------------------- |
| [name]   | ✅ Covered           |
| [name]   | ⚠️ Partial — no test |
| [name]   | ❌ Not covered       |
```

### Step 4 — Coherence Check (Design)

```markdown
### Coherence (Design)

| Decision                  | Followed?    | Notes     |
| ------------------------- | ------------ | --------- |
| [decision from design.md] | ✅ Yes       |           |
| [decision]                | ⚠️ Deviation | [explain] |
```

### Step 5 — Overall Verdict

```markdown
## Verdict: PASS | PASS WITH WARNINGS | FAIL

### Critical Issues (blocking archive)

- [issue 1]

### Warnings (non-blocking)

- [warning 1]

### Review Checklist

- [ ] All critical issues resolved
- [ ] Review user docs if UX-impacting
```

### Step 6 — Write verify-report.md

Create `openspec/changes/<change-name>/verify-report.md` with the full report.

---

## Output

1. State the verdict clearly: **PASS**, **PASS WITH WARNINGS**, or **FAIL**
2. List critical issues (if any) that block archiving
3. If PASS → recommend `/sdd-archive <change-name>`
4. If FAIL → list exactly what needs to be fixed
