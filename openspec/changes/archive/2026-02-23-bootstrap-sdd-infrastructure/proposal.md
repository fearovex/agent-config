# Proposal: Bootstrap SDD Infrastructure on claude-config

**Date:** 2026-02-23
**Status:** ARCHIVED (retroactive)
**Change:** bootstrap-sdd-infrastructure

## Problem

The `claude-config` repository — the source of truth for the global Claude Code configuration — had no SDD infrastructure applied to itself:
- No `openspec/` directory or `config.yaml`
- No `ai-context/` memory layer
- No documented conventions, known issues, or architecture decisions
- Every change to skills was made ad-hoc without SDD artifacts

This is a fundamental contradiction: a system designed to enforce SDD on every project was not applying SDD to itself.

## Proposed Solution

Apply the full SDD bootstrap to `claude-config`:
1. Create `openspec/config.yaml` with English-only rules
2. Create all 5 `ai-context/` memory files with real content
3. Establish the convention that all future skill changes require at minimum `/sdd:ff`
4. Archive the changes already made this session (project-audit rewrite, project-fix creation) as a retroactive SDD entry

## Success Criteria

- `openspec/config.yaml` exists and is valid
- All 5 `ai-context/` files exist with substantive content
- `changelog-ai.md` documents the history of changes to this repo
- `/project:audit` run on `claude-config` returns SDD Ready: FULL
