# Delta Spec: sdd-verify-execution

Change: 2026-03-10-sdd-verify-enforcement
Date: 2026-03-10
Base: openspec/specs/sdd-verify-execution/spec.md

## ADDED — New requirements

### Requirement: Tool execution section in verify-report.md

The `sdd-verify` skill MUST include a `## Tool Execution` section in `verify-report.md` that records the command run, its exit code, and a summary of test output (pass count, failure count, error messages). This section is always written — even when test execution is skipped.

#### Scenario: Tool execution section written after successful test run

- **GIVEN** a test runner was detected and executed successfully (exit code 0)
- **WHEN** `sdd-verify` writes `verify-report.md`
- **THEN** the file MUST include a `## Tool Execution` section
- **AND** the section MUST record the command run (e.g., `npm test`)
- **AND** the section MUST record the exit code (e.g., `0`)
- **AND** the section MUST record a summary of output: pass count, failure count, and any error messages

#### Scenario: Tool execution section written after failing test run

- **GIVEN** a test runner was detected and the tests failed (exit code non-zero)
- **WHEN** `sdd-verify` writes `verify-report.md`
- **THEN** the file MUST include a `## Tool Execution` section
- **AND** the section MUST record the command run and the non-zero exit code
- **AND** the section MUST list failing test names if parseable from output

#### Scenario: Tool execution section written when test runner is not detected

- **GIVEN** no test runner was detected in the project
- **WHEN** `sdd-verify` writes `verify-report.md`
- **THEN** the file MUST still include a `## Tool Execution` section
- **AND** the section MUST state: "Test Execution: SKIPPED — no test runner detected"

#### Scenario: verify_commands key takes priority over auto-detection

- **GIVEN** `openspec/config.yaml` contains a `verify_commands` key with one or more commands
- **WHEN** `sdd-verify` begins the tool execution step
- **THEN** it MUST use the configured commands instead of the auto-detected test runner
- **AND** it MUST NOT run auto-detected commands when `verify_commands` is present

---

### Requirement: Criteria in verify-report.md may only be marked [x] with evidence

A criterion in `verify-report.md` MUST only be marked `[x]` (checked) when it is verified by actual tool output or an explicit user-provided evidence statement. Abstract reasoning or code inspection alone MUST NOT suffice to check a criterion `[x]`.

#### Scenario: Criterion checked based on passing tool output

- **GIVEN** a test runner was executed and its output confirms a specific criterion is met
- **WHEN** `sdd-verify` produces `verify-report.md`
- **THEN** that criterion MAY be marked `[x]`
- **AND** the corresponding tool output or evidence MUST appear in the `## Tool Execution` section

#### Scenario: Criterion not checked when tool execution is skipped

- **GIVEN** no test runner was detected and no `verify_commands` are configured
- **WHEN** `sdd-verify` produces `verify-report.md`
- **THEN** no criterion MUST be marked `[x]` solely on the basis of code inspection
- **AND** criteria requiring execution evidence MUST be marked `[ ]` with a note: "Manual confirmation required — no tool output available"

#### Scenario: Criterion checked based on explicit user evidence

- **GIVEN** the user provides an explicit evidence statement alongside a criterion
  (e.g., a paste of test output, a screenshot reference, or a direct confirmation)
- **WHEN** `sdd-verify` writes `verify-report.md`
- **THEN** that criterion MAY be marked `[x]`
- **AND** the evidence statement MUST be recorded adjacent to the criterion entry

---

### Requirement: verify_commands optional key in openspec/config.yaml

The `openspec/config.yaml` file MUST support an optional `verify_commands` key that overrides auto-detection with a user-specified list of verification commands. When absent, auto-detection behavior is unchanged.

#### Scenario: verify_commands runs each command in sequence

- **GIVEN** `openspec/config.yaml` contains:
  ```yaml
  verify_commands:
    - "npm test"
    - "npm run lint"
  ```
- **WHEN** `sdd-verify` runs the tool execution step
- **THEN** it MUST run `npm test` first, then `npm run lint`
- **AND** it MUST capture the exit code and output for each command separately
- **AND** the `## Tool Execution` section MUST list each command and its result

#### Scenario: verify_commands absent — auto-detection applies unchanged

- **GIVEN** `openspec/config.yaml` does NOT contain a `verify_commands` key
- **WHEN** `sdd-verify` runs the tool execution step
- **THEN** it MUST use auto-detection as defined in the base spec (package.json, pyproject.toml, etc.)

---

## MODIFIED — Modified requirements

### Requirement: Spec Compliance Matrix _(modified)_

The Spec Compliance Matrix MUST cross-reference spec scenarios against BOTH code inspection evidence AND tool execution output (when tool execution was performed). A scenario verified only by code inspection with no corresponding passing test MUST receive status UNTESTED when a test runner exists — not COMPLIANT.

_(Before: "When no test runner exists" was the only criterion distinguishing UNTESTED from COMPLIANT. The distinction now applies whenever a test runner exists but no test covers the scenario, regardless of code inspection confidence.)_

#### Scenario: Scenario without test coverage marked UNTESTED when runner exists _(modified)_

- **GIVEN** a test runner was detected and executed
- **AND** a spec scenario has no corresponding test in the test suite
- **WHEN** `sdd-verify` produces the Spec Compliance Matrix
- **THEN** that scenario MUST receive status UNTESTED
- **AND** the Evidence column MUST state "No test coverage found"
- **AND** code inspection confidence MUST NOT elevate the status to COMPLIANT

---

## Rules

- The `## Tool Execution` section is mandatory in every `verify-report.md` — even when skipped
- A `[x]` criterion MUST have verifiable evidence (tool output or explicit user statement)
- `verify_commands` in config overrides auto-detection entirely when present — they are not additive
- Commands listed under `verify_commands` are assumed non-destructive — the user is responsible for this
- A command that exits non-zero is recorded but MUST NOT block `sdd-verify` from completing; it contributes to the verdict via existing WARNING/CRITICAL logic
