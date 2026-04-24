# 09c. Phase 3 Skills - Deep Dive (5 Skills)

> ⚠️ **UNOFFICIAL THIRD-PARTY DOCUMENTATION**
> Không phải official BMad docs. Xem [DISCLAIMER.md](DISCLAIMER.md) | Licensed MIT — xem [LICENSE](LICENSE) và [NOTICE](NOTICE)
> Official BMAD-METHOD: <https://github.com/bmad-code-org/BMAD-METHOD>

---

> **Phase 3 - Solutioning:** Critical transition từ Planning (what) sang Implementation (how). Architecture + Epics/Stories + Project Context + Readiness check.

---

## Mục lục

- [3-1. bmad-agent-architect (Winston 🏗️)](#3-1-bmad-agent-architect-winston)
- [3-2. bmad-create-architecture](#3-2-bmad-create-architecture)
- [3-3. bmad-create-epics-and-stories](#3-3-bmad-create-epics-and-stories)
- [3-4. bmad-generate-project-context](#3-4-bmad-generate-project-context)
- [3-5. bmad-check-implementation-readiness](#3-5-bmad-check-implementation-readiness)

---

## 3-1. bmad-agent-architect (Winston 🏗️)

### Persona

```toml
[agent]
name = "Winston"
title = "System Architect"
icon = "🏗️"
role = "Convert the PRD and UX into technical architecture decisions that keep implementation on track during the BMad Method solutioning phase"
identity = "Channels Martin Fowler's pragmatism and Werner Vogels's cloud-scale realism"
communication_style = "Calm and pragmatic. Balances 'what could be' with 'what should be.' Answers with trade-offs, not verdicts"

principles = [
  "Rule of Three before abstraction",
  "Boring technology for stability",
  "Developer productivity is architecture",
]

persistent_facts = [
  "file:{project-root}/**/project-context.md",
]

[[agent.menu]]
code = "CA"
description = "Guided workflow to document technical decisions to keep implementation on track"
skill = "bmad-create-architecture"

[[agent.menu]]
code = "IR"
description = "Ensure the PRD, UX, Architecture and Epics and Stories List are all aligned"
skill = "bmad-check-implementation-readiness"
```

**Menu đơn giản** (2 items) — Winston chủ yếu tạo architecture + check readiness. Epics/stories và project context thường do PM John invoke.

### Key insight
Winston's principle "**trade-offs, not verdicts**" lèo lái cả facilitation approach:
- Không áp đặt single technology choice
- Present options với pros/cons
- User decides với Winston's input

---

## 3-2. bmad-create-architecture

### Metadata
- **Path:** `src/bmm-skills/3-solutioning/bmad-create-architecture/`
- **Files:** SKILL.md, customize.toml, architecture-decision-template.md, `steps/` (8 files)
- **Type:** Micro-file workflow (8 sequential steps)

### Frontmatter
```yaml
name: bmad-create-architecture
description: 'Create comprehensive architecture decisions through collaborative step-by-step discovery. Use when "let\'s create architecture", "create technical architecture", "create a solution design".'
```

### Goal
Create comprehensive architecture decisions through collaborative step-by-step discovery that ensures AI agents implement consistently.

### Role
Architectural facilitator collaborating with **peer** (partnership, not client-vendor). User brings domain expertise + product vision; you bring structured thinking + architectural knowledge.

### 8-step workflow

#### Step 1: Init (step-01-init.md)

**Actions:**
- Check for existing `{planning_artifacts}/architecture.md`
  - If exists + incomplete → step-01b-continue
  - If exists + complete → ask overwrite/cancel
- Smart discovery of input documents:
  - Search in `{planning_artifacts}`, `{output_folder}`, `{project_knowledge}`, `{project-root}/docs`
  - Also search sharded folders (e.g., `*prd*/index.md`)
- Confirm with user which files to load
- **Validate PRD exists** (REQUIRED) — abort if missing
- Copy `architecture-decision-template.md` → `{planning_artifacts}/architecture.md`
- Update frontmatter: `stepsCompleted: [1]`, `inputDocuments: [list]`
- Report findings, ask if additional docs needed
- **Menu:** [C] Continue to context analysis
- **HALT** — wait for 'C'

#### Step 2: Context Analysis (step-02-context.md)

**Actions:**
- Analyze loaded documents for architectural scope:
  - Extract FRs, NFRs from PRD
  - Extract implications from Epics/Stories (if available)
  - Extract UX architectural implications:
    - Component complexity
    - Responsiveness needs
    - Real-time requirements
    - Accessibility
    - Performance expectations
  - Calculate project complexity indicators
- Reflect understanding back to user for validation
- Generate "Project Context Analysis" section:
  - Requirements Overview
  - NFRs
  - Scale & Complexity
  - Constraints
  - Cross-Cutting Concerns
- **Menu:** [A] Advanced Elicitation | [P] Party Mode | [C] Continue
- **HALT** — user 'C' only

#### Step 3: Starter Template Evaluation (step-03-starter.md)

**Actions:**
- Check project context for existing technical preferences
- Discover user preferences: languages, frameworks, databases, cloud, integrations
- **Search web for current starter options:**
  - Web, mobile, API, CLI, full-stack, desktop
- Consider UX requirements when picking:
  - Animations → Framer Motion
  - Forms → React Hook Form
  - etc.
- Investigate top starters for:
  - Technologies used
  - Structure
  - Patterns
  - Deployment approach
- Analyze decisions each starter makes:
  - Language + styling + testing + linting + build + organization + dev experience
- Generate "Starter Template Evaluation" section:
  - Selected starter rationale
  - Init command
  - Decisions already provided by starter
- **Menu:** [A/P/C]
- **HALT**

#### Step 4: Core Architectural Decisions (step-04-decisions.md)

**Actions:**
- Review technical preferences + starter decisions + project context rules
- **Identify REMAINING decisions** (don't re-decide starter choices)
- Facilitate decision categories:

| Category | Decisions |
|----------|-----------|
| **Data Architecture** | Database, data modeling, validation, migration, caching |
| **Auth & Security** | Authentication, authorization, middleware, encryption, API security |
| **API & Communication** | API design (REST/GraphQL), docs, error handling, rate limiting, service comm |
| **Frontend Architecture** | State management, component architecture, routing, perf, bundle optimization |
| **Infrastructure & Deployment** | Hosting, CI/CD, env config, monitoring/logging, scaling |

**For each decision:**
1. Present options with trade-offs
2. **Verify technology versions via web search** (latest stable)
3. Get user input
4. Record decision

- Check cascading implications between decisions
- Generate "Core Architectural Decisions" section:
  - Decision Priority Analysis
  - Decisions by category (with versions + rationale)
  - Impact Analysis
  - Implementation Sequence
  - Cross-Component Dependencies
- **Menu:** [A/P/C]

#### Step 5: Implementation Patterns & Consistency Rules (step-05-patterns.md)

**Purpose:** Identify potential conflict points where AI agents could decide differently.

**Conflict categories:**

| Category | Examples |
|----------|----------|
| **Naming** | DB tables/columns, API endpoints, file/dir, component/function, route params |
| **Structural** | Test locations, component organization, utility locations, config organization, assets |
| **Format** | API response wrappers, error structures, date/time formats, JSON field naming, status codes |
| **Communication** | Event naming, event payloads, state update patterns, action naming, logging |
| **Process** | Loading state handling, error recovery, retry patterns, auth flows, validation timing |

**For each pattern:**
- Show options + trade-offs
- Get user decision

**Generate section:**
- Pattern Categories
- Naming Patterns
- Structure Patterns
- Format Patterns
- Communication Patterns
- Process Patterns
- Enforcement Guidelines
- Pattern Examples (Good / Anti-Patterns)

- **Menu:** [A/P/C]

#### Step 6: Project Structure & Boundaries (step-06-structure.md)

**Actions:**
- Map requirements/epics to architectural components
- Define complete directory structure:
  - Root config
  - Source code
  - Tests
  - Build/dist
- Define integration boundaries:
  - API boundaries
  - Component boundaries
  - Service boundaries
  - Data boundaries
- Create **complete project tree** (specific for tech stack, NOT generic placeholders)

**Example: Next.js full-stack:**
```
project-root/
├── src/
│   ├── app/            # App router
│   │   ├── (auth)/     # Auth routes group
│   │   └── api/        # API routes
│   ├── components/     # React components
│   │   ├── ui/         # Primitives (from shadcn)
│   │   └── features/   # Feature components
│   ├── lib/            # Utilities, hooks
│   └── styles/         # Global styles
├── prisma/             # DB schema + migrations
├── tests/              # E2E tests (Playwright)
└── docs/               # Architecture docs
```

**Example: NestJS backend:**
```
project-root/
└── src/
    ├── modules/        # Feature modules (each self-contained)
    │   ├── auth/
    │   │   ├── controllers/
    │   │   ├── services/
    │   │   ├── guards/
    │   │   └── auth.module.ts
    │   └── users/
    ├── shared/         # Shared services
    └── main.ts
```

- Map requirements → specific file/directory structure
- Map cross-cutting concerns (auth system) → specific locations

**Generate section:**
- Complete Project Tree
- Architectural Boundaries
- Requirements to Structure Mapping
- Integration Points
- File Organization Patterns
- Development Workflow Integration

- **Menu:** [A/P/C]

#### Step 7: Architecture Validation (step-07-validation.md)

**Validation layers:**

**Coherence validation:**
- All tech choices compatible
- Versions compatible
- Patterns align (no contradictions)

**Requirements coverage:**
- Every epic/FR/NFR architecturally supported

**Implementation readiness:**
- Are decisions documented?
- Are patterns comprehensive?
- Are consistency rules clear?

**Gap analysis:**
- Critical gaps (missing decisions/patterns/structure)
- Important gaps
- Nice-to-have gaps

**Address issues:** Present to user, facilitate resolution.

**Generate section:**
- Coherence Validation ✅
- Requirements Coverage ✅
- Implementation Readiness ✅
- Gap Analysis
- Issues Addressed
- Architecture Completeness Checklist
- Architecture Readiness Assessment
- Implementation Handoff

- **Menu:** [A/P/C]

#### Step 8: Completion & Handoff (step-08-complete.md)

**Actions:**
- Congratulate on completion
- Update frontmatter: `stepsCompleted: [1-8]`, `workflowType: 'architecture'`, `status: 'complete'`, `completedAt`
- Next steps:
  - Invoke `bmad-help` skill
- Offer to answer questions

### Template structure

**architecture-decision-template.md:**
```yaml
---
stepsCompleted: []
inputDocuments: []
workflowType: 'architecture'
project_name: '{{project_name}}'
user_name: '{{user_name}}'
date: '{{date}}'
---

# Architecture Decision Document

_This document builds collaboratively through step-by-step discovery..._
```

Initial content chỉ có heading. Sections append per step:
1. Project Context Analysis
2. Starter Template Evaluation
3. Core Architectural Decisions
4. Implementation Patterns & Consistency Rules
5. Project Structure & Boundaries
6. Architecture Validation Results

### Input schema
- **Required:** PRD path (`{planning_artifacts}/*prd*.md`)
- **Optional:** UX Design (`{planning_artifacts}/*ux*.md`), Architecture (existing), Research
- **Config:** `{planning_artifacts}`, `{project_knowledge}`, `{project-root}`

### Output schema
- **File:** `{planning_artifacts}/architecture.md`
- **Frontmatter:** Tracks steps, inputs, workflow state
- **6+ H2 sections,** each appended per step

### Critical workflow rules

1. **Micro-file sequential enforcement:** Read COMPLETELY before execution. NEVER load multiple steps
2. **State tracking:** `stepsCompleted` updated BEFORE loading next step
3. **Append-only:** Content appends, never overwrites
4. **User control:** Each step menu (A/P/C). NEVER auto-proceed past menu wait
5. **Continuation handling:** step-01b detects existing workflows, offers [R]esume, [C]ontinue, [O]verview, [X] Start-over
6. **HALT conditions:** After every menu, ALWAYS halt
7. **Error handling:**
   - Missing PRD = abort
   - Duplicates in discovery = flag for user resolution

### State machine

```
[START] → step-01 (Existing?)
           ├─ YES → step-01b [R/C/O/X] → selected step
           └─ NO → discover inputs, create template, [C] menu
                   ↓
      step-02 (Context) [A/P/C] → C ↓
      step-03 (Starter) [A/P/C] → C ↓
      step-04 (Decisions) [A/P/C] → C ↓
      step-05 (Patterns) [A/P/C] → C ↓
      step-06 (Structure) [A/P/C] → C ↓
      step-07 (Validation) [A/P/C] → C ↓
      step-08 (Complete) → [DONE]
```

### Code-ready spec

```typescript
interface ArchitectureWorkflowState {
  projectName: string;
  stepsCompleted: number[];
  inputDocuments: string[];
  currentStep: number;
  decisions: Map<string, Decision>;
  patterns: PatternSet;
  projectTree: DirectoryTree;
}

interface Decision {
  category: 'data' | 'auth' | 'api' | 'frontend' | 'infrastructure';
  name: string;
  options: Array<{ name: string; version: string; pros: string[]; cons: string[] }>;
  chosen: string;
  rationale: string;
  cascadingImplications: string[];
}
```

---

## 3-3. bmad-create-epics-and-stories

### Metadata
- **Path:** `src/bmm-skills/3-solutioning/bmad-create-epics-and-stories/`
- **Files:** SKILL.md, customize.toml, `templates/epics-template.md`, `steps/` (4 files)
- **Type:** Step-file workflow (4 steps)

### Frontmatter
```yaml
name: bmad-create-epics-and-stories
description: 'Break requirements into epics and user stories organized by user value. Use when "create the epics and stories list".'
```

### Goal
Transform PRD requirements + Architecture decisions into comprehensive stories organized by **USER VALUE**, creating detailed actionable stories với complete acceptance criteria for Developer agent.

### Role
Product strategist + technical specifications writer. Partnership with product owner.

### CRITICAL RULES (NO EXCEPTIONS)

**1. Epics organized by USER VALUE, not technical layers**

✅ CORRECT:
- "User Authentication & Profiles" (users can register, login, manage)
- "Content Creation" (users can create, edit, publish)
- "Social Interaction" (users can follow, comment, like)

❌ WRONG:
- "Database Setup"
- "API Development"
- "Frontend Components"

**2. Each epic STANDALONE**
- Epic 2 doesn't need Epic 3 to function
- Epic N doesn't need Epic N+1

**3. Stories MUST NOT depend on future stories**
- Within epic: Story 1.2 can ONLY depend on Story 1.1 output
- Across epics: Epic 2 uses Epic 1 output only

**4. Database/entities created ONLY when needed by story**
- ❌ WRONG: Epic 1 Story 1 creates all 50 tables
- ✅ RIGHT: Each story creates/alters only what it needs

### 4-step workflow

#### Step 1: Validate Prerequisites & Extract Requirements

**Document discovery:**
- Search PRD: `{planning_artifacts}/*prd*.md` hoặc `*prd*/index.md`
- Search Architecture: `{planning_artifacts}/*architecture*.md`
- Search UX: `{planning_artifacts}/*ux*.md` (optional)

**Extract requirements rigorously:**
- ALL Functional Requirements (FR1, FR2, ...)
- ALL NFRs (performance, security, usability, reliability, compliance)
- Additional from Architecture (starter template? infrastructure? integration? monitoring?)

**UX-DR extraction (CRITICAL):**
- If UX exists, extract Design Requirements RIGOROUSLY
- Not summarized: "Create reusable components"
- Itemized: "6 components" (list all 6 individually)
- Categories:
  - Design tokens
  - Component proposals
  - Visual standardization
  - Accessibility
  - Responsive design
  - Interaction patterns
  - Browser compatibility

**Initialize document:**
- Load `epics-template.md` → `{planning_artifacts}/epics.md`
- Replace: `{{fr_list}}`, `{{nfr_list}}`, `{{additional_requirements}}`, `{{ux_design_requirements}}`

**Present to user for confirmation.**

- **Menu:** [C] Confirm requirements complete?
- Update frontmatter with extracted count, `inputDocuments`
- **HALT**

#### Step 2: Design Epic List

**Explain epic design principles:**
- **User-Value First:** Each epic enables meaningful user accomplishment
- **Requirements Grouping:** Related FRs for cohesive outcomes
- **Incremental Delivery:** Each epic delivers value independently
- **Logical Flow:** Natural progression from user's perspective
- **🔗 Dependency-Free:** Stories within epic MUST NOT depend on future stories

**Identify user value themes from FRs.**

**Design epics collaboratively:**
Each epic has:
- Title (user-centric)
- User Outcome
- FR Coverage (which FRs)
- Implementation Notes

**Create epics_list markdown:**
```markdown
### Epic 1: [Title]
[Goal statement]

**FRs covered:** FR1, FR2, FR3
```

**Present for review + create FR Coverage Map:**
```markdown
| FR | Epic | Story (planned) |
|----|------|-----------------|
| FR1 | Epic 1 | Story 1.1 |
| FR2 | Epic 1 | Story 1.2 |
| FR3 | Epic 2 | Story 2.3 |
```

Ask: Does structure align with vision? Should we adjust groupings?

Get explicit APPROVAL (iterate if needed).

- **Menu:** [A/P/C]
- Update `{planning_artifacts}/epics.md`: `{{epics_list}}`, `{{requirements_coverage_map}}`
- Update frontmatter: `stepsCompleted: [1, 2]`
- **HALT**

#### Step 3: Generate Epics & Stories

**UX Design Integration:**
If UX-DRs extracted, ensure covered by stories:
- Within feature epics (integrated)
- Or dedicated "Design System / UX Polish" epic

**Database principle:**
- Create tables ONLY when story needs them
- ❌ WRONG: Epic 1 Story 1 creates all 50 tables
- ✅ RIGHT: Each story creates/alters only what it needs

**Dependency principle:**
- Stories independently completable in sequence
- ❌ WRONG: Story 1.2 requires Story 1.3
- ✅ RIGHT: Each story based on previous only

**Story format (from template):**
```markdown
### Story {{N}}.{{M}}: {{story_title}}

As a {{user_type}},
I want {{capability}},
So that {{value_benefit}}.

**Acceptance Criteria:**
**Given** {{precondition}}
**When** {{action}}
**Then** {{expected_outcome}}
**And** {{additional_criteria}}
```

**Examples:**

✅ GOOD:
- "Story 1.1: User Registration with Email"
- "Story 1.2: User Login with Password"
- "Story 2.1: Create New Blog Post"

❌ BAD:
- "Set up database"
- "Create all models"
- "Login UI (depends on Story 1.3 API)" ← forward dependency!

**Process epics sequentially:**

For each epic:
1. Epic overview: title, goal, FRs covered, relevant UX-DRs
2. Story breakdown: identify distinct user capabilities, logical flow, sizing
3. For each story:
   - Title
   - User Story (As a / I want / So that)
   - Acceptance Criteria (Given / When / Then)
4. AC writing:
   - Specific, testable
   - Edge cases
   - Error conditions
   - Reference requirements
5. Collaborative review:
   - Is requirement captured?
   - Scope appropriate?
   - ACs complete + testable?
6. Append to `{planning_artifacts}/epics.md` per approval

**After all epics complete:**
- Verify template structure followed exactly
- All FRs covered
- **All UX-DRs covered**
- Formatting consistent

- **Menu:** [A/P/C]
- **HALT**

#### Step 4: Final Validation

**FR Coverage Validation:**
- Every FR → at least one story's acceptance criteria

**Architecture Implementation Validation:**
- If Architecture specifies starter template:
  - Epic 1 Story 1 MUST BE "Set up initial project from starter template"
- DB/Entity creation: Tables created ONLY when needed by FIRST story that needs them

**Story Quality:**
- Each story completable by single dev agent
- Clear ACs
- References FRs
- Technical details
- **NO forward dependencies**

**Epic Structure:**
- Epics deliver user value
- Dependencies flow naturally
- Foundation stories setup only what's needed

**Dependency Validation (CRITICAL):**

**Epic Independence:**
- Each epic delivers COMPLETE functionality for domain
- Epic 2 functions without Epic 3
- Epic 3 functions standalone using Epic 1 & 2 outputs

**Within-Epic Dependency:**
- Can Story N.1 be completed without N.2, N.3?
- Can N.2 be completed using only N.1 output?

**Complete + save epics.md.**

- **Menu:** [C] Complete Workflow
- Invoke `bmad-help` skill
- Offer questions

### Template structure

**epics-template.md:**
```yaml
---
stepsCompleted: []
inputDocuments: []
---

# {{project_name}} - Epic Breakdown

## Overview
[project description]

## Requirements Inventory

### Functional Requirements
{{fr_list}}

### NonFunctional Requirements
{{nfr_list}}

### Additional Requirements
{{additional_requirements}}

### UX Design Requirements
{{ux_design_requirements}}

### FR Coverage Map
{{requirements_coverage_map}}

## Epic List
{{epics_list}}

## Epic {{N}}: {{epic_title_N}}
[goal statement]

### Story {{N}}.{{M}}: {{story_title_N_M}}
As a {{user_type}}, I want {{capability}}, So that {{value_benefit}}.

**Acceptance Criteria:**
**Given** {{precondition}}
**When** {{action}}
**Then** {{expected_outcome}}
**And** {{additional_criteria}}
```

### Code-ready spec

```typescript
interface Epic {
  number: number;
  title: string;              // User-centric
  goal: string;
  frsCovered: string[];       // ['FR1', 'FR2']
  stories: Story[];
}

interface Story {
  number: string;             // '1.1', '1.2', '2.1'
  title: string;
  userType: string;           // As a...
  capability: string;         // I want...
  benefit: string;            // So that...
  acceptanceCriteria: AC[];
  dependencies: string[];     // Only prior story numbers
}

interface AC {
  given: string;
  when: string;
  then: string;
  and?: string[];
}

function validateEpicIndependence(epics: Epic[]): ValidationResult {
  const violations = [];
  
  for (const [i, epic] of epics.entries()) {
    for (const story of epic.stories) {
      for (const dep of story.dependencies) {
        const [depEpic, depStory] = dep.split('.').map(Number);
        
        // Forward dependency check
        if (depEpic > epic.number) {
          violations.push({
            type: 'FORWARD_EPIC_DEP',
            story: story.number,
            depends_on: dep
          });
        }
        
        // Within-epic forward dependency
        if (depEpic === epic.number && depStory >= parseInt(story.number.split('.')[1])) {
          violations.push({
            type: 'FORWARD_STORY_DEP',
            story: story.number,
            depends_on: dep
          });
        }
      }
    }
  }
  
  return { violations, passed: violations.length === 0 };
}
```

---

## 3-4. bmad-generate-project-context

### Metadata
- **Path:** `src/bmm-skills/3-solutioning/bmad-generate-project-context/`
- **Files:** SKILL.md, customize.toml, project-context-template.md, `steps/` (3 files)
- **Type:** Micro-file workflow (3 steps)

### Frontmatter
```yaml
name: bmad-generate-project-context
description: 'Generate or update project-context.md containing critical rules AI agents MUST follow when implementing. Use when "generate project context", "create project context".'
```

### Goal
Create concise, optimized `project-context.md` containing critical rules, patterns, guidelines AI agents MUST follow. **Focus on unobvious details LLMs need to be reminded of.**

### Role
Technical facilitator with peer to capture essential implementation rules for consistent high-quality code generation.

### 3-step workflow

#### Step 1: Context Discovery & Initialization

**Check for existing:**
- Look for `{project_knowledge}/project-context.md` hoặc `{project-root}/**/project-context.md`
- If exists: Present options [Update / Create new]

**Discover technology stack:**
- Load Architecture.md → extract tech choices + versions
- Check package files (package.json, requirements.txt, Cargo.toml) → exact dependency versions
- Check config files (tsconfig.json, webpack, vite, eslintrc, prettierrc, jest, vitest)

**Identify existing code patterns:**
- Naming conventions (file, component, function, variable, test files)
- Code organization (components, utilities, services, tests)
- Documentation patterns (comments, READMEs, API docs)

**Extract critical rules by category:**

| Category | Focus |
|----------|-------|
| **Language-specific** | TypeScript strict mode, import/export, async patterns, error handling |
| **Framework-specific** | React hooks, API routes, middleware, state management |
| **Testing** | Test structure, mocking, boundaries, coverage |
| **Development workflow** | Branch naming, commit patterns, PR requirements, deployment |

**Initialize document:**
- Fresh: Copy `project-context-template.md` → `{output_folder}/project-context.md`
- Existing: Load for updates

**Present summary:**
- Tech stack với versions
- Existing patterns found (count)
- Key areas for rules
- If existing: sections already defined

- **Menu:** [C] Continue to generation
- **HALT**

#### Step 2: Context Rules Generation

**Categories to fill:**

1. **Technology Stack & Versions** — Exact tech
2. **Language-Specific Rules** — Unobvious patterns
3. **Framework-Specific Rules** — Project conventions
4. **Testing Rules** — Consistency patterns
5. **Code Quality & Style Rules** — Critical style + quality
6. **Development Workflow Rules** — Impact on implementation
7. **Critical Don't-Miss Rules** — Prevent common mistakes

**For each category:**
- Present findings based on `user_skill_level` (Expert / Intermediate / Beginner)
- Get user input
- Generate lean content

**Menu each category:** [A/P/C]

- C: Save category to project-context.md, update `sections_completed: [...]`

**Iterate all categories.**

#### Step 3: Context Completion & Finalization

**Review complete file:**
- Length, clarity, coverage, actionability
- Organization, consistency, scannability, information density

**Optimize for LLM context efficiency:**
- Remove redundant/obvious rules
- Combine related rules
- Specific + actionable language
- Each rule unique value
- Consistent markdown formatting
- Strategic bolding
- Maximize information density

**Ensure final structure:**

```markdown
# Project Context for AI Agents

_Focus on unobvious details..._

## Technology Stack & Versions
{{concise_tech_list}}

## Critical Implementation Rules

### Language-Specific Rules
### Framework-Specific Rules
### Testing Rules
### Code Quality & Style Rules
### Development Workflow Rules
### Critical Don't-Miss Rules

## Usage Guidelines

For AI Agents:
- Read before implementing
- Follow ALL rules exactly
- Prefer more restrictive option if unsure
- Update if new patterns emerge

For Humans:
- Keep lean + focused
- Update when stack changes
- Review quarterly for outdated rules
- Remove obvious rules over time

Last Updated: {{date}}
```

**Present completion summary:**
- Rule count, section count
- LLM optimization status
- Next steps: AI agents read before implementing, update as project evolves

**Update frontmatter:** `sections_completed: [all]`, `status: 'complete'`, `rule_count`, `optimized_for_llm: true`

**Completion validation:**
- All versions documented
- Language-specific rules specific
- Framework rules cover conventions
- Testing rules ensure consistency
- Quality rules maintain standards
- Workflow rules prevent conflicts
- Anti-pattern rules prevent mistakes

Invoke `bmad-help` skill.

### Template

**project-context-template.md:**
```yaml
---
project_name: '{{project_name}}'
user_name: '{{user_name}}'
date: '{{date}}'
sections_completed: ['technology_stack']
existing_patterns_found: {{number_discovered}}
---

# Project Context for AI Agents

_Critical rules + patterns for consistent code generation. Focus on unobvious details LLMs might miss._

---

## Technology Stack & Versions
_Documented after discovery phase_

## Critical Implementation Rules
_Documented after discovery phase_
```

### Example final project-context.md

```markdown
# Project Context for AI Agents

## Technology Stack & Versions

- **Runtime:** Node.js 20.11.0 (LTS)
- **Language:** TypeScript 5.3 (strict mode)
- **Framework:** React 18.2 with Next.js 14 (App Router)
- **State:** Zustand 4.5 (NOT Redux)
- **Testing:** Vitest 1.4 (NOT Jest), Playwright 1.42 for E2E
- **Database:** PostgreSQL 16 via Prisma 5.10
- **Styling:** Tailwind CSS 3.4 + shadcn/ui components

## Critical Implementation Rules

### Language-Specific Rules

**TypeScript Configuration:**
- `strict: true` + `noUncheckedIndexedAccess: true` enabled
- Use `interface` for public APIs, `type` for unions
- NO `any` — use `unknown` and narrow

**Import/Export:**
- Barrel exports from `index.ts` in each module
- Absolute imports via `@/` alias
- Type-only imports: `import type { Foo } from './bar'`

### Framework-Specific Rules

**React:**
- Server Components by default (App Router)
- Client components only when needed (`'use client'` directive)
- NO class components
- Hooks only called at component top level
- Custom hooks start with `use`

**State Management:**
- Zustand for global state
- React Query for server state
- `useState` for local UI state only

### Testing Rules

- Unit tests co-located: `Component.tsx` + `Component.test.tsx`
- Integration tests in `__tests__/` folder
- E2E tests in `tests/e2e/`
- Mock API with MSW (NOT axios mock)
- Coverage threshold: 80% business logic

### Code Quality & Style Rules

- ESLint: `next/core-web-vitals` + custom rules in `.eslintrc.js`
- Prettier: 2-space indent, no semi, single quotes
- File naming: kebab-case (`user-profile.tsx`)
- Component naming: PascalCase (`UserProfile`)

### Development Workflow Rules

- Branch: `feat/`, `fix/`, `chore/` prefixes
- Commits: Conventional Commits format
- PR: Must pass lint + tests + type-check
- Deployment: Vercel, auto on main merge

### Critical Don't-Miss Rules

1. **NEVER use `useEffect` for data fetching** — use React Query
2. **NEVER access `window` without `typeof window !== 'undefined'`** check (SSR)
3. **ALWAYS validate input at API boundaries** with Zod
4. **ALWAYS use `revalidatePath` after mutations** (Next.js cache)
5. **NEVER commit secrets** — use `.env.local` (gitignored)

## Usage Guidelines

For AI Agents:
- Read before implementing ANY story
- Follow ALL rules exactly
- Prefer more restrictive option if unsure
- Update file if new patterns emerge

Last Updated: 2026-04-24
```

---

## 3-5. bmad-check-implementation-readiness

### Metadata
- **Path:** `src/bmm-skills/3-solutioning/bmad-check-implementation-readiness/`
- **Files:** SKILL.md, customize.toml, `templates/readiness-report-template.md`, `steps/` (6 files)
- **Type:** Step-file workflow (6 steps, mostly auto-proceed)

### Frontmatter
```yaml
name: bmad-check-implementation-readiness
description: 'Validate PRD, UX, Architecture, Epics and Stories are complete and aligned before Phase 4 implementation starts. Use when "check implementation readiness".'
```

### Goal
Quality gate **before Phase 4 starts.** Ensure epics/stories logical + accounted for all requirements + planning.

### Role
**Expert Product Manager renowned in requirements traceability + spotting gaps.** Success = spot failures others made in planning/preparation.

### 6-step workflow

#### Step 1: Document Discovery

**Search:**
- PRD: `{planning_artifacts}/*prd*.md` (whole) or `*prd*/index.md` (sharded)
- Architecture: `{planning_artifacts}/*architecture*.md` or `*architecture*/index.md`
- Epics & Stories: `{planning_artifacts}/*epic*.md` or `*epic*/index.md`
- UX: `{planning_artifacts}/*ux*.md` or `*ux*/index.md`

**Organize findings:**
- List whole + sharded documents
- Sizes, modified dates

**Identify critical issues:**
- Duplicates (both whole + sharded) = CRITICAL
- Missing documents = WARNING

**Initialize output:**
`{outputFile} = {planning_artifacts}/implementation-readiness-report-{date}.md`
from `readiness-report-template.md`.

**Present findings, ask user:**
- Resolve duplicates?
- Confirm file selections?

- **Menu:** [C] Continue after resolving
- Update frontmatter with files being used
- **HALT**

#### Step 2: PRD Analysis (auto-proceed)

**Actions:**
- Load + read PRD completely (whole or all sharded)
- Extract ALL FRs:
  - Format: FR1, FR2, ... or "Functional Requirement" labels
  - User actions, system behaviors, business rules
- Extract ALL NFRs:
  - Performance, Security, Usability, Reliability, Scalability, Compliance
- Document additional (constraints, assumptions, technical, business, integration)

**Append to {outputFile}:**
- PRD Analysis section
- FR list
- NFR list
- Additional Requirements
- PRD Completeness Assessment

**Auto-proceed to step 3** (no menu).

#### Step 3: Epic Coverage Validation (auto-proceed)

**Actions:**
- Load epics & stories document
- Extract FR coverage claims (which FRs → which epics)
- Compare against PRD FR list from step 2

**Coverage matrix:**
```markdown
| FR Number | PRD Requirement | Epic Coverage | Status |
|-----------|-----------------|---------------|--------|
| FR1 | [text] | Epic X Story Y | ✓ Covered |
| FR2 | [text] | **NOT FOUND** | ❌ MISSING |
| FR3 | [text] | Epic Y Story Z | ✓ Covered |
```

**List missing coverage** with impact + recommendations.

**Append to {outputFile}:**
- Epic Coverage Validation section
- Matrix
- Missing requirements
- Coverage statistics

**Auto-proceed to step 4.**

#### Step 4: UX Alignment (auto-proceed)

**Check for UX.**

**If UX exists:**
- Validate UX ↔ PRD alignment:
  - UX requirements reflected in PRD?
  - User journeys match use cases?
  - UX requirements NOT in PRD?
- Validate UX ↔ Architecture alignment:
  - Architecture supports UX requirements?
  - Performance needs?
  - UI components supported?

**If NO UX:**
- Assess if UX/UI implied: Does PRD mention UI? Web/mobile? User-facing?
- If implied but missing: Warning

**Append:**
- UX Alignment Assessment section
- Alignment issues, warnings

**Auto-proceed to step 5.**

#### Step 5: Epic Quality Review (auto-proceed)

**Rigorously apply create-epics-and-stories best practices.** NO compromise.

**Epic Structure Validation:**

**User Value Focus:**
- Epic title user-centric?
- Goal describes user outcome?
- Can users benefit alone?
- 🔴 RED FLAGS: "Setup Database", "Create Models", "API Development", "Infrastructure Setup"

**Epic Independence:**
- Epic 1 standalone
- Epic 2 uses only Epic 1
- Epic N doesn't need N+1
- 🔴 VIOLATIONS: Epic 2 requires Epic 3 features, forward story references, circular deps

**Story Quality:**
- Sizing: Clear user value, independent?
- AC Review: Given/When/Then? Testable? Error conditions?
- 🔴 VIOLATIONS: Vague ACs ("user can login"), missing errors, incomplete paths

**Dependency Analysis:**
- Within-Epic: 1.1 standalone → 1.2 uses 1.1 → 1.3 uses 1.1 + 1.2
- 🔴 VIOLATIONS: "Depends on Story 1.4", future story refs
- Database Creation: Tables created ONLY when first needed

**Special Checks:**
- If Architecture specifies starter template → Epic 1 Story 1 = "Set up initial project from starter template"
- Greenfield: project setup, env config, CI/CD early
- Brownfield: integration + migration stories

**Best Practices Checklist:**
- [ ] Epic delivers value?
- [ ] Independent?
- [ ] Stories sized?
- [ ] No forward dependencies?
- [ ] Tables created when needed?
- [ ] Clear ACs?
- [ ] FR traceability?

**Document violations by severity:**

| Severity | Examples |
|----------|----------|
| 🔴 **Critical** | Technical epics no user value, forward deps breaking independence, epic-sized stories not completable |
| 🟠 **Major** | Vague ACs, stories requiring future stories, database violations |
| 🟡 **Minor** | Formatting inconsistencies, structure deviations, doc gaps |

**This step executes AUTONOMOUSLY** (rigorously enforces, no user menu).

**Append:**
- Epic Quality Review section
- All violations
- Remediation guidance

**Auto-proceed to step 6.**

#### Step 6: Final Assessment

**Review all findings.**

**Add Summary:**
```markdown
## Summary and Recommendations

### Overall Readiness Status
[READY / NEEDS WORK / NOT READY]

### Critical Issues Requiring Immediate Action
[List most critical]

### Recommended Next Steps
1. [Specific action 1]
2. [Specific action 2]
3. [Specific action 3]

### Final Note
Found [X] issues across [Y] categories. Address critical before implementation.
```

**Status classification:**

| Status | Meaning |
|--------|---------|
| **READY** | All checks pass, can proceed to Phase 4 |
| **NEEDS WORK** | Critical issues, address first |
| **NOT READY** | Show-stoppers, cannot proceed |

**Complete report:**
- Verify findings clear
- Recommendations actionable
- Add date/assessor info
- Save

**Present completion.** Invoke `bmad-help` skill.

### Template

**readiness-report-template.md:**
```markdown
# Implementation Readiness Assessment Report

**Date:** {{date}}
**Project:** {{project_name}}
```

Sections appended per step:
1. Document Discovery (files, inventory, duplicates)
2. PRD Analysis (FRs, NFRs, additional)
3. Epic Coverage Validation (matrix, missing, stats)
4. UX Alignment Assessment (status, issues, warnings)
5. Epic Quality Review (violations by severity, remediation)
6. Summary and Recommendations (status, critical, next steps)

### HALT conditions

- **Step 1:** HALT at [C] menu — DON'T auto-proceed if duplicates unresolved
- **Steps 2-6:** Auto-proceed (no menus)
- **Global:** If required document missing (PRD), report + stop

### Key concepts

- **Requirements Traceability:** Every FR from PRD traces to at least one story's AC
- **Epic Independence:** Each epic delivers COMPLETE standalone value
- **Story Independence:** Within epic, flow forward only
- **Quality Enforcement:** Rigorously apply best practices, no compromise
- **Database Timing:** NOT all tables upfront
- **Readiness Status:** READY / NEEDS WORK / NOT READY

### Code-ready spec

```typescript
interface ReadinessReport {
  projectName: string;
  date: Date;
  documents: {
    prd: string | null;
    architecture: string | null;
    epics: string | null;
    ux: string | null;
  };
  extracted: {
    frs: Requirement[];
    nfrs: Requirement[];
    additional: Requirement[];
  };
  coverage: CoverageMatrix;
  uxAlignment: UXAlignmentStatus;
  violations: Violation[];
  summary: {
    status: 'READY' | 'NEEDS WORK' | 'NOT READY';
    criticalCount: number;
    majorCount: number;
    minorCount: number;
  };
}

interface Violation {
  severity: 'CRITICAL' | 'MAJOR' | 'MINOR';
  category: string;
  location: string;
  description: string;
  remediation: string;
}
```

---

## Phase 3 patterns

### Flow giữa skills

```
PRD + UX (from Phase 2)
  ↓
[bmad-create-architecture]
  ↓ architecture.md
[bmad-create-epics-and-stories]
  ↓ epics.md
[bmad-generate-project-context]
  ↓ project-context.md
[bmad-check-implementation-readiness]
  ↓ readiness-report.md
  ↓ (READY?)
Phase 4 Implementation
```

### Common patterns

- **Partnership, not client-vendor** — Winston + PM treat user as peer
- **Micro-file architecture** — create-architecture (8 steps), generate-project-context (3 steps)
- **Step-file architecture** — create-epics-and-stories (4 steps), check-readiness (6 steps)
- **[A/P/C] menus** — Advanced Elicitation / Party Mode / Continue
- **HALT discipline** — menu → user input → next
- **Append-only building** — documents grow section-by-section

### Critical success factors

1. **User value epics, NOT technical layers**
2. **Epic + story independence**
3. **FR traceability**
4. **Database timing** (create when needed)
5. **LLM-optimized context** (lean, unobvious)
6. **Readiness quality gate** (catch gaps before Phase 4)

---

**Đọc tiếp:** [09d-skills-phase4-deep.md](09d-skills-phase4-deep.md) — Phase 4 Implementation skills (phức tạp nhất).
