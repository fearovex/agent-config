# SDD Bootstrap Guide — GitHub Copilot (No Claude Code Required)

> How to set up Specification-Driven Development (SDD) in any project using only GitHub Copilot in VS Code.

---

## Prerequisites

- VS Code with the GitHub Copilot extension installed and authenticated
- Git repository initialized in the target project
- This `claude-config` repo cloned locally (you need one file from it)

---

## Part 1 — One-time setup per project

### Step 1 — Copy the Copilot instructions file

Copy `.github/copilot-instructions.md` from this repo to the target project:

```
# From the claude-config repo root:
cp .github/copilot-instructions.md <path-to-your-project>/.github/copilot-instructions.md
```

> **Why this works**: VS Code automatically loads `.github/copilot-instructions.md` as system-level context for Copilot in that workspace. Copilot will read it at the start of every session — no configuration needed.

This single file gives Copilot:
- The full SDD workflow (phases, artifacts, paths)
- Active coaching instructions (it will guide you through SDD proactively)
- The project memory layer structure (`ai-context/`)

---

### Step 2 — Create the SDD directory structure

In the target project, create the following directories and the config file:

```bash
mkdir -p openspec/changes/archive
mkdir -p ai-context
mkdir -p docs/adr
```

Create `openspec/config.yaml` with this content (replace the project name):

```yaml
mode: openspec
project: your-project-name
```

Create an empty `docs/adr/README.md`:

```markdown
# Architecture Decision Records

| # | Title | Status | Date |
|---|-------|--------|------|
```

At this point the project structure looks like:

```
your-project/
├── .github/
│   └── copilot-instructions.md   ← the SDD brain for Copilot
├── openspec/
│   ├── config.yaml
│   └── changes/
│       └── archive/
├── ai-context/                   ← project memory layer (populated in Step 4)
└── docs/
    └── adr/
        └── README.md
```

---

### Step 3 — Customize the instructions for this project

Open the target project in VS Code and open Copilot Chat. Run this prompt:

```
Read the codebase and update the following sections in .github/copilot-instructions.md
to reflect this project's actual stack and patterns:
- ## Tech Stack
- ## Architecture
- ## Conventions

Do not modify ## SDD Development Workflow, ## Active SDD Coaching Instructions,
## Working Principles, or ## Bootstrapping Other Projects With Copilot.
```

Copilot will scan the project and rewrite only the project-specific sections, leaving the SDD machinery intact.

Review the output before confirming — check that the tech stack table is accurate and the conventions match what the team actually uses.

---

### Step 4 — Generate the project memory layer

Run this prompt in Copilot Chat:

```
Read the project and create the following files in ai-context/,
following the table structure described in the ## SDD Development Workflow section
of .github/copilot-instructions.md:

- ai-context/stack.md
- ai-context/architecture.md
- ai-context/conventions.md
- ai-context/known-issues.md
```

These files serve as persistent context for every future Copilot session — Copilot reads them at session start so it doesn't need to re-scan the codebase each time.

---

### Step 5 — Commit the setup

```bash
git add .github/copilot-instructions.md openspec/ ai-context/ docs/adr/
git commit -m "chore: add SDD structure and Copilot instructions"
```

**Setup complete.** The project is now SDD-ready with Copilot as the AI assistant.

---

## Part 2 — Daily workflow

### Starting a new feature or fix

When you want to implement something, tell Copilot in Chat:

```
I want to implement [describe the feature/fix]. Follow the SDD workflow.
```

Copilot will guide you step by step:

1. **Propose** → writes `openspec/changes/<change-name>/proposal.md`
2. **Design** → writes `openspec/changes/<change-name>/design.md`  
   *(for small changes, propose + design can be done together)*
3. **Tasks** → writes `openspec/changes/<change-name>/tasks.md`
4. **Confirm** → Copilot asks you to review before writing any code
5. **Apply** → implements phase by phase, asks before each phase
6. **Verify** → writes `openspec/changes/<change-name>/verify-report.md`
7. **Archive** → moves the folder to `openspec/changes/archive/YYYY-MM-DD-<name>/`

### What each artifact is for

