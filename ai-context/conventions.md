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
- Always run `sync.sh` before committing to capture `~/.claude/` state
- Commit after each SDD phase (at minimum after apply and after archive)

## SDD workflow for this repo

**Minimum for any skill change:**
```
/sdd:ff <change-name>   →   user approves   →   /sdd:apply   →   sync.sh   →   git commit
```

**Required for breaking changes to orchestrator or SDD phase skills:**
Full cycle: explore → propose → spec + design → tasks → apply → verify → archive

## install.sh / sync.sh usage

- `sync.sh` — run BEFORE committing. Captures current `~/.claude/` state into the repo.
- `install.sh` — run on new machines or after a reset. Restores `~/.claude/` from repo.
- Never edit files directly in `~/.claude/` and forget to sync. Changes will be lost on next install.
