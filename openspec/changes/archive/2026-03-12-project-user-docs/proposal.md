# Proposal: project-user-docs

Date: 2026-03-12
Status: Draft

## Intent

Create a comprehensive user-facing guide explaining the agent-config system, its deployment model, and how to configure both globally and at the project level.

## Motivation

The project currently lacks user-focused documentation. The technical CLAUDE.md is comprehensive but dense (400+ lines) and written for AI agents, not humans. New users need a clear entry point that explains:
1. What agent-config is and why they're using it
2. How install.sh and sync.sh work
3. How global configuration combines with project-local overrides
4. The conflict resolution workflow (audit → fix → update)
5. Quick reference of available commands
6. A hands-on quick-start checklist

Without this guide, onboarding friction is high, and users struggle to understand the global/local precedence model and how to debug configuration conflicts.

## Scope

### Included

- `docs/user-guide.md` — comprehensive guide (~300-400 lines) covering:
  - "What is agent-config?" — high-level description for humans
  - Deployment model (install.sh, ~/.claude/, sync.sh, and how all projects read from it)
  - Global configuration out-of-the-box (CLAUDE.md, skill catalog, memory layer)
  - Project-level customization (when and how to override, with worked example)
  - Global/local precedence diagram and interaction rules
  - Conflict resolution workflow with step-by-step guide and realistic scenario
  - Available commands at a glance (human-readable table, not copy of CLAUDE.md)
  - Quick-start checklist for new projects
  - Troubleshooting section (optional but recommended)
  - "See also" links to technical docs (SKILL-RESOLUTION.md, ORCHESTRATION.md, format-types.md)
- README.md update — add a link to `docs/user-guide.md` in the overview section
- No additional documentation files beyond user-guide.md (CLAUDE-OVERRIDES.md is optional and deferred)

### Excluded (explicitly out of scope)

- Deep technical implementation details (SDD phase internals, orchestrator algorithms) — link to ORCHESTRATION.md for those
- Skill authoring guide — link to `skills/README.md`
- How to read or update ai-context/ files — mention ai-context/ exists but defer to `/memory-init` skill
- Complete API reference for CLAUDE.md syntax (intent_classification override, hooks, etc.) — brief example with reference to CLAUDE.md itself
- Rewriting or reorganizing CLAUDE.md itself
- Creating separate modular documentation files (SETUP.md, CONFIGURATION.md, etc.) — single guide for simplicity and discovery

## Proposed Approach

**Single comprehensive user-guide.md** (Approach A from exploration):

1. Create one user-focused document with clear narrative flow
2. Start with a "What is this?" section that builds context for non-technical readers
3. Use one worked example throughout (global skill override scenario) to illustrate global/local interaction, precedence, and conflict resolution
4. Include precedence diagram showing skill resolution order
5. Step-by-step conflict resolution workflow with realistic scenario output
6. Human-readable command table (adapt from CLAUDE.md, simplify for users)
7. Quick-start checklist: new machine setup, first SDD cycle, deploying a config change
8. Troubleshooting with common gotchas (sync.sh does NOT deploy skills, direct ~/.claude/ edits are lost, etc.)
9. Cross-links to technical docs (SKILL-RESOLUTION.md, ORCHESTRATION.md, format-types.md, skills/README.md)

The guide is narrative-driven (not reference-driven) to ease learning, while still providing actionable steps and clear mental models.

## Affected Areas

| Area/Module | Type of Change | Impact |
|-------------|--------|--------|
| docs/user-guide.md | New file | High — primary deliverable |
| README.md | Modified | Low — add one link to user-guide.md |
| docs/ | Directory structure | Low — adds one new .md file to existing docs/ |

## Risks

| Risk | Probability | Impact | Mitigation |
|-----|-----------|--------|-----------|
| Documentation drift as system evolves | Medium | Medium | Include `Last updated:` date, add cross-links to canonical sources (CLAUDE.md, skills/), recommend quarterly review |
| Explaining precedence rules is confusing | Low | Medium | Use a clear precedence diagram + one worked example with realistic output |
| Guide becomes too long (scope creep) | Medium | Low | Strict scope: setup, configuration, conflict resolution only. Link to technical docs for deep dives. Stop at 400 lines. |
| Example becomes stale if skill names or commands change | Low | Medium | Use generic placeholder names in examples ("global-skill-name") or link to current command list |
| Users skip the guide and ask the same questions | Low | Low | Make it discoverable from README.md; not a blocker for acceptance |

## Rollback Plan

If the guide is found to be inaccurate or unhelpful:

1. Delete `docs/user-guide.md`
2. Remove the link from `README.md` (revert the one-line addition)
3. Commit with message: `docs: remove user-guide (revert to technical docs only)`

No other files are affected — rollback is trivial.

## Dependencies

- No code changes required
- No external dependencies
- README.md exists and is readable (it does)

## Success Criteria

- [ ] `docs/user-guide.md` created with all 6 required sections (What is agent-config? / Deployment / Global config / Project customization / Conflict resolution / Quick-start)
- [ ] Global/local interaction explained with worked example showing precedence and conflict resolution
- [ ] Conflict resolution workflow includes step-by-step guide with realistic output (audit-report.md snippet, fix-report.md snippet)
- [ ] Command reference table is human-readable and covers at least 15 key commands (not verbose copy of CLAUDE.md)
- [ ] Quick-start checklist includes: new machine setup, first SDD cycle, deploying a config change
- [ ] Document is 250-400 lines (substantial but readable in one sitting)
- [ ] README.md updated with link to user-guide.md
- [ ] No broken links to existing docs (SKILL-RESOLUTION.md, ORCHESTRATION.md, etc.)
- [ ] User review confirms the guide is understandable to someone new to the system

## Effort Estimate

Medium (2-3 hours to write + review + finalize links)

Breakdown:
- Structure + outline: 30 min
- "What is agent-config?" + "Deployment" sections: 45 min
- "Global config" + "Project customization" sections with example: 60 min
- "Conflict resolution" workflow: 45 min
- "Quick-start" + "Troubleshooting": 30 min
- Cross-links + README.md update + final review: 30 min
