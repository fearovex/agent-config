# Spec: spec-context-discovery

Change: 2026-03-21-fix-archive-residue-specs-loading
Date: 2026-03-21

## Overview

This spec defines how all SDD phase skills discover and load relevant master specs during Step 0c (Spec context preload). The discovery mechanism is index-first: if `openspec/specs/index.yaml` exists, keyword-based domain scoring is applied; otherwise, directory-based stem matching is used as a fallback. The goal is to ensure that phase skills have access to all relevant behavioral contracts early in their execution.

---

## Requirements

### Requirement: Index-first spec discovery algorithm

All SDD phase skills (`sdd-explore`, `sdd-propose`, `sdd-spec`, `sdd-design`, `sdd-tasks`, `sdd-apply`, `sdd-verify`) MUST implement a three-tier spec discovery sequence in Step 0c:

1. **Tier 1 — Index-based discovery (if index.yaml exists)**:
   - Read `openspec/specs/index.yaml`
   - Extract all domain entries and their keyword arrays
   - Score each domain by matching against change name tokens and explicit keywords
   - Select the top 3 domains by score (hard cap)

2. **Tier 2 — Directory-based fallback (if Tier 1 finds no matches OR index.yaml is absent)**:
   - List subdirectory names in `openspec/specs/`
   - Apply stem matching: split change name on hyphens, match stems against domain names
   - Select up to 3 matching domains

3. **Tier 3 — No match**:
   - Skip spec context preload
   - Proceed with no error (non-blocking)

#### Scenario: Index.yaml exists — keyword scoring is applied

- **GIVEN** `openspec/specs/index.yaml` exists with domain entries including:
  ```yaml
  domains:
    - domain: payment-system
      keywords: [payment, transaction, charge, refund, invoice, billing]
    - domain: user-auth
      keywords: [auth, login, password, session, token, jwt]
    - domain: notification-system
      keywords: [email, sms, notification, alert, message, broadcast]
  ```
- **AND** the change name is `2026-03-21-add-email-refund-notifications`
- **WHEN** Step 0c runs the discovery algorithm
- **THEN** the skill MUST:
  1. Tokenize the change name into stems: `["add", "email", "refund", "notifications"]` (discard single-char stems)
  2. Check index.yaml for explicit keyword matches:
     - `notification-system`: matches "email" and "notifications" → score += 2
     - `payment-system`: matches "refund" → score += 1
     - `user-auth`: no matches → score = 0
  3. Select the top domains by score: `notification-system` (score 2), `payment-system` (score 1)
  4. Load at most 3 specs: read `openspec/specs/notification-system/spec.md` and `openspec/specs/payment-system/spec.md`
- **AND** the output MUST include: `Spec context loaded from: notification-system/spec.md, payment-system/spec.md`

#### Scenario: Stem matching within domain names (index-first chain)

- **GIVEN** `openspec/specs/index.yaml` exists
- **AND** a domain is named `spec-context-discovery` with keywords `[index, spec, discovery, keywords]`
- **AND** the change name is `2026-03-21-improve-spec-discovery`
- **WHEN** Step 0c applies keyword matching
- **THEN** explicit keywords take precedence:
  - `spec-context-discovery`: matches "spec" and "discovery" (from keywords array) → score += 2
- **AND** if no keywords match, stem matching applies as a secondary heuristic within the index scoring

#### Scenario: Index.yaml is absent — directory-based fallback is applied

- **GIVEN** `openspec/specs/` exists
- **AND** `openspec/specs/index.yaml` does NOT exist
- **AND** subdirectories include: `sdd-archive-execution/`, `spec-context-discovery/`, `sdd-orchestration/`
- **AND** the change name is `2026-03-21-fix-archive-residue-specs-loading`
- **WHEN** Step 0c detects missing index.yaml and applies Tier 2 fallback
- **THEN** it MUST:
  1. List directory names: `["sdd-archive-execution", "spec-context-discovery", "sdd-orchestration"]`
  2. Extract change name stems: `["fix", "archive", "residue", "specs", "loading"]`
  3. Apply stem matching (case-insensitive, substring match):
     - `sdd-archive-execution`: contains "archive" → match
     - `spec-context-discovery`: contains "spec" → match
     - `sdd-orchestration`: no match
  4. Load top 3: read both matching specs
- **AND** emit: `INFO: index.yaml not found — using directory-based stem matching.`
- **AND** still emit: `Spec context loaded from: sdd-archive-execution/spec.md, spec-context-discovery/spec.md`

