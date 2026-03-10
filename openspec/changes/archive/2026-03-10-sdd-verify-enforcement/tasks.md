# Task Plan: 2026-03-10-sdd-verify-enforcement

Date: 2026-03-10
Design: openspec/changes/2026-03-10-sdd-verify-enforcement/design.md

## Progress: 7/7 tasks

## Phase 1: sdd-verify SKILL.md updates

- [x] 1.1 Modify `skills/sdd-verify/SKILL.md` — Step 6 (Run Tests): add `verify_commands` config key check before auto-detection. When `verify_commands` is present in `openspec/config.yaml`, run each listed command in sequence and capture exit code + output per command. When absent, auto-detection proceeds unchanged. ✓

- [x] 1.2 Modify `skills/sdd-verify/SKILL.md` — Step 10 (Create verify-report.md): mandate the `## Tool Execution` section. The section MUST always be written — even when test execution was skipped. Add the `[x]` evidence rule: a criterion may only be marked `[x]` when backed by tool output or explicit user-provided evidence; otherwise leave `[ ]` with note "Manual confirmation required — no tool output available". ✓

- [x] 1.3 Modify `skills/sdd-verify/SKILL.md` — `## Rules` section: add two rules:
  - "The `## Tool Execution` section is mandatory in every `verify-report.md` — even when skipped"
  - "A criterion marked `[x]` MUST have verifiable evidence: tool output or an explicit user evidence statement" ✓

## Phase 2: sdd-apply SKILL.md update

- [x] 2.1 Modify `skills/sdd-apply/SKILL.md` — Step 7 / Output to Orchestrator block: remove all text containing `/commit` or `git commit` from the final output summary. Replace the commit suggestion with:
  ```
  Implementation complete. Next step:
    /sdd-verify <change-name>  — verify against specs before committing
  ``` ✓

## Phase 3: openspec/config.yaml documentation

- [x] 3.1 Modify `openspec/config.yaml` — add a `verify_commands` documentation block (commented, following the same pattern as `diagnosis_commands`). The block should include: description of the key, its type, override semantics, and a usage example. ✓

## Phase 4: Memory update

- [x] 4.1 Update `ai-context/changelog-ai.md` — record the change: sdd-verify-enforcement adds mandatory `## Tool Execution` section, evidence-based `[x]` criteria rule, `verify_commands` config key, and removes `/commit` suggestion from sdd-apply. ✓

- [x] 4.2 Update `ai-context/architecture.md` — add entry under "Key architectural decisions":
  "sdd-verify enforces an evidence gate before archiving: `verify-report.md` MUST include a `## Tool Execution` section and criteria marked `[x]` MUST have tool output or explicit user evidence (added 2026-03-10, change: sdd-verify-enforcement). `sdd-apply` no longer suggests `/commit` — only `/sdd-verify` is offered as the next step." ✓

---

## Implementation Notes

- The `verify_commands` key is a `list[string]`; commands run in listed order. When present, it overrides auto-detection entirely — it is NOT additive with auto-detection.
- The `## Tool Execution` section must appear in `verify-report.md` for every run. When skipped (no runner, no `verify_commands`), the section still appears with: "Test Execution: SKIPPED — no test runner detected".
- The `[x]` evidence rule applies to ALL criteria in `verify-report.md` — not only test-execution-related ones.
- The `/commit` removal in `sdd-apply` applies to all phases and all output blocks — not only the final phase summary.
- After apply, run `bash install.sh` to deploy the updated SKILL.md files to `~/.claude/`.

## Blockers

None.
