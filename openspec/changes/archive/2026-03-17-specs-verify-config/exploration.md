# Exploration: specs-verify-config

## Current State

### sdd-verify (current behavior)

`sdd-verify` detects the test runner using a hardcoded priority table (package.json → pyproject.toml → Makefile → Gradle → mix.exs). The only config-level override is the `verify_commands` key in `openspec/config.yaml`, which replaces auto-detection entirely. There is no mechanism to run real project tests during verification of a SDD change — it verifies spec compliance and code inspection, then skips test execution with a WARNING when no runner is found (which is always the case for the agent-config project itself, which has no test runner).

The `openspec/config.yaml` already documents `verify_commands` as a full override, and `coverage.threshold` as an optional advisory threshold. The schema is well-structured and extensible.

### project-setup (current behavior)

`project-setup` (Step 4) generates `openspec/config.yaml` with a fixed template. The template includes stack detection fields, artifact rules, and commented-out optional keys (`tdd`, `verify_commands`, `diagnosis_commands`, etc.). It does NOT currently auto-populate `verify_commands` or any test-command fields based on detected stack. The test runner detection is entirely left to `sdd-verify` at runtime.

### memory-init (current behavior)

`memory-init` does NOT generate or touch `openspec/config.yaml`. It only creates `ai-context/` files. Stack information including test commands is recorded in `ai-context/stack.md` (`## Testing` section: framework, command, coverage). This information is already available but is not used to populate `openspec/config.yaml`.

### Existing config.yaml schema

The `openspec/config.yaml` in agent-config currently defines:
- `verify_commands` (optional commented-out key) — list of commands, overrides auto-detection
- `coverage` (optional commented-out key) — threshold and tool
- `testing.strategy` — describes the test philosophy for this repo

There is NO `verify-config.yaml` — verification config is co-located in `openspec/config.yaml`.

---

## Affected Areas

| File/Module | Impact | Notes |
| ----------- | ------ | ----- |
| `skills/sdd-verify/SKILL.md` | HIGH | Must read `verify-config.yaml` as a new input source, or extend config.yaml reading |
| `skills/project-setup/SKILL.md` | MEDIUM | Must auto-generate `verify-config.yaml` (or extend config.yaml) based on detected stack |
| `skills/memory-init/SKILL.md` | MEDIUM | Must auto-generate `verify-config.yaml` (or extend config.yaml) based on detected stack |
| `openspec/config.yaml` | LOW | Possibly extended with new `verify_config_path:` redirect key, or a new `verify` section |
| `openspec/specs/sdd-verify-execution/spec.md` | HIGH | Must be extended with new scenarios for `verify-config.yaml` loading behavior |
| `openspec/specs/config-schema/spec.md` | MEDIUM | Must document the new file or new key |
| `ai-context/architecture.md` | LOW | Artifact table needs a new row for `verify-config.yaml` |

---

## Analyzed Approaches

### Approach A: New `verify-config.yaml` per-project file

**Description**: Create a dedicated `verify-config.yaml` at the project root (or in `openspec/`). `sdd-verify` reads this file first, before consulting `openspec/config.yaml`. `project-setup` and `memory-init` auto-generate `verify-config.yaml` by detecting the stack. The file would contain: `test_commands`, `build_command`, `coverage_threshold`, `type_check_command`.

**Pros**:
- Clean separation of concerns — test configuration isolated from SDD workflow config
- Project teams can version it independently
- Clear and discoverable by developers

**Cons**:
- Introduces a new file type/location that teams need to learn
- The existing `openspec/config.yaml` already has `verify_commands` — parallel keys create confusion
- Two files to maintain instead of one
- `project-setup` and `memory-init` already write to `openspec/config.yaml` — a second file adds complexity
- Would require deprecating or documenting the relationship between `verify_commands` (in config.yaml) and the new file

**Estimated effort**: Medium
**Risk**: Medium — potential config.yaml / verify-config.yaml conflict

### Approach B: Extend `openspec/config.yaml` with an auto-populated `verify` section

**Description**: Add a `verify:` top-level section to `openspec/config.yaml` (parallel to `testing:`, `coverage:`) with fields: `test_commands`, `build_command`, `type_check_command`. `project-setup` and `memory-init` auto-populate these fields during stack detection. `sdd-verify` reads the `verify:` section as a higher-priority source than its auto-detection table, but lower than the existing `verify_commands` key (which remains the manual override).

**Pros**:
- All verification configuration stays in one file (`openspec/config.yaml`)
- No new file type to introduce or document
- Consistent with existing pattern: `verify_commands`, `coverage`, `tdd` are all in config.yaml
- `project-setup` already writes `openspec/config.yaml` — natural extension
- `memory-init` can write the `verify:` section using the testing info it captures in `stack.md`

