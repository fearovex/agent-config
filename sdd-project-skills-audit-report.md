# SDD and Project Skills Audit Report

Date: 2026-03-06
Repository: `claude-config`
Scope: `skills/sdd-*/SKILL.md` and `skills/project-*/SKILL.md`
Method: Static review of active skill files and cross-check against repository conventions in `CLAUDE.md`, `ai-context/conventions.md`, and exported instructions.

## Executive Summary

The SDD and `project-*` skill set is mostly complete and structurally consistent at a high level:

- All expected SDD phase skill files are present: 11/11
- All expected `project-*` skill files are present: 7/7
- No missing `SKILL.md` files were found in these groups
- All reviewed files include frontmatter and a `## Rules` section or equivalent terminal rules block

The main issues are consistency problems between the documented contract and the actual skill implementations, rather than missing files or obviously broken skills.

## Positive Signals

1. The core SDD flow is fully represented: `sdd-explore`, `sdd-propose`, `sdd-spec`, `sdd-design`, `sdd-tasks`, `sdd-apply`, `sdd-verify`, `sdd-archive`, plus the orchestrators `sdd-ff`, `sdd-new`, and `sdd-status`.
2. The meta-tool layer is complete: `project-setup`, `project-onboard`, `project-audit`, `project-analyze`, `project-fix`, `project-update`, and `project-claude-organizer` all exist.
3. The central registry in `CLAUDE.md` includes the active SDD and `project-*` skills, so there is no obvious registry/file drift in these groups.

## Findings

### MEDIUM-1: Trigger syntax is inconsistent across SDD and project skills

**Evidence**

- User-facing repo docs standardize slash commands such as `/sdd-ff`, `/sdd-new`, `/project-audit`, `/project-fix`, and `/project-setup`.
- Several active skill files still use legacy trigger tokens in `**Triggers**`:
  - `sdd-explore` uses `sdd:explore`
  - `sdd-propose` uses `sdd:propose`
  - `sdd-spec` uses `sdd:spec`
  - `sdd-design` uses `sdd:design`
  - `sdd-tasks` uses `sdd:tasks`
  - `sdd-apply` uses `sdd:apply`
  - `sdd-verify` uses `sdd:verify`
  - `sdd-archive` uses `sdd:archive`
- `project-setup` and `project-update` do not include the slash-command form in `**Triggers**`, while the other `project-*` skills do.

**Affected files**

- `skills/sdd-explore/SKILL.md`
- `skills/sdd-propose/SKILL.md`
- `skills/sdd-spec/SKILL.md`
- `skills/sdd-design/SKILL.md`
- `skills/sdd-tasks/SKILL.md`
- `skills/sdd-apply/SKILL.md`
- `skills/sdd-verify/SKILL.md`
- `skills/sdd-archive/SKILL.md`
- `skills/project-setup/SKILL.md`
- `skills/project-update/SKILL.md`

**Why it matters**

This weakens discoverability and makes the command model look inconsistent. A reader moving between `CLAUDE.md`, README, and the individual skills sees two command dialects: slash commands and legacy `sdd:phase` tokens.

**Recommended fix**

Normalize `**Triggers**` so all command-like entries use the slash-command form that the repo currently documents.

### MEDIUM-2: The procedural-section contract is defined more strictly than the skills actually implement it

**Evidence**

- `CLAUDE.md` and exported instructions describe `procedural` skills as requiring `## Process`.
- `ai-context/conventions.md` uses a looser rule: `## Process` or `### Step N`.
- Several procedural skills rely on alternative section shapes instead of a literal `## Process` heading:
  - `sdd-ff` uses `## Step 1`, `## Step 2`, etc., with no top-level `## Process`
  - `sdd-new` uses `## Step 1`, `## Step 2`, etc., with no top-level `## Process`
  - `project-setup` uses `## Setup Process`
  - `project-audit` uses `## Audit Process — 10 Dimensions`
  - `project-fix` uses `## Fix Process`

**Affected files**

- `CLAUDE.md`
- `ai-context/conventions.md`
- `.github/copilot-instructions.md`
- `skills/sdd-ff/SKILL.md`
- `skills/sdd-new/SKILL.md`
- `skills/project-setup/SKILL.md`
- `skills/project-audit/SKILL.md`
- `skills/project-fix/SKILL.md`

**Why it matters**

The repo currently has two competing definitions of “valid procedural skill”. That ambiguity can leak into audits, scaffolding rules, and future skill authoring.

**Recommended fix**

Pick one contract and apply it everywhere:

- Option A: require literal `## Process` everywhere and rename the affected skills.
- Option B: formalize the looser rule (`## Process` or `### Step N` or an equivalent named process section) in `CLAUDE.md`, exported docs, and any audit logic.

### MEDIUM-3: `project-audit` still accepts a legacy `## Execution rules` heading that no longer matches the repo convention

**Evidence**

- `project-audit` D10 structural quality says a `SKILL.md` passes if it contains `## Rules` or `## Execution rules`.
- The current repository convention in `CLAUDE.md` and `ai-context/conventions.md` standardizes on `## Rules`.

**Affected files**

- `skills/project-audit/SKILL.md`
- `CLAUDE.md`
- `ai-context/conventions.md`

**Why it matters**

This means the audit tool can validate a non-canonical structure that the rest of the repo no longer describes as standard. It weakens the usefulness of the audit as an enforcement mechanism.

**Recommended fix**

Update `project-audit` to treat `## Rules` as the canonical target. If backward compatibility is still needed, document that as an explicit transitional exception.

### LOW-1: Template examples with `TODO` markers remain embedded in active skill files

**Evidence**

- `project-fix` contains stub templates with `TODO` markers for missing sections.
- `project-claude-organizer` contains multiple scaffold templates with `TODO` markers for generated skill skeletons.

**Affected files**

- `skills/project-fix/SKILL.md`
- `skills/project-claude-organizer/SKILL.md`

**Why it matters**

This is not necessarily wrong, but it creates audit noise risk when other tooling performs naive placeholder scans without understanding code fences or example blocks.

**Recommended fix**

If placeholder-based audits become noisy, either:

- make those checks code-fence-aware, or
- move large templates to dedicated example/template files.

## Health Assessment

Current health for SDD and `project-*` skills: `Good with consistency debt`

- Structural completeness: good
- Registry alignment: good
- Command consistency: mixed
- Contract consistency: mixed
- Audit enforceability: mixed

## Recommended Next Steps

1. Normalize trigger syntax to slash commands across all `sdd-*` and `project-*` skills.
2. Decide the canonical procedural-section contract and update either the skills or the docs so they match.
3. Tighten `project-audit` so its structural pass/fail logic matches the current repository convention.
4. If you want stronger ongoing health signals, add a dedicated self-audit skill or script for `skills/*/SKILL.md` contract validation.

## Practical Project Health Checklist

To monitor overall health of this repo going forward, the most useful sequence is:

1. Re-run the repository-wide consistency review after every config-heavy change.
2. Run a focused skill audit on `skills/sdd-*`, `skills/project-*`, and any recently edited tech skills.
3. Verify active docs stay aligned with runtime behavior: `README.md`, `CLAUDE.md`, `.github/copilot-instructions.md`, `GEMINI.md`, and `ai-context/*`.
4. Check `openspec/changes/` for incomplete active changes missing proposal/design/tasks/verify artifacts.
5. Review `ai-context/changelog-ai.md` after major sessions to ensure architectural decisions and workflow changes were recorded.
