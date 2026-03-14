# Closure: add-clarification-gate-for-ambiguous-inputs

Start date: 2026-03-14
Close date: 2026-03-14

## Summary

Added a clarification gate to the orchestrator's intent classification flow. When a user sends an ambiguous input (single word, standalone verb, vague phrase, or weak-binding compound phrase), the orchestrator now presents a structured 3-option prompt before routing — instead of silently defaulting to Question.

## Modified Specs

| Domain | Action | Change |
| ------ | ------ | ------ |
| orchestrator-behavior | Modified | "Ambiguous single-word messages MUST default to Question" → now triggers clarification gate |
| orchestrator-behavior | Added | Requirement: Ambiguous input detection and clarification gate |
| orchestrator-behavior | Added | Requirement: Clarification prompt structure |
| orchestrator-behavior | Added | Requirement: Routing after clarification response |
| orchestrator-behavior | Added | Requirement: Ambiguity detection heuristics (H1–H4) |
| orchestrator-behavior | Added | Requirement: Clarification gate does not interfere with slash commands or strong signals |

## Modified Code Files

- `CLAUDE.md` (repo root) — Added `## Ambiguity Detection Heuristics` section with H1–H4 definitions; added clarification gate branch in Classification Decision Table; added prompt template and routing table
- `~/.claude/CLAUDE.md` (runtime) — Same changes deployed via install.sh
- `ai-context/conventions.md` — Added subsection documenting the clarification gate pattern
- `ai-context/architecture.md` — Added key decision #21 documenting the gate design
- `ai-context/changelog-ai.md` — Entry dated 2026-03-14 recording all changes

## Key Decisions Made

- Gate is inline logic in CLAUDE.md — no new skill created (inline decision, not a delegatable phase)
- No session persistence / no caching of clarification results (simplicity over optimization)
- 4 heuristics (H1: single-word, H2: standalone verb, H3: vague noun phrase, H4: compound weak binding) with reserved exclusion list for natural response words
- Gate placed after slash command and strong-signal branches — only fires when all other classification fails
- Prompt structure: summary line + 3 numbered options + free text fallback

## Lessons Learned

- The verify phase surfaced an unresolved warning about manual session testing — the spec's own validation criteria require "2+ independent sessions" which cannot be confirmed by code inspection alone. Future specs should distinguish between "verifiable by code review" and "verifiable only at runtime."
- The "help" word edge case (whether to include in reserved exclusion list) was flagged as a suggestion but not acted on — it is documented in the verify-report for future consideration.

## User Docs Reviewed

N/A — this change modifies orchestrator classification behavior (CLAUDE.md), not user-facing skill workflows. The scenarios.md, quick-reference.md, and onboarding.md files (if they exist) do not need updates for this internal orchestrator logic change.
