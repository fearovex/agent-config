# AI Changelog — claude-config

> Log of significant changes made with AI assistance. Newest first.

---

## 2026-02-23 — Bootstrap SDD infrastructure on claude-config

**Type:** Configuration / Meta
**Agent:** Claude Sonnet 4.6
**SDD cycle:** Applied retroactively (changes were made without prior SDD cycle — documented here as first archive entry)

**What changed:**
- `openspec/config.yaml` — Created: SDD configuration for this repo with English-only rules
- `ai-context/stack.md` — Created: project identity, file types, skill catalog inventory
- `ai-context/architecture.md` — Created: two-layer architecture, skill structure, artifact communication map
- `ai-context/conventions.md` — Created: naming, SKILL.md structure, git workflow, sync rules
- `ai-context/known-issues.md` — Created: rsync on Windows, install.sh directionality, GITHUB_TOKEN dependency
- `ai-context/changelog-ai.md` — Created: this file

**Decisions made:**
- `ai-context/` placed at repo root (not `docs/ai-context/`) since this is not a code project
- `openspec/config.yaml` uses English-only rules — this repo enforces the English standard
- Known issues documented immediately to capture technical debt visible at bootstrap time

---

## 2026-02-23 — Overhaul project-audit, create project-fix

**Type:** Feature
**Agent:** Claude Sonnet 4.6
**Commit:** `680ce20`
**SDD cycle:** NOT applied (retroactive — this was the change that motivated applying SDD to this repo)

**What changed:**
- `skills/project-audit/SKILL.md` — Full rewrite: 4 dimensions → 7 dimensions, added FIX_MANIFEST output, structured audit-report.md artifact
- `skills/project-fix/SKILL.md` — New skill: reads audit-report.md as spec, implements corrections phase by phase
- `CLAUDE.md` — Registered `/project:fix` in meta-tools table and skill routing table

**Why this change was made:**
Audit of the Audiio V3 project revealed that project-audit only checked file existence, not content quality or SDD readiness. The new audit generates a machine-readable report consumed by project-fix, implementing the audit→fix flow as a self-contained SDD meta-cycle.

**Technical debt created:**
- project-audit does not handle projects without package.json (affects claude-config itself)
- Both skills were written without prior SDD artifacts — violates the standard this repo enforces

---

## 2026-02-23 — Initial commit: SDD architecture setup

**Type:** Initial Setup
**Commit:** `4c62733`
**Agent:** Claude Sonnet 4.6 (prior session)

**What changed:**
- Initial CLAUDE.md with SDD orchestrator pattern
- Full SDD phase skill catalog (8 phases)
- Meta-tool skills: project-setup, project-audit, project-update
- Technology skill catalog (~25 skills)
- install.sh + sync.sh scripts
- settings.json with MCP server configuration
