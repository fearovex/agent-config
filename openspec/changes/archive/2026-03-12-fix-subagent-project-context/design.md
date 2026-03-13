# Technical Design: 2026-03-12-fix-subagent-project-context

Date: 2026-03-12
Proposal: openspec/changes/2026-03-12-fix-subagent-project-context/proposal.md

---

## General Approach

Sub-agents receive governance priming by two coordinated changes: (1) orchestrators (`sdd-ff`, `sdd-new`) add a `Project governance:` field to every sub-agent prompt's CONTEXT section, exposing the absolute path to the project's `CLAUDE.md`; (2) all seven SDD phase skills expand their Step 0 CLAUDE.md read from "extract Skills Registry section only" to "read the full file and log unbreakable rules, tech stack, and intent classification status". Both changes are purely additive. Step 0 remains non-blocking in all skills. No artifact format, phase DAG, or skill resolution logic is altered.

---

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|---|---|---|---|
| Sub-agent model for explore | sonnet | haiku (current) | explore must analyze codebase patterns and detect architectural gaps — haiku loses nuance in complex codebases |
| Sub-agent model for propose | sonnet | haiku (current) | proposal requires scope reasoning, risk assessment, and trade-off decisions — haiku produces shallow proposals |
| Sub-agent model for tasks | sonnet | haiku (current) | atomic task decomposition with dependency ordering requires reasoning — haiku misses edge cases and cross-file dependencies |
| Governance delivery mechanism | Path injection in sub-agent prompt CONTEXT field | Inline full-content injection; separate governance artifact | Path injection keeps prompt size minimal (<200 bytes overhead) and lets the sub-agent decide when/if to load the file — consistent with the "artifacts over in-memory state" architecture convention |
| Scope of CLAUDE.md read in Step 0 | Read full file; log unbreakable rules, tech stack, and intent classification status | Read only Unbreakable Rules section; keep Skills Registry only read | Full read provides maximum governance visibility with no additional I/O calls; partial reads create partial-governance confusion; Skills-Registry-only was explicitly identified as inadequate in the proposal |
| Loading order | Step 0 (governance) runs before Step 1 (prior artifacts) | Load governance inline during each decision point | Step 0 first ensures governance is available for all subsequent steps including prior artifact reading; loading per-decision adds complexity and unpredictable order |
| Governance logging format | Structured inline log: rule count, tech stack, intent classification on/off | No logging; structured JSON output; separate log artifact | Inline log makes governance visibility auditable in sub-agent output; structured JSON is over-engineered for a priming note; a separate artifact adds unnecessary I/O |
| Fallback behavior when CLAUDE.md absent | Log INFO note and continue; treat governance as empty | Block sub-agent; emit warning | Consistent with existing Step 0 non-blocking contract; CLAUDE.md is optional by convention; governance gap in old projects is acceptable and self-resolving |
| Documentation update scope | Update `docs/sdd-context-injection.md` and `openspec/agent-execution-contract.md` | Update CLAUDE.md architecture section only | Both documents are explicitly referenced by the contract and the context injection spec; they define the canonical input format and Step 0 template — both must stay in sync |
| Cross-cutting global convention | This change introduces a cross-cutting governance injection pattern affecting all SDD phase skills and orchestrators | N/A | Triggers ADR generation (keyword: "cross-cutting") |

---

## Data Flow

### Before this change

```
Orchestrator (sdd-ff / sdd-new)
  │
  └──► sub-agent prompt:
         CONTEXT:
         - Project: /abs/path
         - Change: slug
         - Previous artifacts: [paths]

Sub-agent Step 0:
  reads → ai-context/stack.md
  reads → ai-context/architecture.md
  reads → ai-context/conventions.md
  reads → CLAUDE.md  ← only ## Skills Registry section extracted
```

### After this change

```
Orchestrator (sdd-ff / sdd-new)
  │
  └──► sub-agent prompt:
         CONTEXT:
         - Project: /abs/path
         - Change: slug
         - Previous artifacts: [paths]
         - Project governance: /abs/path/CLAUDE.md   ← NEW

Sub-agent Step 0:
  reads → ai-context/stack.md
  reads → ai-context/architecture.md
  reads → ai-context/conventions.md
  reads → CLAUDE.md  ← full file; logs rules count, tech stack, intent classification
         Governance log output (inline):
           "Governance loaded: 5 unbreakable rules, tech stack: Markdown+YAML+Bash,
            intent classification: enabled"
```

### Governance injection propagation

```
sdd-ff / sdd-new (orchestrator)
  ├──► sdd-explore  → Step 0 reads full CLAUDE.md → logs governance
  ├──► sdd-propose  → Step 0a reads full CLAUDE.md → logs governance
  ├──► sdd-spec     → Step 0a reads full CLAUDE.md → logs governance
  ├──► sdd-design   → Step 0 reads full CLAUDE.md → logs governance
  ├──► sdd-tasks    → Step 0 reads full CLAUDE.md → logs governance
  ├──► sdd-apply    → project context load (sub-section) reads full CLAUDE.md
  └──► sdd-verify   → Step 0 reads full CLAUDE.md → logs governance
```

