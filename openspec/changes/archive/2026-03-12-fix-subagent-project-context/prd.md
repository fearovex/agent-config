---
title: Sub-Agent Project Context Injection
status: Draft
author: Claude Code
date: 2026-03-12
related-change: openspec/changes/2026-03-12-fix-subagent-project-context/
---

# PRD: Sub-Agent Project Context Injection

## Problem Statement

Sub-agents in the SDD orchestrator do not receive project-level governance context (CLAUDE.md) in their initial prompt, causing them to discover governance rules late during task execution. This creates an asymmetry where Copilot (which receives full governance upfront) respects project constraints, but SDD sub-agents make architectural and organizational decisions without visibility into those constraints.

## Target Users

- **Primary**: Developers using Claude Code SDD orchestrator to run automated SDD cycles
- **Secondary**: Operators maintaining the agent-config repository and ensuring project governance compliance

## User Stories

### Must Have

- As a developer, I want sub-agents to respect my project's governance rules (naming, architecture, organizational patterns) so that artifacts generated during SDD cycles follow project conventions without requiring rework.
- As an operator, I want sub-agents to log the governance rules they've loaded so that I can verify governance visibility in sub-agent execution output.

### Should Have

- As a developer, I want the orchestrator to be transparent about what governance it passes to sub-agents so that I understand what constraints are available for decision-making.
- As a developer, I want governance discovery to happen early (at sub-agent startup) rather than late so that initial decisions reflect project constraints.

### Could Have

- As a developer, I want to see a summary of loaded governance rules in sub-agent output so that I can spot governance misalignment issues quickly.

### Won't Have

- As a developer, I want CLAUDE.md to be passed inline in the prompt — OUT OF SCOPE: files should be read by sub-agents, not embedded in prompts (reduces token waste, avoids prompt pollution).
- As a developer, I want governance passed asynchronously to sub-agents — OUT OF SCOPE: synchronous loading ensures governance is available before any decision-making happens.

## Non-Functional Requirements

- No change to sub-agent context isolation semantics (sub-agents remain independent execution contexts)
- No change to artifact communication patterns (file-based, not prompt-based)
- All changes must be non-breaking (absent CLAUDE.md does not cause sub-agent failure)
- Fully reversible (git revert should restore system to functioning state)
- No new dependencies introduced
- All changes confined to SDD orchestration layer (skills/, docs/, openspec/); no changes to project-level code

## Acceptance Criteria

- [ ] All six SDD phase skills (sdd-explore, sdd-propose, sdd-spec, sdd-design, sdd-tasks, sdd-apply, sdd-verify) have expanded Step 0a that reads full CLAUDE.md
- [ ] Orchestrator prompts in sdd-ff and sdd-new include explicit "Project governance: [path]" CONTEXT field
- [ ] Sub-agent Step 0 output includes a summary of loaded governance (unbreakable rules, tech stack, intent classification status)
- [ ] Project audit score after apply is >= previous score (no regression)
- [ ] Verify-report.md includes evidence of governance visibility in sub-agent output (sub-agent logs showing loaded rules)
- [ ] Documentation updated (agent-execution-contract.md, sdd-context-injection.md)

## Notes

This is a **technical/infrastructure change** serving the SDD orchestrator system. It is not a user-facing feature, and no PRD marketing content is required. The primary users are operators and developers using Claude Code SDD cycles.

See `openspec/changes/2026-03-12-fix-subagent-project-context/proposal.md` for full technical details.
