# Technical Design: normalize-tech-skill-structure

Date: 2026-02-27
Proposal: openspec/changes/normalize-tech-skill-structure/proposal.md

## General Approach

Every tech skill SKILL.md receives two purely additive insertions: a `**Triggers**` line
derived mechanically from the frontmatter `description` field, and a `## Rules` section
appended at the end of the file with 3–5 technology-specific constraints. No existing
content is modified or deleted. The frontmatter block is never touched. Changes are
batched into four apply groups to stay within sub-agent context limits.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|---------------|
| Trigger text source | Extract the sentence after "Trigger:" in the frontmatter `description` field | Rewrite triggers from scratch | Frontmatter already has a human-authored trigger sentence; extracting it avoids invention and keeps body consistent with frontmatter semantics |
| Trigger placement | Insert immediately after the opening blockquote description (`> ...`) or after the `## Description` block when a blockquote is absent | Insert before the first `##` section | The SDD SKILL.md convention (conventions.md) specifies `**Triggers**` appears directly after the blockquote; `claude-code-expert` and `excel-expert` already follow this placement, so we match it |
| Trigger placement for files with no blockquote | Insert after the H1 heading line and a blank line | After frontmatter | django-drf, smart-commit, github-pr, playwright, and others have no blockquote — insert after the `## When to Use` header line instead, since that is the effective opening section |
| Rules content derivation | Write skill-specific rules from reading the actual SKILL.md content | Generic 5-rule template for all skills | Generic rules would add noise without value; each skill's existing patterns, anti-patterns, and constraints directly inform what the Rules section must say |
| Rules section position | Append at the very end of each file | Insert before Quick Reference | End position matches the established SDD convention (`## Rules` is always the final section in conformant SKILL.md files) |
| Apply batching | 4 batches of 5–6 files, grouped by technology domain | One batch per file (23 sub-agents) or one giant batch | Balances sub-agent context limits against parallelism; domain grouping keeps related context together for the agent |
| Files needing both sections | 20 files: ai-sdk-5, django-drf, electron, elixir-antipatterns, github-pr, hexagonal-architecture-java, java-21, jira-epic, jira-task, nextjs-15, playwright, pytest, react-19, react-native, smart-commit, spring-boot-3, tailwind-4, typescript, zod-4, zustand-5 | — | These 20 have no `**Triggers**` line in the Markdown body (confirmed by reading files and by audit D10 findings) |
| Files needing Rules only | 3 files: claude-code-expert, excel-expert, image-ocr | — | These 3 already have `**Triggers**` in their body (confirmed by reading files) but no `## Rules` section |

## Data Flow

```
For each of the 20 "both missing" skills:

  frontmatter description field
        │
        ▼
  extract text after "Trigger:" keyword
        │
        ▼
  compose: **Triggers**: <extracted text>
        │
        ▼
  insert after opening blockquote / first content block
        │
        ▼
  compose: ## Rules  (3–5 skill-specific constraints)
        │
        ▼
  append at end of file

For each of the 3 "Rules only" skills (claude-code-expert, excel-expert, image-ocr):

  read existing **Triggers** line (already present, skip)
        │
        ▼
  compose: ## Rules  (3–5 skill-specific constraints)
        │
        ▼
  append at end of file
```

## Trigger Text Derivation Table

The following table documents exactly what text will be used as the `**Triggers**` value
for each of the 20 skills that need it. Text is extracted from the frontmatter `description`
field, specifically the content following "Trigger:" within that field.

