# Technical Design: standardize-phase-completion-messages

Date: 2026-03-22
Proposal: openspec/changes/2026-03-22-standardize-phase-completion-messages/proposal.md

## General Approach

Apply a uniform two-line natural language gate pattern to all SDD phase skill completion messages. The pattern replaces command-as-gate messages ("Run: /sdd-X") with a conversational prompt ("Continue with X? Reply **yes**") followed by a secondary manual command reference. Two skills already use this pattern (sdd-ff Step 4, sdd-apply completion). The remaining skills (sdd-new, sdd-apply verify-suggestion, sdd-verify, sdd-explore, sdd-propose, sdd-spec, sdd-design, sdd-tasks) will be audited and updated where the old pattern exists.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
| -------- | ------ | ---------------------- | ------------- |
| Gate template wording | `Continue with <next phase>? Reply **yes** to proceed or **no** to pause.\n_(Manual: /sdd-<phase> <slug>)_` | Removing command reference entirely; using "yes/no/skip" three-option gate | Matches the proven pattern already in sdd-ff (line 397-398). Two options (yes/no) keep it simple. Command remains discoverable as secondary reference. |
| sdd-apply completion message | Update from `Next step: /sdd-verify` to natural language gate | Keep as-is (command-only) | sdd-apply's completion text (lines 580-584) uses command-only format — inconsistent with sdd-ff's gate style. Must be updated for uniformity. |
| sdd-new completion message | Update from `Ready to implement? Run: /sdd-apply` to natural language gate | Keep as-is | sdd-new (lines 326-327) uses command-as-gate — must match sdd-ff's pattern. |
| Phases with no next phase (sdd-archive) | No gate change needed — terminal phase | Adding a "cycle complete" gate | sdd-archive has `next_recommended: []` — no gate to convert. Leave as-is. |
| Output JSON next_recommended | Keep unchanged — orchestrator presentation layer handles formatting | Modify JSON values | The `next_recommended` JSON field is machine-readable for the orchestrator. The natural language gate is in the prose/template sections, not the JSON output. Changing JSON would break orchestrator contracts. |

## Data Flow

```
User invokes /sdd-ff or /sdd-new
  ↓
Orchestrator delegates to sub-agent (propose → spec → design → tasks)
  ↓
Sub-agent completes work, returns Output JSON to orchestrator
  ↓
Orchestrator reads next_recommended from JSON
  ↓
Orchestrator presents natural language gate to user:
  "Continue with <phase>? Reply **yes** to proceed or **no** to pause."
  _(Manual: /sdd-<phase> <slug>)_
  ↓
User replies yes → orchestrator launches next sub-agent
User replies no  → orchestrator pauses, shows resume command

Standalone phase invocations (e.g., /sdd-verify directly):
  ↓
Sub-agent completes, shows completion message with gate in its own output
  ↓
User decides next step
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `skills/sdd-new/SKILL.md` | Modify | Lines 326-327: replace `Ready to implement? Run:\n  /sdd-apply [slug]` with natural language gate pattern |
| `skills/sdd-apply/SKILL.md` | Modify | Lines 580-584: replace `Implementation complete. Next step:\n  /sdd-verify <change-name>` with natural language gate pattern |
| `skills/sdd-verify/SKILL.md` | Modify | Completion message: add natural language gate for sdd-archive transition |
| `skills/sdd-explore/SKILL.md` | No change needed | Output JSON only — orchestrator handles presentation. No prose gate exists. |
| `skills/sdd-propose/SKILL.md` | No change needed | Output JSON only — orchestrator handles presentation. No prose gate exists. |
| `skills/sdd-spec/SKILL.md` | No change needed | Output JSON only — orchestrator handles presentation. No prose gate exists. |
| `skills/sdd-design/SKILL.md` | No change needed | Output JSON only — orchestrator handles presentation. No prose gate exists. |
| `skills/sdd-tasks/SKILL.md` | No change needed | Output JSON only — orchestrator handles presentation. Already has note that orchestrator formats next_recommended. |

## Interfaces and Contracts

No new interfaces. The change is wording-only in prose sections of SKILL.md files. The Output JSON `next_recommended` fields remain unchanged — the orchestrator's presentation layer is responsible for rendering natural language gates from those values.

**Template string (canonical):**

```
Continue with <next phase>? Reply **yes** to proceed or **no** to pause.
_(Manual: `/sdd-<phase> [inferred-slug]`)_
```

Where `<next phase>` is the human-readable phase name (e.g., "implementation", "verification", "archival").

## Testing Strategy

| Layer | What to test | Tool |
| ----- | ------------ | ---- |
| Manual | Read each modified SKILL.md and verify wording matches template | Visual inspection |
| Integration | Run `/sdd-ff` end-to-end on a test change and verify all gates use natural language | Manual /sdd-ff run |
| Audit | Run `/project-audit` to verify SKILL.md structural compliance | /project-audit |

## Migration Plan

No data migration required.

## Open Questions

None. The pattern is already proven in sdd-ff Step 4 (lines 397-398) and the exact template is defined in the proposal.
