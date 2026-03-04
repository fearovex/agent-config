# Closure: config-export

Start date: 2026-03-03
Close date: 2026-03-03

## Summary

Created the `config-export` skill — a procedural meta-tool that reads a project's CLAUDE.md and ai-context/ files and uses LLM in-context transformation to generate tool-specific instruction files for GitHub Copilot, Google Gemini, and Cursor.

## Modified Specs

| Domain | Action | Change |
|--------|--------|--------|
| config-export-skill | Created | New master spec — invocation contract, source collection, target selection, dry-run, file writing, idempotency, summary |
| config-export-targets | Created | New master spec — content requirements and strip/retain rules for Copilot, Gemini, and Cursor export targets |

## Modified Code Files

- `skills/config-export/SKILL.md` — new skill (Steps 1–5: collection, target selection, dry-run, writing, summary; embedded transformation prompts for all 3 targets)
- `CLAUDE.md` — skills registry entry added under "Tools / Platforms"

## Key Decisions Made

- Implementation pattern: procedural SKILL.md only — no helper scripts, consistent with all existing meta-tools
- Transformation engine: Claude in-context via embedded prompts — no external API calls; prompts are reviewable and tunable
- Target file locations: canonical tool-expected paths (`.github/copilot-instructions.md`, `GEMINI.md`, `.cursor/rules/*.mdc`)
- Dry-run default: preview before write; no flag to skip
- Cursor MDC: 3 domain files (conventions, stack, architecture) — domain-split for selective Cursor rule application
- Claude target (CLAUDE.md re-export) deferred to avoid conflict with project-update; V1 exports only 3 external tools
- `globs: ""` enforced as default — skill must never guess at glob patterns

## Lessons Learned

- The design.md data flow diagram included an aspirational `/edit` option at the dry-run confirmation step; the spec only required `[y/N]`. No compliance gap, but design should be kept aligned with spec-level requirements to avoid confusion during verification.
- Integration testing against a real project was not performed in this verification run (per design.md Testing Strategy recommendation). Manual invocation against a live project (e.g., Audiio V3) is the recommended next step to confirm end-to-end output quality.

## User Docs Reviewed

N/A — change pre-dates this requirement.
