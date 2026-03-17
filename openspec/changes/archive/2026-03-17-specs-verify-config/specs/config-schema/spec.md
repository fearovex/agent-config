# Delta Spec: config-schema

Change: 2026-03-17-specs-verify-config
Date: 2026-03-17
Base: openspec/specs/config-schema/spec.md

---

## ADDED — New requirements

### Requirement: verify: is an optional top-level section in openspec/config.yaml

`openspec/config.yaml` MUST accept a `verify:` top-level section. Its absence MUST NOT break any existing skill that reads `openspec/config.yaml`, and MUST NOT alter any `sdd-verify` behavior (existing fallbacks remain fully in effect).

#### Scenario: config.yaml without verify: section — no behavioral change

- **GIVEN** a project whose `openspec/config.yaml` does not contain a `verify:` key
- **WHEN** `sdd-verify` reads `openspec/config.yaml`
- **THEN** `sdd-verify` behaves identically to the pre-change version
- **AND** no error, warning, or INFO note is emitted about the absent `verify:` key

#### Scenario: config.yaml with a valid verify: section passes parsing without errors

- **GIVEN** a project whose `openspec/config.yaml` contains a `verify:` section with valid sub-keys
- **WHEN** any SDD phase skill reads `openspec/config.yaml`
- **THEN** the file parses without errors
- **AND** no existing skill's behavior is altered by the presence of the `verify:` key (only `sdd-verify` acts on it)

---

### Requirement: verify.test_commands declares the project's test commands

The `test_commands` key under `verify:` MUST be a list of one or more shell command strings. When present and non-empty, `sdd-verify` MUST use these commands (priority level 2) instead of running auto-detection.

#### Scenario: verify.test_commands contains a single command

- **GIVEN** `openspec/config.yaml` contains:
  ```yaml
  verify:
    test_commands:
      - "bash install.sh --dry-run"
  ```
- **WHEN** a developer or SDD phase skill reads the config
- **THEN** the value is parseable as a YAML list with one string element: `"bash install.sh --dry-run"`
- **AND** `sdd-verify` uses this command at priority level 2 (when `verify_commands` is absent)

#### Scenario: verify.test_commands contains multiple commands

- **GIVEN** `openspec/config.yaml` contains:
  ```yaml
  verify:
    test_commands:
      - "bash install.sh --check"
      - "bash hooks/validate.sh"
  ```
- **WHEN** `sdd-verify` reads the config
- **THEN** both commands are available as an ordered list
- **AND** `sdd-verify` executes them in declaration order

#### Scenario: verify.test_commands is an empty list — treated as absent

- **GIVEN** `openspec/config.yaml` contains `verify:\n  test_commands: []`
- **WHEN** `sdd-verify` evaluates the priority model
- **THEN** it MUST treat the empty list the same as absent
- **AND** it MUST fall through to auto-detection (level 3)

---

### Requirement: verify.build_command declares the project's build command

The `build_command` key under `verify:` MUST be a single string. When present, `sdd-verify` MUST use it in place of auto-detected build commands.

#### Scenario: verify.build_command present — used by sdd-verify

- **GIVEN** `openspec/config.yaml` contains:
  ```yaml
  verify:
    build_command: "bash install.sh"
  ```
- **WHEN** `sdd-verify` runs its build/type-check step
- **THEN** it MUST execute `bash install.sh` as the build command
- **AND** it MUST NOT attempt to auto-detect a build command from package.json, Makefile, etc.

#### Scenario: verify.build_command absent — auto-detection applies

- **GIVEN** the `verify:` section does not contain a `build_command` key
- **WHEN** `sdd-verify` runs its build/type-check step
- **THEN** it MUST fall back to auto-detection for the build command (unchanged behavior)

---

### Requirement: verify.type_check_command declares the project's type check command

The `type_check_command` key under `verify:` MUST be a single string. When present, `sdd-verify` MUST use it in place of auto-detected type check commands.

#### Scenario: verify.type_check_command present — used by sdd-verify

- **GIVEN** `openspec/config.yaml` contains:
  ```yaml
  verify:
    type_check_command: "npx tsc --noEmit"
  ```
- **WHEN** `sdd-verify` runs its build/type-check step
- **THEN** it MUST execute `npx tsc --noEmit` as the type check command
- **AND** it MUST NOT attempt to auto-detect a type check command from tsconfig.json or devDependencies

