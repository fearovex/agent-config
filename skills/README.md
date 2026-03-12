# Skills — Discovery Guide

> How skills are structured, discovered, and invoked in this system.

---

## What is a Skill?

A **skill** is a directory containing exactly one `SKILL.md` file. The SKILL.md is a Markdown file with YAML frontmatter that defines the skill's behavior, triggers, and process steps.

```
skills/
└── sdd-ff/
    └── SKILL.md   ← the only required file
```

When Claude Code receives a command like `/sdd-ff`, it reads `SKILL.md` and follows its instructions.

---

## SKILL.md Format

Every SKILL.md MUST have YAML frontmatter followed by Markdown content:

```yaml
---
name: skill-name
description: >
  One-line description. Trigger: /command <args>, alias, natural language phrase.
format: procedural   # procedural | reference | anti-pattern
model: haiku         # haiku | sonnet | opus
---
```

### Format types

| Format | Required sections | Use when |
|--------|-------------------|----------|
| `procedural` | `**Triggers**`, `## Process`, `## Rules` | Step-by-step workflows |
| `reference` | `**Triggers**`, `## Patterns` or `## Examples`, `## Rules` | Pattern catalogs, lookup guides |
| `anti-pattern` | `**Triggers**`, `## Anti-patterns`, `## Rules` | What NOT to do |

Absent `format:` defaults to `procedural`.

---

## Skill Resolution

When a skill is referenced (e.g., `~/.claude/skills/sdd-explore/SKILL.md`), the system resolves it using this priority order:

```
1. .claude/skills/<name>/SKILL.md         (project-local — highest priority)
2. openspec/config.yaml skill_overrides   (explicit redirect)
3. ~/.claude/skills/<name>/SKILL.md       (global catalog — fallback)
```

See `docs/SKILL-RESOLUTION.md` for the full algorithm and config override format.

---

## Sub-Agent Invocation

Orchestrator skills launch phase sub-agents via the Task tool using this pattern:

```
Task tool:
  subagent_type: "general-purpose"
  model: haiku
  prompt: |
    You are a specialized SDD sub-agent.

    STEP 1: Read the file ~/.claude/skills/sdd-[PHASE]/SKILL.md
    STEP 2: Follow its instructions exactly

    CONTEXT:
    - Project: [absolute path]
    - Change: [change-slug]
    - Previous artifacts: [list of paths]

    TASK: Execute the [phase] phase for change "[slug]".

    Return:
    - status: ok|warning|blocked|failed
    - summary: executive summary
    - artifacts: files created/modified
    - next_recommended: next phases
    - risks: identified risks (if any)
```

For the full I/O contract, see `openspec/agent-execution-contract.md`.

---

## Step 0 — Project Context Loading

All SDD phase skills load project context in Step 0 before doing any work:

```
1. Read ai-context/stack.md
2. Read ai-context/architecture.md
3. Read ai-context/conventions.md
4. Extract ## Skills Registry from CLAUDE.md
```

This step is **non-blocking**: missing files produce `INFO` notes, never `blocked` or `failed` status.

---

## Adding a Project-Local Skill

To override a global skill for a specific project:

```bash
# Option 1: Use /skill-add to copy a global skill into the project
/skill-add sdd-explore

# Option 2: Create manually
mkdir -p .claude/skills/sdd-explore
# Write your custom SKILL.md
```

The project-local version will be resolved first from that point on.

---

## Creating a New Skill

Use `/skill-create <name>` to scaffold a new skill directory. The skill-creator will prompt for:
- Skill name
- Format type (procedural/reference/anti-pattern)
- Trigger phrases
- Whether it's global or project-specific

---

## Registry

The canonical agent registry is in `agents.md`. It lists all skills with their format, model, I/O spec, and capability boundaries.

Skills in this repository (global catalog):

- **SDD Orchestrators**: `sdd-ff`, `sdd-new`, `sdd-status`
- **SDD Phases**: `sdd-explore`, `sdd-propose`, `sdd-spec`, `sdd-design`, `sdd-tasks`, `sdd-apply`, `sdd-verify`, `sdd-archive`
- **Meta-tools**: `project-setup`, `project-onboard`, `project-audit`, `project-analyze`, `project-fix`, `project-update`, `skill-creator`, `skill-add`, `memory-init`, `memory-update`, `codebase-teach`, `project-claude-organizer`, `claude-folder-audit`
- **Technology**: `react-19`, `nextjs-15`, `typescript`, `zustand-5`, `zod-4`, `tailwind-4`, `ai-sdk-5`, `react-native`, `electron`, `django-drf`, `spring-boot-3`, `hexagonal-architecture-java`, `java-21`, `playwright`, `pytest`
- **Tooling**: `github-pr`, `jira-task`, `jira-epic`, `smart-commit`, `elixir-antipatterns`
- **Design Principles**: `solid-ddd`, `feature-domain-expert`
- **Platform Tools**: `claude-code-expert`, `excel-expert`, `image-ocr`, `config-export`