| Skill | Extracted Trigger Text |
|-------|------------------------|
| `ai-sdk-5` | When building AI chat interfaces, using Vercel AI SDK, streaming LLM responses, or integrating tools. |
| `django-drf` | When building REST APIs with Django - ViewSets, Serializers, Filters. |
| `electron` | When building Electron apps, working with main/renderer processes, IPC communication, or native OS integrations. |
| `elixir-antipatterns` | Durante code review, refactoring, o al escribir código Phoenix/Ecto. |
| `github-pr` | When creating PRs, writing PR descriptions, or using gh CLI for pull requests. |
| `hexagonal-architecture-java` | When designing Java services with hexagonal architecture, clean architecture, or ports-and-adapters pattern. |
| `java-21` | When writing Java 21 code, using records, sealed interfaces, or virtual threads for I/O. |
| `jira-epic` | When creating Jira epics, planning large features, or structuring work spanning multiple components. |
| `jira-task` | When creating Jira tickets, tasks, or issues for features, bugs, or enhancements. |
| `nextjs-15` | When building Next.js apps, working with app router, server/client components, or API routes. |
| `playwright` | When writing E2E tests, using Playwright, implementing page objects, or testing UI flows. |
| `pytest` | When writing Python tests, using pytest, mocking dependencies, or testing async code. |
| `react-19` | When building React components, using hooks, working with forms, or server/client components. |
| `react-native` | When building mobile apps, working with React Native components, using Expo, React Navigation, or NativeWind. |
| `smart-commit` | When the user says "commit", "smart commit", or /commit. |
| `spring-boot-3` | When building Spring Boot applications, configuring beans, or implementing REST services. |
| `tailwind-4` | When styling with Tailwind, using className, conditional styles, or dark mode. |
| `typescript` | When writing TypeScript, defining types/interfaces, or using utility types. |
| `zod-4` | When validating data, defining schemas, working with forms, or using Zod for type safety. |
| `zustand-5` | When managing global state in React, using Zustand, or implementing state slices. |

Note on `elixir-antipatterns`: the trigger sentence in the frontmatter is in Spanish
("Durante code review..."). Per project rules, ALL content MUST be in English. The trigger
line inserted in the Markdown body will be translated to English:
`During code review, refactoring, or when writing Phoenix/Ecto code.`

## Rules Section Content Specification

The following specifies the exact Rules content for each skill. These are derived from
the skill's actual patterns, anti-patterns, and constraints, not generic filler.

### ai-sdk-5
```markdown
## Rules

- This skill targets AI SDK v5 only — patterns are breaking changes from v4 (`useChat` import path, `message.parts`, `sendMessage`); do NOT mix v4 syntax
- Always use `message.parts` array iteration to render message content; never access `message.content` as a string
- Tool definitions require a Zod schema for `parameters`; untyped tool calls are not supported in v5
- Server routes must return `result.toDataStreamResponse()` for streaming to work with `useChat` transport
- Handle `error` state from `useChat` explicitly in the UI; never silently swallow streaming errors
```

### django-drf
```markdown
## Rules

- Use separate serializer classes for read, create, and update operations — never a single serializer with branching `to_representation`
- All ViewSets must declare `permission_classes` explicitly; never rely on global defaults for security-sensitive endpoints
- Filters belong in a dedicated `FilterSet` class — never add filter logic directly inside view methods
- Pagination must be configured globally in `settings.py`; per-view pagination overrides are acceptable only when requirements differ
- Test ViewSets with `APIClient` and `force_authenticate`; never bypass authentication in tests with `permission_classes = []` on the ViewSet
```

### electron
```markdown
## Rules

- All IPC communication must go through named channels defined in `preload.js` — never expose the full `ipcRenderer` object to the renderer process
- `contextIsolation: true` and `nodeIntegration: false` are required security settings; do not relax them without explicit justification
- Long-running or blocking operations (file I/O, network) belong in the main process, not the renderer
- Auto-updater events must be handled explicitly; silent failures leave users on outdated versions
- Native OS integrations (menus, trays, notifications) must be set up in the main process lifecycle, not in renderer components
```

### elixir-antipatterns
```markdown
## Rules

- This skill is a catalog of what NOT to do — every pattern here represents a code smell or anti-pattern to avoid or eliminate during review
- Apply this skill during code review and refactoring sessions, not as a guide for initial implementation
- Ecto queries must not be constructed inside business logic modules — keep query logic in dedicated query modules or Ecto schemas
- Error handling in Phoenix controllers must use pattern matching on tagged tuples (`{:ok, _}` / `{:error, _}`), not bare exceptions
- Testing anti-patterns (e.g., testing implementation details instead of behavior) are as critical to fix as runtime anti-patterns
```

### github-pr
```markdown
## Rules

- PR titles must follow conventional commit format (`type(scope): description`); vague titles like "fix bug" or "update" are rejected
- PR descriptions must include a Summary section and a Testing section at minimum
- Each PR must be logically atomic — one concern per PR; split large changes into sequential PRs
- Link related issues using `Closes #N` in the PR body to enable automatic issue closure on merge
- Never create a PR directly to `main`/`master` without a branch; always use `gh pr create` from a feature branch
```

### hexagonal-architecture-java
```markdown
## Rules

