# Technical Design: 2026-03-10-sdd-verify-enforcement

Date: 2026-03-10
Proposal: openspec/changes/2026-03-10-sdd-verify-enforcement/proposal.md

## General Approach

Two SKILL.md files are modified: `skills/sdd-verify/SKILL.md` and `skills/sdd-apply/SKILL.md`.

`sdd-verify` gains a formalized tool-execution protocol: a `verify_commands` config key overrides
auto-detection; the `## Tool Execution` section becomes mandatory in every `verify-report.md`;
and the `[x]` evidence rule is added as an explicit constraint. `sdd-apply` loses the `/commit`
suggestion from its final output, replacing it with a single `/sdd-verify` pointer.

No new files, no new dependencies, no schema migration — all changes are textual updates to existing
Markdown skill files and a documentation addition to `openspec/config.yaml`.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|---------------|
| Config key for custom commands | `verify_commands` (new top-level key in `openspec/config.yaml`) | Reuse `diagnosis_commands`; add a new `verify` sub-object | `verify_commands` mirrors the existing `diagnosis_commands` pattern — same level, same semantics (non-destructive, list of strings). Reusing `diagnosis_commands` would conflate apply-time and verify-time operations. A sub-object is unnecessary for V1. |
| `## Tool Execution` section placement in verify-report.md | After `## Detail: Testing`, before `## Detail: Coverage Validation` | At the top; appended at the bottom | Logical flow: completeness → correctness → coherence → testing (static) → execution (dynamic) → coverage → compliance. Matches the order of Steps in `sdd-verify`. |
| `[x]` evidence rule enforcement | Prose rule in SKILL.md (`## Rules`) + inline instruction in Step 10 | Hard block in the skill (refuse to write `[x]` without evidence) | Claude cannot truly enforce a hard block on its own output. A clear rule in `## Rules` and an inline instruction at Step 10 is the correct convention for this meta-system: rules govern behavior, not code guards. This is consistent with how all other constraints are enforced across SDD skills. |
| sdd-apply commit suggestion removal | Remove `/commit` and `git commit` text from the final output block in Step 7 | Add a disclaimer alongside the commit suggestion | A disclaimer is weaker than removal. The proposal is explicit: "Remove any suggestion of `/commit` from the final summary." Removal is unambiguous and removes the temptation. |

## Data Flow

```
sdd-verify execution flow (modified steps highlighted):

Step 1 — Read artifacts
  ↓
Step 2 — Completeness Check
  ↓
Step 3 — Correctness Check
  ↓
Step 4 — Coherence Check
  ↓
Step 5 — Testing Check (static — code inspection)
  ↓
Step 6 — [MODIFIED] Run Tests / verify_commands
    Read openspec/config.yaml → verify_commands present?
      YES → run each listed command in sequence
      NO  → auto-detect runner (package.json, pytest, etc.)
    Capture exit code + stdout/stderr for each command
    ↓
Step 7 — Build & Type Check (unchanged)
  ↓
Step 8 — Coverage Validation (unchanged)
  ↓
Step 9 — Spec Compliance Matrix
    [MODIFIED] Scenarios without test coverage → UNTESTED
    when a test runner exists (not only when runner absent)
  ↓
Step 10 — [MODIFIED] Create verify-report.md
    Mandatory ## Tool Execution section
    [x] only when tool output or explicit user evidence present
```

```
sdd-apply final output (modified):

Step 7 — Update progress in tasks.md
  ↓
Output to Orchestrator
  summary: "Implementation complete. Next step:
    /sdd-verify <change-name>  — verify against specs before committing"
  [NO /commit mention]
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `skills/sdd-verify/SKILL.md` | Modify | Step 6: add `verify_commands` config key check before auto-detection; Step 10: mandate `## Tool Execution` section; add `[x]` evidence rule to Step 10 and `## Rules` |
| `skills/sdd-apply/SKILL.md` | Modify | Step 7 / Output block: remove `/commit` and `git commit` text; replace with `/sdd-verify <change-name>` pointer |
| `openspec/config.yaml` | Modify | Add `verify_commands` documentation block (commented, with usage example) — mirrors existing `diagnosis_commands` pattern |

## Interfaces and Contracts

### verify_commands config key (new)

```yaml
# openspec/config.yaml
verify_commands:
  - "npm test"
  - "npm run lint"
```

- Type: `list[string]` — ordered; each string is a shell command
- Optional: when absent, auto-detection applies unchanged
- Semantics: commands run in listed order; each captures exit code + output independently
- Assumed non-destructive: user responsibility (same convention as `diagnosis_commands`)
- Overrides: when present, replaces auto-detection entirely (not additive)

### ## Tool Execution section (mandatory in verify-report.md)

```markdown
## Tool Execution

| Command | Exit Code | Result |
|---------|-----------|--------|
| npm test | 0 | PASS — 42 passed, 0 failed |
| npm run lint | 0 | PASS — no lint errors |

[If skipped:]
Test Execution: SKIPPED — no test runner detected
```

### [x] evidence rule

A criterion in `verify-report.md` may be marked `[x]` only when:
1. A tool command was run and its output confirms the criterion, OR
2. The user provided an explicit evidence statement

When neither condition is met: criterion MUST be left `[ ]` with note:
`"Manual confirmation required — no tool output available"`

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Manual integration | Run `/sdd-verify` on a real project after applying the change; confirm `## Tool Execution` section appears and `[x]` criteria have evidence | Manual |
| Manual integration | Run `/sdd-apply` on a real project; confirm no `/commit` appears in output | Manual |
| Audit | Run `/project-audit` on claude-config; score must be >= previous (98) | `/project-audit` |

No automated test runner exists for this project (claude-config is a Markdown/YAML/Bash meta-system). Verification is via manual integration testing against a real target project and the audit score gate.

## Migration Plan

No data migration required. All changes are textual modifications to SKILL.md files and `openspec/config.yaml` documentation. Existing `verify-report.md` files already produced are unaffected.

`install.sh` must be run after apply to deploy the updated skills to `~/.claude/`.

## Open Questions

None.