**Cons**:
- Makes `openspec/config.yaml` larger (though it's already well-commented)
- The relationship between `verify:` (auto-detected) and `verify_commands` (full override) needs clear documentation
- Requires updating the spec for `config-schema` to document the new section

**Estimated effort**: Low-Medium
**Risk**: Low — additive change to an established file, no new artifacts

### Approach C: Populate existing `verify_commands` during project-setup / memory-init

**Description**: Instead of adding a new section, `project-setup` and `memory-init` simply populate the `verify_commands` list when they detect a known test runner (e.g., `npm test`, `pytest`, `make test`). The existing `sdd-verify` logic already reads `verify_commands` as the primary override — no change to `sdd-verify` is needed.

**Pros**:
- Zero changes to `sdd-verify`
- No new schema sections
- Minimal scope

**Cons**:
- `verify_commands` is intended as a manual, user-controlled override — auto-populating it blurs its purpose
- Once populated, the user loses auto-detection fallback behavior (by design of the `verify_commands` key)
- If the user changes the test runner, they must remember to update `verify_commands` manually
- Feels like a workaround rather than a proper solution

**Estimated effort**: Low
**Risk**: Low — but introduces semantic confusion about who owns `verify_commands`

---

## Approach Comparison

| Approach | Pros | Cons | Effort | Risk |
| -------- | ---- | ---- | ------ | ---- |
| A: New verify-config.yaml | Clean separation | Two-file complexity, conflicts with existing verify_commands | Medium | Medium |
| B: New `verify:` section in config.yaml | Single file, consistent pattern | Needs clear priority docs vs verify_commands | Low-Medium | Low |
| C: Populate verify_commands directly | Zero sdd-verify changes | Semantic confusion, loses fallback | Low | Low |

---

## Recommendation

**Approach B** — extend `openspec/config.yaml` with an auto-populated `verify:` section.

This is the most architecturally coherent approach. It follows the existing pattern (all verification config lives in `openspec/config.yaml`), does not introduce a new file type, and is fully backwards-compatible. The key insight is: `verify_commands` remains the **explicit manual override** (highest priority), while the new `verify:` section provides **auto-detected defaults** (lower priority, generated by project-setup/memory-init). This priority model is analogous to how `tdd.enabled` vs heuristic detection works in `sdd-apply`.

**Priority model for sdd-verify Step 6:**
1. `verify_commands` present → use as-is, skip all other detection
2. `verify.test_commands` present (new auto-detected section) → use these commands
3. Neither → fall back to existing auto-detection table (package.json, pytest, etc.)

**Changes required:**
1. `sdd-verify` SKILL.md — insert priority level 2 check between `verify_commands` check and auto-detection
2. `project-setup` SKILL.md — Step 4 template should auto-populate `verify.test_commands` etc. when detected
3. `memory-init` SKILL.md — optionally write/update `openspec/config.yaml verify:` section if the file exists (non-blocking if absent)
4. `openspec/specs/sdd-verify-execution/spec.md` — add scenarios for new priority level
5. `openspec/specs/config-schema/spec.md` or a new `openspec/specs/verify-config/spec.md` — document the `verify:` section schema

---

## Identified Risks

- **Risk: priority conflicts with verify_commands** — must be clearly documented; `verify_commands` must remain the highest-priority override. Mitigation: document priority order explicitly in both SKILL.md and spec.
- **Risk: memory-init touching config.yaml unexpectedly** — `memory-init` currently does NOT write `openspec/config.yaml`. Adding this behavior would be a new side effect. Mitigation: make it non-blocking (only update when file already exists, add `verify:` section only if absent), and clearly document the new behavior.
- **Risk: project-setup generates stale commands** — auto-detected commands are only correct at setup time. If the project changes its test runner, the `verify:` section becomes stale. Mitigation: document that `verify:` is a starting point, not a live detection.
- **Risk: sdd-verify-execution spec drift** — the existing spec defines `verify_commands` semantics precisely. Adding a new priority level requires carefully amending the spec without breaking the existing requirements. Mitigation: add new scenarios in a separate Requirement section, not modifying existing ones.

---

## Open Questions

- Should `memory-init` write to `openspec/config.yaml` at all? This is a new behavior for that skill. Alternatively, `memory-init` could only write a comment block to `ai-context/stack.md` noting the recommended `verify:` config, leaving the user to paste it into `config.yaml` manually.
- What is the exact field structure for `verify:`? Candidates: `test_commands` (list), `build_command` (string), `type_check_command` (string), `lint_command` (string). Which are in scope for this change?
- Should `verify:` support per-environment overrides (e.g., `verify.ci_commands` vs `verify.local_commands`)?

---

## Ready for Proposal

Yes — Approach B is well-defined. The three open questions can be resolved during the `sdd-spec` phase with concrete Given/When/Then scenarios. The change scope is clear: three skills + one spec + schema documentation.
