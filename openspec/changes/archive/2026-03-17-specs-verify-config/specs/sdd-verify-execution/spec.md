# Delta Spec: sdd-verify-execution

Change: 2026-03-17-specs-verify-config
Date: 2026-03-17
Base: openspec/specs/sdd-verify-execution/spec.md

---

## ADDED — New requirements

### Requirement: verify.test_commands in config as priority level 2 fallback

The `sdd-verify` skill MUST consult the `verify.test_commands` key in `openspec/config.yaml` when the `verify_commands` key is absent. This creates a three-level priority model for test command resolution:

1. `verify_commands` present → use those commands (existing level 1, unchanged)
2. `verify.test_commands` present → use these commands (new level 2)
3. Neither key present → fall back to auto-detection table (existing level 3, unchanged)

When `verify.test_commands` is used, `sdd-verify` MUST behave identically to how it behaves under `verify_commands`: run each command in sequence, capture exit code and output per command, and write results to the `## Tool Execution` section of `verify-report.md`.

#### Scenario: verify.test_commands used when verify_commands is absent

- **GIVEN** `openspec/config.yaml` contains a `verify:` section with `test_commands: ["bash install.sh --dry-run"]`
- **AND** `openspec/config.yaml` does NOT contain a `verify_commands` key
- **WHEN** `sdd-verify` runs the tool execution step
- **THEN** it MUST run `bash install.sh --dry-run`
- **AND** it MUST capture the exit code and output
- **AND** the `## Tool Execution` section MUST record the command, exit code, and output summary
- **AND** auto-detection (package.json, pyproject.toml, Makefile, etc.) MUST NOT run

#### Scenario: verify_commands takes priority over verify.test_commands

- **GIVEN** `openspec/config.yaml` contains both a `verify_commands` key AND a `verify.test_commands` key
- **WHEN** `sdd-verify` runs the tool execution step
- **THEN** it MUST use the `verify_commands` list (level 1 — highest priority)
- **AND** it MUST NOT execute the commands listed under `verify.test_commands`

#### Scenario: verify.test_commands absent — auto-detection applies

- **GIVEN** `openspec/config.yaml` does NOT contain a `verify_commands` key
- **AND** `openspec/config.yaml` does NOT contain a `verify.test_commands` key (or the `verify:` section is absent)
- **WHEN** `sdd-verify` runs the tool execution step
- **THEN** it MUST fall through to the auto-detection table (package.json, pyproject.toml, Makefile, etc.)
- **AND** behavior is identical to the pre-change base spec

#### Scenario: verify.test_commands is empty list — treated as absent

- **GIVEN** `openspec/config.yaml` contains `verify.test_commands: []` (empty list)
- **WHEN** `sdd-verify` evaluates the priority model
- **THEN** it MUST treat the empty list the same as absent — fall through to auto-detection
- **AND** it MUST NOT attempt to execute zero commands and declare success

#### Scenario: verify.test_commands runs multiple commands in sequence

- **GIVEN** `openspec/config.yaml` contains:
  ```yaml
  verify:
    test_commands:
      - "bash install.sh --check"
      - "bash hooks/validate.sh"
  ```
- **AND** `openspec/config.yaml` does NOT contain `verify_commands`
- **WHEN** `sdd-verify` runs the tool execution step
- **THEN** it MUST run `bash install.sh --check` first, then `bash hooks/validate.sh`
- **AND** it MUST capture the exit code and output for each command separately
- **AND** the `## Tool Execution` section MUST list each command and its individual result

#### Scenario: verify.build_command executed when present

- **GIVEN** `openspec/config.yaml` contains a `verify.build_command` key (e.g., `build_command: "bash install.sh"`)
- **WHEN** `sdd-verify` runs the build/type-check step
- **THEN** it MUST use `verify.build_command` as the build command
- **AND** it MUST capture the exit code and output
- **AND** the result MUST appear in the verify-report.md Build/Type Check section

#### Scenario: verify.type_check_command executed when present

- **GIVEN** `openspec/config.yaml` contains a `verify.type_check_command` key
- **WHEN** `sdd-verify` runs the build/type-check step
- **THEN** it MUST execute the specified type check command
- **AND** it MUST capture the exit code and output
- **AND** the result MUST appear in the verify-report.md Build/Type Check section

#### Scenario: Tool execution section states source of commands

- **GIVEN** `sdd-verify` used `verify.test_commands` (priority level 2) to determine the test command
- **WHEN** `sdd-verify` writes `verify-report.md`
- **THEN** the `## Tool Execution` section MUST identify the command source as "verify.test_commands (config level 2)"
- **AND** it MUST NOT label the source as "auto-detected" or "verify_commands"

---

## MODIFIED — Modified requirements

### Requirement: verify_commands optional key in openspec/config.yaml
_(Before: single-level config override; now: level 1 in a three-level priority model)_

The `openspec/config.yaml` file MUST support the `verify_commands` key as level 1 (highest priority) in the test command resolution model. When present, it overrides both `verify.test_commands` (level 2) and auto-detection (level 3). Existing behavior is unchanged — this requirement is modified only to make the priority relationship explicit.

#### Scenario: verify_commands absent — auto-detection applies unchanged _(modified)_

- **GIVEN** `openspec/config.yaml` does NOT contain a `verify_commands` key
- **AND** `openspec/config.yaml` does NOT contain a `verify.test_commands` key
- **WHEN** `sdd-verify` runs the tool execution step
- **THEN** it MUST use auto-detection as defined in the base spec (package.json, pyproject.toml, etc.)
- **AND** behavior is unchanged from the pre-change version

---

## Rules (additions)

- `verify.test_commands` is level 2: higher priority than auto-detection, lower than `verify_commands`
- An empty `verify.test_commands` list MUST be treated as absent — fall through to level 3
- When `verify.test_commands` is used, the `## Tool Execution` section MUST label the source as "verify.test_commands (config level 2)"
- `verify.build_command` overrides auto-detected build command when present
- `verify.type_check_command` overrides auto-detected type check command when present
- All new `verify:` sub-keys are optional — their absence MUST NOT degrade behavior (existing fallbacks apply)