#### Scenario: No matches in either tier — fallback is silent

- **GIVEN** the change name is `2026-03-21-fix-ui-button-styling`
- **AND** no `index.yaml` keywords match
- **AND** no `openspec/specs/` directories contain stems matching the change
- **WHEN** Step 0c runs discovery
- **THEN** it MUST skip spec context preload silently (non-blocking)
- **AND** no WARNING or ERROR is emitted
- **AND** execution proceeds to the main phase work without error

#### Scenario: Hard cap at 3 domains prevents excessive spec loading

- **GIVEN** a change name that matches 5 different domain keywords in index.yaml
- **WHEN** Step 0c scores and ranks domains
- **THEN** it MUST select only the top 3 by score (or first 3 if scores are tied)
- **AND** the lower-ranked domains MUST NOT be loaded
- **AND** the output MUST NOT list more than 3 specs

---

### Requirement: Spec discovery precedes main phase work (Step 0c placement)

Spec context preload MUST run as a sub-step of Step 0, before any main phase work begins. Loaded specs are treated as enrichment context, not as blocking dependencies.

#### Scenario: Loaded specs are available as enrichment context

- **GIVEN** a skill has loaded 2 matching specs via Step 0c
- **WHEN** the main phase work (e.g., writing exploration.md or spec.md) begins
- **THEN** the loaded specs MUST be available for reference during content writing
- **AND** they inform behavioral contracts and requirement language (enrichment)
- **AND** they do NOT override user intent from the proposal or exploration

#### Scenario: Step 0c runs before Step 1

- **GIVEN** a phase skill is executing
- **WHEN** the skill's execution sequence is examined
- **THEN** Step 0 sub-steps (including Step 0c) MUST complete before Step 1 begins
- **AND** any file reads for spec loading MUST complete before main phase processing

---

### Requirement: Keyword matching uses explicit index.yaml keywords array + stem matching

The keyword matching algorithm MUST implement two parallel scoring strategies:

1. **Explicit keyword matching**: Check if any change name stem appears in a domain's `keywords` array (case-insensitive).
2. **Stem matching**: Split domain name on hyphens; check if any change name stem appears as a substring within any domain name stem (case-insensitive).

Both strategies contribute to a domain's score; the domain with the highest total score ranks first.

#### Scenario: Explicit keywords in index.yaml override stem matching

- **GIVEN** two domains:
  - `payment-flow`: keywords: `["payment", "transaction", "checkout"]`
  - `payment-ledger-system`: (no keywords or empty keywords)
- **AND** the change name is `2026-03-21-fix-payment-transaction-flow`
- **WHEN** keyword matching runs
- **THEN** `payment-flow` receives a higher score because "payment" and "transaction" are explicit keywords
- **AND** `payment-flow` is selected before `payment-ledger-system` (which only matches via stem "payment")

#### Scenario: Stem matching within domain names (fallback within index scoring)

- **GIVEN** a domain name is `memory-management-lifecycle`
- **AND** change name is `2026-03-21-add-memory-cleanup-on-startup`
- **WHEN** keyword matching finds no explicit match
- **THEN** stem matching within the domain name applies:
  - Domain stem: `["memory", "management", "lifecycle"]`
  - Change stem: `["add", "memory", "cleanup", "startup"]`
  - "memory" matches both → this domain scores higher than domains with no overlap

#### Scenario: Keywords array is authoritative; empty keywords means no explicit match

- **GIVEN** a domain in index.yaml has `keywords: []` (empty array)
- **AND** the change name includes words in the domain's name
- **WHEN** keyword matching runs
- **THEN** explicit keyword matching MUST find no match (empty array = no keywords)
- **AND** stem matching within the domain name MAY still apply as a secondary tiebreaker

---

### Requirement: Fallback message indicates which mechanism was used

When specs are loaded, Step 0c MUST emit a log line indicating which mechanism was used. This ensures users and developers understand why certain specs were selected.

#### Scenario: Index-based discovery logs source

- **GIVEN** `openspec/specs/index.yaml` exists and keyword matching succeeded
- **WHEN** specs are loaded
- **THEN** the output MUST include: `Spec context loaded from: [list of domain/spec.md]` (no fallback note)
- **AND** this indicates Tier 1 was used

#### Scenario: Directory fallback logs reason

