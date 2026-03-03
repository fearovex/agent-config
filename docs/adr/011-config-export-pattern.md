# ADR-011: Config Export Pattern

## Status

Proposed

## Context

Users invest significant effort curating `CLAUDE.md` instructions, `ai-context/` memory files, and skills registries that capture full project context. This configuration is currently locked to Claude Code. When a team member uses a different AI coding assistant (GitHub Copilot, Google Gemini, Cursor), they start from zero — no project conventions, no architectural context, no stack awareness. A mechanism is needed to allow the configured context to travel with the project across AI tools.

The existing meta-tool pattern (procedural `SKILL.md` files, no external dependencies, no helper scripts) has proven sufficient for complex operations such as `project-analyze`, `memory-init`, and `project-fix`. A new export skill can follow this same established pattern without introducing new architectural concepts.

## Decision

We will implement `config-export` as a procedural `SKILL.md` skill that uses Claude in-context LLM transformation to export the project's `CLAUDE.md` and `ai-context/` files to tool-native instruction formats. The skill follows the same single-file procedural pattern used by all existing meta-tool skills: no helper scripts, no external API calls, no new runtime dependencies. Transformation prompts are embedded directly in the `SKILL.md` so they are transparent, reviewable, and tunable by the user. Exported files are one-way snapshots; no sync or watch mechanism is introduced.

## Consequences

**Positive:**

- Consistent with all existing meta-tool skills — no new patterns to learn for contributors
- No new runtime dependencies — runs in any Claude Code session without setup
- Transformation prompts are version-controlled alongside the skill and can be improved incrementally
- Dry-run default prevents silent overwrites and allows quality review before committing output
- Purely additive — does not modify any existing files in the user's project

**Negative:**

- Output quality depends on Claude's in-context transformation capability — LLM output is non-deterministic and may require manual review or iteration
- Transformation prompts must be carefully curated for each target tool's format; poor prompts produce low-quality exports
- No automatic re-export on CLAUDE.md changes — exported files will drift over time and must be manually re-run after significant config changes
