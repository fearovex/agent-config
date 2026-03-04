# Spec: sdd-phase-context-loading

Change: feature-domain-knowledge-layer
Date: 2026-03-03

---

## Requirements

### Requirement: sdd-propose optional domain context preload

`sdd-propose` MUST gain an optional domain context preload step. The step reads `ai-context/features/<domain>.md` when a filename match is found and uses the content to enrich the proposal's context. The step MUST be non-blocking: when no match is found, `sdd-propose` proceeds normally without error.

The domain slug matching heuristic MUST work as follows:
1. List all `.md` files in `ai-context/features/` (excluding `_template.md` and files with leading underscores).
2. Compare each filename stem against the change name — a match occurs when the change name **contains** or **starts with** the domain slug, or when the domain slug **contains** the change name stem (case-insensitive, hyphen-normalized).
3. If a match is found, read the file and treat its content as enrichment context before writing the proposal.
4. If multiple files match, load all matching files.
5. If the `ai-context/features/` directory does not exist, skip this step silently.

The preload step MUST be placed **after** reading `exploration.md`, `openspec/config.yaml`, and `ai-context/architecture.md` (existing Step 1) and **before** Step 2 (understand the request in depth).

#### Scenario: Preload succeeds with a matching feature file

- **GIVEN** `ai-context/features/payments.md` exists and contains domain knowledge for the payments bounded context
- **AND** the change name is `add-payment-gateway`
- **WHEN** `sdd-propose` executes the domain context preload step
- **THEN** `payments.md` is identified as a match (change name contains `payment`)
- **AND** the file is read and its content is available as enrichment context during proposal authoring
- **AND** the resulting `proposal.md` reflects awareness of the domain's business rules and invariants

#### Scenario: Preload is skipped when no file matches

- **GIVEN** `ai-context/features/` contains only `auth.md` and `_template.md`
- **AND** the change name is `add-payment-gateway`
- **WHEN** `sdd-propose` executes the domain context preload step
- **THEN** no file is loaded (no slug matches `add-payment-gateway` against `auth`)
- **AND** `sdd-propose` proceeds to Step 2 without error or warning
- **AND** `proposal.md` is produced normally

#### Scenario: Preload is skipped when features directory is absent

- **GIVEN** the project does not have an `ai-context/features/` directory
- **WHEN** `sdd-propose` executes the domain context preload step
- **THEN** the step is silently skipped
- **AND** `sdd-propose` proceeds to Step 2 without error or warning

#### Scenario: Preload does not block proposal creation on file read error

- **GIVEN** `ai-context/features/payments.md` exists but cannot be read (e.g., permissions issue)
- **WHEN** `sdd-propose` attempts the domain context preload step
- **THEN** the preload step logs an INFO-level warning in the orchestrator output
- **AND** `sdd-propose` continues and produces `proposal.md` without error
- **AND** `status` in the orchestrator output MUST be `ok` or `warning`, NEVER `blocked` or `failed` due to this step alone

#### Scenario: Template file is never loaded

- **GIVEN** `ai-context/features/` contains `_template.md` and no other files
- **WHEN** `sdd-propose` executes the domain context preload step
- **THEN** `_template.md` is NOT loaded regardless of the change name
- **AND** the step is silently skipped

---

### Requirement: sdd-spec optional domain context preload

`sdd-spec` MUST gain the same optional domain context preload capability as `sdd-propose`. The heuristic, behavior on miss, and non-blocking contract are identical to the `sdd-propose` requirement above.

The preload step in `sdd-spec` MUST be placed within Step 1 (Read prior artifacts), executed **after** reading `proposal.md` and any existing `openspec/specs/<domain>/spec.md` but **before** identifying affected domains (Step 2).

The feature file content MUST be used to:
- Identify business rules that should be reflected as requirements in the spec
- Surface known invariants that must appear as THEN clauses in scenarios
- Avoid writing scenarios that contradict documented business rules

The feature file content MUST NOT:
- Replace the need to read the existing `openspec/specs/<domain>/spec.md` when it exists
- Cause `sdd-spec` to write implementation details into the spec
- Produce scenarios that are not grounded in observable behavior

#### Scenario: sdd-spec enriches spec with domain knowledge from feature file

- **GIVEN** `ai-context/features/auth.md` exists and documents an invariant: "A user account MUST be verified before it can perform privileged operations"
- **AND** the change name is `auth-privilege-escalation-fix`
- **WHEN** `sdd-spec` executes the domain context preload step
- **THEN** `auth.md` is identified as a match and read
- **AND** the generated spec MUST include a requirement or scenario that reflects the verification invariant as an observable precondition (GIVEN clause or requirement constraint)

#### Scenario: sdd-spec preload does not replace reading the existing domain spec

- **GIVEN** `ai-context/features/auth.md` exists
- **AND** `openspec/specs/auth/spec.md` also exists
- **WHEN** `sdd-spec` runs Step 1
- **THEN** BOTH `openspec/specs/auth/spec.md` AND `ai-context/features/auth.md` are read
- **AND** the feature file is treated as contextual enrichment, not as a replacement for the existing behavioral spec

#### Scenario: sdd-spec proceeds normally with no feature file match

- **GIVEN** `ai-context/features/` contains only `payments.md`
- **AND** the change name is `notification-retry-policy`
- **WHEN** `sdd-spec` executes the domain context preload step
- **THEN** no file matches (`notification` does not match `payments`)
- **AND** `sdd-spec` proceeds to Step 2 without error or warning
- **AND** the produced spec is complete and valid

#### Scenario: Preload outcome is communicated to the orchestrator

- **GIVEN** `sdd-spec` loads one or more feature files during preload
- **WHEN** `sdd-spec` returns its orchestrator output
- **THEN** the `summary` field MUST note that domain context was preloaded (e.g., "domain context loaded from ai-context/features/auth.md")
- **AND** the loaded file paths MUST appear in the `artifacts` list (read, not written)

