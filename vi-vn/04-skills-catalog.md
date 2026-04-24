# 04. Skills Catalog - 39 Skills chi tiết

> ⚠️ **UNOFFICIAL THIRD-PARTY DOCUMENTATION**
> Không phải official BMad docs. Xem [DISCLAIMER.md](DISCLAIMER.md) | Licensed MIT — xem [LICENSE](LICENSE) và [NOTICE](NOTICE)
> Official BMAD-METHOD: <https://github.com/bmad-code-org/BMAD-METHOD>

---

> Catalog chi tiết tất cả 39 skills của BMad: 12 core + 27 BMM (4 phases). Mỗi skill: mục đích, input, output, workflow, sub-skill invoke.

---

## Mục lục

- [Phần I: 12 Core Skills](#phần-i-12-core-skills)
- [Phần II: 27 BMM Skills](#phần-ii-27-bmm-skills)
  - [Phase 1: Analysis (5 skills)](#phase-1-analysis-5-skills)
  - [Phase 2: Plan-Workflows (6 skills)](#phase-2-plan-workflows-6-skills)
  - [Phase 3: Solutioning (5 skills)](#phase-3-solutioning-5-skills)
  - [Phase 4: Implementation (11 skills)](#phase-4-implementation-11-skills)
- [Tóm lược patterns](#tóm-lược-patterns)

---

## Phần I: 12 Core Skills

Core skills dùng chung ở mọi phase, không bị ràng buộc theo lifecycle.

Location: `src/core-skills/`

### C-1. bmad-advanced-elicitation

| Thuộc tính | Giá trị |
|-----------|---------|
| **Mục đích** | Push LLM xem xét lại output qua specific reasoning method (pre-mortem, first principles, red team, socratic...) |
| **Khi dùng** | Sau khi AI sinh content, user muốn "dig deeper" hoặc mention phương pháp critique |
| **Input** | Current section content + methods.csv + agent roster (nếu party-mode) |
| **Output** | Enhanced content section |
| **Sub-skills** | Không |
| **Template/resources** | `methods.csv` (28+ reasoning methods) |
| **Pattern** | Menu-driven (1-5, r=reshuffle, a=all, x=proceed) |

**Methods nổi bật:**
- Pre-mortem Analysis, First Principles, Inversion
- Red Team vs Blue Team, Socratic Questioning
- Constraint Removal, Stakeholder Mapping
- Analogical Reasoning

**Workflow:**
1. Load methods.csv + agent roster (nếu party-mode enabled)
2. Present 5 selected methods + menu
3. User picks → execute method → display enhanced version
4. Ask apply changes? → Re-present menu hoặc return

---

### C-2. bmad-brainstorming

| Thuộc tính | Giá trị |
|-----------|---------|
| **Mục đích** | Facilitate brainstorming sessions với 30+ creative techniques |
| **Khi dùng** | "help me brainstorm", "help me ideate" |
| **Input** | Project context + optional context_file |
| **Output** | `{output_folder}/brainstorming/brainstorming-session-{date}-{time}.md` |
| **Sub-skills** | Không (internal step files) |
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

**Đặc biệt:**
- Anti-bias protocol: shift domain every 10 ideas
- Quantity goal: 100+ ideas before organizing

---

### C-3. bmad-customize

| Thuộc tính | Giá trị |
|-----------|---------|
| **Mục đích** | Author override TOML cho agent/workflow customization |
| **Khi dùng** | "customize bmad", "override a skill", "change agent behavior" |
| **Input** | Project root (có `_bmad/`), user intent, target skill's `customize.toml` |
| **Output** | Override file: `_bmad/custom/{skill-name}.toml` hoặc `.user.toml` |
| **Sub-skills** | `list_customizable_skills.py` (Python script, không skill invoke) |
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

| Thuộc tính | Giá trị |
|-----------|---------|
| **Mục đích** | Lossless compression của tài liệu để LLM consume hiệu quả |
| **Khi dùng** | "distill documents", "create a distillate" |
| **Input** | source_documents (required), downstream_consumer, token_budget, output_path, --validate |
| **Output** | Single `-distillate.md` (≤5K tokens) hoặc split folder `-distillate/` |
| **Sub-skills** | 2 sub-agents qua Agent tool (`distillate-compressor.md`, `round-trip-reconstructor.md`) |
| **Template/resources** | `resources/compression-rules.md`, `resources/distillate-format-reference.md`, `resources/splitting-strategy.md` |
| **Pattern** | 4 stages, fan-out spawning nếu lớn |

**Stages:**
1. Analyze — run `analyze_sources.py`, get routing recommendation
2. Compress — spawn compressor sub-agent(s) (parallel nếu fan-out)
3. Verify & Output — completeness check, format check, save
4. Round-Trip Validate (optional, `--validate`)

**Đặc biệt:**
- Compression ≠ Summarization (lossless, reversible)
- Graceful degradation nếu subagent unavailable

---

### C-5. bmad-editorial-review-prose

| Thuộc tính | Giá trị |
|-----------|---------|
| **Mục đích** | Copy-editor review text cho communication issues (clarity, readability) |
| **Khi dùng** | "review for prose", "improve the prose" |
| **Input** | content (≥3 words), style_guide (optional, override), reader_type (`humans`/`llm`) |
| **Output** | 3-column table [Original \| Revised \| Changes] hoặc "No issues" |
| **Sub-skills** | Không |
| **Template/resources** | Microsoft Writing Style Guide (baseline) |
| **Pattern** | Single-pass review với output structured |

**Đặc biệt:**
- **CONTENT IS SACROSANCT** — không challenge ý tưởng, chỉ cách biểu đạt
- Khác reader_type: `humans` vs `llm` (LLM cần unambiguous refs, structured format)

---

### C-6. bmad-editorial-review-structure

| Thuộc tính | Giá trị |
|-----------|---------|
| **Mục đích** | Structural editor propose cuts/reorg/simplification, preserve comprehension |
| **Khi dùng** | "structural review" — **run BEFORE copy-edit** |
| **Input** | content, style_guide, purpose, target_audience, reader_type, length_target |
| **Output** | Recommendations (CUT/MERGE/MOVE/CONDENSE/QUESTION/PRESERVE) với rationale |
| **Sub-skills** | Không |
| **Template/resources** | 5 structure models (Tutorial, Reference, Explanation, Prompt/Task, Strategic) |
| **Pattern** | Multi-step analytical |

**Flow:**
1. Validate input
2. Understand purpose (infer hoặc provided)
3. Structural analysis (map sections, pick model)
4. Flow analysis (reader journey, pacing)
5. Generate prioritized recommendations
6. Output

---

### C-7. bmad-help

| Thuộc tính | Giá trị |
|-----------|---------|
| **Mục đích** | Phân tích state + recommend next skill(s) hoặc answer BMad Q&A |
| **Khi dùng** | "help", "what to do next", "what to start with" |
| **Input** | Catalog (`_bmad/_config/bmad-help.csv`), config, artifacts, llms.txt |
| **Output** | Orientation + skill recommendation + quick-start offer |
| **Sub-skills** | Không (reference others) |
| **Template/resources** | `bmad-help.csv`, `llms.txt` (module docs) |
| **Pattern** | Catalog-driven routing |

**Logic:**
1. Parse catalog → skill descriptions, phases, dependencies
2. Scan artifacts → determine current progress
3. Recommend next required step + optional items
4. Present trong `communication_language`
5. Offer run single skill nếu next step rõ

**Catalog fields:**
- `phases`: "anytime" hoặc phase number
- `dependencies`: `after: [skill-x]`, `before: [skill-y]`
- `required: true/false` — gates blocking progression

---

### C-8. bmad-index-docs

| Thuộc tính | Giá trị |
|-----------|---------|
| **Mục đích** | Generate/update `index.md` cho folder docs |
| **Khi dùng** | "create or update an index of all files" |
| **Input** | Target directory path |
| **Output** | `index.md` với file listings organized |
| **Sub-skills** | Không |
| **Template/resources** | None specific |
| **Pattern** | Scan → group → describe → write |

**Quy tắc:**
- Relative paths `./`
- Alphabetical trong mỗi group
- Skip hidden files
- 3-10 words description per file

---

### C-9. bmad-party-mode

| Thuộc tính | Giá trị |
|-----------|---------|
| **Mục đích** | Multi-agent orchestrated discussions (real subagents via Agent tool) |
| **Khi dùng** | "party mode", "multi-agent conversation", "group discussion", "roundtable" |
| **Input** | `--model` (optional force model), `--solo` (roleplay mode), agent roster, project context |
| **Output** | Full agent responses (unabridged, own voice) |
| **Sub-skills** | Spawn agents via Agent tool |
| **Template/resources** | Agent persona templates |
| **Pattern** | Parallel subagent spawning |

**Modes:**
- **SUBAGENT MODE** — mỗi agent là real, independent thinking (via Agent tool)
- **SOLO MODE** (`--solo`) — roleplay all agents yourself (single LLM)

**Core loop:**
1. Parse arguments
2. Load agent roster + project context
3. Welcome user, show roster
4. Pick 2-4 relevant agents per round
5. Spawn subagents in parallel
6. Present responses (full, không blend)
7. Handle follow-ups

**Rules:**
- Never blend/paraphrase agent responses
- Context summary < 400 words per round
- Rotate agents (avoid same 2 dominating)

---

### C-10. bmad-review-adversarial-general

| Thuộc tính | Giá trị |
|-----------|---------|
| **Mục đích** | Cynical review + produce findings ≥10 items |
| **Khi dùng** | "review something", "critical review" |
| **Input** | content (diff/spec/story/doc), also_consider (optional) |
| **Output** | Markdown list, findings only (no approval) |
| **Sub-skills** | Không |
| **Template/resources** | None |
| **Pattern** | Single-pass adversarial |

**Rules:**
- HALT nếu zero findings (suspicious, re-analyze)
- Attitude: cynical, jaded, skeptical of everything
- Find AT LEAST 10 issues

---

### C-11. bmad-review-edge-case-hunter

| Thuộc tính | Giá trị |
|-----------|---------|
| **Mục đích** | Walk every branching path + boundary, report ONLY unhandled edge cases |
| **Khi dùng** | "edge-case analysis of code, specs, or diffs" |
| **Input** | content (diff/file/function), also_consider (optional) |
| **Output** | JSON array of unhandled paths |
| **Sub-skills** | Không |
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

**Khác adversarial-general:** method-driven (path walking), không attitude-driven. Orthogonal skill.

**Edge classes checked:**
- Missing else/default
- Null/empty inputs, off-by-one, overflow
- Type coercion, race conditions, timeouts

---

### C-12. bmad-shard-doc

| Thuộc tính | Giá trị |
|-----------|---------|
| **Mục đích** | Split large markdown (based on level-2 sections) |
| **Khi dùng** | "perform shard document" |
| **Input** | Source .md path |
| **Output** | Destination folder + index.md |
| **Sub-skills** | External CLI: `npx @kayvan/markdown-tree-parser` |
| **Template/resources** | Tool output |
| **Pattern** | External tool invocation |

**Flow:**
1. Get source document (verify .md)
2. Get destination folder (default: folder named after source)
3. Execute `markdown-tree-parser explode`
4. Verify output
5. Handle original (Delete/Move/Keep) — **Delete recommended**

---

## Phần II: 27 BMM Skills

Location: `src/bmm-skills/`

### Phase 1: Analysis (5 skills)

#### 1-1. bmad-agent-analyst (Mary 📊)

| Thuộc tính | Giá trị |
|-----------|---------|
| **Type** | Agent persona |
| **Role** | Business Analyst |
| **Mục đích** | Strategic analysis, market research, competitive analysis, requirements elicitation |
| **Khi dùng** | "talk to Mary", "request the business analyst" |
| **Customize.toml** | persona + menu |
| **Menu skills** | BD (brainstorming), PB (product-brief), PF (prfaq), DP (document-project) |

**Persona:**
- Style: "Treasure hunter narrating the find"
- Principles: Porter's rigor, Minto's Pyramid Principle, verifiable evidence

---

#### 1-2. bmad-agent-tech-writer (Paige 📚)

| Thuộc tính | Giá trị |
|-----------|---------|
| **Type** | Agent persona |
| **Role** | Technical Writer |
| **Mục đích** | Documentation specialist, DITA/OpenAPI/Mermaid master |
| **Khi dùng** | "talk to Paige", "request the tech writer" |
| **Menu skills** | Documentation-focused |

**Persona:**
- Style: "Patient teacher with apt analogies"
- Principles: Diagrams > prose khi carry signal, every word earns its place

---

#### 1-3. bmad-document-project

| Thuộc tính | Giá trị |
|-----------|---------|
| **Type** | Workflow |
| **Mục đích** | Document brownfield projects cho AI context |
| **Khi dùng** | "document this project", "generate project docs" |
| **Input** | Config + project structure |
| **Output** | Project documentation (theo instructions.md) |
| **Sub-skills** | Internal (`instructions.md`) |
| **Pattern** | Discovery + structured docs |

**Mục đích deep:** Khi apply BMad vào project có sẵn (brownfield), AI cần hiểu codebase. Skill này sinh docs từ code.

---

#### 1-4. bmad-prfaq

| Thuộc tính | Giá trị |
|-----------|---------|
| **Type** | Workflow (5 stages) |
| **Mục đích** | Amazon's Working Backwards PRFAQ — press release + FAQ |
| **Khi dùng** | "create a PRFAQ", "work backwards", "run the PRFAQ challenge" |
| **Input** | Customer, problem, stakes, solution concept |
| **Output** | `{planning_artifacts}/prfaq-{project_name}.md` + optional distillate |
| **Sub-skills** | `artifact-analyzer.md`, `web-researcher.md` (sub-agents) |
| **Template/resources** | `prfaq-template.md`, `press-release.md`, `customer-faq.md`, `internal-faq.md`, `verdict.md` |
| **Pattern** | 5 stages |

**5 stages:**
1. **Ignition** — raw concept → customer-first thinking
2. **Press Release** — iterative drafting với hard coaching
3. **Customer FAQ** — devil's advocate questions
4. **Internal FAQ** — skeptical stakeholder questions
5. **Verdict** — synthesis, strength assessment

**Flags:** `--headless` / `-H` (autonomous first-draft).

---

#### 1-5. bmad-product-brief

| Thuộc tính | Giá trị |
|-----------|---------|
| **Type** | Workflow (5 stages) |
| **Mục đích** | Create executive summary product brief (1-2 pages) |
| **Khi dùng** | "create or update a Product Brief" |
| **Input** | Product/project description, existing docs, competitive context |
| **Output** | `{planning_artifacts}/brief-{name}.md` + optional distillate |
| **Sub-skills** | `artifact-analyzer.md`, `web-researcher.md`, review subagents |
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

| Thuộc tính | Giá trị |
|-----------|---------|
| **Type** | Agent persona |
| **Role** | Product Manager |
| **Mục đích** | Drive PRD creation, user interviews, stakeholder alignment |
| **Menu skills** | CP (create-prd), EP (edit-prd), VP (validate-prd), CI (check-implementation-readiness) |

**Persona:**
- Style: "Detective interrogating a cold case"
- Principles: Jobs-to-be-Done, user value first, tech feasibility as constraint

---

#### 2-2. bmad-agent-ux-designer (Sally 🎨)

| Thuộc tính | Giá trị |
|-----------|---------|
| **Type** | Agent persona |
| **Role** | UX Designer |
| **Mục đích** | UX specs, interaction design, accessibility |
| **Menu skills** | CU (create-ux-design) + related |

**Persona:**
- Style: "Filmmaker pitching the scene before code exists"
- Principles: Empathy + edge-case rigor, user need first

---

#### 2-3. bmad-create-prd

| Thuộc tính | Giá trị |
|-----------|---------|
| **Type** | Workflow (step-file architecture) |
| **Mục đích** | Create comprehensive PRD |
| **Khi dùng** | "let's create a product requirements document" |
| **Input** | Config + Product Brief / PRFAQ (nếu có) |
| **Output** | `{planning_artifacts}/prd.md` |
| **Sub-skills** | Internal step files (no external invoke) |
| **Template/resources** | `steps-c/` directory |
| **Pattern** | Micro-file với state tracking |

**Critical rules:**
- NEVER load multiple steps
- ALWAYS read entire step before execute
- Update frontmatter state after each step
- HALT at menus, wait for input

---

#### 2-4. bmad-create-ux-design

| Thuộc tính | Giá trị |
|-----------|---------|
| **Type** | Workflow (micro-file) |
| **Mục đích** | Plan UX patterns + design specifications |
| **Khi dùng** | "let's create UX design", "help me plan the UX" |
| **Input** | PRD, project context |
| **Output** | `{planning_artifacts}/ux-design-specification.md` |
| **Sub-skills** | Internal step files |
| **Template/resources** | `steps/` directory, `ux-design-template.md` |

---

#### 2-5. bmad-edit-prd

| Thuộc tính | Giá trị |
|-----------|---------|
| **Type** | Workflow (step-file) |
| **Mục đích** | Edit + enhance existing PRD |
| **Khi dùng** | "edit this PRD" |
| **Input** | Existing PRD path |
| **Output** | Updated PRD |
| **Pattern** | `steps-e/` (E-prefixed cho edit mode) |

---

#### 2-6. bmad-validate-prd

| Thuộc tính | Giá trị |
|-----------|---------|
| **Type** | Workflow (step-file) |
| **Mục đích** | Validate PRD against BMAD standards |
| **Khi dùng** | "validate this PRD" |
| **Input** | PRD path |
| **Output** | Validation report |
| **Pattern** | `steps-v/` (V-prefixed cho validate mode) |

**Quality gate** trước khi pass sang Solutioning.

---

### Phase 3: Solutioning (5 skills)

#### 3-1. bmad-agent-architect (Winston 🏗️)

| Thuộc tính | Giá trị |
|-----------|---------|
| **Type** | Agent persona |
| **Role** | System Architect |
| **Menu skills** | CA (create-architecture), CE (create-epics-and-stories), GP (generate-project-context), CI (check-implementation-readiness) |

**Persona:**
- Style: "Seasoned engineer at the whiteboard, measured, trade-offs over verdicts"
- Principles: Boring technology for stability, developer productivity as architecture

---

#### 3-2. bmad-check-implementation-readiness

| Thuộc tính | Giá trị |
|-----------|---------|
| **Type** | Workflow (step-file) |
| **Mục đích** | Validate PRD + UX + Architecture + Epics complete, aligned BEFORE Phase 4 |
| **Khi dùng** | "check implementation readiness" |
| **Input** | PRD, UX, Architecture, Epics, Stories (ALL required) |
| **Output** | Readiness report |
| **Pattern** | `steps/` directory, checklist-driven |

**Role:** Expert PM spotting gaps. Quality gate trước dev.

---

#### 3-3. bmad-create-architecture

| Thuộc tính | Giá trị |
|-----------|---------|
| **Type** | Workflow (micro-file) |
| **Mục đích** | Collaborative step-by-step architecture discovery |
| **Khi dùng** | "let's create architecture", "create technical architecture" |
| **Input** | PRD, UX, project context |
| **Output** | `{planning_artifacts}/architecture.md` |
| **Sub-skills** | Internal step files |
| **Template/resources** | `architecture-decision-template.md`, `steps/` |
| **Pattern** | Partnership facilitation |

**Đặc biệt:**
- "Partnership, not client-vendor"
- Collaborative with peer (user là peer, không client)
- Prevent implementation conflicts (multiple agents shouldn't use REST và GraphQL)

---

#### 3-4. bmad-create-epics-and-stories

| Thuộc tính | Giá trị |
|-----------|---------|
| **Type** | Workflow (step-file) |
| **Mục đích** | Break requirements → epics + stories organized by user value |
| **Khi dùng** | "create the epics and stories list" |
| **Input** | PRD, Architecture, UX (ALL required) |
| **Output** | `{planning_artifacts}/epics.md` |
| **Pattern** | `steps/`, BDD-formatted ACs |

**Đặc biệt:**
- BDD-formatted acceptance criteria
- Source hints trỏ về PRD/Architecture (traceability)
- Requirements decomposition expertise

---

#### 3-5. bmad-generate-project-context

| Thuộc tính | Giá trị |
|-----------|---------|
| **Type** | Workflow (micro-file) |
| **Mục đích** | Create `project-context.md` với critical rules AI agents MUST follow |
| **Khi dùng** | "generate project context", "create project context" |
| **Input** | Architecture, previous implementations, patterns |
| **Output** | `{output_folder}/project-context.md` |
| **Template/resources** | `project-context-template.md` |
| **Pattern** | LLM-optimized (lean) |

**Đặc biệt:**
- Focus on "do NOT forget" items
- Prevent common implementation mistakes
- Shorter hơn Architecture, nhưng critical cho dev agent

---

### Phase 4: Implementation (11 skills)

#### 4-1. bmad-agent-dev (Amelia 💻)

| Thuộc tính | Giá trị |
|-----------|---------|
| **Type** | Agent persona |
| **Role** | Senior Software Engineer |
| **Menu skills** | DS (dev-story), QD (quick-dev), CR (code-review), CP (checkpoint-preview), CC (correct-course) |

**Persona:**
- Style: "Terminal prompt — exact file paths, AC IDs, commit-message brevity"
- Principles: Test-first (red-green-refactor), 100% pass before review

---

#### 4-2. bmad-checkpoint-preview

| Thuộc tính | Giá trị |
|-----------|---------|
| **Type** | Workflow |
| **Mục đích** | LLM-assisted human-in-the-loop review guide (purpose → context → details) |
| **Khi dùng** | "checkpoint", "human review", "walk me through this change" |
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
- If spec has "Suggested Review Order", use it

---

#### 4-3. bmad-code-review

| Thuộc tính | Giá trị |
|-----------|---------|
| **Type** | Workflow |
| **Mục đích** | Adversarial code review với parallel layers |
| **Khi dùng** | "run code review", "review this code" |
| **Input** | Code changes/diff |
| **Output** | Structured findings + triage |
| **Sub-skills** | workflow.md invokes Blind Hunter, Edge Case Hunter, Acceptance Auditor (parallel) |
| **Pattern** | Parallel multi-layer review |

**Đặc biệt:**
- 3 parallel layers:
  - **Blind Hunter** — find issues không có spec
  - **Edge Case Hunter** — boundary conditions (reuse C-11)
  - **Acceptance Auditor** — verify ACs met
- Structured triage into action categories
- Recommend run với **different LLM** than implementer

---

#### 4-4. bmad-correct-course

| Thuộc tính | Giá trị |
|-----------|---------|
| **Type** | Workflow (XML-formatted) |
| **Mục đích** | Manage significant mid-sprint changes |
| **Khi dùng** | "correct course", "propose sprint change" |
| **Input** | PRD (required), Epics+Stories (required), Architecture+UX (optional), change trigger |
| **Output** | `{planning_artifacts}/sprint-change-proposal-{date}.md` |
| **Sub-skills** | `checklist.md` (analysis checklist) |
| **Modes** | Incremental (collaborative) vs Batch (all at once) |

**5-step flow:**
1. Initialize change navigation (gather trigger, doc access, mode preference)
2. Execute change analysis checklist (interactive)
3. Draft specific change proposals
4. Generate Sprint Change Proposal (issue summary, impact, approach, changes, handoff)
5. Finalize + route implementation

**Scope classification:**
- **Minor** → direct dev
- **Moderate** → backlog
- **Major** → epic review

---

#### 4-5. bmad-create-story

| Thuộc tính | Giá trị |
|-----------|---------|
| **Type** | Workflow (XML-formatted, 6 steps) |
| **Mục đích** | Create story file với ALL context developer needs |
| **Khi dùng** | "create the next story", "create story [id]" |
| **Input** | sprint-status.yaml OR story ID, Epics, PRD, Architecture, UX |
| **Output** | `{implementation_artifacts}/{epic}-{story}-{title}.md` + updated sprint-status.yaml |
| **Sub-skills** | `discover-inputs.md` (artifact loading) |
| **Template/resources** | `template.md` |
| **Pattern** | Exhaustive pre-dev preparation |

**6 steps:**
1. Determine target story (sprint-status hoặc user input)
2. Load + analyze core artifacts (epics, PRD, architecture, UX + previous story learnings + git patterns)
3. Architecture analysis (guardrails)
4. Web research (latest tech, versions, prevent outdated implementations)
5. Create story file from template
6. Update sprint-status.yaml to `ready-for-dev`

**Mục đích deep:** ZERO LLM mistakes prevention:
- Reinventing wheels
- Wrong libraries
- Wrong file locations
- Regressions
- Vague implementations

---

#### 4-6. bmad-dev-story

| Thuộc tính | Giá trị |
|-----------|---------|
| **Type** | Workflow (XML inline, 10 steps) |
| **Mục đích** | Execute story implementation với TDD discipline |
| **Khi dùng** | "dev this story [file]", "implement the next story in sprint plan" |
| **Input** | Story file (from create-story) hoặc auto-discover từ sprint-status |
| **Output** | Code implementation + updated story file |
| **Sub-skills** | Internal XML workflow |
| **Pattern** | 10 steps với RED-GREEN-REFACTOR cycle |

**10 steps:**
1. Find next ready story + load it
2. Load project context + story information
3. Detect review continuation + extract review context
4. Mark story in-progress
5. Implement task following RED-GREEN-REFACTOR
6. Author comprehensive tests
7. Run validations + tests
8. Validate + mark task complete (ONLY when fully done)
9. Story completion + mark for review
10. Completion communication + user support

**Critical rules:**
- Execute ALL steps in exact order, DO NOT skip
- Do NOT stop for "milestones" — continue until COMPLETE
- NEVER mark task complete nếu NOT all validations pass
- NO LYING OR CHEATING on validation

---

#### 4-7. bmad-qa-generate-e2e-tests

| Thuộc tính | Giá trị |
|-----------|---------|
| **Type** | Workflow |
| **Mục đích** | Generate automated API + E2E tests for implemented code |
| **Khi dùng** | "create qa automated tests for [feature]" |
| **Input** | Implemented code |
| **Output** | Test files + summary (`{implementation_artifacts}/tests/test-summary.md`) |
| **Pattern** | Detect framework → generate tests → run → summary |

**Rules:**
- Use project's existing test framework (don't introduce new)
- Happy path + 1-2 error cases per test
- Tests linear + simple
- Verify tests pass before handoff

---

#### 4-8. bmad-quick-dev

| Thuộc tính | Giá trị |
|-----------|---------|
| **Type** | Workflow |
| **Mục đích** | Implements any user intent following project's existing patterns |
| **Khi dùng** | "build", "fix", "tweak", "refactor", "add", "modify" |
| **Input** | User description of change |
| **Output** | Code artifacts |
| **Pattern** | Flexible |

**Mục đích deep:** Quick Flow path (không qua formal PRD/Architecture/Story).
Phù hợp: 1-15 stories, bug fixes, small features, established projects.

---

#### 4-9. bmad-retrospective

| Thuộc tính | Giá trị |
|-----------|---------|
| **Type** | Workflow (12 steps với agent dialogue) |
| **Mục đích** | Post-epic review với party-mode facilitation |
| **Khi dùng** | "run a retrospective", "lets retro the epic" |
| **Input** | sprint-status.yaml, epic number, story files, PRD/Architecture/UX |
| **Output** | `{implementation_artifacts}/epic-{epic_number}-retro-{date}.md` + updated sprint-status |
| **Pattern** | Natural dialogue format, NO BLAME |

**12 steps:**
1. Epic Discovery
2. Document Discovery
3. Deep Story Analysis (dev notes, struggles, review feedback, lessons, debt, testing)
4. Load Previous Retro (action items follow-through)
5. Preview Next Epic (dependencies, prep gaps)
6. Initialize Retrospective (agents, rules, metrics)
7. Epic Review Discussion (went well, didn't)
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

**Ghi chú quan trọng:**
- Psychological safety PARAMOUNT — NO BLAME
- Focus on systems/processes, NOT individuals
- No time estimates (AI changed dev speed)
- Two-part: epic review + next epic prep

---

#### 4-10. bmad-sprint-planning

| Thuộc tính | Giá trị |
|-----------|---------|
| **Type** | Workflow |
| **Mục đích** | Generate sprint status tracking from epics |
| **Khi dùng** | "run sprint planning", "generate sprint plan" |
| **Input** | Epics document |
| **Output** | `sprint-status.yaml` |
| **Pattern** | Structured generation |

**sprint-status.yaml tracks:**
- Epic status (pending/in-progress/complete)
- Story status (draft/ready-for-dev/in-progress/review/done)
- Completion percentage

---

#### 4-11. bmad-sprint-status

| Thuộc tính | Giá trị |
|-----------|---------|
| **Type** | Workflow |
| **Mục đích** | Summarize sprint + surface risks/blockers |
| **Khi dùng** | "check sprint status", "show sprint status" |
| **Input** | sprint-status.yaml |
| **Output** | Status summary + risk report |
| **Pattern** | Snapshot + risk analysis |

---

## Tóm lược patterns

### Per-phase skill count

| Phase | Skills | Agents | Workflows | Key outputs |
|-------|--------|--------|-----------|-------------|
| **Core** | 12 | 2 (Mary, Paige — trong BMM) | 10 | Shared tools |
| **Phase 1: Analysis** | 5 | 2 (Mary, Paige) | 3 | Product Brief, PRFAQ, project docs |
| **Phase 2: Planning** | 6 | 2 (John, Sally) | 4 | PRD, UX Design |
| **Phase 3: Solutioning** | 5 | 1 (Winston) | 4 | Architecture, Epics, Stories, Project Context |
| **Phase 4: Implementation** | 11 | 1 (Amelia) | 10 | Sprint, Stories, Code, Reviews, Retrospectives |

### Tổng: 39 skills = 8 agents + 31 workflows

### Architectural patterns quan sát được

1. **Micro-file architecture** — Brainstorming, UX Design, Create Architecture, Project Context
2. **XML inline workflow** — Dev Story, Create Story, Correct Course
3. **Step-file + XML mixed** — PRD create/edit/validate (với `steps-c/`, `steps-e/`, `steps-v/`)
4. **Agent persona** — All 8 agents với `customize.toml`
5. **Sub-agent spawning** — Party Mode, Distillator, Product Brief, PRFAQ
6. **External CLI invocation** — Shard Doc (markdown-tree-parser), Customize (Python scripts)

### Skill invocation patterns

```
Agent (customize.toml menu)
  ├─ skill: "bmad-create-prd"      ← invoke skill directly
  └─ prompt: "Switch to Mary..."    ← prompt LLM action

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

- **Skills invoke skills** qua menu dispatch (tên `bmad-*`)
- **Step files invoke other step files** qua "Read fully and follow `./file.md`"
- **Sub-agents spawn** qua Agent tool (parallel)
- **External tools**: `npx @kayvan/markdown-tree-parser`, `python3 resolve_*.py`
- **Config resolution**: 4-layer merge (installer team/user → custom team/user)

---

**Đọc tiếp:** [05-flows-and-diagrams.md](05-flows-and-diagrams.md) — Mermaid diagrams cho mọi flow quan trọng.
