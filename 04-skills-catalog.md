# 04. Skills Catalog - 39 Skills in detail

> ⚠️ **UNOFFICIAL THIRD-PARTY DOCUMENTATION**
> NOT official BMad docs. See [DISCLAIMER.md](DISCLAIMER.md) | Licensed MIT — see [LICENSE](LICENSE) and [NOTICE](NOTICE)
> Official BMAD-METHOD: <https://github.com/bmad-code-org/BMAD-METHOD>

---

> A detailed catalog of all 39 BMad skills: 12 core + 27 BMM (4 phases). For each skill: purpose, input, output, workflow, sub-skill invocation.

---

## Table of Contents

- [Part I: 12 Core Skills](#part-i-12-core-skills)
- [Part II: 27 BMM Skills](#part-ii-27-bmm-skills)
  - [Phase 1: Analysis (5 skills)](#phase-1-analysis-5-skills)
  - [Phase 2: Plan-Workflows (6 skills)](#phase-2-plan-workflows-6-skills)
  - [Phase 3: Solutioning (5 skills)](#phase-3-solutioning-5-skills)
  - [Phase 4: Implementation (11 skills)](#phase-4-implementation-11-skills)
- [Pattern summary](#pattern-summary)

---

## Part I: 12 Core Skills

Core skills are used across every phase and are not bound to a specific point in the lifecycle.

Location: `src/core-skills/`

### C-1. bmad-advanced-elicitation

| Attribute | Value |
|-----------|---------|
| **Purpose** | Push the LLM to re-examine its output via a specific reasoning method (pre-mortem, first principles, red team, Socratic...) |
| **When to use** | After the AI produces content and the user wants to "dig deeper" or mentions a critique method |
| **Input** | Current section content + methods.csv + agent roster (if party-mode) |
| **Output** | Enhanced content section |
| **Sub-skills** | None |
| **Template/resources** | `methods.csv` (28+ reasoning methods) |
| **Pattern** | Menu-driven (1-5, r=reshuffle, a=all, x=proceed) |

**Notable methods:**
- Pre-mortem Analysis, First Principles, Inversion
- Red Team vs Blue Team, Socratic Questioning
- Constraint Removal, Stakeholder Mapping
- Analogical Reasoning

**Workflow:**
1. Load methods.csv + agent roster (if party-mode enabled)
2. Present 5 selected methods + menu
3. User picks → execute method → display enhanced version
4. Ask apply changes? → re-present menu or return

---

### C-2. bmad-brainstorming

| Attribute | Value |
|-----------|---------|
| **Purpose** | Facilitate brainstorming sessions using 30+ creative techniques |
| **When to use** | "help me brainstorm", "help me ideate" |
| **Input** | Project context + optional context_file |
| **Output** | `{output_folder}/brainstorming/brainstorming-session-{date}-{time}.md` |
| **Sub-skills** | None (internal step files) |
| **Template/resources** | `brain-methods.csv`, `template.md`, 8 step files |
| **Pattern** | Micro-file architecture, 4 branching options |

**Steps:**
```
step-01-session-setup → check continuation?
  ├─ step-01b-continue (resume)
  ├─ step-02a-user-selected (manual pick)
  ├─ step-02b-ai-recommended (AI suggests)
  ├─ step-02c-random-selection (random)
  └─ step-02d-progressive-flow (progressive)
      ↓
step-03-technique-execution
      ↓
step-04-idea-organization
```

**Special notes:**
- Anti-bias protocol: shift domain every 10 ideas
- Quantity goal: 100+ ideas before organizing

---

### C-3. bmad-customize

| Attribute | Value |
|-----------|---------|
| **Purpose** | Author override TOML for agent/workflow customization |
| **When to use** | "customize bmad", "override a skill", "change agent behavior" |
| **Input** | Project root (contains `_bmad/`), user intent, target skill's `customize.toml` |
| **Output** | Override file: `_bmad/custom/{skill-name}.toml` or `.user.toml` |
| **Sub-skills** | `list_customizable_skills.py` (Python script, not a skill invocation) |
| **Template/resources** | `customize.toml` blueprint, `resolve_customization.py` |
| **Pattern** | 6-step interactive flow |

**Steps:**
1. Preflight — check `_bmad/`, resolver script
2. Classify intent — Directed/Exploratory/Audit/Cross-cutting
3. Discovery — list customizable skills (if exploratory)
4. Determine surface — agent vs workflow
5. Compose override — translate plain-English → TOML
6. Team vs user placement → show, confirm, write, verify

---

### C-4. bmad-distillator

| Attribute | Value |
|-----------|---------|
| **Purpose** | Lossless compression of documents for efficient LLM consumption |
| **When to use** | "distill documents", "create a distillate" |
| **Input** | source_documents (required), downstream_consumer, token_budget, output_path, --validate |
| **Output** | A single `-distillate.md` (≤5K tokens) or split folder `-distillate/` |
| **Sub-skills** | 2 sub-agents via the Agent tool (`distillate-compressor.md`, `round-trip-reconstructor.md`) |
| **Template/resources** | `resources/compression-rules.md`, `resources/distillate-format-reference.md`, `resources/splitting-strategy.md` |
| **Pattern** | 4 stages, fan-out spawning for large inputs |

**Stages:**
1. Analyze — run `analyze_sources.py`, get routing recommendation
2. Compress — spawn compressor sub-agent(s) (parallel if fan-out)
3. Verify & Output — completeness check, format check, save
4. Round-Trip Validate (optional, `--validate`)

**Special notes:**
- Compression ≠ Summarization (lossless, reversible)
- Graceful degradation if a sub-agent is unavailable

---

### C-5. bmad-editorial-review-prose

| Attribute | Value |
|-----------|---------|
| **Purpose** | Copy-editor review of text for communication issues (clarity, readability) |
| **When to use** | "review for prose", "improve the prose" |
| **Input** | content (≥3 words), style_guide (optional, override), reader_type (`humans`/`llm`) |
| **Output** | 3-column table [Original \| Revised \| Changes] or "No issues" |
| **Sub-skills** | None |
| **Template/resources** | Microsoft Writing Style Guide (baseline) |
| **Pattern** | Single-pass review with structured output |

**Special notes:**
- **CONTENT IS SACROSANCT** — don't challenge ideas, only how they're expressed
- Different reader_type: `humans` vs `llm` (LLMs need unambiguous references, structured format)

---

### C-6. bmad-editorial-review-structure

| Attribute | Value |
|-----------|---------|
| **Purpose** | Structural editor proposing cuts/reorg/simplification while preserving comprehension |
| **When to use** | "structural review" — **run BEFORE copy-edit** |
| **Input** | content, style_guide, purpose, target_audience, reader_type, length_target |
| **Output** | Recommendations (CUT/MERGE/MOVE/CONDENSE/QUESTION/PRESERVE) with rationale |
| **Sub-skills** | None |
| **Template/resources** | 5 structure models (Tutorial, Reference, Explanation, Prompt/Task, Strategic) |
| **Pattern** | Multi-step analytical |

**Flow:**
1. Validate input
2. Understand purpose (inferred or provided)
3. Structural analysis (map sections, pick model)
4. Flow analysis (reader journey, pacing)
5. Generate prioritized recommendations
6. Output

---

### C-7. bmad-help

| Attribute | Value |
|-----------|---------|
| **Purpose** | Analyze state + recommend next skill(s) or answer BMad Q&A |
| **When to use** | "help", "what to do next", "what to start with" |
| **Input** | Catalog (`_bmad/_config/bmad-help.csv`), config, artifacts, llms.txt |
| **Output** | Orientation + skill recommendation + quick-start offer |
| **Sub-skills** | None (references others) |
| **Template/resources** | `bmad-help.csv`, `llms.txt` (module docs) |
| **Pattern** | Catalog-driven routing |

**Logic:**
1. Parse catalog → skill descriptions, phases, dependencies
2. Scan artifacts → determine current progress
3. Recommend the next required step + optional items
4. Present in the `communication_language`
5. Offer to run a single skill if the next step is clear

**Catalog fields:**
- `phases`: "anytime" or a phase number
- `dependencies`: `after: [skill-x]`, `before: [skill-y]`
- `required: true/false` — gates that block progression

---

### C-8. bmad-index-docs

| Attribute | Value |
|-----------|---------|
| **Purpose** | Generate/update `index.md` for a docs folder |
| **When to use** | "create or update an index of all files" |
| **Input** | Target directory path |
| **Output** | `index.md` with organized file listings |
| **Sub-skills** | None |
| **Template/resources** | None specific |
| **Pattern** | Scan → group → describe → write |

**Rules:**
- Relative paths `./`
- Alphabetical within each group
- Skip hidden files
- 3-10 words description per file

---

### C-9. bmad-party-mode

| Attribute | Value |
|-----------|---------|
| **Purpose** | Multi-agent orchestrated discussions (real subagents via the Agent tool) |
| **When to use** | "party mode", "multi-agent conversation", "group discussion", "roundtable" |
| **Input** | `--model` (optional force model), `--solo` (roleplay mode), agent roster, project context |
| **Output** | Full agent responses (unabridged, in each agent's own voice) |
| **Sub-skills** | Spawns agents via the Agent tool |
| **Template/resources** | Agent persona templates |
| **Pattern** | Parallel subagent spawning |

**Modes:**
- **SUBAGENT MODE** — each agent is real and thinks independently (via the Agent tool)
- **SOLO MODE** (`--solo`) — roleplay all agents yourself (single LLM)

**Core loop:**
1. Parse arguments
2. Load agent roster + project context
3. Welcome user, show roster
4. Pick 2-4 relevant agents per round
5. Spawn subagents in parallel
6. Present responses (full, not blended)
7. Handle follow-ups

**Rules:**
- Never blend/paraphrase agent responses
- Context summary < 400 words per round
- Rotate agents (don't let the same 2 dominate)

---

### C-10. bmad-review-adversarial-general

| Attribute | Value |
|-----------|---------|
| **Purpose** | Cynical review + produce ≥10 findings |
| **When to use** | "review something", "critical review" |
| **Input** | content (diff/spec/story/doc), also_consider (optional) |
| **Output** | Markdown list, findings only (no approval) |
| **Sub-skills** | None |
| **Template/resources** | None |
| **Pattern** | Single-pass adversarial |

**Rules:**
- HALT if zero findings (suspicious, re-analyze)
- Attitude: cynical, jaded, skeptical of everything
- Find AT LEAST 10 issues

---

### C-11. bmad-review-edge-case-hunter

| Attribute | Value |
|-----------|---------|
| **Purpose** | Walk every branching path + boundary, report ONLY unhandled edge cases |
| **When to use** | "edge-case analysis of code, specs, or diffs" |
| **Input** | content (diff/file/function), also_consider (optional) |
| **Output** | JSON array of unhandled paths |
| **Sub-skills** | None |
| **Template/resources** | Strict JSON format |
| **Pattern** | Exhaustive path analysis |

**JSON format:**
```json
[{
  "location": "file:line-range",
  "trigger_condition": "max 15 words",
  "guard_snippet": "minimal code that closes gap",
  "potential_consequence": "max 15 words"
}]
```

**Difference from adversarial-general:** method-driven (path walking), not attitude-driven. An orthogonal skill.

**Edge classes checked:**
- Missing else/default
- Null/empty inputs, off-by-one, overflow
- Type coercion, race conditions, timeouts

---

### C-12. bmad-shard-doc

| Attribute | Value |
|-----------|---------|
| **Purpose** | Split a large markdown file (based on level-2 sections) |
| **When to use** | "perform shard document" |
| **Input** | Source .md path |
| **Output** | Destination folder + index.md |
| **Sub-skills** | External CLI: `npx @kayvan/markdown-tree-parser` |
| **Template/resources** | Tool output |
| **Pattern** | External tool invocation |

**Flow:**
1. Get source document (verify .md)
2. Get destination folder (default: folder named after the source)
3. Execute `markdown-tree-parser explode`
4. Verify output
5. Handle original (Delete/Move/Keep) — **Delete recommended**

---

## Part II: 27 BMM Skills

Location: `src/bmm-skills/`

### Phase 1: Analysis (5 skills)

#### 1-1. bmad-agent-analyst (Mary 📊)

| Attribute | Value |
|-----------|---------|
| **Type** | Agent persona |
| **Role** | Business Analyst |
| **Purpose** | Strategic analysis, market research, competitive analysis, requirements elicitation |
| **When to use** | "talk to Mary", "request the business analyst" |
| **Customize.toml** | persona + menu |
| **Menu skills** | BD (brainstorming), PB (product-brief), PF (prfaq), DP (document-project) |

**Persona:**
- Style: "Treasure hunter narrating the find"
- Principles: Porter's rigor, Minto's Pyramid Principle, verifiable evidence

---

#### 1-2. bmad-agent-tech-writer (Paige 📚)

| Attribute | Value |
|-----------|---------|
| **Type** | Agent persona |
| **Role** | Technical Writer |
| **Purpose** | Documentation specialist, DITA/OpenAPI/Mermaid master |
| **When to use** | "talk to Paige", "request the tech writer" |
| **Menu skills** | Documentation-focused |

**Persona:**
- Style: "Patient teacher with apt analogies"
- Principles: Diagrams > prose when they carry signal, every word earns its place

---

#### 1-3. bmad-document-project

| Attribute | Value |
|-----------|---------|
| **Type** | Workflow |
| **Purpose** | Document brownfield projects for AI context |
| **When to use** | "document this project", "generate project docs" |
| **Input** | Config + project structure |
| **Output** | Project documentation (per instructions.md) |
| **Sub-skills** | Internal (`instructions.md`) |
| **Pattern** | Discovery + structured docs |

**Deep purpose:** When applying BMad to an existing project (brownfield), the AI needs to understand the codebase. This skill produces docs from code.

---

#### 1-4. bmad-prfaq

| Attribute | Value |
|-----------|---------|
| **Type** | Workflow (5 stages) |
| **Purpose** | Amazon's Working Backwards PRFAQ — press release + FAQ |
| **When to use** | "create a PRFAQ", "work backwards", "run the PRFAQ challenge" |
| **Input** | Customer, problem, stakes, solution concept |
| **Output** | `{planning_artifacts}/prfaq-{project_name}.md` + optional distillate |
| **Sub-skills** | `artifact-analyzer.md`, `web-researcher.md` (sub-agents) |
| **Template/resources** | `prfaq-template.md`, `press-release.md`, `customer-faq.md`, `internal-faq.md`, `verdict.md` |
| **Pattern** | 5 stages |

**5 stages:**
1. **Ignition** — raw concept → customer-first thinking
2. **Press Release** — iterative drafting with hard coaching
3. **Customer FAQ** — devil's advocate questions
4. **Internal FAQ** — skeptical stakeholder questions
5. **Verdict** — synthesis, strength assessment

**Flags:** `--headless` / `-H` (autonomous first-draft).

---

#### 1-5. bmad-product-brief

| Attribute | Value |
|-----------|---------|
| **Type** | Workflow (5 stages) |
| **Purpose** | Create an executive summary product brief (1-2 pages) |
| **When to use** | "create or update a Product Brief" |
| **Input** | Product/project description, existing docs, competitive context |
| **Output** | `{planning_artifacts}/brief-{name}.md` + optional distillate |
| **Sub-skills** | `artifact-analyzer.md`, `web-researcher.md`, review sub-agents |
| **Template/resources** | contextual-discovery.md, guided-elicitation.md, draft-and-review.md, finalize.md |
| **Modes** | `--autonomous`/`-A`, `--yolo`, default guided |

**Stages:**
1. Understand Intent
2. Contextual Discovery (fan-out sub-agents)
3. Guided Elicitation
4. Draft & Review (fan-out review sub-agents)
5. Finalize

---

### Phase 2: Plan-Workflows (6 skills)

#### 2-1. bmad-agent-pm (John 📋)

| Attribute | Value |
|-----------|---------|
| **Type** | Agent persona |
| **Role** | Product Manager |
| **Purpose** | Drive PRD creation, user interviews, stakeholder alignment |
| **Menu skills** | CP (create-prd), EP (edit-prd), VP (validate-prd), CI (check-implementation-readiness) |

**Persona:**
- Style: "Detective interrogating a cold case"
- Principles: Jobs-to-be-Done, user value first, tech feasibility as a constraint

---

#### 2-2. bmad-agent-ux-designer (Sally 🎨)

| Attribute | Value |
|-----------|---------|
| **Type** | Agent persona |
| **Role** | UX Designer |
| **Purpose** | UX specs, interaction design, accessibility |
| **Menu skills** | CU (create-ux-design) + related |

**Persona:**
- Style: "Filmmaker pitching the scene before code exists"
- Principles: Empathy + edge-case rigor, user need first

---

#### 2-3. bmad-create-prd

| Attribute | Value |
|-----------|---------|
| **Type** | Workflow (step-file architecture) |
| **Purpose** | Create a comprehensive PRD |
| **When to use** | "let's create a product requirements document" |
| **Input** | Config + Product Brief / PRFAQ (if any) |
| **Output** | `{planning_artifacts}/prd.md` |
| **Sub-skills** | Internal step files (no external invocation) |
| **Template/resources** | `steps-c/` directory |
| **Pattern** | Micro-file with state tracking |

**Critical rules:**
- NEVER load multiple steps
- ALWAYS read the entire step before executing
- Update frontmatter state after each step
- HALT at menus, wait for input

---

#### 2-4. bmad-create-ux-design

| Attribute | Value |
|-----------|---------|
| **Type** | Workflow (micro-file) |
| **Purpose** | Plan UX patterns + design specifications |
| **When to use** | "let's create UX design", "help me plan the UX" |
| **Input** | PRD, project context |
| **Output** | `{planning_artifacts}/ux-design-specification.md` |
| **Sub-skills** | Internal step files |
| **Template/resources** | `steps/` directory, `ux-design-template.md` |

---

#### 2-5. bmad-edit-prd

| Attribute | Value |
|-----------|---------|
| **Type** | Workflow (step-file) |
| **Purpose** | Edit + enhance an existing PRD |
| **When to use** | "edit this PRD" |
| **Input** | Existing PRD path |
| **Output** | Updated PRD |
| **Pattern** | `steps-e/` (E-prefixed for edit mode) |

---

#### 2-6. bmad-validate-prd

| Attribute | Value |
|-----------|---------|
| **Type** | Workflow (step-file) |
| **Purpose** | Validate a PRD against BMAD standards |
| **When to use** | "validate this PRD" |
| **Input** | PRD path |
| **Output** | Validation report |
| **Pattern** | `steps-v/` (V-prefixed for validate mode) |

**Quality gate** before passing to Solutioning.

---

### Phase 3: Solutioning (5 skills)

#### 3-1. bmad-agent-architect (Winston 🏗️)

| Attribute | Value |
|-----------|---------|
| **Type** | Agent persona |
| **Role** | System Architect |
| **Menu skills** | CA (create-architecture), CE (create-epics-and-stories), GP (generate-project-context), CI (check-implementation-readiness) |

**Persona:**
- Style: "Seasoned engineer at the whiteboard, measured, trade-offs over verdicts"
- Principles: Boring technology for stability, developer productivity as architecture

---

#### 3-2. bmad-check-implementation-readiness

| Attribute | Value |
|-----------|---------|
| **Type** | Workflow (step-file) |
| **Purpose** | Validate that PRD + UX + Architecture + Epics are complete and aligned BEFORE Phase 4 |
| **When to use** | "check implementation readiness" |
| **Input** | PRD, UX, Architecture, Epics, Stories (ALL required) |
| **Output** | Readiness report |
| **Pattern** | `steps/` directory, checklist-driven |

**Role:** An expert PM spotting gaps. A quality gate before development.

---

#### 3-3. bmad-create-architecture

| Attribute | Value |
|-----------|---------|
| **Type** | Workflow (micro-file) |
| **Purpose** | Collaborative step-by-step architecture discovery |
| **When to use** | "let's create architecture", "create technical architecture" |
| **Input** | PRD, UX, project context |
| **Output** | `{planning_artifacts}/architecture.md` |
| **Sub-skills** | Internal step files |
| **Template/resources** | `architecture-decision-template.md`, `steps/` |
| **Pattern** | Partnership facilitation |

**Special notes:**
- "Partnership, not client-vendor"
- Collaborative with a peer (the user is a peer, not a client)
- Prevent implementation conflicts (multiple agents shouldn't use REST and GraphQL simultaneously)

---

#### 3-4. bmad-create-epics-and-stories

| Attribute | Value |
|-----------|---------|
| **Type** | Workflow (step-file) |
| **Purpose** | Break requirements → epics + stories organized by user value |
| **When to use** | "create the epics and stories list" |
| **Input** | PRD, Architecture, UX (ALL required) |
| **Output** | `{planning_artifacts}/epics.md` |
| **Pattern** | `steps/`, BDD-formatted ACs |

**Special notes:**
- BDD-formatted acceptance criteria
- Source hints pointing back to the PRD/Architecture (traceability)
- Requirements decomposition expertise

---

#### 3-5. bmad-generate-project-context

| Attribute | Value |
|-----------|---------|
| **Type** | Workflow (micro-file) |
| **Purpose** | Create a `project-context.md` with critical rules AI agents MUST follow |
| **When to use** | "generate project context", "create project context" |
| **Input** | Architecture, previous implementations, patterns |
| **Output** | `{output_folder}/project-context.md` |
| **Template/resources** | `project-context-template.md` |
| **Pattern** | LLM-optimized (lean) |

**Special notes:**
- Focus on "do NOT forget" items
- Prevent common implementation mistakes
- Shorter than Architecture but critical for the dev agent

---

### Phase 4: Implementation (11 skills)

#### 4-1. bmad-agent-dev (Amelia 💻)

| Attribute | Value |
|-----------|---------|
| **Type** | Agent persona |
| **Role** | Senior Software Engineer |
| **Menu skills** | DS (dev-story), QD (quick-dev), CR (code-review), CP (checkpoint-preview), CC (correct-course) |

**Persona:**
- Style: "Terminal prompt — exact file paths, AC IDs, commit-message brevity"
- Principles: Test-first (red-green-refactor), 100% pass before review

---

#### 4-2. bmad-checkpoint-preview

| Attribute | Value |
|-----------|---------|
| **Type** | Workflow |
| **Purpose** | LLM-assisted human-in-the-loop review guide (purpose → context → details) |
| **When to use** | "checkpoint", "human review", "walk me through this change" |
| **Input** | Change context (diff, branch, git) |
| **Output** | Structured review guidance |
| **Pattern** | `steps/`, front-load-then-shut-up |

**5-step walkthrough:**
1. **Orientation** — intent summary, stats (files, modules, lines)
2. **Walkthrough** — organized by concern (not file order), "why this approach" + clickable stops
3. **Detail Pass** — 2-5 high-risk spots, tagged by risk ([auth], [schema], [billing])
4. **Testing** — 2-5 manual observations to build confidence
5. **Wrap-Up** — Approve / rework / discuss

**Interactive:**
- Can invoke other tools mid-walk ("run code review on error handling", "party mode on schema")
- If the spec has a "Suggested Review Order", use it

---

#### 4-3. bmad-code-review

| Attribute | Value |
|-----------|---------|
| **Type** | Workflow |
| **Purpose** | Adversarial code review with parallel layers |
| **When to use** | "run code review", "review this code" |
| **Input** | Code changes/diff |
| **Output** | Structured findings + triage |
| **Sub-skills** | workflow.md invokes Blind Hunter, Edge Case Hunter, Acceptance Auditor (parallel) |
| **Pattern** | Parallel multi-layer review |

**Special notes:**
- 3 parallel layers:
  - **Blind Hunter** — find issues without having the spec
  - **Edge Case Hunter** — boundary conditions (reuses C-11)
  - **Acceptance Auditor** — verify ACs met
- Structured triage into action categories
- Recommend running with a **different LLM** from the implementer

---

#### 4-4. bmad-correct-course

| Attribute | Value |
|-----------|---------|
| **Type** | Workflow (XML-formatted) |
| **Purpose** | Manage significant mid-sprint changes |
| **When to use** | "correct course", "propose sprint change" |
| **Input** | PRD (required), Epics+Stories (required), Architecture+UX (optional), change trigger |
| **Output** | `{planning_artifacts}/sprint-change-proposal-{date}.md` |
| **Sub-skills** | `checklist.md` (analysis checklist) |
| **Modes** | Incremental (collaborative) vs Batch (all at once) |

**5-step flow:**
1. Initialize change navigation (gather trigger, doc access, mode preference)
2. Execute the change analysis checklist (interactive)
3. Draft specific change proposals
4. Generate the Sprint Change Proposal (issue summary, impact, approach, changes, handoff)
5. Finalize + route implementation

**Scope classification:**
- **Minor** → direct dev
- **Moderate** → backlog
- **Major** → epic review

---

#### 4-5. bmad-create-story

| Attribute | Value |
|-----------|---------|
| **Type** | Workflow (XML-formatted, 6 steps) |
| **Purpose** | Create a story file with ALL the context the developer needs |
| **When to use** | "create the next story", "create story [id]" |
| **Input** | sprint-status.yaml OR story ID, Epics, PRD, Architecture, UX |
| **Output** | `{implementation_artifacts}/{epic}-{story}-{title}.md` + updated sprint-status.yaml |
| **Sub-skills** | `discover-inputs.md` (artifact loading) |
| **Template/resources** | `template.md` |
| **Pattern** | Exhaustive pre-dev preparation |

**6 steps:**
1. Determine target story (sprint-status or user input)
2. Load + analyze core artifacts (epics, PRD, architecture, UX + lessons from the previous story + git patterns)
3. Architecture analysis (guardrails)
4. Web research (latest tech, versions, prevent outdated implementations)
5. Create story file from the template
6. Update sprint-status.yaml to `ready-for-dev`

**Deep purpose:** ZERO LLM mistakes — prevent:
- Reinventing wheels
- Wrong libraries
- Wrong file locations
- Regressions
- Vague implementations

---

#### 4-6. bmad-dev-story

| Attribute | Value |
|-----------|---------|
| **Type** | Workflow (XML inline, 10 steps) |
| **Purpose** | Execute story implementation with TDD discipline |
| **When to use** | "dev this story [file]", "implement the next story in sprint plan" |
| **Input** | Story file (from create-story) or auto-discovered from sprint-status |
| **Output** | Code implementation + updated story file |
| **Sub-skills** | Internal XML workflow |
| **Pattern** | 10 steps with the RED-GREEN-REFACTOR cycle |

**10 steps:**
1. Find the next ready story + load it
2. Load project context + story information
3. Detect review continuation + extract review context
4. Mark story in-progress
5. Implement the task following RED-GREEN-REFACTOR
6. Author comprehensive tests
7. Run validations + tests
8. Validate + mark task complete (ONLY when fully done)
9. Story completion + mark for review
10. Completion communication + user support

**Critical rules:**
- Execute ALL steps in exact order, DO NOT skip
- Do NOT stop for "milestones" — continue until COMPLETE
- NEVER mark a task complete if NOT all validations pass
- NO LYING OR CHEATING on validation

---

#### 4-7. bmad-qa-generate-e2e-tests

| Attribute | Value |
|-----------|---------|
| **Type** | Workflow |
| **Purpose** | Generate automated API + E2E tests for implemented code |
| **When to use** | "create qa automated tests for [feature]" |
| **Input** | Implemented code |
| **Output** | Test files + summary (`{implementation_artifacts}/tests/test-summary.md`) |
| **Pattern** | Detect framework → generate tests → run → summary |

**Rules:**
- Use the project's existing test framework (don't introduce a new one)
- Happy path + 1-2 error cases per test
- Tests linear + simple
- Verify tests pass before handoff

---

#### 4-8. bmad-quick-dev

| Attribute | Value |
|-----------|---------|
| **Type** | Workflow |
| **Purpose** | Implements any user intent following the project's existing patterns |
| **When to use** | "build", "fix", "tweak", "refactor", "add", "modify" |
| **Input** | User description of the change |
| **Output** | Code artifacts |
| **Pattern** | Flexible |

**Deep purpose:** The Quick Flow path (bypasses formal PRD/Architecture/Story).
Suitable for: 1-15 stories, bug fixes, small features, established projects.

---

#### 4-9. bmad-retrospective

| Attribute | Value |
|-----------|---------|
| **Type** | Workflow (12 steps with agent dialogue) |
| **Purpose** | Post-epic review with party-mode facilitation |
| **When to use** | "run a retrospective", "lets retro the epic" |
| **Input** | sprint-status.yaml, epic number, story files, PRD/Architecture/UX |
| **Output** | `{implementation_artifacts}/epic-{epic_number}-retro-{date}.md` + updated sprint-status |
| **Pattern** | Natural dialogue format, NO BLAME |

**12 steps:**
1. Epic Discovery
2. Document Discovery
3. Deep Story Analysis (dev notes, struggles, review feedback, lessons, debt, testing)
4. Load Previous Retro (action-item follow-through)
5. Preview Next Epic (dependencies, prep gaps)
6. Initialize Retrospective (agents, rules, metrics)
7. Epic Review Discussion (what went well, what didn't)
8. Next Epic Preparation (readiness assessment)
9. Synthesize Action Items (SMART format)
10. Critical Readiness Exploration (testing, deployment, acceptance)
11. Closure + Celebration
12. Save + Update Status

**Party-mode agents:**
- Amelia (Developer) — facilitator
- Alice (Product Owner)
- Charlie (Senior Dev)
- Dana (QA Engineer)
- Elena (Junior Dev)
- {user_name} (Project Lead) — active participant

**Important notes:**
- Psychological safety is PARAMOUNT — NO BLAME
- Focus on systems/processes, NOT individuals
- No time estimates (AI changed dev speed)
- Two-part: epic review + next epic prep

---

#### 4-10. bmad-sprint-planning

| Attribute | Value |
|-----------|---------|
| **Type** | Workflow |
| **Purpose** | Generate sprint status tracking from epics |
| **When to use** | "run sprint planning", "generate sprint plan" |
| **Input** | Epics document |
| **Output** | `sprint-status.yaml` |
| **Pattern** | Structured generation |

**sprint-status.yaml tracks:**
- Epic status (pending/in-progress/complete)
- Story status (draft/ready-for-dev/in-progress/review/done)
- Completion percentage

---

#### 4-11. bmad-sprint-status

| Attribute | Value |
|-----------|---------|
| **Type** | Workflow |
| **Purpose** | Summarize the sprint + surface risks/blockers |
| **When to use** | "check sprint status", "show sprint status" |
| **Input** | sprint-status.yaml |
| **Output** | Status summary + risk report |
| **Pattern** | Snapshot + risk analysis |

---

## Pattern summary

### Per-phase skill count

| Phase | Skills | Agents | Workflows | Key outputs |
|-------|--------|--------|-----------|-------------|
| **Core** | 12 | 2 (Mary, Paige — inside BMM) | 10 | Shared tools |
| **Phase 1: Analysis** | 5 | 2 (Mary, Paige) | 3 | Product Brief, PRFAQ, project docs |
| **Phase 2: Planning** | 6 | 2 (John, Sally) | 4 | PRD, UX Design |
| **Phase 3: Solutioning** | 5 | 1 (Winston) | 4 | Architecture, Epics, Stories, Project Context |
| **Phase 4: Implementation** | 11 | 1 (Amelia) | 10 | Sprint, Stories, Code, Reviews, Retrospectives |

### Total: 39 skills = 8 agents + 31 workflows

### Architectural patterns observed

1. **Micro-file architecture** — Brainstorming, UX Design, Create Architecture, Project Context
2. **XML inline workflow** — Dev Story, Create Story, Correct Course
3. **Step-file + XML mixed** — PRD create/edit/validate (with `steps-c/`, `steps-e/`, `steps-v/`)
4. **Agent persona** — All 8 agents with `customize.toml`
5. **Sub-agent spawning** — Party Mode, Distillator, Product Brief, PRFAQ
6. **External CLI invocation** — Shard Doc (markdown-tree-parser), Customize (Python scripts)

### Skill invocation patterns

```
Agent (customize.toml menu)
  ├─ skill: "bmad-create-prd"      ← invoke a skill directly
  └─ prompt: "Switch to Mary..."    ← prompt the LLM to act

Workflow step
  ├─ Internal: ./steps/step-02.md  ← intra-skill, read fully
  ├─ Sub-file: ./resources/X.md    ← intra-skill, load
  ├─ External CLI: npx tool, python3 script  ← deterministic logic
  └─ Cross-skill: "Invoke the `bmad-xxx` skill"  ← delegate
```

### Input/output patterns

| Layer | Input | Output |
|-------|-------|--------|
| **Core (1-12)** | Content, context, config | Enhanced content, reports, indexed docs |
| **Phase 1** | Raw idea + research | Product Brief, PRFAQ, project docs |
| **Phase 2** | Brief + requirements | PRD, UX specs |
| **Phase 3** | PRD + UX | Architecture, Epics, Stories, Project Context |
| **Phase 4** | Stories | Code, Tests, Sprint tracking, Retrospective |

### Integration points

- **Skills invoke skills** via menu dispatch (by `bmad-*` name)
- **Step files invoke other step files** via "Read fully and follow `./file.md`"
- **Sub-agents spawned** via the Agent tool (in parallel)
- **External tools**: `npx @kayvan/markdown-tree-parser`, `python3 resolve_*.py`
- **Config resolution**: 4-layer merge (installer team/user → custom team/user)

---

**Read next:** [05-flows-and-diagrams.md](05-flows-and-diagrams.md) — Mermaid diagrams for every important flow.
