# Technical Design: 2026-03-17-specs-verify-config

Date: 2026-03-17
Proposal: openspec/changes/2026-03-17-specs-verify-config/proposal.md

## General Approach

Extend `openspec/config.yaml` with a `verify:` top-level section and wire it into three SKILL.md files as additive, non-breaking changes. `sdd-verify` gains a mid-priority check (level 2) between the existing `verify_commands` override and the auto-detection table. `project-setup` auto-populates the `verify:` section during config.yaml generation. `memory-init` conditionally writes the section as a non-blocking side effect. All changes are additive YAML/Markdown edits; no new files, no build artifacts, no runtime dependencies.

---

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
| -------- | ------- | --------------------- | ------------- |
| New config key placement | `verify:` as a top-level section with sub-keys `test_commands`, `build_command`, `type_check_command` | Flat top-level keys (`verify_test_commands`, `verify_build_command`); nested under `testing:` | Mirrors the existing `coverage:` top-level pattern in config.yaml; groups verification intent under one namespace; does not collide with existing keys |
| Priority model in sdd-verify Step 6 | Insert level 2 check between existing `verify_commands` check and auto-detection table | Add level 2 before level 1; merge verify_commands and verify.test_commands | Maintains full backward compatibility — `verify_commands` retains absolute priority; new behavior is strictly additive |
| Empty list treatment | Empty `verify.test_commands: []` falls through to level 3 (auto-detection) | Treat empty list as valid zero-command execution | Prevents silent "success" when a user accidentally sets an empty list; explicit non-execution is safer than implicit no-op |
| `memory-init` side effect scope | Write `verify:` only when config.yaml exists AND `verify:` key is absent | Always write `verify:`, merge with existing values | Idempotent one-time initialization — user-set values are never overwritten; safe to run multiple times |
| `project-setup` populate scope | Populate `test_commands` unconditionally when a runner is detected; `build_command` and `type_check_command` as optional annotations | Always emit all three sub-keys even when empty | Keeps generated config.yaml clean; absent sub-keys are valid (fallback to auto-detection applies per spec) |
| Schema documentation convention | Inline comments in generated config.yaml (same pattern as existing `verify_commands`, `coverage:` sections) | Separate schema doc file; update only ai-context/ | Follows the existing `openspec-config-documentation` convention; schema is co-located with the config file it documents |
| ADR creation | Not required — this is an additive convention extension, not a cross-cutting architectural change | Create ADR documenting priority model | The priority model is implementation-level detail for a single skill; no new architectural pattern is introduced |

---

## Data Flow

```
sdd-verify Step 6 — test command resolution:

Read openspec/config.yaml
          │
          ▼
  verify_commands present?
          │
     YES  │  NO
          │
          ▼        ▼
     Use level 1   verify.test_commands present AND non-empty?
     (unchanged)         │
                    YES  │  NO
                         │
                         ▼        ▼
                    Use level 2   Auto-detection table (level 3)
                    (new)         (unchanged: package.json → pyproject → Makefile → etc.)


project-setup Step 4 — config.yaml generation:

Detect stack (Step 1 output)
          │
     Runner detected?
          │
     YES  │  NO
          │
          ▼        ▼
  Emit verify:     Omit verify: section entirely
  section with     (absence is valid)
  test_commands
  [+ optional build_command, type_check_command]


memory-init final step — verify: back-fill:

openspec/config.yaml exists?
          │
     YES  │  NO
          │
          ▼        ▼
  verify: key      Skip silently
  absent?
          │
     YES  │  NO
          │
          ▼        ▼
  Append verify:   Skip (idempotent)
  section with
  detected commands
```

---

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `skills/sdd-verify/SKILL.md` | Modify | Step 6: insert level 2 priority block between `verify_commands` check and auto-detection table; update inline comment to reference three-level model |
| `skills/project-setup/SKILL.md` | Modify | Step 4: extend `openspec/config.yaml` template block to include `verify:` section generation logic with stack-conditional population; add inline comments documenting all three sub-keys |
| `skills/memory-init/SKILL.md` | Modify | Add new final step (after feature discovery): non-blocking `verify:` section back-fill into existing config.yaml |
| `openspec/config.yaml` (agent-config) | Modify | Add `verify:` section block with inline comments as a documented example (same pattern as existing `verify_commands`, `coverage:` comment blocks) |
| `openspec/specs/sdd-verify-execution/spec.md` | Modify | Append new requirement section for priority level 2 behavior; append rules additions |
| `openspec/specs/config-schema/spec.md` | Modify | Append new requirement sections for `verify:` top-level section, its sub-keys, and `project-setup`/`memory-init` population behavior |