- **GIVEN** `openspec/specs/index.yaml` is absent
- **AND** directory-based stem matching found matches
- **WHEN** specs are loaded
- **THEN** the output MUST include: `INFO: index.yaml not found — using directory-based stem matching.` (on a separate line before spec loading)
- **AND** THEN: `Spec context loaded from: [list of domain/spec.md]`
- **AND** this indicates Tier 2 was used

#### Scenario: No specs matched — silent skip

- **GIVEN** neither Tier 1 nor Tier 2 found matches
- **WHEN** Step 0c completes
- **THEN** no log output is produced for the spec context step (silent skip)
- **AND** execution continues to Step 1 without error

---

### Requirement: Step 0c is non-blocking — errors do not halt execution

Step 0c (Spec context preload) MUST be non-blocking. File read errors, missing directories, or index parsing errors MUST NOT produce `status: failed` or `status: blocked`.

#### Scenario: index.yaml exists but cannot be parsed

- **GIVEN** `openspec/specs/index.yaml` exists but has malformed YAML (syntax error)
- **WHEN** Step 0c attempts to parse it
- **THEN** it MUST log: `INFO: index.yaml could not be parsed — falling back to directory-based matching.`
- **AND** it MUST proceed to Tier 2 (directory fallback) automatically
- **AND** `status` MUST remain `ok`

#### Scenario: openspec/specs/ directory is absent

- **GIVEN** `openspec/specs/` directory does not exist
- **WHEN** Step 0c attempts to list subdirectories
- **THEN** it MUST log: `INFO: openspec/specs/ not found — skipping spec context preload.`
- **AND** execution MUST continue to Step 1 without error

#### Scenario: Individual spec file cannot be read

- **GIVEN** Step 0c matches a domain `auth-system` and attempts to read `openspec/specs/auth-system/spec.md`
- **AND** the file cannot be read (permissions, missing)
- **WHEN** the read is attempted
- **THEN** it MUST log: `INFO: Could not read openspec/specs/auth-system/spec.md — skipping this spec.`
- **AND** other matched specs MUST still be loaded
- **AND** execution continues without halting

---

### Requirement: Loaded specs are included in artifacts list

When Step 0c loads one or more specs, the skill's output MUST include the loaded spec paths in the `artifacts` list with `[read]` annotation.

#### Scenario: Artifacts list includes loaded specs

- **GIVEN** Step 0c loads `spec-context-discovery/spec.md` and `sdd-archive-execution/spec.md`
- **WHEN** the skill produces its final output
- **THEN** the `artifacts` list MUST include:
  ```
  - openspec/specs/spec-context-discovery/spec.md [read]
  - openspec/specs/sdd-archive-execution/spec.md [read]
  ```
- **AND** `[read]` annotation indicates these files were read (not written)

---

### Requirement: Index.yaml schema expectations

Loaded specs are ONLY useful if `openspec/specs/index.yaml` follows a predictable structure. This spec defines the expected schema for Step 0c to function.

#### Scenario: Index.yaml contains domains with keywords array

- **GIVEN** `openspec/specs/index.yaml` is read
- **WHEN** the algorithm extracts entries
- **THEN** each entry MUST have:
  - `domain`: string (directory name under `openspec/specs/`)
  - `keywords`: array of strings (3–8 terms)
  - `summary`: string (one-line description, optional for matching but recommended)
  - `related`: array of strings (optional, related domain names)
- **AND** entries with missing `keywords` field MUST be treated as having no explicit keywords (empty array fallback)

#### Scenario: Empty keywords array means no explicit matches for that domain

- **GIVEN** a domain entry has `keywords: []` (explicitly empty)
- **WHEN** keyword matching runs
- **THEN** this domain receives no score from explicit keyword matching
- **AND** stem matching within the domain name MAY still apply

---

## Rules

- Index.yaml is the authoritative source for keyword-based discovery if present
- Directory-based stem matching is a reliable fallback when index.yaml is absent
- The hard cap of 3 specs per phase ensures bounded context loading
- Explicit keywords in index.yaml override directory-based stem matching in scoring precedence
- Spec loading is non-blocking: any error automatically falls back to the next tier or skips silently
- All SDD phase skills (7 total) MUST implement the same index-first algorithm in Step 0c for consistency
- Log lines MUST clearly indicate which discovery mechanism was used for transparency
- The algorithm is deterministic: given the same change name and index.yaml, the same specs are selected

---
