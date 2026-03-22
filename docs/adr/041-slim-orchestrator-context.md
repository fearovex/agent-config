# ADR-041: Slim Orchestrator Context — Inline Classification, On-Demand Presentation, Budget Governance

## Status

Accepted

## Context

The global CLAUDE.md has grown through successive additive changes (intent classification, ambiguity heuristics, scope estimation, teaching principles, communication persona, redundant SDD flow summaries) to 47.5k characters in the project copy and 43.9k characters in the global runtime copy. Both files are loaded simultaneously by Claude Code at session start, consuming ~91.4k characters of context window before any user interaction. The project CLAUDE.md is 95% identical to the global version, doubling context waste. ADR-029 established that intent classification is inline in CLAUDE.md with "no new skill" — but this was decided when the classification section was ~3k characters, not ~17.7k. Meanwhile, presentation-layer content (communication persona, teaching principles, session banner) and SDD flow documentation that is already fully contained in skill files (Fast-Forward, Apply Strategy, Phase DAG, delegation pattern) account for ~13.5k additional characters that do not need to be always-loaded.

Three forces create the need for this decision: (1) context window scarcity — every character of CLAUDE.md competes with codebase analysis, skill content, and conversation history; (2) duplication waste — the project/global identity doubles the cost; (3) growth trajectory — without governance, every orchestrator improvement will continue expanding the file.

## Decision

We will refine the inline-vs-skill boundary established by ADR-029 as follows:

1. **Classification logic stays inline in CLAUDE.md** for timing safety. The Classification Decision Table (~5.5k chars), Scope Estimation Heuristic (~2.5k chars), and Ambiguity Detection Heuristics (~1.8k chars) MUST remain in CLAUDE.md because they must execute before any response can be generated. This preserves ADR-029's core intent.

2. **Presentation-layer content moves to an on-demand skill.** Session Banner, Communication Persona, Teaching Principles, and New-User Detection move to `skills/orchestrator-persona/SKILL.md`, loaded by the orchestrator on first free-form response per session. These sections are needed when generating the response text, not during classification.

3. **Redundant SDD flow documentation is removed.** The `## Fast-Forward`, `## Apply Strategy`, `## SDD Flow — Phase DAG`, and `## How I Execute Commands` sections are deleted from CLAUDE.md because they are fully documented in `sdd-ff/SKILL.md` and `sdd-new/SKILL.md`, which are the authoritative sources.

4. **Budget governance is established** with three thresholds:
   - Global CLAUDE.md: 20,000 characters maximum
   - Project CLAUDE.md (override-only): 5,000 characters maximum
   - Newly created orchestrator skills: 8,000 characters maximum
   - Enforcement: `project-audit` reports INFO-severity findings when thresholds are exceeded
   - Existing skills exceeding the 8k threshold are grandfathered

5. **Project CLAUDE.md becomes override-only** for all projects except agent-config (where the file IS the global config). Override-only format contains: project identity header, Tech Stack, project-specific Unbreakable Rules additions, Project Memory pointers, and project-local Skills Registry entries.

This decision supersedes the "no new skill" aspect of ADR-029 while preserving its core safety principle: classification is inline for timing guarantees.

## Consequences

**Positive:**

- Always-loaded context drops from ~91.4k to ~21-25k characters (~73% reduction)
- Classification timing is preserved — the most critical orchestrator function is unaffected
- Budget governance prevents future context bloat through audit enforcement
- Presentation logic is cleanly separated from routing logic, improving maintainability
- The `install.sh` deploy process remains unchanged (plain copy, no build step)

**Negative:**

- The persona skill must be loaded on first free-form response, adding one file read per session
- Developers modifying orchestrator behavior must now consider which file to edit (CLAUDE.md for classification, persona skill for presentation)
- The 8k budget for new orchestrator skills constrains future skill creation — complex presentation needs may require splitting
- 15 existing skills exceed the 8k threshold and are grandfathered, creating an inconsistency