- Domain entities and use cases must have zero dependencies on framework classes (no Spring annotations, no JPA annotations inside domain)
- Ports are interfaces defined in the domain layer; adapters are implementations in the infrastructure layer — never the reverse
- Application services (use cases) orchestrate domain logic only; they must not contain persistence or HTTP concerns
- Each adapter must implement exactly one port; combining multiple ports in a single adapter class is a violation of the pattern
- Tests for use cases must use test doubles (stubs/fakes) for ports, never the real adapter implementations
```

### java-21
```markdown
## Rules

- Use `record` for all immutable data carriers (DTOs, value objects); mutable data classes with getters/setters are unnecessary in Java 21+
- Compact constructors in records are the required location for validation — never validate after construction
- Virtual threads are for I/O-bound concurrency only; CPU-bound tasks should still use platform thread pools
- `sealed interface` + `permits` is required for closed class hierarchies; open inheritance hierarchies with `instanceof` chains are an anti-pattern
- Pattern matching `switch` expressions must be exhaustive — rely on compiler enforcement rather than adding a catch-all `default`
```

### jira-epic
```markdown
## Rules

- Epics must include a high-level overview, acceptance criteria, and a task decomposition section — an epic with only a title is incomplete
- Technical diagrams (architecture, flow, component) are required for epics that span multiple system components
- Each epic must be decomposable into independently deliverable Jira tasks before it is considered ready for development
- Epic scope must be bounded — if the description spans more than one business domain, split into separate epics
- Use Jira Wiki markup syntax when formatting epic descriptions to ensure correct rendering in Jira
```

### jira-task
```markdown
## Rules

- Every task must have a clear Definition of Done — acceptance criteria stated as verifiable conditions, not vague descriptions
- Tasks that require front-end AND back-end changes must be split into separate component tasks linked under the same epic or story
- Use Jira Wiki markup for all task descriptions; plain text without formatting is not acceptable for structured tasks
- Task estimates must be included when the team uses story points or time tracking; estimateless tasks block sprint planning
- Bug tasks must include: steps to reproduce, expected behavior, and actual behavior — missing any of these is an incomplete bug report
```

### nextjs-15
```markdown
## Rules

- Server Components are the default; add `'use client'` only when the component requires browser APIs, event handlers, or React state
- Never add `'use client'` to layout or page files — this forces the entire subtree client-side and defeats Server Component benefits
- Server Actions (`'use server'`) must be the mechanism for mutations from forms; avoid client-side fetch for form submissions
- `revalidatePath` or `revalidateTag` must be called after mutations that change cached data; stale caches are a correctness bug
- `import 'server-only'` must be added to any module that accesses secrets, databases, or server-only APIs to prevent accidental client bundling
```

### playwright
```markdown
## Rules

- All selectors must use accessibility attributes (`getByRole`, `getByLabel`, `getByText`) or `data-testid`; CSS class selectors are fragile and forbidden
- Every test must be isolated — no shared mutable state between tests; use `beforeEach`/`afterEach` for setup and teardown
- Page Object Model is required for any test suite with more than 3 pages; inline selectors across multiple test files are a maintenance liability
- Assertions must use Playwright's built-in auto-waiting matchers (`toBeVisible`, `toHaveText`); manual `waitForTimeout` calls are not acceptable
- Test files must be co-located with the feature they test or placed in a dedicated `e2e/` directory — never mixed with unit test files
```

### pytest
```markdown
## Rules

- Fixtures are the required mechanism for test setup and dependency injection — never use `setUp`/`tearDown` class methods (that is unittest style)
- Use `@pytest.mark.parametrize` for data-driven tests; copy-pasted test functions that differ only in input values are a duplication anti-pattern
- Mock external dependencies (HTTP, DB, filesystem) at the boundary using `pytest-mock` or `unittest.mock.patch`; never let tests hit real external services
- Async tests require `@pytest.mark.asyncio`; forgetting the marker causes the test to pass without actually executing the coroutine
- Scope fixtures correctly (`function`, `module`, `session`) — wide-scope fixtures that mutate shared state cause test order dependencies
```

### react-19
```markdown
## Rules

- Do not add `useMemo` or `useCallback` when React Compiler is active — the compiler handles memoization automatically and manual wrapping is redundant
- `'use client'` must be applied at the lowest possible component in the tree; never mark a page or layout as a Client Component
- `forwardRef` is no longer needed — pass `ref` as a regular prop; using `forwardRef` in new React 19 code is unnecessary legacy syntax
- The `use()` hook can be called conditionally (unlike all other hooks); this is intentional and must be used instead of conditional `useContext` workarounds
- Server Actions must use `useActionState` for form state management; managing form submission state manually with `useState` + `useEffect` is the old pattern
```

### react-native
```markdown
## Rules

