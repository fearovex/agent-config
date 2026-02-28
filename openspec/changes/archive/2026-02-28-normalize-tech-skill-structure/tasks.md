# Task Plan: normalize-tech-skill-structure

Date: 2026-02-27
Design: openspec/changes/normalize-tech-skill-structure/design.md

## Progress: 33/33 tasks

---

## Phase 1: Batch 1 — Frontend / React (6 files)

- [x] 1.1 Modify `skills/react-19/SKILL.md` — insert `**Triggers**: When building React components, using hooks, working with forms, or server/client components.` immediately after the `## When to Use` header line; append the `## Rules` section (5 rules) at end of file
- [x] 1.2 Modify `skills/nextjs-15/SKILL.md` — insert `**Triggers**: When building Next.js apps, working with app router, server/client components, or API routes.` immediately after the `## When to Use` header line; append the `## Rules` section (5 rules) at end of file
- [x] 1.3 Modify `skills/typescript/SKILL.md` — insert `**Triggers**: When writing TypeScript, defining types/interfaces, or using utility types.` immediately after the `## When to Use` header line; append the `## Rules` section (5 rules) at end of file
- [x] 1.4 Modify `skills/tailwind-4/SKILL.md` — insert `**Triggers**: When styling with Tailwind, using className, conditional styles, or dark mode.` immediately after the `## When to Use` header line; append the `## Rules` section (5 rules) at end of file
- [x] 1.5 Modify `skills/zustand-5/SKILL.md` — insert `**Triggers**: When managing global state in React, using Zustand, or implementing state slices.` immediately after the `## When to Use` header line; append the `## Rules` section (5 rules) at end of file
- [x] 1.6 Modify `skills/zod-4/SKILL.md` — insert `**Triggers**: When validating data, defining schemas, working with forms, or using Zod for type safety.` immediately after the `## When to Use` header line; append the `## Rules` section (5 rules) at end of file

---

## Phase 2: Batch 2 — AI / Mobile / Desktop (5 files)

- [x] 2.1 Modify `skills/ai-sdk-5/SKILL.md` — insert `**Triggers**: When building AI chat interfaces, using Vercel AI SDK, streaming LLM responses, or integrating tools.` immediately after the `## When to Use` header line; append the `## Rules` section (5 rules) at end of file
- [x] 2.2 Modify `skills/react-native/SKILL.md` — insert `**Triggers**: When building mobile apps, working with React Native components, using Expo, React Navigation, or NativeWind.` immediately after the `## When to Use` header line; append the `## Rules` section (5 rules) at end of file
- [x] 2.3 Modify `skills/electron/SKILL.md` — insert `**Triggers**: When building Electron apps, working with main/renderer processes, IPC communication, or native OS integrations.` immediately after the `## When to Use` header line; append the `## Rules` section (5 rules) at end of file
- [x] 2.4 Modify `skills/claude-code-expert/SKILL.md` — append the `## Rules` section (5 rules) at end of file only (Triggers line already present; do NOT modify it)
- [x] 2.5 Modify `skills/excel-expert/SKILL.md` — append the `## Rules` section (5 rules) at end of file only (Triggers line already present; do NOT modify it)

---

## Phase 3: Batch 3 — Backend / Java (6 files)

- [x] 3.1 Modify `skills/django-drf/SKILL.md` — insert `**Triggers**: When building REST APIs with Django - ViewSets, Serializers, Filters.` before the first `##` section heading (no `## When to Use` and no blockquote — insert before `## ViewSet Pattern`); append the `## Rules` section (5 rules) at end of file
- [x] 3.2 Modify `skills/spring-boot-3/SKILL.md` — insert `**Triggers**: When building Spring Boot applications, configuring beans, or implementing REST services.` immediately after the `## When to Use` header line; append the `## Rules` section (5 rules) at end of file
- [x] 3.3 Modify `skills/java-21/SKILL.md` — insert `**Triggers**: When writing Java 21 code, using records, sealed interfaces, or virtual threads for I/O.` immediately after the `## When to Use` header line; append the `## Rules` section (5 rules) at end of file
- [x] 3.4 Modify `skills/hexagonal-architecture-java/SKILL.md` — insert `**Triggers**: When designing Java services with hexagonal architecture, clean architecture, or ports-and-adapters pattern.` immediately after the `## When to Use` header line; append the `## Rules` section (5 rules) at end of file
- [x] 3.5 Modify `skills/elixir-antipatterns/SKILL.md` — insert `**Triggers**: During code review, refactoring, or when writing Phoenix/Ecto code.` immediately after the `## When to Use` header line (use English translation — frontmatter has Spanish text; body must be English per project rules); append the `## Rules` section (5 rules) at end of file
- [x] 3.6 Modify `skills/image-ocr/SKILL.md` — append the `## Rules` section (5 rules) at end of file only (Triggers line already present; do NOT modify it)

