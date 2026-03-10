# Proposal: sdd-verify-enforcement

Date: 2026-03-10
Status: Draft

## Intent

Enforce that `sdd-verify` executes real verification using the project's own tooling (tests, linters, build commands), and block commit suggestions until at least one tool-verified criterion is confirmed in `verify-report.md`.

## Motivation

The current `sdd-verify` skill produces a list of manual verification steps without executing them. It then suggests `/commit` alongside `/sdd-verify`, allowing the user to commit an unverified implementation. For example:

- "Phase 6 — Manual verification required (3 tests): Trigger Stripe CLI webhook... Call CheckStripeMembershipStatus()..."
- "Ready to run /sdd-verify fix-subscription-status-stripe-sync or /commit?"

This is abstract verification: the AI describes what to test but does not test it. Combined with the premature commit suggestion, this pattern allows unverified code to be committed with the appearance of a completed cycle.

## Scope

### Included

- `sdd-verify` must attempt to run the project's test/build tooling before producing `verify-report.md`
  - Reads `openspec/config.yaml` for `verify_commands` if defined
  - Falls back to auto-detection: `npm test`, `pytest`, `./gradlew test`, `mix test`, etc.
- `verify-report.md` must include a `## Tool Execution` section with actual command output (pass/fail/error)
- A criterion in `verify-report.md` can only be marked `[x]` if it was verified by a tool run or explicit user confirmation with evidence
- `sdd-apply` must NOT suggest `/commit` — it must suggest `/sdd-verify` only
- `/commit` is the user's decision after reviewing `verify-report.md`
- Add `verify_commands` optional key to `openspec/config.yaml` schema documentation

### Excluded

- Integration or E2E test execution (scope limited to unit/build verification)
- Changes to `sdd-archive` — archiving still requires `verify-report.md` with at least one `[x]`, unchanged
- Automated fix of failing tests — `sdd-verify` reports, does not fix

## Proposed Approach

### `sdd-verify` process addition

After reading specs and implementation:

```
STEP N — Execute verification tooling:
  1. Read openspec/config.yaml for verify_commands
  2. If absent, detect: check for package.json (npm test), requirements.txt (pytest),
     pom.xml (mvn test), build.gradle (./gradlew test), mix.exs (mix test)
  3. Run detected command(s) with a timeout of 120s
  4. Capture stdout/stderr
  5. Write ## Tool Execution section in verify-report.md with:
     - Command run
     - Exit code
     - Summary of output (pass count, fail count, error messages)
  6. Mark criteria [x] only if tool output confirms them, or user provides explicit evidence
```

### `sdd-apply` change

Remove any suggestion of `/commit` from the final summary. Replace with:

```
Implementation complete. Next step:
  /sdd-verify <change-name>  — verify against specs before committing
```

## Affected Areas

| Area/Module | Type of Change | Impact |
|-------------|----------------|--------|
| `skills/sdd-verify/SKILL.md` | Modified | High — tool execution step added |
| `skills/sdd-apply/SKILL.md` | Modified | Medium — commit suggestion removed |
| `openspec/config.yaml` schema | Modified | Low — `verify_commands` key documented |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Test suite unavailable or not auto-detectable | Medium | Medium | Graceful fallback: note "no test command detected", mark criteria as requiring manual confirmation |
| Long test suites block the verify phase | Medium | Low | 120s timeout; partial results are captured and noted |
| User still commits without verifying | High | Medium | Cannot be prevented technically — process enforcement is the control |

## Success Criteria

- [ ] `sdd-verify` runs at least one project tooling command and records output in `verify-report.md`
- [ ] `verify-report.md` includes a `## Tool Execution` section with actual command output
- [ ] `sdd-apply` final output does NOT contain `/commit` — only `/sdd-verify`
- [ ] A criterion marked `[x]` in `verify-report.md` has a corresponding tool output or user evidence entry
- [ ] `verify-report.md` has at least one [x] criterion checked