---

## File Change Matrix

| File | Action | What is added/modified |
|---|---|---|
| `skills/sdd-ff/SKILL.md` | Modify | Add `- Project governance: [project-root]/CLAUDE.md` to CONTEXT block in all sub-agent prompt templates; fix model assignments: explore→sonnet, propose→sonnet, tasks→sonnet |
| `skills/sdd-new/SKILL.md` | Modify | Add `- Project governance: [project-root]/CLAUDE.md` to CONTEXT block in all sub-agent prompt templates; fix model assignments: explore→sonnet, propose→sonnet, tasks→sonnet |
| `skills/sdd-explore/SKILL.md` | Modify | Step 0 item 4: replace "extract the `## Skills Registry` section" with "read the full CLAUDE.md" + add governance logging instruction |
| `skills/sdd-propose/SKILL.md` | Modify | Step 0a item 4: same substitution as sdd-explore |
| `skills/sdd-spec/SKILL.md` | Modify | Step 0a item 4: same substitution as sdd-explore |
| `skills/sdd-design/SKILL.md` | Modify | Step 0 item 4: same substitution as sdd-explore |
| `skills/sdd-tasks/SKILL.md` | Modify | Step 0 item 4: same substitution as sdd-explore |
| `skills/sdd-apply/SKILL.md` | Modify | Project context load sub-section item 4: same substitution as sdd-explore |
| `skills/sdd-verify/SKILL.md` | Modify | Step 0 item 4: same substitution as sdd-explore |
| `openspec/agent-execution-contract.md` | Modify | Input fields table: add `Project governance` row; update example prompt in Input Format section |
| `docs/sdd-context-injection.md` | Modify | Step 0 Block Template: update item 4 text; add "Governance Logging" subsection; update "How Loaded Context Is Used" table; update Graceful Degradation rule for missing CLAUDE.md |

---

## Interfaces and Contracts

### Updated sub-agent prompt CONTEXT block (canonical form after change)

```
CONTEXT:
- Project: <absolute-path-to-project-root>
- Change: <change-slug>
- Previous artifacts: <comma-separated list of artifact paths, or "none">
- Project governance: <absolute-path-to-project-root>/CLAUDE.md
```

### Updated Step 0 item 4 (canonical wording for all skills)

```markdown
4. Read the full project `CLAUDE.md` (at project root). Extract and log:
   - Count of items listed under `## Unbreakable Rules`
   - Value of the primary language from `## Tech Stack`
   - Whether `intent_classification:` is `disabled` (check for Override section)
   Output a single governance log line:
   `Governance loaded: [N] unbreakable rules, tech stack: [language], intent classification: [enabled|disabled]`
   If CLAUDE.md is absent: log `INFO: project CLAUDE.md not found — governance falls back to global defaults.`
```

### Updated agent-execution-contract Input fields table

| Field | Type | Required | Description |
|---|---|---|---|
| `Project` | absolute path | yes | Root directory of the project being worked on |
| `Change` | string (slug) | yes | The change slug (e.g., `2026-03-12-agent-registry`) |
| `Previous artifacts` | list of paths | no | Artifacts from prior phases; `"none"` when this is the first phase |
| `Project governance` | absolute path | no | Path to the project's CLAUDE.md; absent when orchestrator does not inject it (non-breaking) |
| `TASK` | string | yes | Precise description of the work to be done |

---

## Testing Strategy

| Layer | What to test | Tool |
|---|---|---|
| Manual review | Each modified SKILL.md has the correct Step 0 wording (full CLAUDE.md read + governance log line) | Human review against canonical Step 0 wording |
| Manual review | Each sub-agent prompt template in sdd-ff and sdd-new has the `Project governance:` CONTEXT field | Human review of all 8 prompt blocks |
| Manual review | agent-execution-contract.md and docs/sdd-context-injection.md match the new canonical form | Human review of both documents |
| Integration (manual) | Run `/sdd-ff test-governance-injection` on this project; confirm sub-agent outputs include `Governance loaded:` line | Execute and inspect sub-agent return summary |
| Regression (manual) | Run `/project-audit` before and after; confirm score >= previous | `/project-audit` output |

No automated test runner applies — this is a Markdown skills project. Testing is manual review + integration execution.

---

## Migration Plan

No data migration required. All changes are additive text edits to SKILL.md files and documentation. No schema, artifact format, or phase DAG changes.

---

## Open Questions

None.

---

## ADR Note

The Technical Decisions table contains the keyword "cross-cutting" in the last row. This triggers ADR generation per the sdd-design Step 4 rule. See `docs/adr/030-subagent-governance-injection-cross-cutting-pattern.md`.
