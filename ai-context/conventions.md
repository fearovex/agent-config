# Conventions — claude-config

> Last updated: 2026-02-23

## Language

**ALL content MUST be in English.** This includes:
- SKILL.md files
- config.yaml content
- ai-context/ files
- openspec/ artifacts
- Commit messages
- Comments in scripts

No exceptions. Spanish or any other language is a violation.

## Naming conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Skill directories | kebab-case | `project-audit/`, `sdd-propose/` |
| Skill entry point | UPPER | `SKILL.md` |
| SDD phase skills | `sdd-[phase]` prefix | `sdd-propose`, `sdd-apply` |
| Meta-tool skills | `project-[action]` prefix | `project-audit`, `project-fix` |
| Tech skills | `[tech]-[version]` | `react-19`, `nextjs-15`, `zustand-5` |
| SDD change names | kebab-case descriptive | `improve-project-audit`, `add-wallet-skill` |
| openspec changes | `openspec/changes/[name]/` | `openspec/changes/add-project-fix/` |
| Archived changes | `YYYY-MM-DD-[name]` | `2026-02-23-add-project-fix` |

## SKILL.md structure

Every SKILL.md must have these sections in order:

```markdown
# skill-name

> One-line description of what it does.

**Triggers**: [when to use this skill]

---

## [Main process sections]
[Step-by-step instructions]

---

## Rules
[Constraints and invariants — always at the end]
```

## Git conventions

- Commit messages in English
- Conventional commits: `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`
- **Workflow A (config changes)**: edit in repo → `bash install.sh` → `git commit`
- **Workflow B (memory capture)**: `bash sync.sh` → `git add memory/` → `git commit`
- Commit after each SDD phase (at minimum after apply and after archive)

## SDD workflow for this repo

**Minimum for any skill change:**
```
/sdd:ff <change-name>   →   user approves   →   /sdd:apply   →   install.sh   →   git commit
```

**Required for breaking changes to orchestrator or SDD phase skills:**
Full cycle: explore → propose → spec + design → tasks → apply → verify → archive

## Workflows

### Workflow A — Config changes (skills, CLAUDE.md, hooks, ai-context, openspec)
```
edit in repo → bash install.sh → git commit
```
Use this when you modify any skill, CLAUDE.md, settings.json, hooks/, ai-context/, or openspec/.
`install.sh` deploys the repo to `~/.claude/` so Claude picks up the changes on the next session.
Never run `sync.sh` for these — it will not capture them (by design).

### Workflow B — Memory capture
```
bash sync.sh → git add memory/ && git commit
```
Use this periodically to persist Claude's automatic memory updates (`~/.claude/memory/`) into the repo.
This is the ONLY directory that flows `~/.claude/ → repo/`.
