# Proposal: 2026-03-17-specs-verify-config

Date: 2026-03-17
Status: Draft

## Intent

Extend `openspec/config.yaml` with an auto-populated `verify:` section so that `sdd-verify` can use project-detected test commands without requiring manual `verify_commands` override.

## Motivation

Currently, `sdd-verify` detects the test runner at runtime via a hardcoded priority table (package.json → pyproject.toml → Makefile → Gradle → mix.exs). For projects with no standard manifest (like `agent-config`, which has no package.json or pyproject.toml), auto-detection always fails and verification skips test execution with a WARNING. The only existing workaround is the manual `verify_commands` override in `openspec/config.yaml`, which is intended as an explicit user-controlled escape hatch — not as a default configuration target.

Meanwhile, `project-setup` already detects the tech stack during initialization, and `memory-init` already captures test command information in `ai-context/stack.md`. Neither currently uses this information to pre-populate any verification configuration. This is a gap: the information is available but unused.

The solution is to add a `verify:` section to `openspec/config.yaml` that `project-setup` and `memory-init` auto-populate, and that `sdd-verify` consults as a mid-priority fallback between the manual `verify_commands` override and the auto-detection table.

## Scope

### Included

- `sdd-verify` SKILL.md: insert priority level 2 check — read `verify.test_commands` from `openspec/config.yaml` when `verify_commands` is absent
- `project-setup` SKILL.md: auto-populate `verify.test_commands`, `verify.build_command`, `verify.type_check_command` in the generated `openspec/config.yaml` when a stack is detected
- `memory-init` SKILL.md: write/update the `verify:` section in `openspec/config.yaml` when the file already exists and the `verify:` key is absent (non-blocking side effect)
- `openspec/specs/sdd-verify-execution/spec.md` or a new domain spec: add scenarios for the new priority level 2 behavior
- `openspec/specs/config-schema/spec.md` or a new `openspec/specs/verify-config/spec.md`: document the `verify:` section fields and their semantics

### Excluded (explicitly out of scope)

- Per-environment overrides (e.g., `verify.ci_commands` vs `verify.local_commands`) — deferred to a follow-up change if needed
- Auto-refreshing stale `verify:` entries — once written, `verify:` is a starting point; users must update it manually if the test runner changes
- Renaming or deprecating the existing `verify_commands` key — it remains the highest-priority manual override
- Changes to `sdd-apply` or any SDD phase other than `sdd-verify`
- Coverage threshold logic — `coverage.threshold` is already in `config.yaml` and remains unchanged

## Proposed Approach

Add a `verify:` top-level section to `openspec/config.yaml` with the following fields:
- `test_commands` (list of strings): commands to run the project's test suite
- `build_command` (string, optional): command to build the project before testing
- `type_check_command` (string, optional): command to run type-checking

**Priority model in `sdd-verify` Step 6:**
1. `verify_commands` present in config → use as-is (existing behavior, unchanged)
2. `verify.test_commands` present (new) → use these commands
3. Neither → fall back to existing auto-detection table (package.json, pytest, etc.)

`project-setup` auto-populates `verify.test_commands` (and optionally `build_command`, `type_check_command`) during Step 4 (config.yaml generation) based on detected stack.

`memory-init` optionally writes the `verify:` section if `openspec/config.yaml` already exists and the `verify:` key is absent. This is a non-blocking side effect — missing config.yaml does not block `memory-init`.

Specs are updated or created to capture the new priority model with Given/When/Then scenarios.

## Affected Areas

| Area/Module | Type of Change | Impact |
| ----------- | -------------- | ------ |
| `skills/sdd-verify/SKILL.md` | Modified | High — new priority level 2 check inserted |
| `skills/project-setup/SKILL.md` | Modified | Medium — Step 4 auto-populates `verify:` section |
| `skills/memory-init/SKILL.md` | Modified | Medium — optional non-blocking `verify:` section write |
| `openspec/config.yaml` (agent-config) | Modified | Low — `verify:` section added as documentation example |
| `openspec/specs/sdd-verify-execution/spec.md` | Modified | High — new scenarios for priority level 2 |
| `openspec/specs/config-schema/spec.md` | Modified | Medium — `verify:` section schema documented |

## Risks

| Risk | Probability | Impact | Mitigation |
| ---- | ----------- | ------ | ---------- |
| Priority conflicts with `verify_commands` | Low | Medium | Document priority order explicitly in both SKILL.md and spec; `verify_commands` remains level 1 (highest) |
| `memory-init` unexpected side effect on `config.yaml` | Low | Low | Only add `verify:` section when file exists AND key is absent; behavior is non-blocking and documented |
| Stale `verify:` section after runner change | Medium | Low | Document that `verify:` is a one-time starting point, not live detection; users must update manually |
| Spec drift (`sdd-verify-execution` spec) | Low | Medium | Add new scenarios in a new `## Requirement` section; do not modify existing requirements |

## Rollback Plan

This change modifies only SKILL.md files (text files, no compiled output) and YAML configuration. If the new behavior causes issues:

1. Revert `skills/sdd-verify/SKILL.md` to the committed version before this change (remove priority level 2 block)
2. Revert `skills/project-setup/SKILL.md` and `skills/memory-init/SKILL.md` to pre-change versions
3. Remove or comment out the `verify:` section from any affected `openspec/config.yaml` files
4. Run `bash install.sh` to re-deploy the reverted SKILL.md files to `~/.claude/`
5. Verify: run `/sdd-verify` on a test project and confirm it falls back to auto-detection as before

No database, build artifact, or external service is affected. Rollback is complete within one git revert + install.sh run.

## Dependencies

- `openspec/specs/sdd-verify-execution/spec.md` must exist (it does, per exploration.md)
- `openspec/specs/config-schema/spec.md` must exist (it does, per exploration.md) — or a new `verify-config` spec domain will be created
- No external dependencies

## Success Criteria

- [ ] `sdd-verify` SKILL.md includes a clearly labeled priority level 2 block that reads `verify.test_commands` from `openspec/config.yaml` between `verify_commands` check and auto-detection table
- [ ] `project-setup` SKILL.md Step 4 includes instructions to auto-populate `verify.test_commands` (and optionally `build_command`, `type_check_command`) based on detected stack
- [ ] `memory-init` SKILL.md includes a non-blocking step to write the `verify:` section to `openspec/config.yaml` when the file exists and the key is absent
- [ ] At least one spec file documents the `verify:` section field schema and the three-level priority model
- [ ] At least two Given/When/Then scenarios in a spec file cover: (a) `verify.test_commands` present → used, and (b) `verify.test_commands` absent → falls back to auto-detection

## Effort Estimate

Low-Medium (1–2 days): three SKILL.md edits of moderate size + two spec updates. No new files required (all edits are additive to existing files). The priority model logic is simple (a new `if` branch). Spec writing is the most time-consuming part due to scenario precision requirements.
