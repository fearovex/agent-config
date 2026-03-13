# ADR-030: Sub-Agent Governance Injection as a Cross-Cutting Pattern

## Status

Proposed

## Context

SDD sub-agents operate in isolated context windows and receive only a minimal prompt (skill path, project path, change slug, prior artifact paths). Before this decision, Step 0 in all phase skills read the project CLAUDE.md but extracted only the `## Skills Registry` section, leaving the rest of the governance file (unbreakable rules, tech stack, intent classification settings) invisible to sub-agents at decision time. This created a governance asymmetry: the orchestrator operated under the full CLAUDE.md rules, but sub-agents did not. Copilot (via Cursor) receives the full governance export upfront; sub-agents did not enjoy equivalent priming. The gap produced decision drift where sub-agents made architectural or organizational choices inconsistent with project constraints — only discoverable after the fact in verification.

## Decision

We will establish sub-agent governance injection as a cross-cutting pattern that applies uniformly across all SDD phase skills and both orchestrator skills. Specifically:

1. Both orchestrators (`sdd-ff`, `sdd-new`) add a `Project governance: <absolute-path>/CLAUDE.md` field to the CONTEXT block of every sub-agent prompt they emit.
2. All seven SDD phase skills (`sdd-explore`, `sdd-propose`, `sdd-spec`, `sdd-design`, `sdd-tasks`, `sdd-apply`, `sdd-verify`) expand their Step 0 CLAUDE.md read from "extract Skills Registry section only" to "read the full file and log a single governance summary line" (rule count, tech stack language, intent classification status).
3. The canonical Step 0 item 4 wording and the agent-execution-contract input fields table are updated to document the new pattern.
4. The `docs/sdd-context-injection.md` reference document is updated to reflect the expanded CLAUDE.md read.
5. All failure modes (missing file, unreadable content) remain non-blocking INFO notes — governance injection never causes `status: blocked` or `status: failed`.

## Consequences

**Positive:**

- Sub-agents receive the same governance priming that the orchestrator carries, eliminating governance asymmetry
- Governance visibility is confirmed in sub-agent output via the logged governance summary line, making priming auditable
- The change is purely additive — no artifact format, phase DAG, or skill resolution logic is altered
- Fully reversible: reverting the CONTEXT field addition and the Step 0 wording in all affected files restores the prior state with no artifact loss

**Negative:**

- Each sub-agent invocation now reads one additional file (full CLAUDE.md instead of a section); on very large CLAUDE.md files this increases context window usage slightly
- The Step 0 canonical wording must be maintained consistently across seven skills; any future Step 0 modification must propagate to all seven files
- New SDD phase skills added in the future must adopt the governance injection pattern explicitly — it is not automatically enforced