- Use Expo managed workflow by default for new projects; bare workflow is appropriate only when a native module unavailable in Expo is strictly required
- Navigation must be implemented with React Navigation; never use ad-hoc conditional rendering or `useState` to simulate navigation stacks
- NativeWind (Tailwind for React Native) styles must use `className` prop — never mix NativeWind with inline `style` objects on the same component
- Platform-specific code must be isolated with `Platform.select()` or `.ios.tsx`/`.android.tsx` file extensions; never use `Platform.OS` checks inline in JSX
- All async operations (permissions, storage, network) must handle loading and error states explicitly — unhandled promise rejections crash the app silently on some platforms
```

### smart-commit
```markdown
## Rules

- Never commit without first presenting the generated message summary and waiting for explicit user confirmation
- Detect and block commits that contain secrets (API keys, tokens, passwords) found by pattern matching in the diff
- Detect and warn on `console.log`, `debugger`, `TODO`, and large binary files in the staged diff before committing
- Commit messages must follow conventional commits format (`type(scope): description`); generated messages that cannot be classified must default to `chore:` with a descriptive subject
- Only staged files (`git diff --cached`) are in scope — never auto-stage unstaged files or untracked files
```

### spring-boot-3
```markdown
## Rules

- Constructor injection is mandatory — `@Autowired` field injection is forbidden; it hides dependencies and prevents unit testing without a Spring context
- Configuration must use `@ConfigurationProperties` with typed records; scattered `@Value` annotations are a maintainability anti-pattern
- `@Transactional` belongs on service methods only — never on controller methods or repository methods that already inherit transactions
- `@Transactional(readOnly = true)` must be used for all query-only service methods; it signals intent and enables database-level optimizations
- Exception handling must be centralized in a `@RestControllerAdvice` class; `try/catch` in controllers for business exceptions is a duplication anti-pattern
```

### tailwind-4
```markdown
## Rules

- Use the `cn()` utility (clsx + tailwind-merge) for all conditional class composition; string concatenation for dynamic classes causes class conflicts that tailwind-merge resolves
- Tailwind 4 uses CSS-first configuration (`@theme` in CSS) — never use `tailwind.config.js` theme extensions for new Tailwind 4 projects
- Avoid `@apply` in component CSS files; Tailwind utility classes belong in the markup, not extracted into CSS rules
- Component library classes (shadcn/ui, Radix) must not be overridden with Tailwind classes on the same element — extend via variants or wrapper elements
- Dynamic class names must be complete strings (e.g., `'text-red-500'`), never constructed by string interpolation (e.g., `` `text-${color}-500` ``) — PurgeCSS/Tailwind cannot detect partial class names
```

### typescript
```markdown
## Rules

- `any` is forbidden — use `unknown` with type guards or generics; `@ts-ignore` is only acceptable as a last resort with an explanatory comment
- Use `import type` for type-only imports to ensure they are erased at compile time and do not affect the runtime bundle
- Prefer `const` objects with `as const` over plain union types for enums and string literals — this preserves runtime values alongside the type
- Non-null assertions (`!`) require an immediately preceding null check; bare `value!` without a guard is a runtime crash waiting to happen
- Interfaces should be flat and composable — deeply nested inline type definitions inside other types are a readability and reusability anti-pattern
```

### zod-4
```markdown
## Rules

- This skill targets Zod v4 specifically — `z.string().email()` and other validators changed in v4; verify the installed version before applying patterns
- Define schemas as named constants, not inline — reusing schema definitions ensures consistency between validation and TypeScript type inference
- Use `z.infer<typeof Schema>` to derive TypeScript types from schemas; manually duplicating types alongside schemas causes drift
- `safeParse` is required for user input validation — `parse` throws by default and must only be used when an exception is the correct error handling strategy
- Zod schemas for form validation must be defined outside the component to avoid recreation on every render
```

### zustand-5
```markdown
## Rules

- Stores must be split by domain concern (auth store, cart store, UI store) — a single global store that grows without bound is a maintenance anti-pattern
- Always use selectors to subscribe to specific state slices (`useStore(s => s.count)`) — subscribing to the full store object causes unnecessary re-renders on any state change
- Persist middleware (`zustand/middleware`) must be applied only to stores that genuinely need persistence; over-persisting creates stale-state bugs after schema changes
- Store actions must be defined inside the `create` callback, not as external functions that receive the store as a parameter
- Zustand 5 uses `useShallow` for object selectors to prevent re-renders when returned object references change — wrap object selectors with `useShallow`
```

### claude-code-expert (Rules only — Triggers already present)
```markdown
## Rules

