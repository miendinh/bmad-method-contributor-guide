# 09b. Phase 1 + 2 Skills - Deep Dive (11 Skills)

> ⚠️ **UNOFFICIAL THIRD-PARTY DOCUMENTATION**
> NOT official BMad docs. See [DISCLAIMER.md](DISCLAIMER.md) | Licensed MIT — see [LICENSE](LICENSE) and [NOTICE](NOTICE)
> Official BMAD-METHOD: <https://github.com/bmad-code-org/BMAD-METHOD>

---

> **Phase 1 - Analysis:** 5 skills (Analyst persona + 4 workflows)
> **Phase 2 - Planning:** 6 skills (PM + UX personas + 4 PRD/UX workflows)

---

## Table of Contents

### Phase 1 - Analysis
- [1-1. bmad-agent-analyst (Mary 📊)](#1-1-bmad-agent-analyst-mary)
- [1-2. bmad-agent-tech-writer (Paige 📚)](#1-2-bmad-agent-tech-writer-paige)
- [1-3. bmad-document-project](#1-3-bmad-document-project)
- [1-4. bmad-prfaq](#1-4-bmad-prfaq)
- [1-5. bmad-product-brief](#1-5-bmad-product-brief)

### Phase 2 - Planning
- [2-1. bmad-agent-pm (John 📋)](#2-1-bmad-agent-pm-john)
- [2-2. bmad-agent-ux-designer (Sally 🎨)](#2-2-bmad-agent-ux-designer-sally)
- [2-3. bmad-create-prd](#2-3-bmad-create-prd)
- [2-4. bmad-create-ux-design](#2-4-bmad-create-ux-design)
- [2-5. bmad-edit-prd](#2-5-bmad-edit-prd)
- [2-6. bmad-validate-prd](#2-6-bmad-validate-prd)

---

# PHASE 1 - ANALYSIS

## 1-1. bmad-agent-analyst (Mary 📊)

### Metadata
- **Path:** `src/bmm-skills/1-analysis/bmad-agent-analyst/`
- **Type:** Agent persona skill

### Persona (customize.toml)

```toml
[agent]
name = "Mary"
title = "Business Analyst"
icon = "📊"
role = "Help the user ideate research and analyze before committing to a project in the BMad Method analysis phase"
identity = "Channels Michael Porter's strategic rigor and Barbara Minto's Pyramid Principle discipline"
communication_style = "Treasure hunter's excitement for patterns, McKinsey memo's structure for findings"

principles = [
  "Every finding grounded in verifiable evidence",
  "Requirements stated with absolute precision",
  "Every stakeholder voice represented",
]

persistent_facts = [
  "file:{project-root}/**/project-context.md",
]

activation_steps_prepend = []
activation_steps_append = []

[[agent.menu]]
code = "BP"
description = "Expert guided brainstorming facilitation"
skill = "bmad-brainstorming"

[[agent.menu]]
code = "MR"
description = "Market analysis, competitive landscape, customer needs and trends"
skill = "bmad-market-research"

[[agent.menu]]
code = "DR"
description = "Industry domain deep dive, subject matter expertise and terminology"
skill = "bmad-domain-research"

[[agent.menu]]
code = "TR"
description = "Technical feasibility, architecture options and implementation approaches"
skill = "bmad-technical-research"

[[agent.menu]]
code = "CB"
description = "Create or update product briefs through guided or autonomous discovery"
skill = "bmad-product-brief"

[[agent.menu]]
code = "WB"
description = "Working Backwards PRFAQ challenge — forge and stress-test product concepts"
skill = "bmad-prfaq"

[[agent.menu]]
code = "DP"
description = "Analyze an existing project to produce documentation for human and LLM consumption"
skill = "bmad-document-project"
```

### Activation flow (8 steps - same for all agents)

```
1. Resolve agent block (3-level merge: default → team → user)
2. Execute activation_steps_prepend
3. Adopt persona (name, title, icon, role, identity, style, principles)
4. Load persistent_facts (expand file: globs)
5. Load config: user_name, communication_language, etc.
6. Greet user with icon 📊 prefix, in communication_language
   Example: "📊 Hi Alice! I'm Mary, your Business Analyst..."
7. Execute activation_steps_append
8. Dispatch (user intent clear → invoke skill directly) OR Render menu
```

### Mental model
- Mary specializes in **evidence-based** analysis
- Every claim needs a citation
- Pyramid Principle: top-down summaries
- Entry flow from "BP" (brainstorm) → "CB" (product brief) → "WB" (PRFAQ stress test)

---

## 1-2. bmad-agent-tech-writer (Paige 📚)

### Persona

```toml
[agent]
name = "Paige"
title = "Technical Writer"
icon = "📚"
role = "Capture and curate project knowledge so humans and future LLM agents stay in sync during the BMad Method analysis phase"
identity = "Writes with Julia Evans's accessibility and Edward Tufte's visual precision"
communication_style = "Patient educator — explains like teaching a friend. Every analogy earns its place"

principles = [
  "Write for the reader's task, not the writer's checklist",
  "A diagram beats a thousand-word paragraph",
  "Audience-aware: simplify or detail as the reader needs",
]

[[agent.menu]]
code = "DP"
description = "Generate comprehensive project documentation (brownfield analysis, architecture scanning)"
skill = "bmad-document-project"

[[agent.menu]]
code = "WD"
description = "Author a document following documentation best practices through guided conversation"
prompt = "write-document.md"

[[agent.menu]]
code = "MG"
description = "Create a Mermaid-compliant diagram based on your description"
prompt = "mermaid-gen.md"

[[agent.menu]]
code = "VD"
description = "Validate documentation against standards and best practices"
prompt = "validate-doc.md"

[[agent.menu]]
code = "EC"
description = "Create clear technical explanations with examples and diagrams"
prompt = "explain-concept.md"
```

### Sub-prompt files

**write-document.md:** 4-step discovery flow (intent → research → draft → review)

**validate-doc.md:** Load → analyze vs standards → report improvements

**mermaid-gen.md:** Interactive diagram creation with syntax validation

**explain-concept.md:** Understand concept → pick analogy → examples → diagram → draft

---

## 1-3. bmad-document-project

### Metadata
- **Path:** `src/bmm-skills/1-analysis/bmad-document-project/`
- **Files:** SKILL.md, customize.toml, `instructions.md`, 4 templates (deep-dive, index, project-overview, source-tree), 2 workflow files (full-scan, deep-dive), checklist.md
- **Type:** XML workflow skill

### Frontmatter
```yaml
name: bmad-document-project
description: 'Document brownfield projects for AI context. Use when "document this project" or "generate project docs".'
```

### Deep purpose
**Brownfield AI onboarding:** When applying BMad to an existing codebase, the AI needs context. This skill scans the codebase + generates structured docs.

### 3 modes

1. **`initial_scan`** — First time, no docs exist
2. **`full_rescan`** — Refresh entire documentation
3. **`deep_dive`** — Focus on a specific area (e.g., auth, billing)

### Input schema
- `{project_knowledge}` folder path
- Resume decision (if state file exists)
- Optional: specific folder/topic for deep_dive

### Output schema

```
{project_knowledge}/
├── index.md                     # Master index
├── project-overview.md          # High-level architecture
├── source-tree-{timestamp}.md   # Code structure
├── deep-dive-{topic}-{timestamp}.md  # Focused analyses
└── project-scan-report.json     # State file
```

State file schema:
```json
{
  "mode": "initial_scan | full_rescan | deep_dive",
  "scan_level": "standard | exhaustive",
  "current_step": 3,
  "completed_steps": [1, 2],
  "project_type_ids": ["webapp-react", "api-nodejs"],
  "timestamp": "2026-04-24T10:30:00Z",
  "last_scanned": "2026-04-24T10:25:00Z"
}
```

### XML workflow

**Step 1: Check for existing state**

```xml
<step n="1" goal="Detect existing scan state">
  <check if="project-scan-report.json exists">
    <action>Read state file, extract mode/scan_level/current_step/completed_steps</action>
    <action>Calculate state age</action>
    
    <check if="state age >= 24 hours">
      <action>Auto-archive old state</action>
      <goto step="0.5">Start fresh</goto>
    </check>
    
    <ask>Resume (1), Start Fresh (2), Cancel (3)?</ask>
    
    <check if="user selects 1">
      <action>Load cached project_type_ids</action>
      <action>Continue from current_step</action>
    </check>
    
    <check if="user selects 2">
      <action>Archive old file</action>
      <goto step="0.5">Continue to mode detection</goto>
    </check>
  </check>
  
  <check if="no state file">
    <goto step="0.5">Continue</goto>
  </check>
</step>
```

**Step 0.5/3: Mode detection**

```xml
<check if="index.md exists">
  <ask>Re-scan entire (1), Deep-dive area (2), Keep existing (3)?</ask>
  
  <check if="1">
    <action>workflow_mode = "full_rescan"</action>
    <action>Follow full-scan-workflow.md</action>
  </check>
  
  <check if="2">
    <action>workflow_mode = "deep_dive"</action>
    <action>scan_level = "exhaustive"</action>
    <action>Follow deep-dive-workflow.md</action>
  </check>
  
  <check if="3">
    <action>EXIT (keep existing)</action>
  </check>
</check>

<check if="no index.md">
  <action>workflow_mode = "initial_scan"</action>
  <action>Follow full-scan-workflow.md</action>
</check>
```

### Scan execution (full-scan-workflow.md)

Steps (in full-scan-workflow.md):
1. Detect project types (languages, frameworks, tooling)
2. Analyze entry points (main, index files)
3. Trace dependencies (package.json, imports)
4. Map directory structure
5. Identify patterns (naming, organization, conventions)
6. Generate project-overview.md
7. Generate source-tree-{timestamp}.md
8. Update index.md
9. Save state

### State machine

```
[Entry]
  ↓
[Check state file]
  ├─ Exists + < 24h → [Ask resume/fresh/cancel]
  │                     ├─ Resume → [Continue from current_step]
  │                     └─ Fresh → [Archive old, continue]
  └─ Not exist / > 24h
      ↓
  [Check index.md]
      ├─ Exists → [Ask rescan/deep-dive/keep]
      │           ├─ Rescan → [full_rescan]
      │           └─ Deep-dive → [deep_dive]
      └─ Not exist → [initial_scan]
           ↓
  [Execute scan workflow]
           ↓
  [Update state file periodically]
           ↓
  [Complete + save index.md]
```

---

## 1-4. bmad-prfaq

### Metadata
- **Path:** `src/bmm-skills/1-analysis/bmad-prfaq/`
- **Files:** SKILL.md (136 lines), customize.toml, `assets/prfaq-template.md`, 4 stage references (press-release, customer-faq, internal-faq, verdict), 2 sub-agents (artifact-analyzer, web-researcher)
- **Type:** Multi-stage workflow with subagent fan-out

### Frontmatter
```yaml
name: bmad-prfaq
description: 'Working Backwards: The PRFAQ Challenge. Forge product concepts through Amazon methodology. Use when "create a PRFAQ", "work backwards", "run the PRFAQ challenge".'
```

### Deep purpose
**Amazon's Working Backwards methodology.** Force writing the press release for a completed product **BEFORE building it**. If you cannot write a compelling press release, the product isn't ready.

**Tone:** Tough love coaching. Challenge vague thinking. Reject weak ideas.

### Arguments
- `--headless` / `-H` — Autonomous first-draft from provided context

### Input schema

**Required (headless mode):**
- `customer` — specific persona, not "everyone"
- `problem` — concrete, felt, not abstract
- `stakes` — why it matters, consequences
- `solution` — concept direction

**Optional:**
- Competitive context, technical constraints, team/org context, target market, research

### Output schema

**Location:** `{planning_artifacts}/prfaq-{project_name}.md`

```yaml
---
title: "PRFAQ: {project_name}"
status: "draft | press-release | customer-faq | internal-faq | complete"
created: "{timestamp}"
updated: "{timestamp}"
stage: 1-5
inputs: [files used]
---
```

**Sections:**
- Headline + Subheadline
- Problem paragraph (feel customer pain)
- Solution paragraph (what changes)
- Leader quote
- How It Works (user perspective)
- Customer quote (human, not marketing)
- Getting Started (clear path to first value)
- Customer FAQ (6-10 questions, hardest first)
- Internal FAQ (6-10 questions, feasibility focused)
- The Verdict (strength assessment)

### 5 stages in detail

#### Stage 1: Ignition (SKILL.md body)

**Goal:** Raw concept on the table, establish customer-first thinking.

Routing logic:
```
If solution-first → redirect to problem
If technology-first → challenge: "why does anyone still care?"
If problem-first → dig deeper: 
  - How do they cope today?
  - Tried what?
  - Why unsolved?
```

**Capture 4 essentials:** Customer, problem, stakes, solution concept.

**Fast-track:** If all 4 in opening message → move directly to Stage 2.

**Graceful redirect:** After 2-3 exchanges, if user can't articulate → suggest `bmad-brainstorming`.

**Contextual Gathering:**
```
Ask about existing inputs (brainstorming output, research, etc.)
Fan out subagents in parallel:
  1. Artifact Analyzer
     - Scans {planning_artifacts} + {project_knowledge} + user paths
     - Returns JSON: documents_found, key_insights, user_market_context, 
                     technical_context, ideas_and_decisions, raw_detail_worth_preserving
  2. Web Researcher
     - Searches competitive landscape, market context
     - Returns JSON: competitive_landscape, market_context, user_sentiment,
                     timing_and_opportunity, risks_and_considerations
```

**Graceful degradation:** If subagents unavailable, scan 1-2 docs inline + targeted web search.

**Create output** at `{planning_artifacts}/prfaq-{project_name}.md` using the template.

**Append coaching notes block** (HTML comment):
```html
<!-- coaching-notes-stage-1
- Concept type: commercial / non-commercial / internal tool
- Assumptions challenged: [list]
- Subagent findings: [key extracts]
-->
```

**HALT:** When there is enough to draft the press release headline → route to `./references/press-release.md`.

#### Stage 2: Press Release (press-release.md)

**Goal:** A press release the customer would stop scrolling for.

**Iterative drafting:**
- Challenge every sentence: specificity, customer relevance, honesty
- Concept type adaptation: commercial → "announce product", non-commercial → "announce initiative"

**Structure forces clarity:**

| Section | Question to answer |
|---------|-------------------|
| Headline | One sentence, captures value? |
| Subheadline | Who benefits? What changes? |
| Opening | What, for whom, why care? |
| Problem | Make reader FEEL pain, no solution mention |
| Solution | What changes for customer, not features |
| Leader quote | Vision beyond feature list |
| How It Works | From customer's perspective |
| Customer quote | Human sound? (not marketing) |
| Getting Started | Clear, concrete first step |

**Quality bars:**
- No jargon
- No weasel words ("best-in-class", "world-class")
- Mom test (could mom understand?)
- "So what?" test
- Honest framing

**Coaching loop:**
```
Draft → self-challenge out loud → invite user sharpening
```

**Headless mode:** Draft complete press release from inputs, apply quality bars internally.

**Update document:** Append press release, `status: "press-release"`, `stage: 2`.

**Append coaching notes:** rejected framings, competitive positioning, differentiators, out-of-scope details (for distillate).

**HALT:** When press release is coherent + compelling → route to `./customer-faq.md`.

#### Stage 3: Customer FAQ (customer-faq.md)

**Goal:** Validate value prop through the hardest customer questions.

**Role:** Become the customer. Busy, skeptical, been burned. Read the press release. Now questioning.

**Generate 6-10 questions covering:**

| Category | Examples |
|----------|----------|
| Skepticism | "How different from [existing]?" / "Why switch?" |
| Trust | "What happens to my data?" / "If this shuts down?" |
| Practical | "How much?" / "How long to start?" |
| Edge cases | "What if I need [uncommon]?" |
| Hard question | The one team hopes nobody asks |

**DON'T generate softballs:** "How do I sign up?" is CTA, not FAQ.

**Calibrate by concept type:**
- Commercial: cost, competitor switching, trust/viability
- Non-commercial: effort to adopt, why change workflow, maintenance/sustainability

**Coaching answers:**
1. Present all questions at once
2. Work through together
3. Quality checks:
   - Honest? If "we don't do that yet" → explain roadmap or alternative
   - Specific? "Enterprise-grade security" ❌ → What certifications, encryption, SLA?
   - Believable? Marketing language destroys FAQ credibility
   - Gap revealed? Name it, force decision: launch blocker | fast-follow | accepted trade-off

**Append coaching notes:** gaps revealed, trade-off decisions, competitive intelligence, scope/requirements signals.

**HALT:** When every question has an honest, specific answer → route to `./internal-faq.md`.

#### Stage 4: Internal FAQ (internal-faq.md)

**Goal:** Stress-test from the builder's side. "Can we pull this off — and should we?"

**Role:** Internal stakeholder panel — engineering, finance, legal, operations, CEO.

**Generate 6-10 questions covering:**

| Category | Examples |
|----------|----------|
| Feasibility | "Hardest technical problem?" / "What don't we know how to build?" |
| Business viability | "Unit economics?" / "First 100 customers?" |
| Resource | "What team?" / "Realistic timeline?" / "What say no to?" |
| Risk | "What kills this?" / "Worst-case?" / "Regulatory exposure?" |
| Strategic | "Why us? Why now?" / "In 3 years, what?" |
| Avoided question | Thing keeping founder up at night |

**Calibrate to context:**
- Solo founder MVP ≠ enterprise product
- Non-commercial: "unit economics" → "maintenance burden"

**Coaching answers:**
- Demand specificity: "We'll figure it out" ❌
- Honest unknowns OK — unexamined unknowns NOT OK
- Watch for hand-waving on resources/timeline (most over-optimistic)

**Append coaching notes:** feasibility risks, resource/timeline estimates, unknowns flagged, strategic positioning.

**HALT:** Route to `./verdict.md`.

#### Stage 5: Verdict (verdict.md)

**Goal:** Honest assessment. Finalize PRFAQ + produce distillate.

**Verdict categories:**

| Verdict | Meaning |
|---------|---------|
| **Forged in steel** | Clear, compelling, defensible |
| **Needs more heat** | Promising but underdeveloped |
| **Cracks in foundation** | Genuine risks, unresolved contradictions |

**Present directly, don't soften.** Constructive frame but honest.

**Polish PRFAQ:** Cohesive narrative, FAQs flow, formatting consistent.

**Append verdict section**, `status: "complete"`, `stage: 5`.

**Produce distillate** at `{planning_artifacts}/prfaq-{project_name}-distillate.md`:
- Dense bullets by theme
- Self-contained bullets
- Include:
  - Rejected framings + why
  - Requirements signals
  - Technical context/constraints
  - Competitive intelligence
  - Open questions
  - Scope signals (in/out/maybe MVP)
  - Resource/timeline estimates
  - Verdict findings (especially "needs heat" + "cracks") as actionable items

**Present completion:** PRFAQ URL + distillate URL. Suggest "use as input for PRD creation."

**Headless output:**
```json
{
  "status": "complete",
  "prfaq": "path",
  "distillate": "path",
  "verdict": "forged | needs-heat | cracked",
  "key_risks": ["..."],
  "open_questions": ["..."]
}
```

### Resume detection
- Check if output file exists
- Read only first 20 lines for frontmatter `stage`
- Offer resume from that stage

### Sub-agent: Artifact Analyzer

```markdown
# Artifact Analyzer Sub-Agent

## Input
- paths: [list of file/folder paths]
- product_intent: brief description

## Task
Scan documents for insights relevant to product intent.

## Output (JSON)
{
  "documents_found": [...],
  "key_insights": [max 5 bullets],
  "user_market_context": [max 5 bullets],
  "technical_context": [max 5 bullets],
  "ideas_and_decisions": [max 5 bullets],
  "raw_detail_worth_preserving": [max 5 bullets]
}

## Rules
- Max 1500 tokens
- 5 bullets per section
```

### Sub-agent: Web Researcher

```markdown
# Web Researcher Sub-Agent

## Input
- product_intent: brief description
- target_market: optional

## Task
Search competitive landscape, market size, trends, user sentiment.

## Output (JSON)
{
  "competitive_landscape": [max 5 bullets],
  "market_context": [max 5 bullets],
  "user_sentiment": [max 5 bullets],
  "timing_and_opportunity": [max 5 bullets],
  "risks_and_considerations": [max 5 bullets]
}

## Rules
- Max 1000 tokens
- 5 bullets per section
- Cite sources where possible
```

---

## 1-5. bmad-product-brief

### Metadata
- **Path:** `src/bmm-skills/1-analysis/bmad-product-brief/`
- **Files:** SKILL.md (118 lines), customize.toml (48 lines, defines `brief_template`), 4 stage prompts, 4 sub-agents, resources/brief-template.md
- **Type:** Multi-mode workflow

### Frontmatter
```yaml
name: bmad-product-brief
description: 'Create compelling product briefs through collaborative discovery. Use when "create or update a Product Brief".'
```

### Deep purpose
Create a 1-2 page executive summary product brief with intelligent artifact analysis + web research.

**Design rationale:** Understand intent FIRST before scanning artifacts — without knowing the topic, scanning is noise, not signal.

**Capture-don't-interrupt pattern:** User shares details beyond brief scope (requirements, architecture, platform, timeline) → capture silently for distillate.

### Activation modes

| Mode | Flag | Behavior |
|------|------|----------|
| **Autonomous** | `--autonomous` / `-A` | Ingest inputs, fan out subagents, produce brief WITHOUT interaction |
| **Yolo** | `--yolo` / "just draft it" | Draft complete brief upfront, refine with user |
| **Guided** (default) | (none) | Conversational discovery with soft gates |

### Input schema
- Product/project description
- Existing documents (paths, not read yet)
- Competitive context (optional)
- Multi-idea detection

### Output schema

**Location:** `{planning_artifacts}/product-brief-{project_name}.md`

```yaml
---
title: "Product Brief: {project_name}"
status: "draft | complete"
created: "{timestamp}"
updated: "{timestamp}"
inputs: [files used]
---
```

**Structure:** 1-2 pages executive summary.

**Optional distillate:** `{planning_artifacts}/product-brief-{project_name}-distillate.md`

### 5 stages

#### Stage 1: Understand Intent (SKILL.md)

**Goal:** Know WHY the user is here + WHAT the brief is about BEFORE anything else.

**Brief type detection:**
- Product → focus on market differentiation
- Internal tool → focus on adoption path
- Research project → focus on stakeholder value
- Other → case-by-case

**Multi-idea disambiguation:** If multiple competing ideas → pick one focus, others can be briefed separately.

**Existing brief:** Read fully, treat as rich input. "What's changed? Update/improve?"

**Contextual gathering:**
- Acknowledge paths user provided + NOTE for Stage 2
- DO NOT read files yet
- Summarize product intent from user's description (not docs)
- Ask "Any other docs, research, brainstorming? Anything else before I dig in?"

**"Anything else?" pattern:** At natural pauses, ask — draws out unknown context.

**Capture-don't-interrupt:** Out-of-scope details → capture silently for distillate. Acknowledge briefly ("Good detail, I'll capture that"), don't derail.

**Fast-track:** All 4 essentials in the opening → confirm + move to Stage 2.

**Graceful redirect:** Can't articulate after 2-3 exchanges → suggest `bmad-brainstorming`.

**HALT:** When there is enough → route to `prompts/contextual-discovery.md` with the current mode.

#### Stage 2: Contextual Discovery (contextual-discovery.md)

**Goal:** Armed with intent, intelligently gather + synthesize context (docs, project knowledge, web research).

**Subagent fan-out (parallel):**
1. **Artifact Analyzer** — Scans `{planning_artifacts}`, `{project_knowledge}`, user paths
2. **Web Researcher** — Searches competitive + market

**Graceful degradation:** If subagents unavailable, read 1-2 docs inline + targeted web searches.

**Synthesis:** Merge findings + user's shared context. Identify gaps. Note surprises.

**Mode-specific behavior:**

| Mode | Action |
|------|--------|
| Guided | Present summary, highlight surprises, share gaps. Ask "Anything else, or shall we move on?" → Stage 3 |
| Yolo | Absorb silently → Stage 4 |
| Autonomous | Absorb → Stage 4 |

#### Stage 3: Guided Elicitation (guided-elicitation.md) - GUIDED MODE ONLY

**Goal:** Fill gaps with smart targeted questioning — NOT rote section-by-section.

**Skip entirely** in Yolo + Autonomous modes → go directly to Stage 4.

**Topics to cover (flexibly, conversationally):**

| Category | Questions |
|----------|-----------|
| Vision & Problem | Core problem? Who? How solve today? Success for users? What makes your angle different? |
| Users & Value | Who most acutely? Different user types? "Aha moment"? Fit into workflow? |
| Market & Differentiation | Competitive alternatives? Unfair advantage? Why now? |
| Success & Scope | How know working? Metrics? Minimum viable version? What explicitly NOT in v1? 2-3 years? |

**Flow per topic:**
```
1. Lead with what you know ("Based on input + research, sounds like X. Right?")
2. Ask gap question (targeted, specific)
3. Reflect + confirm
4. "Anything else on this, or move on?"
```

**Capture-don't-interrupt:** Detail beyond brief scope → silently for distillate.

**When to move on:**
- Have substance to draft 1-2 page brief covering: problem + who, solution + differentiator, target users (at least primary), success criteria, MVP-level scope
- Missing details surface during review
- After <3-4 exchanges, if confident + complete, proactively offer to draft

**Transition:** "I think I have a solid picture. Ready to draft, or anything else?"

#### Stage 4: Draft & Review (draft-and-review.md)

**Goal:** Produce executive brief + run multiple review lenses BEFORE user sees.

**Step 1: Draft**
- Use template at `{workflow.brief_template}`
- Executive audience — persuasive, clear, concise, 1-2 pages
- Lead with the problem
- Concrete over abstract
- Confident voice
- Write in `{document_output_language}`

**Step 2: Fan out review subagents (parallel)**

Three reviewers:
1. **Skeptic Reviewer** — "What's missing? Assumptions untested? Vague?"
2. **Opportunity Reviewer** — "Adjacent value? Market angles? Underemphasized?"
3. **Contextual Reviewer** (you pick best lens):
   - Healthtech → regulatory/compliance
   - Devtools → developer experience/adoption friction
   - Marketplace → network effects/chicken-egg
   - Enterprise → procurement/organizational change
   - Default → go-to-market risk

**Graceful degradation:** Perform all three sequentially yourself if subagents unavailable.

**Step 3: Integrate Review**
- Triage findings — group by theme, dedup
- Apply non-controversial improvements directly
- Flag substantive suggestions needing user input

**Step 4: Present to User**

| Mode | Action |
|------|--------|
| Headless | Skip to Stage 5, save improved draft |
| Yolo | Present draft + insights: "Changes?" |
| Guided | Present draft + insights |

Iterate as long as user wants. Soft gate: "anything else, or happy?"

#### Stage 5: Finalize (finalize.md)

**Step 1: Polish + Save**
- Update brief file
- `status: "complete"`, `updated` timestamp
- Ensure formatting is clean

**Step 2: Offer distillate**

"Captured additional detail — [mention 2-3 examples]. Want a detail pack for PRD creation?"

**If yes:**
```yaml
---
title: "Product Brief Distillate: {project_name}"
type: llm-distillate
source: "product-brief-{project_name}.md"
created: "{timestamp}"
purpose: "Token-efficient context for downstream PRD creation"
---
```

Dense bullets by theme, self-contained, including:
- Rejected ideas + rationale
- Requirements hints
- Technical context
- Detailed user scenarios
- Competitive intelligence
- Open questions
- Scope signals
- Resource/timeline estimates

**Headless mode:** Always create distillate automatically (unless session too brief).

**Step 3: Present completion**
```
Your product brief for {project_name} is complete!

Executive Brief: {path}
Detail Pack: {path}  [if distillate]

Recommended next: Use as input for PRD creation. Tell assistant "create a PRD" and point to these files.
```

**Headless JSON:**
```json
{
  "status": "complete",
  "brief": "path",
  "distillate": "path or null",
  "confidence": "high | medium | low",
  "open_questions": ["..."]
}
```

### State machine

```
[Entry]
  ↓ parse args
[Stage 1: Intent]
  ↓ route by mode
  ├─ autonomous → [Stage 2 direct]
  ├─ yolo → [Stage 1 (brief)] → [Stage 4 direct]
  └─ guided → [Stage 1 (discovery)]
              ↓
[Stage 2: Contextual Discovery]
  ↓ mode check
  ├─ guided → [Stage 3: Elicitation]
  │             ↓
  └─ yolo/autonomous → [Stage 4: Draft & Review]
                        ↓
[Stage 5: Finalize]
  ↓
[Complete + optional distillate]
```

---

# PHASE 2 - PLANNING

## 2-1. bmad-agent-pm (John 📋)

### Persona

```toml
[agent]
name = "John"
title = "Product Manager"
icon = "📋"
role = "Translate product vision into a validated PRD, epics, and stories that development can execute during the BMad Method planning phase"
identity = "Thinks like Marty Cagan and Teresa Torres. Writes with Bezos's six-pager discipline"
communication_style = "Detective's 'why?' relentless. Direct, data-sharp, cuts through fluff"

principles = [
  "PRDs emerge from user interviews, not template filling",
  "Ship the smallest thing that validates the assumption",
  "User value first; technical feasibility is a constraint",
]

[[agent.menu]]
code = "CP"
description = "Expert led facilitation to produce your Product Requirements Document"
skill = "bmad-create-prd"

[[agent.menu]]
code = "VP"
description = "Validate a PRD is comprehensive, lean, well organized and cohesive"
skill = "bmad-validate-prd"

[[agent.menu]]
code = "EP"
description = "Update an existing Product Requirements Document"
skill = "bmad-edit-prd"

[[agent.menu]]
code = "CE"
description = "Create the Epics and Stories Listing that will drive development"
skill = "bmad-create-epics-and-stories"

[[agent.menu]]
code = "IR"
description = "Ensure PRD, UX, Architecture and Epics and Stories List aligned"
skill = "bmad-check-implementation-readiness"

[[agent.menu]]
code = "CC"
description = "Determine how to proceed if major need for change discovered mid implementation"
skill = "bmad-correct-course"
```

---

## 2-2. bmad-agent-ux-designer (Sally 🎨)

### Persona

```toml
[agent]
name = "Sally"
title = "UX Designer"
icon = "🎨"
role = "Turn user needs and PRD into UX design specifications that inform architecture and implementation during BMad Method planning phase"
identity = "Grounded in Don Norman's human-centered design and Alan Cooper's persona discipline"
communication_style = "Paints pictures with words. User stories that make you feel the problem. Empathetic advocate"

principles = [
  "Every decision serves a genuine user need",
  "Start simple, evolve through feedback",
  "Data-informed, but always creative",
]

[[agent.menu]]
code = "CU"
description = "Guidance through realizing the plan for your UX to inform architecture and implementation"
skill = "bmad-create-ux-design"
```

Simple menu (only 1 item) — Sally primarily does UX via CU.

---

## 2-3. bmad-create-prd

### Metadata
- **Path:** `src/bmm-skills/2-plan-workflows/bmad-create-prd/`
- **Files:** SKILL.md (104 lines), customize.toml, `steps-c/` (15 step files), `templates/prd-template.md`, `data/prd-purpose.md`
- **Type:** Step-file architecture workflow (12 main steps + sidecars)

### Frontmatter
```yaml
name: bmad-create-prd
description: 'Create comprehensive PRDs from scratch through a disciplined step-file architecture. Use when user asks to "create a PRD" or "document requirements".'
```

### Workflow architecture (critical rules)

**Core principles:**
- Micro-file design (each step self-contained)
- Just-in-time loading (ONLY current step in memory)
- Sequential enforcement (NO skipping, optimization)
- State tracking via `stepsCompleted` array in frontmatter
- Append-only document building

**Processing rules:**
1. READ COMPLETELY — entire step file before action
2. FOLLOW SEQUENCE — numbered sections in order
3. WAIT FOR INPUT — menu presented, HALT
4. CHECK CONTINUATION — only proceed on user 'C'
5. SAVE STATE — update `stepsCompleted` before loading next
6. LOAD NEXT — read fully and follow next step

**Critical rules (NO EXCEPTIONS):**
- 🛑 NEVER load multiple step files
- 📖 ALWAYS read entire step before exec
- 🚫 NEVER skip steps
- 💾 ALWAYS update frontmatter
- 🎯 ALWAYS follow exact instructions
- ⏸️ ALWAYS halt at menus
- 📋 NEVER create mental todo lists from future steps

### Step sequence (15 files)

1. **step-01-init** — Initialize workflow, detect state, handle continuation
2. **step-01b-continue** — Resume if incomplete
3. **step-02-discovery** — Project classification + domain
4. **step-02b-vision** — (optional sidecar) Product vision
5. **step-02c-executive-summary** — (optional sidecar) Executive summary
6. **step-03-success** — Success criteria (measurable, user-centric)
7. **step-04-journeys** — User journey mapping
8. **step-05-domain** — Domain-specific requirements
9. **step-06-innovation** — Innovation + differentiation
10. **step-07-project-type** — Project type classification (greenfield/brownfield/platform extension/internal tool)
11. **step-08-scoping** — MVP scoping, scope boundaries
12. **step-09-functional** — Functional requirements (capability contract)
13. **step-10-nonfunctional** — NFRs (performance, security, scalability, accessibility)
14. **step-11-polish** — Polish for flow + coherence
15. **step-12-complete** — Completion, validation options, next steps

### Output schema

```yaml
---
title: "PRD: {project_name}"
status: "in-progress | draft | complete"
created: "{timestamp}"
updated: "{timestamp}"
stepsCompleted: [1, 2, 3, ...]
inputDocuments: ["path/to/brief.md", ...]
documentCounts:
  briefCount: 1
  researchCount: 2
  brainstormingCount: 1
  projectDocsCount: 3
projectType: "greenfield-web"
discoveredScope: "MVP + phase 2"
---

# PRD: {project_name}

## Executive Summary
[From step-02c sidecar if used]

## Vision
[From step-02b sidecar if used]

## Project Context
[From step-02-discovery]

## Success Criteria
[From step-03]

## User Journeys
[From step-04]

## Domain Requirements
[From step-05]

## Innovation & Differentiation
[From step-06]

## Project Type Classification
[From step-07]

## Scope
[From step-08]

### In scope (MVP)
### Out of scope
### Future considerations

## Functional Requirements
[From step-09]

### FR1: [name]
Description...
Acceptance signals...

### FR2: ...

## Non-Functional Requirements
[From step-10]

### Performance
### Security
### Scalability
### Accessibility
### Observability

## Polish notes
[From step-11]
```

### Per-step detail (highlight key ones)

**step-01-init.md:**
- Check for existing `{planning_artifacts}/prd.md`
- If exists + incomplete → load state → step-01b-continue
- If exists + complete → ask overwrite/cancel
- Discover input docs (brief, PRFAQ, research)
- Initialize prd.md with frontmatter
- Menu: [C] Continue

**step-02-discovery.md:**
- Project classification (greenfield? brownfield? platform extension? internal tool?)
- Domain understanding (B2B SaaS? consumer? enterprise? developer tool?)
- Load input docs, extract relevant context
- Menu: [A/P/C]

**step-03-success.md:**
- Success criteria — measurable, user-centric, time-bound
- Primary metric (one), Supporting metrics (2-3)
- How will we know the product is working?
- Menu: [A/P/C]

**step-09-functional.md:**
- Functional requirements as a **capability contract**
- Format: FR1, FR2, ... with:
  - Name
  - Description (what capability)
  - Acceptance signals (how to verify)
- User-centric, not technical implementation
- Menu: [A/P/C]

**step-12-complete.md:**
- Final review
- Update `status: "complete"`
- Offer validation chain: "Want to run bmad-validate-prd?"

### State machine

```
[Entry]
  ↓
[step-01: Init]
  ├─ existing incomplete → step-01b (resume)
  ├─ existing complete → ask overwrite
  └─ new → continue
    ↓
[step-02: Discovery] → menu
    ↓
[step-02b: Vision?] (optional sidecar)
    ↓
[step-02c: Exec Summary?] (optional sidecar)
    ↓
[step-03: Success]
    ↓
[step-04: Journeys]
    ↓
[step-05: Domain]
    ↓
[step-06: Innovation]
    ↓
[step-07: Project Type]
    ↓
[step-08: Scoping]
    ↓
[step-09: Functional Reqs]
    ↓
[step-10: NFRs]
    ↓
[step-11: Polish]
    ↓
[step-12: Complete]
```

Each step has an [A/P/C] menu → HALT → user 'C' proceeds.

---

## 2-4. bmad-create-ux-design

### Metadata
- **Path:** `src/bmm-skills/2-plan-workflows/bmad-create-ux-design/`
- **Files:** SKILL.md (76 lines), customize.toml, `steps/` (15 files), `ux-design-template.md`
- **Type:** Step-file workflow (14 main steps)

### Step sequence

1. **step-01-init** — Workflow initialization
2. **step-01b-continue** — Continuation handling
3. **step-02-discovery** — User context discovery
4. **step-03-core-experience** — Core experience articulation
5. **step-04-emotional-response** — Emotional design
6. **step-05-inspiration** — Design inspiration + reference
7. **step-06-design-system** — Design system planning
8. **step-07-defining-experience** — Experience flow definition
9. **step-08-visual-foundation** — Visual design foundation
10. **step-09-design-directions** — Multiple directions exploration
11. **step-10-user-journeys** — User journey specification
12. **step-11-component-strategy** — Component strategy + patterns
13. **step-12-ux-patterns** — UX patterns + interaction design
14. **step-13-responsive-accessibility** — Responsive design + accessibility
15. **step-14-complete** — Completion + validation

### Output schema

**Location:** `{planning_artifacts}/ux-design-specification.md`

Sections:
- Discovery insights
- Core experience principles
- Emotional response goals
- Design system (tokens, components)
- Visual foundation (typography, color, spacing)
- User journeys (happy path + edge cases)
- Component strategy
- UX patterns (interaction design)
- Responsive + accessibility specifications

### Pattern
Same as `bmad-create-prd` — step-file architecture, state tracking, append-only, A/P/C menus.

---

## 2-5. bmad-edit-prd

### Metadata
- **Path:** `src/bmm-skills/2-plan-workflows/bmad-edit-prd/`
- **Files:** SKILL.md, customize.toml, `steps-e/` (5 step files), `data/prd-purpose.md`
- **Type:** Step-file workflow (4-5 steps, E-prefixed for edit mode)

### Step sequence

1. **step-e-01-discovery** — Load PRD + issue discovery
2. **step-e-01b-legacy-conversion** — (optional) Convert legacy format
3. **step-e-02-review** — Review issues + prioritize
4. **step-e-03-edit** — Targeted editing + improvement
5. **step-e-04-complete** — Completion, validation options

### Purpose
Input: path to existing PRD.md.
Output: improved PRD with tracked changes.

Chain option: after complete → offer `bmad-validate-prd`.

---

## 2-6. bmad-validate-prd

### Metadata
- **Path:** `src/bmm-skills/2-plan-workflows/bmad-validate-prd/`
- **Files:** SKILL.md, customize.toml, `steps-v/` (14 step files), `data/prd-purpose.md`
- **Type:** Step-file workflow (13-14 steps, V-prefixed)

### Step sequence

1. **step-v-01-discovery** — Load PRD + analyze
2. **step-v-02-format-detection** — Detect format + structure
3. **step-v-02b-parity-check** — (optional) Legacy format conversion
4. **step-v-03-density-validation** — Content density check
5. **step-v-04-brief-coverage-validation** — Alignment with product brief
6. **step-v-05-measurability-validation** — Success criteria measurable?
7. **step-v-06-traceability-validation** — Requirements traceability
8. **step-v-07-implementation-leakage-validation** — No impl details in requirements
9. **step-v-08-domain-compliance-validation** — Domain-specific compliance
10. **step-v-09-project-type-validation** — Alignment with project type
11. **step-v-10-smart-validation** — SMART quality checks
12. **step-v-11-holistic-quality-validation** — Overall coherence
13. **step-v-12-completeness-validation** — Completeness assessment
14. **step-v-13-report-complete** — Generate report, fix recommendations, offer edit chain

### Output

Validation report with:
- Structure issues
- Content density issues
- Alignment gaps (PRD vs brief)
- Measurability gaps (vague success criteria)
- Traceability gaps
- Implementation leakage (tech detail in requirements)
- Domain non-compliance
- Project type misalignment
- SMART issues (non-specific, non-measurable, non-achievable, non-relevant, non-time-bound)
- Coherence issues
- Completeness gaps

### Chain
After report → offer `bmad-edit-prd` to fix identified issues.

---

## Patterns across Phase 1-2

### Agent activation (universal)
All 4 agents (Mary, Paige, John, Sally) follow the same 8-step activation.

### Step-file architecture (3 workflows use it)
- `bmad-create-prd` (12 steps in steps-c/)
- `bmad-create-ux-design` (14 steps in steps/)
- `bmad-edit-prd` (5 steps in steps-e/)
- `bmad-validate-prd` (14 steps in steps-v/)

**Common traits:**
- Each step self-contained
- Frontmatter `stepsCompleted` tracking
- Append-only document building
- [A]dvanced Elicitation / [P]arty Mode / [C]ontinue menu
- HALT at every menu

### Multi-stage workflows
- `bmad-prfaq` (5 stages)
- `bmad-product-brief` (5 stages, mode-driven)

**Common traits:**
- Stage references as separate files
- Subagent fan-out (parallel)
- Graceful degradation
- Resume detection via frontmatter `stage`

### Subagents pattern
Common sub-agents used across skills:
- **Artifact Analyzer** — scan docs
- **Web Researcher** — market/competitive
- **Skeptic Reviewer** — find gaps
- **Opportunity Reviewer** — find adjacent value
- **Contextual Reviewer** — domain-specific lens

### Distillate pattern
Both `bmad-prfaq` and `bmad-product-brief` produce:
- A main artifact (PRFAQ or Brief)
- An optional distillate (dense bullets for downstream)

The distillate feeds Phase 2 PRD creation with rich context that the main artifact elided.

---

**Continue reading:** [09c-skills-phase3-deep.md](09c-skills-phase3-deep.md) — Phase 3 Solutioning skills in detail.
