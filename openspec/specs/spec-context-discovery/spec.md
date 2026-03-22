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

- **GIVEN** `openspec/specs/index.yaml` exists with domain entries
- **AND** the change name is `2026-03-21-add-email-refund-notifications`
- **WHEN** Step 0c runs the discovery algorithm
- **THEN** the skill MUST tokenize the change name, score domains via explicit keyword matching, and load the top 3 matching specs
- **AND** the output MUST include: `Spec context loaded from: [list of domain/spec.md]`

#### Scenario: Index.yaml is absent — directory-based fallback is applied

- **GIVEN** `openspec/specs/` exists but `openspec/specs/index.yaml` does NOT exist
- **WHEN** Step 0c detects missing index.yaml and applies Tier 2 fallback
- **THEN** it MUST list directory names, extract change name stems, and apply stem matching
- **AND** emit: `INFO: index.yaml not found — using directory-based stem matching.`

#### Scenario: No matches in either tier — fallback is silent

- **GIVEN** the change name matches no keywords or directory stems
- **WHEN** Step 0c runs discovery
- **THEN** it MUST skip spec context preload silently (non-blocking)
- **AND** no WARNING or ERROR is emitted

#### Scenario: Hard cap at 3 domains prevents excessive spec loading

- **GIVEN** a change name that matches 5 different domain keywords in index.yaml
- **WHEN** Step 0c scores and ranks domains
- **THEN** it MUST select only the top 3 by score (or first 3 if scores are tied)

---

### Requirement: Spec discovery precedes main phase work (Step 0c placement)

Spec context preload MUST run as a sub-step of Step 0, before any main phase work begins. Loaded specs are treated as enrichment context, not as blocking dependencies.

---

### Requirement: Keyword matching uses explicit index.yaml keywords array + stem matching

The keyword matching algorithm MUST implement two parallel scoring strategies:

1. **Explicit keyword matching**: Check if any change name stem appears in a domain's `keywords` array (case-insensitive).
2. **Stem matching**: Split domain name on hyphens; check if any change name stem appears as a substring within any domain name stem (case-insensitive).

Both strategies contribute to a domain's score; the domain with the highest total score ranks first.

---

### Requirement: Fallback message indicates which mechanism was used

When specs are loaded, Step 0c MUST emit a log line indicating which mechanism was used.

- Tier 1 (index): `Spec context loaded from: [list of domain/spec.md]`
- Tier 2 (directory fallback): `INFO: index.yaml not found — using directory-based stem matching.` followed by `Spec context loaded from: [list]`
- Tier 3 (no match): silent skip

---

### Requirement: Step 0c is non-blocking — errors do not halt execution

Step 0c MUST be non-blocking. File read errors, missing directories, or index parsing errors MUST NOT produce `status: failed` or `status: blocked`.

- index.yaml parse failure → fallback to Tier 2 with INFO log
- `openspec/specs/` absent → INFO log + skip
- Individual spec file unreadable → INFO log + skip that spec only

---

### Requirement: Loaded specs are included in artifacts list

When Step 0c loads one or more specs, the skill's output MUST include the loaded spec paths in the `artifacts` list with `[read]` annotation.

---

### Requirement: Index.yaml schema expectations

Each entry in `openspec/specs/index.yaml` MUST have:
- `domain`: string (directory name under `openspec/specs/`)
- `keywords`: array of strings (3–8 terms)
- `summary`: string (recommended but optional for matching)
- `related`: array of strings (optional)

Entries with missing `keywords` field MUST be treated as having no explicit keywords (empty array fallback).

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
