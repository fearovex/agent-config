# Task Plan: 2026-03-17-specs-verify-config

Date: 2026-03-17
Design: openspec/changes/2026-03-17-specs-verify-config/design.md

## Progress: 10/10 tasks

---

## Phase 1: Spec updates

- [x] 1.1 Modify `openspec/specs/sdd-verify-execution/spec.md` — append new `## Requirement` section for priority level 2 behavior (verify.test_commands), including all scenarios from delta spec (test_commands used, verify_commands takes priority, empty list falls through, multiple commands in sequence, build_command/type_check_command, source label in ## Tool Execution)
- [x] 1.2 Modify `openspec/specs/config-schema/spec.md` — append new `## Requirement` sections for: `verify:` top-level section, `verify.test_commands`, `verify.build_command`, `verify.type_check_command`, `project-setup` population behavior, `memory-init` optional back-fill behavior; append new `## Rules` additions

---

## Phase 2: sdd-verify skill update

- [x] 2.1 Modify `skills/sdd-verify/SKILL.md` — in Step 6 (test command resolution), insert priority level 2 block between the existing `verify_commands` check and the auto-detection table; block must: (a) read `verify.test_commands` from `openspec/config.yaml`, (b) treat empty list as absent, (c) use level 2 commands identical to how `verify_commands` are used, (d) label source as "verify.test_commands (config level 2)" in `## Tool Execution`; update surrounding inline comment to reference three-level model
- [x] 2.2 Modify `skills/sdd-verify/SKILL.md` — in Step 6, add handling for `verify.build_command` (use when present, overrides auto-detected build command) and `verify.type_check_command` (use when present, overrides auto-detected type check command); add validation: non-list `test_commands` and non-string `build_command`/`type_check_command` are treated as absent with a WARNING

---

## Phase 3: project-setup skill update

- [x] 3.1 Modify `skills/project-setup/SKILL.md` — in Step 4 (config.yaml generation), extend the config.yaml template block to include conditional `verify:` section generation: emit `verify:` section with `test_commands` when a test runner is detected (npm test, pytest, make test, ./gradlew test, mix test); conditionally add `build_command` and `type_check_command` when detected; add inline comments documenting all three sub-keys (matching the schema in design.md)
- [x] 3.2 Modify `skills/project-setup/SKILL.md` — add guard: if stack detection fails or no runner is detected, omit the `verify:` section entirely (absence is valid); failure during detection MUST NOT abort config.yaml generation

---

## Phase 4: memory-init skill update

- [x] 4.1 Modify `skills/memory-init/SKILL.md` — add a new final step (after feature discovery) titled "verify: back-fill": (a) if `openspec/config.yaml` does not exist, skip silently with INFO note; (b) if `verify:` key already present, skip (idempotent); (c) otherwise, detect commands from stack context using the same logic as project-setup detect functions; (d) append `verify:` section to config.yaml; (e) emit INFO: "verify: section added to openspec/config.yaml"
- [x] 4.2 Modify `skills/memory-init/SKILL.md` — ensure the back-fill step is explicitly non-blocking: failure to detect commands or write the section MUST NOT produce `status: blocked` or `status: failed`; emit at most an INFO-level note

---

## Phase 5: config.yaml example update

- [x] 5.1 Modify `openspec/config.yaml` (agent-config) — add `verify:` section block with full inline comments documenting the three-level priority model, all sub-keys and their types, and example values; follow the existing `verify_commands` / `coverage:` comment block pattern for consistency

---

## Phase 6: Documentation and memory

- [x] 6.1 Update `ai-context/changelog-ai.md` — record this change: "Added verify: section to openspec/config.yaml schema; updated sdd-verify with three-level priority model; updated project-setup and memory-init to auto-populate verify: on initialization"

---

## Implementation Notes

- All edits are additive (append new sections, insert new blocks) — do not modify or remove existing content in any SKILL.md
- The `verify:` section is optional everywhere — its absence must never break existing behavior
- Empty `verify.test_commands: []` MUST fall through to level 3 auto-detection (not treated as zero-command success)
- `verify_commands` retains absolute priority (level 1) — level 2 only activates when `verify_commands` is absent
- When writing inline comments in config.yaml, follow the exact same formatting pattern used for existing `coverage:` and `verify_commands` comment blocks
- After applying all tasks, run `bash install.sh` to deploy updated SKILL.md files to `~/.claude/`

## Blockers

None.