#### Scenario: verify.type_check_command absent — auto-detection applies

- **GIVEN** the `verify:` section does not contain a `type_check_command` key
- **WHEN** `sdd-verify` runs its build/type-check step
- **THEN** it MUST fall back to auto-detection for the type check command (unchanged behavior)

---

### Requirement: project-setup auto-populates the verify: section on project initialization

When `project-setup` generates `openspec/config.yaml`, it MUST attempt to populate the `verify:` section based on the detected project stack.

#### Scenario: project-setup detects npm stack — populates verify.test_commands with npm test

- **GIVEN** `project-setup` detects a `package.json` with a `scripts.test` entry
- **WHEN** `project-setup` generates `openspec/config.yaml`
- **THEN** the generated config MUST include:
  ```yaml
  verify:
    test_commands:
      - "npm test"
  ```
- **AND** it MAY also include `build_command` and `type_check_command` based on detected scripts

#### Scenario: project-setup detects Python stack — populates verify.test_commands with pytest

- **GIVEN** `project-setup` detects `pyproject.toml` or `setup.cfg` indicating pytest
- **WHEN** `project-setup` generates `openspec/config.yaml`
- **THEN** the generated config MUST include:
  ```yaml
  verify:
    test_commands:
      - "pytest"
  ```

#### Scenario: project-setup detects no recognizable stack — verify: section omitted

- **GIVEN** `project-setup` cannot detect a recognizable test runner (no package.json, no pyproject.toml, no Makefile with test target, no gradlew)
- **WHEN** `project-setup` generates `openspec/config.yaml`
- **THEN** the generated config MUST NOT include a `verify:` section (or MUST include it with all sub-keys absent/empty)
- **AND** the absence of `verify:` is a valid configuration state (no error)

#### Scenario: project-setup is non-blocking when stack detection fails

- **GIVEN** `project-setup` encounters an error during stack detection
- **WHEN** it generates `openspec/config.yaml`
- **THEN** it MUST NOT fail or abort
- **AND** it MUST proceed without the `verify:` section
- **AND** it MUST emit at most an INFO-level note about skipping `verify:` population

---

### Requirement: memory-init optionally writes the verify: section when absent

When `memory-init` runs on a project that already has `openspec/config.yaml` AND the `verify:` key is absent, `memory-init` SHOULD write the `verify:` section as a non-blocking side effect.

#### Scenario: memory-init adds verify: to existing config.yaml when verify: is absent

- **GIVEN** `openspec/config.yaml` exists in the project
- **AND** the file does NOT contain a `verify:` key
- **AND** `memory-init` has detected the project's test runner from stack context
- **WHEN** `memory-init` completes its primary execution
- **THEN** it MUST append or merge the `verify:` section into `openspec/config.yaml`
- **AND** it MUST NOT overwrite any existing keys in `openspec/config.yaml`
- **AND** it MUST emit an INFO note: "verify: section added to openspec/config.yaml"

#### Scenario: memory-init does not modify config.yaml when verify: already exists

- **GIVEN** `openspec/config.yaml` exists and already contains a `verify:` key
- **WHEN** `memory-init` runs
- **THEN** it MUST NOT modify the existing `verify:` section
- **AND** it MUST NOT overwrite user-configured `test_commands`, `build_command`, or `type_check_command` values

#### Scenario: memory-init does not fail when config.yaml is absent

- **GIVEN** `openspec/config.yaml` does NOT exist in the project
- **WHEN** `memory-init` reaches the step that would write the `verify:` section
- **THEN** it MUST skip this step silently (or with at most an INFO note)
- **AND** `memory-init` MUST NOT fail or produce `status: blocked` or `status: failed`

---

## Rules (additions)

- The `verify:` section is optional — its absence is always valid and MUST NOT alter any behavior
- All sub-keys under `verify:` (`test_commands`, `build_command`, `type_check_command`) are individually optional
- `test_commands` MUST be a YAML list of strings; a non-list value is a configuration error (sdd-verify MUST treat it as absent and emit a WARNING)
- `build_command` and `type_check_command` MUST each be a single string; a list value is a configuration error (sdd-verify MUST treat it as absent and emit a WARNING)
- `memory-init` writes the `verify:` section only when config.yaml exists AND `verify:` is absent — this is a one-time initialization, not live detection
- Schema documentation for the `verify:` section MUST be present as inline comments in the generated `openspec/config.yaml` produced by `project-setup`