- This skill is authoritative for Claude Code configuration only — it does not govern project-level code architecture or language-specific patterns
- CLAUDE.md at the user level (`~/.claude/CLAUDE.md`) applies globally to all sessions; project-level CLAUDE.md overrides or extends it for a specific project
- Skills must be directories with a single `SKILL.md` entry point — never use flat `.md` files directly in the skills directory
- Hooks in `settings.json` must be idempotent — hooks that fail loudly on every run (e.g., lint errors) will interrupt normal Claude Code operation
- MCP server tokens and secrets must be stored as environment variables referenced by `${VAR_NAME}` in `.mcp.json`; never hardcode credentials
```

### excel-expert (Rules only — Triggers already present)
```markdown
## Rules

- Choose the library based on the use case before writing code: ExcelJS for full formatting control, SheetJS for fast read/write with minimal dependencies, pandas/openpyxl for Python data analysis pipelines
- Always close workbook streams after reading or writing; unclosed file handles cause process-level resource leaks in long-running Node.js or Python services
- Column indices in ExcelJS are 1-based, not 0-based — off-by-one errors are the most common bug when building dynamic column layouts
- Never build Excel files by string-concatenating XML — always use the library's API; raw XML manipulation bypasses format validation and corrupts files
- Validate input data types before writing to cells; writing a JavaScript object reference where a string is expected produces `[object Object]` silently in the output file
```

### image-ocr (Rules only — Triggers already present)
```markdown
## Rules

- Select the OCR engine based on the document type and accuracy requirements before writing code: Tesseract for local/offline simple documents, EasyOCR for multilingual handwriting, cloud APIs (Google Vision, AWS Textract) for production accuracy on structured documents
- Image preprocessing (grayscale conversion, binarization, deskew) is required before Tesseract and EasyOCR for non-ideal inputs — skipping it causes significant accuracy degradation
- OCR output must always be treated as unvalidated text — apply post-processing (regex, string normalization) before using extracted values in business logic
- Never pass sensitive document images to cloud OCR APIs without confirming data privacy and compliance requirements with the project owner
- Confidence scores from the OCR engine must be checked; results below the project-defined threshold must be flagged for human review rather than accepted automatically
```

## File Change Matrix

### Batch 1 — Frontend / React (6 files)

| File | Action | What is added |
|------|--------|---------------|
| `skills/react-19/SKILL.md` | Modify | Add `**Triggers**` line after `## When to Use` header; append `## Rules` at end |
| `skills/nextjs-15/SKILL.md` | Modify | Add `**Triggers**` line after `## When to Use` header; append `## Rules` at end |
| `skills/typescript/SKILL.md` | Modify | Add `**Triggers**` line after `## When to Use` header; append `## Rules` at end |
| `skills/tailwind-4/SKILL.md` | Modify | Add `**Triggers**` line after `## When to Use` header; append `## Rules` at end |
| `skills/zustand-5/SKILL.md` | Modify | Add `**Triggers**` line after `## When to Use` header; append `## Rules` at end |
| `skills/zod-4/SKILL.md` | Modify | Add `**Triggers**` line after `## When to Use` header; append `## Rules` at end |

### Batch 2 — AI / Mobile / Desktop (5 files)

| File | Action | What is added |
|------|--------|---------------|
| `skills/ai-sdk-5/SKILL.md` | Modify | Add `**Triggers**` line after `## When to Use` header; append `## Rules` at end |
| `skills/react-native/SKILL.md` | Modify | Add `**Triggers**` line after `## When to Use` header; append `## Rules` at end |
| `skills/electron/SKILL.md` | Modify | Add `**Triggers**` line after `## When to Use` header; append `## Rules` at end |
| `skills/claude-code-expert/SKILL.md` | Modify | Append `## Rules` at end only (Triggers present) |
| `skills/excel-expert/SKILL.md` | Modify | Append `## Rules` at end only (Triggers present) |

### Batch 3 — Backend / Java (6 files)

