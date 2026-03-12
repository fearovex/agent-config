---
title: User Guide for agent-config
status: Draft
author: Claude
date: 2026-03-12
related-change: openspec/changes/2026-03-12-project-user-docs
---

# PRD: User Guide for agent-config

## Problem Statement

New users of agent-config struggle to understand the system without referring to the dense technical CLAUDE.md (400+ lines written for AI agents). There is no user-focused entry point explaining:
- What agent-config does and why they're using it
- How install.sh and sync.sh work
- How global and project-local configuration combine and interact
- How to resolve configuration conflicts

This causes high onboarding friction and repeated questions about basic concepts like the global/local precedence model and deployment workflows.

## Target Users

- Primary: New developers or operators onboarding to agent-config for the first time
- Secondary: Experienced users looking for quick reference on configuration conflicts
- Tertiary: Maintainers explaining the system to stakeholders

## User Stories

### Must Have

- As a new user, I want a high-level explanation of what agent-config is so that I understand why I'm using it
- As a new user, I want to learn how install.sh and sync.sh work so that I know which command to run after making changes
- As a new user, I want to understand how global and project-local configuration combine so that I can override a skill in one project without affecting others
- As a new user, I want a step-by-step guide to resolving configuration conflicts so that I can audit and fix my setup when something goes wrong

### Should Have

- As a new user, I want a quick-start checklist so that I can get up and running with minimal friction
- As a new user, I want a human-readable command reference so that I know what commands are available without reading CLAUDE.md
- As a user, I want troubleshooting tips for common mistakes so that I can self-serve instead of asking for help

### Could Have

- As a user, I want interactive examples so that I can see real output from conflict resolution workflows
- As a user, I want FAQ section covering edge cases so that I can avoid common pitfalls

### Won't Have

- As a user, I want a complete API reference for CLAUDE.md syntax — OUT OF SCOPE: link to CLAUDE.md itself for full syntax
- As a user, I want deep technical details about orchestrator internals — OUT OF SCOPE: link to ORCHESTRATION.md for that

## Non-Functional Requirements

- The guide must be readable in one sitting (250-400 lines)
- The guide must use plain English, not jargon, where possible
- All cross-links to existing documentation (ORCHESTRATION.md, SKILL-RESOLUTION.md, etc.) must be valid
- The guide must not require updates to CLAUDE.md, skills, or other system files (documentation only)
- The guide must include realistic examples that can be verified against actual system behavior

## Acceptance Criteria

- [ ] `docs/user-guide.md` exists with all required sections: What is agent-config? / Deployment / Global config / Project customization / Conflict resolution / Quick-start
- [ ] Global/local interaction is explained with a worked example showing precedence and conflict resolution
- [ ] Conflict resolution workflow includes a step-by-step guide with realistic output snippets
- [ ] Command reference covers at least 15 key commands in human-readable format
- [ ] Quick-start checklist covers new machine setup, first SDD cycle, and deploying a config change
- [ ] Document is 250-400 lines and readable in one sitting
- [ ] README.md is updated with a link to `docs/user-guide.md` in an appropriate section
- [ ] No broken links to existing docs (SKILL-RESOLUTION.md, ORCHESTRATION.md, format-types.md, etc.)
- [ ] User review confirms the guide is understandable to someone with no prior exposure to agent-config

## Notes

- This is an optional PRD for a documentation-only change. No code or system changes required.
- The proposal recommends "Approach A: Single comprehensive user-guide.md" — this PRD elaborates on that approach with user stories and acceptance criteria.
- The guide is intended to complement (not replace) CLAUDE.md. CLAUDE.md remains the authoritative technical reference for the orchestrator and SDD system.
- Future work could split this into modular docs (SETUP.md, CONFIGURATION.md, etc.) if the guide grows beyond 400 lines.