---

## Interfaces and Contracts

### openspec/config.yaml — verify: section schema

```yaml
# ---------------------------------------------------------------------------
# verify (optional) — Auto-detected verification commands for /sdd-verify
# ---------------------------------------------------------------------------
# Populated automatically by project-setup on initialization and optionally
# by memory-init when the section is absent.
# Priority in sdd-verify Step 6:
#   Level 1: verify_commands (manual override — highest, unchanged)
#   Level 2: verify.test_commands (this section)
#   Level 3: auto-detection table (package.json, pytest, Makefile, etc.)
#
# test_commands (list of strings, optional):
#   Commands to run the project test suite. Empty list is treated as absent.
#
# build_command (string, optional):
#   Single command to build the project. Overrides auto-detected build.
#
# type_check_command (string, optional):
#   Single command to run type checking. Overrides auto-detected type check.
#
# verify:
#   test_commands:
#     - "npm test"
#   build_command: "npm run build"
#   type_check_command: "npx tsc --noEmit"
```

### sdd-verify Step 6 — three-level priority pseudo-code

```
if config.verify_commands is present and non-empty:
    → level 1: use verify_commands (existing, unchanged)
    → label source: "verify_commands (config level 1)"
    → skip levels 2 and 3
else if config.verify.test_commands is present and non-empty:
    → level 2: use verify.test_commands
    → label source: "verify.test_commands (config level 2)"
    → skip level 3
else:
    → level 3: auto-detection table (package.json → pyproject → Makefile → etc.)
    → label source: "auto-detected" (existing behavior)
```

### project-setup Step 4 — verify: section generation

```
detect_test_runner():
  if package.json with scripts.test → "npm test" (or yarn/pnpm variant)
  if pyproject.toml / pytest.ini  → "pytest"
  if Makefile with test target     → "make test"
  if gradlew / build.gradle       → "./gradlew test"
  if mix.exs                      → "mix test"
  else                            → None

detect_build_command():
  if package.json with scripts.build     → "npm run build" (or variant)
  if package.json with scripts.typecheck → "npm run typecheck"
  if tsconfig.json + TypeScript dep      → "npx tsc --noEmit"
  else                                   → None

if detect_test_runner() is not None:
    emit verify: section with test_commands, build_command (if found), type_check_command (if found)
else:
    omit verify: section (absence is valid)
```

### memory-init — verify: back-fill step

```
if openspec/config.yaml does not exist:
    skip (INFO note optional)
    return
if verify: key already present in config.yaml:
    skip (idempotent — never overwrite)
    return
detect commands from stack context (same logic as project-setup detect functions)
append verify: section to config.yaml
emit INFO: "verify: section added to openspec/config.yaml"
```

---

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Manual verification | Run `/sdd-verify` on agent-config with `verify:` section added to openspec/config.yaml; confirm level 2 commands execute and appear in `## Tool Execution` section with correct source label | Bash via sdd-verify |
| Manual verification | Run `/sdd-verify` on agent-config with both `verify_commands` AND `verify.test_commands` present; confirm level 1 (`verify_commands`) is used and level 2 is ignored | Bash via sdd-verify |
| Manual verification | Run `/sdd-verify` on agent-config with neither key; confirm auto-detection (level 3) runs as before | Bash via sdd-verify |
| Manual verification | Check that `memory-init` on a project with existing config.yaml (no `verify:`) appends the section without modifying other keys | Manual inspection of resulting config.yaml |
| Integration | Run `/project-audit` on agent-config after apply; score must be >= current score | /project-audit |

---

## Migration Plan

No data migration required. All changes are additive to plain-text SKILL.md files and YAML config. The `verify:` section is optional — existing projects without it continue to work identically. No schema version bump required; YAML parsers ignore unknown keys by convention.

---

## Open Questions

None.
