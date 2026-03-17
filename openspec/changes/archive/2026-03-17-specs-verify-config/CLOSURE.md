# Closure: 2026-03-17-specs-verify-config

Start date: 2026-03-17
Close date: 2026-03-17

## Summary

Extended `openspec/config.yaml` with an optional `verify:` top-level section (`test_commands`, `build_command`, `type_check_command`) so that `sdd-verify` uses project-detected commands at priority level 2 without requiring manual `verify_commands` override. Added auto-population in `project-setup` and a non-blocking back-fill step in `memory-init`.

## Modified Specs

| Domain                  | Action   | Change                                                                                                   |
| ----------------------- | -------- | -------------------------------------------------------------------------------------------------------- |
| sdd-verify-execution    | Modified | Added Requirement: verify.test_commands — priority level 2 config key with 7 scenarios; updated Rules   |
| config-schema           | Modified | Added Requirements: verify: top-level section, verify.test_commands, verify.build_command, verify.type_check_command, project-setup auto-population, memory-init back-fill; updated Rules |

## Modified Code Files

- `skills/sdd-verify/SKILL.md` — Step 6 Level 2 block added; Step 7 config override block added
- `skills/project-setup/SKILL.md` — Step 4 extended with detect_test_runner(), detect_build_command(), detect_type_check_command() and conditional emit logic
- `skills/memory-init/SKILL.md` — Step 8 added: non-blocking verify: back-fill
- `openspec/config.yaml` — fully commented `verify:` block added with inline schema documentation
- `openspec/specs/sdd-verify-execution/spec.md` — new Requirement section and Rules additions
- `openspec/specs/config-schema/spec.md` — new Requirement sections and Rules additions

## Key Decisions Made

- Three-level priority model for test command resolution: `verify_commands` (L1) > `verify.test_commands` (L2) > auto-detection (L3). This keeps the existing `verify_commands` interface intact while adding a more structured config-native alternative.
- Empty `verify.test_commands: []` falls through to auto-detection to prevent silent zero-command success.
- `memory-init` back-fill is non-blocking: write failures produce at most an INFO note and never cause `status: blocked` or `status: failed`.
- No ADR created — the three-level priority model is an incremental extension, not a new architectural pattern.

## Lessons Learned

No significant deviations. All 10 tasks completed in the first apply pass. Verify passed with no issues (SKIPPED dimensions expected for this Markdown/YAML/Bash project type).

## User Docs Reviewed

N/A — pre-dates this requirement / change does not affect user-facing onboarding workflows or scenarios.