| File | When created | Purpose |
|------|-------------|---------|
| `proposal.md` | Phase 1 | Defines the problem, solution, and success criteria — the change contract |
| `design.md` | Phase 2 | Technical design: components affected, data flow, edge cases |
| `tasks.md` | Phase 3 | Phased implementation plan — the only thing that triggers `apply` |
| `verify-report.md` | Phase 6 | Checklist proving the implementation matches the proposal |

### Rules to follow during apply

- **Never start apply without `tasks.md`** — unstructured implementation is the primary source of SDD failures.
- **Never skip the proposal** for non-trivial changes — what gets written in `proposal.md` directly determines the quality of the implementation.
- Apply happens **phase by phase** — Copilot will ask before starting each batch of tasks. This is intentional; review before confirming.

### After significant changes

Run this prompt to keep the memory layer current:

```
Update the relevant sections in ai-context/ to reflect the changes made in this session.
Also update .github/copilot-instructions.md if the stack, architecture, or conventions changed.
```

---

## Part 3 — Keeping the instructions in sync

### When to update `.github/copilot-instructions.md`

Update after:
- Adding or removing major dependencies
- Establishing new team conventions
- Significant architecture changes
- Onboarding new developers (add gotchas and known issues)

Prompt:

```
Update the relevant sections in .github/copilot-instructions.md to reflect
the changes made in this session. Do not modify the SDD workflow sections.
```

### When to update `ai-context/`

Update `ai-context/changelog-ai.md` at the end of every AI-assisted session:

```
Append a changelog entry to ai-context/changelog-ai.md summarizing what was
implemented in this session, what decisions were made, and any risks or known issues
discovered.
```

---

## Part 4 — Reference

### SDD phase quick reference

```
explore (optional)
      │
      ▼
  propose  →  proposal.md
      │
   ┌──┴──────────────┐
   ▼                 ▼
  spec             design       ← run in parallel for large changes
   └──┬──────────────┘
      ▼
   tasks  →  tasks.md
      │
      ▼
   apply
      │
      ▼
  verify  →  verify-report.md
      │
      ▼
 archive  →  openspec/changes/archive/YYYY-MM-DD-<name>/
```

### Artifact paths cheat sheet

| Artifact | Path |
|----------|------|
| Proposal | `openspec/changes/<name>/proposal.md` |
| Design | `openspec/changes/<name>/design.md` |
| Tasks | `openspec/changes/<name>/tasks.md` |
| Verify report | `openspec/changes/<name>/verify-report.md` |
| Archived change | `openspec/changes/archive/YYYY-MM-DD-<name>/` |
| ADR | `docs/adr/NNN-short-title.md` |
| ADR index | `docs/adr/README.md` |
| Stack memory | `ai-context/stack.md` |
| Architecture memory | `ai-context/architecture.md` |
| Conventions memory | `ai-context/conventions.md` |
| Known issues memory | `ai-context/known-issues.md` |
| AI changelog | `ai-context/changelog-ai.md` |

### Useful Copilot prompts

| Situation | Prompt |
|-----------|--------|
| Start a change | `I want to implement X. Follow the SDD workflow.` |
| Only propose | `Write a proposal for X — create openspec/changes/<name>/proposal.md` |
| Only design | `Write a technical design for <name> — create openspec/changes/<name>/design.md` |
| Only tasks | `Break down the implementation for <name> into a tasks.md` |
| Check status | `List the SDD changes in openspec/changes/ and tell me which artifacts each one has` |
| Update memory | `Update ai-context/ to reflect the work done in this session` |
| Update instructions | `Update the Tech Stack and Conventions sections in .github/copilot-instructions.md` |

---

## Troubleshooting

### Copilot doesn't follow the SDD workflow

Check that `.github/copilot-instructions.md` exists at the project root level and that the `## Active SDD Coaching Instructions` section is present. Reopen VS Code after adding it for the first time.

### Copilot skips directly to writing code

Explicitly prompt: `Before writing any code, create proposal.md and tasks.md under openspec/changes/<name>/`

### The proposal is too vague

Ask Copilot to tighten it: `Review proposal.md and add explicit, verifiable success criteria — each criterion must be a checkbox that can be marked done or not done.`

### A change was partially implemented without artifacts

Run: `Create a retroactive proposal.md and tasks.md for the work already done on <name>, then create a verify-report.md checking what was completed.`