---

## Phase 4: Batch 4 — Testing / Tooling / Process (6 files)

- [x] 4.1 Modify `skills/playwright/SKILL.md` — insert `**Triggers**: When writing E2E tests, using Playwright, implementing page objects, or testing UI flows.` immediately after the `## When to Use` header line; append the `## Rules` section (5 rules) at end of file
- [x] 4.2 Modify `skills/pytest/SKILL.md` — insert `**Triggers**: When writing Python tests, using pytest, mocking dependencies, or testing async code.` immediately after the `## When to Use` header line; append the `## Rules` section (5 rules) at end of file
- [x] 4.3 Modify `skills/github-pr/SKILL.md` — insert `**Triggers**: When creating PRs, writing PR descriptions, or using gh CLI for pull requests.` immediately after the `## When to Use` header line; append the `## Rules` section (5 rules) at end of file
- [x] 4.4 Modify `skills/jira-task/SKILL.md` — insert `**Triggers**: When creating Jira tickets, tasks, or issues for features, bugs, or enhancements.` immediately after the `## When to Use` header line; append the `## Rules` section (5 rules) at end of file
- [x] 4.5 Modify `skills/jira-epic/SKILL.md` — insert `**Triggers**: When creating Jira epics, planning large features, or structuring work spanning multiple components.` immediately after the `## When to Use` header line; append the `## Rules` section (5 rules) at end of file
- [x] 4.6 Modify `skills/smart-commit/SKILL.md` — insert `**Triggers**: When the user says "commit", "smart commit", or /commit.` immediately after the `## When to Use` header line; append the `## Rules` section (5 rules) at end of file

---

## Phase 5: Verification and Deploy

- [x] 5.1 Run `bash C:/Users/juanp/claude-config/install.sh` from the repo root — confirm exit code 0 and that all 23 modified SKILL.md files are deployed to `~/.claude/skills/`
- [x] 5.2 Run `grep -r "^\*\*Triggers\*\*" ~/.claude/skills/` — confirm at least 23 lines returned, one per tech skill directory
- [x] 5.3 Run `grep -r "^## Rules" ~/.claude/skills/` — confirm at least 23 lines returned covering all tech skill directories
- [ ] 5.4 Run `/project-audit` — confirm D9-3 (structural completeness) passes with no failures for tech skills; confirm D10-b (structural quality) equals or improves baseline
- [x] 5.5 Run `git add` for all 23 modified `skills/*/SKILL.md` files and create commit with message: `feat(skills): normalize tech skill structure — add Triggers and Rules to 23 skills`

---

## Implementation Notes

- All edits are **purely additive** — read the file before editing to confirm existing content is preserved; do NOT rewrite, reorder, or remove any existing lines
- YAML frontmatter (between the opening and closing `---` delimiters) MUST remain byte-for-byte identical after each edit
- Trigger text for `elixir-antipatterns` MUST be the English translation (`During code review, refactoring, or when writing Phoenix/Ecto code.`) — the frontmatter has Spanish text which is a pre-existing violation; the body addition must be in English
- The exact Rules content for each skill is fully specified in the design document at `openspec/changes/normalize-tech-skill-structure/design.md` under "Rules Section Content Specification" — use that verbatim
- For `django-drf`, identify the first `##` heading in the Markdown body (should be `## ViewSet Pattern`) and insert the Triggers line immediately before it with a blank line separator
- For all other skills using `## When to Use` placement: insert the Triggers line as the first line of content inside that section (after the `## When to Use` heading, before any bullets or paragraphs)
- Verification in Phase 5 MUST target `~/.claude/skills/` (the runtime path post-install), not the repo `skills/` directory

## Blockers

None.
