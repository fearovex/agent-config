# Exploration: Project User Documentation

## Current State

The agent-config project has:
- A technical CLAUDE.md (read by Claude at session start) — comprehensive but dense (400+ lines)
- A README.md that references CLAUDE.md but doesn't explain the relationship
- Architecture and convention docs in ai-context/ (for AI agents, not humans)
- ADRs in docs/adr/ (architectural decisions, not user-focused)
- No docs/ directory files explaining:
  - What agent-config IS to a human user
  - How install.sh / sync.sh work and why
  - How global CLAUDE.md + project-local CLAUDE.md combine
  - How conflict resolution works in practice
  - Quick-start guide for new projects

The proposal identified three documentation gaps:
1. No explanation of what the user gains from running `install.sh`
2. No documentation of global vs. local `CLAUDE.md` interaction (combination, precedence, conflict resolution)
3. No overview doc aimed at a human reader

## Affected Areas

| File/Module | Impact | Notes |
|-------------|--------|-------|
| docs/user-guide.md | NEW | Main deliverable. User-facing guide explaining system, deployment, and configuration. |
| docs/CLAUDE-OVERRIDES.md | OPTIONAL | If created: focused reference for override syntax + examples. |
| README.md | MODIFY | Add link to docs/user-guide.md in the overview section. |
| docs/SKILL-RESOLUTION.md | REFERENCE | Already exists; explains skill precedence. User guide should cross-link. |
| docs/ORCHESTRATION.md | REFERENCE | Already exists; explains SDD flow. User guide should cross-link. |
| docs/format-types.md | REFERENCE | Already exists; explains skill structure. User guide should cross-link. |

## Analyzed Approaches

### Approach A: Single Comprehensive user-guide.md

**Description**: Create one user-focused guide covering all 6 sections from the proposal:
1. What this project is
2. How it works (install.sh → ~/.claude/ → all sessions)
3. Global vs. local CLAUDE.md explanation with examples
4. Conflict resolution workflow (audit → fix → update)
5. Available commands (human-readable summary)
6. Quick-start guide

**Pros**:
- Single file = easy to discover and link
- Comprehensive coverage in one place
- Narrative flow easier for learning
- Natural place to include concrete examples

**Cons**:
- May become 300-400 lines (moderately long)
- As features evolve, updates may be scattered within one file
- Navigation for reference lookups less discoverable

**Estimated effort**: Medium (2-3 hours to write + review)
**Risk**: Low — pure documentation, no code impact

### Approach B: Modular approach (setup.md + config.md + advanced.md)

**Description**: Split into three focused documents:
- docs/SETUP.md — install.sh, first-time setup, machine deployment
- docs/CONFIGURATION.md — global vs. local, override examples, precedence rules
- docs/ADVANCED-WORKFLOWS.md — conflict resolution, troubleshooting, command reference

**Pros**:
- Each file stays <250 lines
- Clear mental model: setup ≠ configuration ≠ troubleshooting
- Easier to update individual concerns without affecting others
- Better reference organization

**Cons**:
- Requires consistent cross-linking to avoid user navigation friction
- More files to maintain
- Risk of duplication if boundaries not clear

**Estimated effort**: Medium-High (3-4 hours to write + review)
**Risk**: Medium — requires clear file boundaries; poor cross-linking could confuse users

### Approach C: Interactive tutorial format (QUICKSTART.md + reference)

**Description**: Create docs/QUICKSTART.md with step-by-step walkthrough (new user gets from zero to running one SDD cycle), plus reference docs for advanced use.

**Pros**:
- Immediate value for new users
- Hands-on, concrete examples
- Users see real results quickly

**Cons**:
- Requires maintaining working examples
- Not reference-friendly for lookups
- Global/local explanation harder in tutorial format
- Doesn't fully address the proposal's "explain how they interact" goal

**Estimated effort**: High (3-4 hours to write + maintain examples)
**Risk**: Medium-High — examples can become stale quickly

## Recommendation

**Approach A: Single comprehensive user-guide.md**

Rationale:
1. **Simplicity**: Users new to agent-config need a single, unified narrative entry point. Multiple files risk confusion ("Which doc do I read first?").
2. **Proposal alignment**: The proposal explicitly asks for one user-focused document covering all 6 sections. Approach A delivers that directly.
3. **Global/local explanation**: This core concept is easier to explain as a narrative journey (problem → solution → examples → conflict handling) in one document than across files.
4. **Maintainability**: Starting with a single well-structured guide is easier to refactor into modules later if needed.
5. **Effort**: Medium effort, low risk of misalignment.

The guide should:
- Start with a high-level "what is this?" for context
- Explain the install.sh + ~/.claude/ deployment model
- Use a concrete global/local example (e.g., "you have global sdd-apply, but your project needs a custom version")
- Step through the conflict resolution workflow with a realistic scenario
- Include a reference table of available commands (copy from CLAUDE.md, adapt for humans)
- End with a quick-start checklist

Structure suggestion:
```
# User Guide — agent-config

## What is agent-config?
## How deployment works (install.sh, sync.sh)
## Global configuration (what you get out of the box)
## Project-level customization (when and how to override)
### Example: Overriding a skill in one project
## Conflict resolution workflow
### Step-by-step: audit → fix → update
### Common scenarios
## Available commands at a glance
## Quick-start checklist
## Troubleshooting (optional)
## See also (links to technical docs)
```

## Identified Risks

- **Documentation drift**: If CLAUDE.md or project-audit/fix behavior changes, user-guide.md must be updated. Mitigation: Include `Last updated:` timestamp and cross-links to canonical sources (CLAUDE.md, Skills Registry).
- **Explaining precedence rules**: The global/local precedence (config override → project-local → global) is complex. Mitigation: Include a clear precedence diagram and one worked example.
- **Scope creep**: User guide could expand to cover every skill and every workflow. Mitigation: Keep it focused on setup, configuration, and conflict resolution — link to technical docs for deep dives.

## Open Questions

1. Should the user guide mention project-local CLAUDE.md syntax (intent_classification override)? Or defer to CLAUDE.md itself for that?
   - **Recommendation**: Include a brief example, with a "See CLAUDE.md for full syntax" note. Users may want to disable intent classification in their project.

2. Should the guide explain how to read ai-context/ files, or is that only for SDD phases?
   - **Recommendation**: Mention ai-context/ exists but defer details to `/memory-init` skill. This guide is for config and setup, not project memory.

3. How detailed should the conflict resolution workflow be? Should it walk through actual audit-report.md output?
   - **Recommendation**: Include one simplified example (2-3 findings) to keep it readable. Link to `/project-audit` skill for full details.

## Ready for Proposal

**Yes.** The exploration is complete.

Approach A (single user-guide.md) aligns with the proposal, has manageable effort and low risk, and provides a clear deliverable. The proposal's success criteria are all achievable:
- [x] docs/user-guide.md with all 6 sections — achievable
- [x] Global/local interaction with example — achievable via "Overriding a skill in one project" section
- [x] Conflict resolution step-by-step — achievable via "Conflict resolution workflow" section
- [x] Written for humans, not AI — achievable by focusing on user mental models, not agent execution details
- [x] Linked from README.md — achievable as final step

**Recommendation**: Proceed to `sdd-propose` with a full proposal incorporating the Approach A structure, then `sdd-spec` to define content boundaries and section requirements.
