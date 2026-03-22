# Delta Spec: Orchestrator Behavior

Change: 2026-03-21-orchestrator-action-control-gates
Date: 2026-03-22
Base: openspec/specs/orchestrator-behavior/spec.md

## ADDED — New requirements

### Requirement: Pre-flight active change scan before routing any Change Request

Before routing a Change Request (recommending `/sdd-ff` or `/sdd-new`), the orchestrator MUST perform an active change scan to detect in-flight cycles with semantic overlap. This check is **advisory only** — it MUST NOT block routing.

**Scan algorithm:**
1. List all directories in `openspec/changes/` excluding `archive/`
2. For each directory, extract slug tokens (split on `-`); discard tokens that are stop words or length ≤ 3 (e.g., `fix`, `add`, `the`, `for`, `and`)
3. Tokenize the current change description using the same rules
4. If any substantive token from the current description matches any substantive token from an in-flight slug: emit the advisory

**Advisory format:**
> "You have `<change-name>` in progress. Do you want to continue that cycle or start a new one?"

The advisory is displayed inline in the response, before the SDD command recommendation. The user MUST always receive the routing recommendation regardless of advisory output.

#### Scenario: Overlap detected with in-flight change

- **GIVEN** `openspec/changes/2026-03-21-orchestrator-refactor/` exists (non-archived)
- **AND** the user sends "update the orchestrator classification rules"
- **WHEN** the orchestrator classifies the message as a Change Request
- **THEN** it MUST emit the advisory: "You have `2026-03-21-orchestrator-refactor` in progress. Do you want to continue that cycle or start a new one?"
- **AND** it MUST still display the SDD command recommendation after the advisory

#### Scenario: No overlap — different semantic domain

- **GIVEN** `openspec/changes/2026-03-21-add-payment-feature/` exists (non-archived)
- **AND** the user sends "fix the auth login bug"
- **WHEN** the orchestrator performs the active change scan
- **THEN** it MUST NOT emit an advisory (no substantive token overlap)
- **AND** it MUST route normally to `/sdd-ff fix-auth-login-bug`

#### Scenario: No active changes exist

- **GIVEN** `openspec/changes/` contains only `archive/` subdirectory or is empty
- **WHEN** the orchestrator performs the active change scan
- **THEN** it MUST skip the advisory silently and proceed to routing

#### Scenario: Short tokens do not produce false-positive advisory

- **GIVEN** `openspec/changes/2026-03-20-fix-add-update/` exists (non-archived)
- **AND** the user sends "fix the spacing"
- **WHEN** the orchestrator performs the active change scan
- **THEN** it MUST NOT emit an advisory — `fix`, `add`, `update` are stop words (length ≤ 3 or common verbs on the stop list)

#### Scenario: Advisory does not block — user can proceed

- **GIVEN** the advisory is displayed for an in-flight change
- **WHEN** the user replies "start a new one"
- **THEN** the orchestrator MUST proceed with the new Change Request routing as normal

---

### Requirement: Pre-flight spec drift advisory before routing any Change Request

Before routing a Change Request, the orchestrator MUST perform a keyword match of the change description against `openspec/specs/index.yaml` domain keywords. If a match is found, it MUST surface a spec drift advisory. This check is **advisory only** — it MUST NOT block routing.

**Match algorithm:**
- If `index.yaml` is absent: skip silently (graceful degradation — no error, no advisory)
- If `index.yaml` is present: tokenize the change description; check each token against domain `keywords[]` arrays in index.yaml
- If any domain keyword matches a token from the description: emit the advisory for that domain
- At most 3 domain advisories are surfaced per Change Request (cap to avoid noise)
- The check is keyword-match only — **no spec file is read** at this stage

**Advisory format:**
> "Your change touches the `<domain>` domain — check the spec before proposing."

The advisory is displayed inline in the response, before the SDD command recommendation. The user MUST always receive the routing recommendation regardless of advisory output.

#### Scenario: Domain match found in index.yaml

- **GIVEN** `openspec/specs/index.yaml` exists and contains domain `orchestrator-behavior` with keywords `[orchestrator, intent-classification, routing]`
- **AND** the user sends "update the orchestrator intent classification"
- **WHEN** the orchestrator performs the spec drift keyword check
- **THEN** it MUST emit: "Your change touches the `orchestrator-behavior` domain — check the spec before proposing."
- **AND** it MUST still display the SDD command recommendation after the advisory

#### Scenario: index.yaml absent — graceful degradation

- **GIVEN** `openspec/specs/index.yaml` does not exist
- **WHEN** the orchestrator attempts the spec drift advisory check
- **THEN** it MUST skip the check silently
- **AND** it MUST NOT emit any error or advisory
- **AND** routing MUST proceed normally

#### Scenario: No domain keyword match

- **GIVEN** `openspec/specs/index.yaml` exists with various domains
- **AND** the user sends "rename the config file"
- **WHEN** the orchestrator performs the keyword check
- **THEN** it MUST NOT emit any spec drift advisory
- **AND** routing MUST proceed normally

#### Scenario: Multiple domain matches are capped at 3

- **GIVEN** `openspec/specs/index.yaml` exists with 10 domains that all keyword-match "update"
- **AND** the user sends "update the system"
- **WHEN** the orchestrator performs the keyword check
- **THEN** it MUST emit advisories for at most 3 matched domains
- **AND** it MUST NOT emit more than 3 advisories in a single pre-flight response

#### Scenario: Pre-flight checks apply only to Change Requests

- **GIVEN** the user asks a Question: "how does the orchestrator work?"
- **WHEN** the orchestrator classifies the intent as Question
- **THEN** it MUST NOT run the pre-flight active change scan
- **AND** it MUST NOT run the pre-flight spec drift advisory
- **AND** it MUST apply Step 8 spec-first Q&A (Question pathway only)
