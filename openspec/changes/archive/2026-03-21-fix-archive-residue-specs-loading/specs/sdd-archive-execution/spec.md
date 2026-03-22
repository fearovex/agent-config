# Delta Spec: sdd-archive-execution

Change: 2026-03-21-fix-archive-residue-specs-loading
Date: 2026-03-21
Base: openspec/specs/sdd-archive-execution/spec.md

---

## ADDED — Source Directory Deletion Verification (Step 4 Enhancement)

### Requirement: Step 4 MUST verify source directory deletion and report status

When `sdd-archive` Step 4 deletes the source directory after a successful copy to the archive destination, it MUST verify that the deletion was successful. If verification fails, the step MUST report a detailed WARNING (not `status: failed`) with manual recovery instructions.

The verification contract applies to Step 4 regardless of platform (Unix-like systems, Windows + Git Bash).

#### Scenario: Happy path — deletion is verified successful

- **GIVEN** all files from `openspec/changes/<change-name>/` have been written to `openspec/changes/archive/<date>-<change-name>/`
- **AND** the copy is confirmed complete
- **WHEN** Step 4 executes the deletion instruction on `openspec/changes/<change-name>/`
- **THEN** the deletion MUST occur
- **AND** Step 4 MUST verify that the source directory no longer exists
- **AND** the output MUST include a confirmation line: `✓ Source directory deleted and verified: openspec/changes/<change-name>/`
- **AND** this confirmation MUST appear before Step 5 begins
- **AND** execution proceeds to Step 5 without any user interaction

#### Scenario: Deletion verification fails — WARNING is reported with recovery path

- **GIVEN** the copy to the archive destination is confirmed complete
- **AND** the deletion of `openspec/changes/<change-name>/` is attempted
- **AND** the directory still exists after the deletion attempt (e.g., a file is locked by another process, or permissions prevent removal)
- **WHEN** Step 4 executes the verification check
- **THEN** the verification MUST detect that the directory still exists
- **AND** the output MUST include a WARNING block with:
  - The exact source path that could not be deleted
  - The literal manual command to delete it: `rm -rf openspec/changes/<change-name>/` (Unix) or equivalent for Windows
  - A note that manual cleanup is required before the archive can be fully confirmed
- **AND** `status` MUST be `warning`, NEVER `failed`
- **AND** execution MUST proceed to Step 5 (non-blocking)
- **AND** the user is NOT prompted for confirmation at this step

#### Scenario: Verification is tolerant of platform-specific behavior

- **GIVEN** Step 4 is executing on a Windows system with Git Bash
- **AND** a file in the source directory is locked (common on Windows)
- **AND** the deletion attempt fails due to the lock
- **WHEN** the verification check runs
- **THEN** the check MUST reliably detect that the directory still exists
- **AND** the same WARNING with recovery instructions MUST be reported
- **AND** no platform-specific errors (e.g., "bash: rm: command not found") are exposed to the user

#### Scenario: Verification uses directory existence check, not exit code alone

- **GIVEN** Step 4 has executed a deletion command
- **WHEN** the verification runs
- **THEN** it MUST check that the directory and all its contents have been removed
- **AND** it MUST NOT rely solely on whether the deletion command returned exit code 0
- **AND** if the directory check shows the directory still exists, a WARNING MUST be emitted regardless of exit code

#### Scenario: No ghost duplicate after successful archive with verification

- **GIVEN** an SDD change is successfully archived via `sdd-archive` and Step 4 completes
- **WHEN** Step 4's deletion verification succeeds
- **THEN** the filesystem contains:
  - `openspec/changes/archive/<date>-<change-name>/` with all previously present files
  - NO `openspec/changes/<change-name>/` directory
  - NO `openspec/changes/<change-name>/` directory with partial contents
- **AND** the archive result shows `status: ok` (not `status: warning`)

---

## Rules

- Deletion verification is mandatory; Step 4 MUST ALWAYS verify after deletion
- Verification is non-blocking: failure to delete does NOT prevent archive from completing
- WARNING-level reporting (not FAILED) ensures users have visibility into residual cleanup without blocking the archive cycle
- The verification MUST check the actual filesystem state (directory existence), not assume the deletion command succeeded
- Manual recovery instructions MUST be explicit and copy-paste-ready
- Platform compatibility (Windows + Git Bash, Unix-like systems) is required
- Confirmation lines in Step 4 output MUST clearly indicate verification success (✓ prefix recommended)

---