| File | Action | What is added |
|------|--------|---------------|
| `skills/django-drf/SKILL.md` | Modify | Add `**Triggers**` line after frontmatter (no blockquote — insert after H1 line); append `## Rules` at end |
| `skills/spring-boot-3/SKILL.md` | Modify | Add `**Triggers**` line after `## When to Use` header; append `## Rules` at end |
| `skills/java-21/SKILL.md` | Modify | Add `**Triggers**` line after `## When to Use` header; append `## Rules` at end |
| `skills/hexagonal-architecture-java/SKILL.md` | Modify | Add `**Triggers**` line after `## When to Use` header; append `## Rules` at end |
| `skills/elixir-antipatterns/SKILL.md` | Modify | Add `**Triggers**` line (English translation) after `## When to Use` header; append `## Rules` at end |
| `skills/image-ocr/SKILL.md` | Modify | Append `## Rules` at end only (Triggers present) |

### Batch 4 — Testing / Tooling / Process (6 files)

| File | Action | What is added |
|------|--------|---------------|
| `skills/playwright/SKILL.md` | Modify | Add `**Triggers**` line after `## When to Use` header; append `## Rules` at end |
| `skills/pytest/SKILL.md` | Modify | Add `**Triggers**` line after `## When to Use` header; append `## Rules` at end |
| `skills/github-pr/SKILL.md` | Modify | Add `**Triggers**` line after `## When to Use` header; append `## Rules` at end |
| `skills/jira-task/SKILL.md` | Modify | Add `**Triggers**` line after `## When to Use` header; append `## Rules` at end |
| `skills/jira-epic/SKILL.md` | Modify | Add `**Triggers**` line after `## When to Use` header; append `## Rules` at end |
| `skills/smart-commit/SKILL.md` | Modify | Add `**Triggers**` line after `## When to Use` header; append `## Rules` at end |

## Trigger Insertion Algorithm

For each skill file, the sub-agent follows this decision tree:

```
Read SKILL.md
      │
      ▼
Does the file have a `## When to Use` section?
      │
      ├── YES → Insert **Triggers** line immediately after the `## When to Use` line
      │          (before the first bullet or paragraph in that section)
      │
      └── NO  → Does the file have a `> ...` blockquote after the H1?
                      │
                      ├── YES → Insert **Triggers** line after the blockquote block
                      │
                      └── NO  → Insert **Triggers** line after the H1 heading line
```

Note: `django-drf` has no `## When to Use` and no blockquote — it goes straight to
`## ViewSet Pattern` after the frontmatter. Triggers line is inserted before
`## ViewSet Pattern`.

## Interfaces and Contracts

No new interfaces or contracts are required. The change is purely textual (Markdown).

The audit dimensions that will be satisfied post-apply:

**D9-3 structural completeness check (from project-audit)**:
- Pattern looked for: `**Triggers**` line present in SKILL.md body
- Pattern looked for: `## Rules` section present in SKILL.md
- All 23 tech skills will have both after apply

**D10-b structural quality check (from project-audit)**:
- Feature docs completeness: SKILL.md files counted as complete when they have
  trigger definition + process/content sections + rules section
- All 23 tech skills will pass after apply

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Structural verify | `grep -r "^\*\*Triggers\*\*" ~/.claude/skills/` returns ≥ 23 hits | bash (post-install) |
| Structural verify | `grep -r "^## Rules" ~/.claude/skills/` returns hits for all 23 tech skills | bash (post-install) |
| Integration | `/project-audit` D9-3 dimension passes with no structural failures | /project-audit skill |
| Integration | `/project-audit` D10-b dimension passes or improves | /project-audit skill |
| Deploy verify | `install.sh` exits 0 and deploys to `~/.claude/skills/` | bash |

Verification must be run against `~/.claude/skills/` (the runtime location after
`install.sh`), not against the repo `skills/` directory.

## Migration Plan

No data migration required. All changes are additive Markdown text edits.

## Apply Batch Summary

```
Batch 1 (Frontend/React):   react-19, nextjs-15, typescript, tailwind-4, zustand-5, zod-4
Batch 2 (AI/Mobile/Desktop): ai-sdk-5, react-native, electron, claude-code-expert, excel-expert
Batch 3 (Backend/Java):     django-drf, spring-boot-3, java-21, hexagonal-architecture-java,
                             elixir-antipatterns, image-ocr
Batch 4 (Testing/Tooling):  playwright, pytest, github-pr, jira-task, jira-epic, smart-commit
```

After all 4 batches complete:
1. Run `bash install.sh` to deploy to `~/.claude/`
2. Run `/project-audit` to verify D9-3 and D10-b
3. Run `git commit` with message: `feat(skills): normalize tech skill structure — add Triggers and Rules to 23 skills`

## Open Questions

None.
