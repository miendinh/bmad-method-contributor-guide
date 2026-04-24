# 📐 BMAD-METHOD ARCHITECTURE - DETAILED SPECIFICATION

> ⚠️ **UNOFFICIAL THIRD-PARTY DOCUMENTATION**
> NOT official BMad docs. See [DISCLAIMER.md](DISCLAIMER.md) | Licensed MIT — see [LICENSE](LICENSE) and [NOTICE](NOTICE)
> Official BMAD-METHOD: <https://github.com/bmad-code-org/BMAD-METHOD>

---

> ⚠️ **OLD FILE — KEPT FOR REFERENCE ONLY**
>
> This file is the **first summary** (v1) of the developer deep-dive documentation set. Its content has been **expanded and updated** in the newer files 01-14.
>
> **Recommendation:** Read [README.md](README.md) to navigate the new documentation set. More detailed files:
> - **[01-philosophy.md](01-philosophy.md)** — Philosophy + 10 principles (replaces section 14 of this file)
> - **[02-environment-and-variables.md](02-environment-and-variables.md)** — Environment variables (replaces sections 4-5 + 9)
> - **[03-skill-anatomy-deep.md](03-skill-anatomy-deep.md)** — Skill anatomy (replaces section 3)
> - **[04-skills-catalog.md](04-skills-catalog.md)** + **[09a-d]** — Skills catalog + deep dive (replaces section 10)
> - **[05-flows-and-diagrams.md](05-flows-and-diagrams.md)** — 16 Mermaid diagrams (supplementary)
> - **[06 + 08]** — Installer internals (replaces section 8)
> - **[07-extension-patterns.md](07-extension-patterns.md)** — Extension patterns (replaces section 12)
> - **[11-14]** — Testing, migration, operations, rewrite blueprint (new)
>
> This older file is kept for anyone who wants a **fast summary** of the whole framework in a single file (~820 lines).

---

> A specification document for the full BMAD-METHOD framework architecture, for understanding, building, and extending the framework.
>
> **Audience:** Experienced developers who want to contribute to the framework, write new modules/skills, or reimplement the framework.

---

## Table of Contents

1. [Repository structure overview](#1-repository-structure-overview)
2. [Three core concepts to distinguish](#2-three-core-concepts-to-distinguish)
3. [Anatomy of a Skill](#3-anatomy-of-a-skill-agent-skills-spec)
4. [Variable system](#4-variable-system)
5. [Path rules (PATH-01 → PATH-05)](#5-path-rules-path-01--path-05---very-important)
6. [Anatomy of an Agent](#6-anatomy-of-an-agent)
7. [Anatomy of a Module](#7-anatomy-of-a-module)
8. [Installer flow](#8-installer-flow-npx-bmad-method-install)
9. [3-level Customization system](#9-3-level-customization-system)
10. [4 BMM phases](#10-4-bmm-phases-end-to-end-workflow)
11. [Validation system](#11-validation-system-30-rules)
12. [EXTENDED SPEC - How to…](#12-extended-spec---how-to)
13. [Build & Distribution](#13-build--distribution)
14. [Original design principles](#14-original-design-principles-for-reimplementation)
15. [Official docs to read in order](#15-official-docs-to-read-in-order)

---

## 1. Repository structure overview

```
BMAD-METHOD/
├── src/                     # Real source of the framework
│   ├── core-skills/         # 12 shared skills (brainstorm, help, shard-doc...)
│   ├── bmm-skills/          # 27 skills across 4 phases (BMM module)
│   └── scripts/             # Resolve config, helpers
├── tools/
│   ├── installer/           # `bmad` CLI (entry: bmad-cli.js)
│   ├── validate-skills.js   # Deterministic validator (14 rules)
│   ├── skill-validator.md   # Catalog of 30+ rules (original spec)
│   ├── build-docs.mjs       # Astro docs build
│   └── validate-*.js        # Link, reference validators
├── docs/                    # Documentation (EN + vi-vn, zh-cn, cs, fr)
├── website/                 # Astro + Starlight
├── test/                    # Regression tests
├── build/                   # Docs build output
└── package.json             # npm scripts, version
```

**Operating model:** Declarative, filesystem-based, no complex runtime. Framework = **structure + prompts + validator**. The AI agent reads files, follows workflows, and writes output files.

---

## 2. Three core concepts to distinguish

| Concept | Definition | Example |
|-----------|-----------|-------|
| **Skill** | A self-contained unit of work — a folder with `SKILL.md` + `workflow.md` + `steps/` | `bmad-brainstorming`, `bmad-create-prd` |
| **Agent** | A persona (character) with a menu of skills | `bmad-agent-pm` (John — Product Manager) |
| **Module** | A package of multiple skills + agents + config, with a `module.yaml` | `core`, `bmm` |

> **Skill = "tool"**, **Agent = "persona wielding multiple tools"**, **Module = "distribution package"**.

---

## 3. Anatomy of a Skill (Agent Skills spec)

### 3.1 Standard directory structure

```
bmad-my-skill/
├── SKILL.md              # L1 metadata (REQUIRED)
├── workflow.md           # Main logic
├── template.md           # Output template (optional)
├── customize.toml        # Override agent/workflow (optional)
├── steps/                # Micro-file architecture
│   ├── step-01-init.md
│   ├── step-02a-branch-a.md
│   ├── step-02b-branch-b.md
│   └── step-03-finalize.md
├── resources/            # Reference docs (optional)
└── agents/               # Sub-agent prompts (optional)
```

### 3.2 SKILL.md - entry point

```yaml
---
name: bmad-my-skill                    # Must match folder name, regex: ^bmad-[a-z0-9]+(-[a-z0-9]+)*$
description: 'Does X. Use when Y.'     # Max 1024 chars, MUST include both "what" + "when to use"
---

Follow the instructions in ./workflow.md.
```

### 3.3 workflow.md - the main frame

```yaml
---
context_file: ''                       # Runtime variables (set when running)
spec_file: ''
---

# My Skill Workflow
**Goal:** ...
**Your Role:** ...

## INITIALIZATION
Load config from `{project-root}/_bmad/core/config.yaml`:
- {project_name}, {output_folder}, {user_name}
- {communication_language}, {document_output_language}

## Paths
- `output_file` = `{planning_artifacts}/my-output.md`

## EXECUTION
Read fully and follow: `./steps/step-01-init.md`
```

### 3.4 Micro-file steps

Each step is an **independent file** ~2-5KB, loaded just-in-time:

```markdown
# Step 01: Init

## YOUR TASK
[Clear objective]

## ACTION
[Detailed instructions]

## NEXT
Read fully and follow: `./step-02-execute.md`
```

**Rules:**
- Sequential (no skipping)
- No forward-loading (don't read future steps early)
- HALT at menus to wait for the user
- Filename format: `step-NN[-variant]-description.md` (NN zero-padded)
- Each step must have a goal section (`## YOUR TASK`)
- A workflow should have 2-10 steps

---

## 4. Variable system

### 4.1 Config variables (from `_bmad/core/config.yaml`)

| Variable | Meaning |
|----------|---------|
| `{project-root}` | Project root directory |
| `{output_folder}` | Default output location |
| `{planning_artifacts}` | Phase 1-3 outputs (PRD, Architecture, ...) |
| `{implementation_artifacts}` | Phase 4 outputs (stories, code reviews, ...) |
| `{project_knowledge}` | Project knowledge (tech stack, conventions) |
| `{communication_language}` | Language the agent speaks |
| `{document_output_language}` | Language of output files |
| `{user_name}` | User/team name |

### 4.2 Runtime variables (set at runtime)

`{date}`, `{status}`, `{spec_file}`, `{story_file}` — declared in frontmatter, filled at execution time.

### 4.3 Rules (REF-01 → REF-03)

- **REF-01:** Every `{variable}` must be defined in frontmatter, config, or runtime
- **REF-02:** File references must resolve (the file must exist)
- **REF-03:** Invoking another skill must use the wording **"Invoke the `skill-name` skill"** — do NOT use "read/load/execute file"

---

## 5. Path rules (PATH-01 → PATH-05) - **very important**

| Rule | Rule | Correct | Incorrect |
|------|---------|------|-----|
| PATH-01 | References inside a skill must be **relative** | `./steps/step-01.md` | `/Users/.../step-01.md` |
| PATH-02 | Do not use `{installed_path}` | (remove this variable) | `{installed_path}/template.md` |
| PATH-03 | References outside the skill must use a **config variable** | `{planning_artifacts}/prd.md` | `~/Documents/prd.md` |
| PATH-04 | Do not store internal paths in a variable | `./template.md` inline | `{template_path}` |
| PATH-05 | **DO NOT reach into another skill's folder** | Invoke the skill | `{project-root}/_bmad/skills/other/template.md` |

**PATH-05 is the encapsulation principle** — if this skill wants to use another skill, it must **invoke it**, not read its files.

---

## 6. Anatomy of an Agent

An agent is defined in **`module.yaml`** + its own persona skill folder:

```yaml
# src/bmm-skills/module.yaml
agents:
  - code: bmad-agent-dev
    name: Amelia
    title: Senior Software Engineer
    icon: "💻"
    description: "Test-first discipline..."
```

And a `customize.toml` file in the persona skill:

```toml
[agent]
name = "Amelia"
title = "Senior Software Engineer"
role = "Implement approved stories with test-first discipline..."
communication_style = "Ultra-succinct. No filler words."
principles = [
  "No task complete without passing tests.",
  "Red, green, refactor — in that order.",
]

# Menu shortcuts the user can type
[[agent.menu]]
code = "DS"
description = "Write the next story's tests and code"
skill = "bmad-dev-story"

[[agent.menu]]
code = "QD"
description = "Unified quick flow"
skill = "bmad-quick-dev"
```

**6 default BMM agents:**

| Agent code | Name | Title | Icon |
|-----------|-----|-------|------|
| `bmad-agent-analyst` | Mary | Business Analyst | 📊 |
| `bmad-agent-pm` | John | Product Manager | 📋 |
| `bmad-agent-ux-designer` | Sally | UX Designer | 🎨 |
| `bmad-agent-architect` | Winston | System Architect | 🏗️ |
| `bmad-agent-dev` | Amelia | Senior Software Engineer | 💻 |
| `bmad-agent-tech-writer` | Paige | Technical Writer | 📚 |

---

## 7. Anatomy of a Module

```yaml
# module.yaml
code: bmm                              # Unique ID
name: "BMad Method Agile-AI"
description: "..."
default_selected: true                 # Auto-selected on install

# Config variables defined by the module
project_name:
  prompt: "What is your project called?"
  default: "{directory_name}"

planning_artifacts:
  prompt: "Where should planning artifacts be stored?"
  default: "{output_folder}/planning-artifacts"
  result: "{project-root}/{value}"     # How the final value is computed

# Directories the installer will create
directories:
  - "{planning_artifacts}"
  - "{implementation_artifacts}"
  - "{project_knowledge}"

# Agents belonging to the module
agents:
  - code: bmad-agent-pm
    name: John
    # ...
```

**Two built-in modules:**
- `core` — shared config, paths, core variables
- `bmm` — 27 skills + 6 agents for agile AI-driven dev

---

## 8. Installer flow (`npx bmad-method install`)

```
1. User runs: npx bmad-method install
           ↓
2. CLI (tools/installer/bmad-cli.js) loads commands
           ↓
3. Interactive prompts from module.yaml config_vars
           ↓
4. Creates _bmad/ structure inside the user's project:
   _bmad/
   ├── core/config.yaml           ← user's answers
   ├── bmm/config.yaml
   ├── skills/
   │   ├── core/                  ← copied from src/core-skills/
   │   └── bmm/                   ← copied from src/bmm-skills/
   ├── scripts/resolve_customization.py
   └── custom/                    ← user overrides
           ↓
5. IDE setup (Claude Code, Cursor, JetBrains, ...)
           ↓
6. Show post-install-notes from module.yaml
```

### Important files inside `_bmad/` after install

```
project-root/
└── _bmad/
    ├── core/
    │   └── config.yaml           # User answers to prompts
    ├── bmm/
    │   ├── config.yaml           # BMM-specific config
    │   └── custom/
    ├── skills/
    │   ├── core/
    │   │   ├── bmad-brainstorming/
    │   │   ├── bmad-help/
    │   │   └── ...
    │   └── bmm/
    │       ├── 1-analysis/
    │       ├── 2-plan-workflows/
    │       ├── 3-solutioning/
    │       └── 4-implementation/
    ├── scripts/
    │   └── resolve_customization.py  # Config resolver
    └── custom/
        └── config.user.toml         # User overrides
```

---

## 9. 3-level Customization system

Every skill/agent has 3 override levels:

```
Level 1 (Default):    {skill-root}/customize.toml
Level 2 (Team):       {project-root}/_bmad/custom/{skill-name}.toml
Level 3 (User):       {project-root}/_bmad/custom/{skill-name}.user.toml
```

**Merge rules:**
- Scalars → user wins (override base)
- Arrays (e.g. `persistent_facts`) → append
- Arrays of tables with a `code`/`id` → replace on match, append new

---

## 10. 4 BMM phases (end-to-end workflow)

```
PHASE 1: Analysis                PHASE 2: Planning
(Understand the problem)         (Plan it)
├── bmad-brainstorming           ├── bmad-create-prd
├── bmad-prfaq                   ├── bmad-create-ux-design
├── bmad-product-brief    →      ├── bmad-validate-prd
└── bmad-document-project        └── Agents: John, Sally
Agents: Mary
      ↓                                ↓
   Product Brief / PRFAQ              PRD + UX Design
      ↓                                ↓

PHASE 3: Solutioning             PHASE 4: Implementation
(Design the architecture)        (Build & ship)
├── bmad-create-architecture     ├── bmad-dev-story
├── bmad-create-epics-and-       ├── bmad-create-story
│   stories                →     ├── bmad-quick-dev
├── bmad-generate-project-       ├── bmad-code-review
│   context                      ├── bmad-sprint-planning
└── bmad-check-implementation-   └── bmad-correct-course
    readiness                    Agents: Amelia
Agents: Winston
      ↓                                ↓
   Architecture + Stories            Shipped code
```

### Phase details

| Phase | Goal | Key Skills | Output |
|-------|------|-----------|--------|
| 1. Analysis | Understand the problem | Brainstorming, PRFAQ, Product Brief, Research | PRD input |
| 2. Planning | Plan the solution | Create PRD, UX Design, Validate PRD | PRD + UX specs |
| 3. Solutioning | Design architecture | Architecture, Epics/Stories, Context | Architecture docs |
| 4. Implementation | Build & ship | Dev Story, Code Review, Sprint Planning | Shipped code |

**Phase-transition principle:** the output of the previous phase → the input of the next phase (file-based handoff).

---

## 11. Validation system (30+ rules)

### 11.1 Deterministic (validate-skills.js)

```bash
node tools/validate-skills.js                  # everything
node tools/validate-skills.js path/to/skill    # 1 skill
node tools/validate-skills.js --strict --json  # CI mode
```

Checks 14 rules: SKILL-01→07, WF-01, WF-02, PATH-02, STEP-01, STEP-06, STEP-07, SEQ-02.

### 11.2 Inference-based (skill-validator.md)

16+ rules that require LLM judgment: PATH-01, PATH-03→05, WF-03, STEP-02→05, SEQ-01, REF-01→03.

### 11.3 Rule catalog

| Group | Purpose |
|------|----------|
| **SKILL-*** | SKILL.md structure + metadata |
| **WF-*** | workflow.md structure |
| **PATH-*** | File path resolution |
| **STEP-*** | Step file anatomy |
| **SEQ-*** | Sequential execution |
| **REF-*** | Variable references |

### 11.4 Key rule details

#### SKILL-* (Skill metadata)

| Rule | Severity | Content |
|------|----------|----------|
| SKILL-01 | CRITICAL | Skill directory MUST contain `SKILL.md` |
| SKILL-02 | CRITICAL | `SKILL.md` MUST have `name` in frontmatter |
| SKILL-03 | CRITICAL | `SKILL.md` MUST have `description` in frontmatter |
| SKILL-04 | HIGH | `name` format: `^bmad-[a-z0-9]+(-[a-z0-9]+)*$` |
| SKILL-05 | HIGH | `name` MUST match directory name |
| SKILL-06 | MEDIUM | `description` max 1024 chars, include "Use when..." |
| SKILL-07 | HIGH | `SKILL.md` MUST have body content after frontmatter |

#### WF-* (Workflow)

| Rule | Severity | Content |
|------|----------|----------|
| WF-01 | HIGH | Only `SKILL.md` may have `name` in frontmatter |
| WF-02 | HIGH | Only `SKILL.md` may have `description` in frontmatter |
| WF-03 | HIGH | `workflow.md` frontmatter variables must be config or runtime |

#### PATH-* (Path rules)

| Rule | Severity | Content |
|------|----------|----------|
| PATH-01 | HIGH | Internal references MUST be relative |
| PATH-02 | HIGH | DO NOT use the `installed_path` variable |
| PATH-03 | HIGH | External references MUST use config variables |
| PATH-04 | MEDIUM | DO NOT store intra-skill paths in variables |
| PATH-05 | CRITICAL | DO NOT reach into another skill's folder |

---

## 12. EXTENDED SPEC - How to…

### 12.1 Add a new Skill

```bash
# 1. Create the folder (name must match the frontmatter name)
mkdir -p src/bmm-skills/4-implementation/bmad-my-skill/steps

# 2. Write SKILL.md
cat > src/bmm-skills/4-implementation/bmad-my-skill/SKILL.md <<'EOF'
---
name: bmad-my-skill
description: 'Does X. Use when Y happens.'
---

Follow the instructions in ./workflow.md.
EOF

# 3. Write workflow.md + steps/step-01-*.md + the following steps

# 4. Validate
node tools/validate-skills.js src/bmm-skills/4-implementation/bmad-my-skill

# 5. Run full quality
npm run quality
```

**Checklist:**
- [ ] Folder name = `name:` in the frontmatter, format `bmad-[a-z0-9-]+`
- [ ] Description contains "Use when ..."
- [ ] workflow.md loads config and declares paths via config vars
- [ ] Steps numbered `step-NN-*.md`, each step has a NEXT reference
- [ ] No absolute paths or `{installed_path}`
- [ ] No reach into another skill's folder (invoke instead of reading files)
- [ ] `npm run validate:skills --strict` passes

### 12.2 Add a new Agent

Add to `module.yaml`:

```yaml
agents:
  - code: bmad-agent-security
    name: Sam
    title: Security Expert
    icon: "🔒"
    description: "Threat modeling + OWASP rigor..."
```

Create the persona skill `bmad-agent-security/` with `customize.toml`:

```toml
[agent]
name = "Sam"
title = "Security Expert"
role = "Threat modeling and security review with OWASP rigor..."
communication_style = "Precise, evidence-based."
principles = [
  "Defense in depth.",
  "Validate inputs at trust boundaries.",
  "Assume breach, minimize blast radius.",
]

[[agent.menu]]
code = "TM"
description = "Threat model the current feature"
skill = "bmad-threat-model"

[[agent.menu]]
code = "SR"
description = "Security review of pending changes"
skill = "bmad-security-review"
```

### 12.3 Add a completely new Module

```
my-org-skills/
├── module.yaml              # code, name, config_vars, agents, directories
├── category-1/
│   ├── bmad-skill-1/
│   └── bmad-skill-2/
└── category-2/
    └── bmad-skill-3/
```

**Minimal module.yaml:**

```yaml
code: my-org
name: "My Org Module"
description: "..."

my_custom_var:
  prompt: "..."
  default: "..."
  result: "{value}"

directories:
  - "{my_custom_dir}"

agents:
  - code: bmad-agent-custom
    name: Name
    title: Title
```

**Register:**
- **Official community**: PR to `tools/installer/external-official-modules.yaml`
- **Private**: Install locally via the CLI custom option
- **npm package**: Publish as a standalone npm package

### 12.4 Customize an existing skill (without editing source)

Create an override in the user's project:

```toml
# {project-root}/_bmad/custom/bmad-dev-story.toml

[workflow]
persistent_facts = [
  "file:{project-root}/docs/coding-standards.md",
  "All tests must pass before commit.",
  "We use Vitest, not Jest.",
]

[[agent.menu]]                       # Add a new menu item
code = "QT"
description = "Quick test generation"
skill = "bmad-qa-generate-e2e-tests"
```

The core skill `bmad-customize` guides you through this interactively.

---

## 13. Build & Distribution

### 13.1 Important npm scripts

```bash
npm run bmad:install      # Install into the current project
npm run docs:build        # Build Astro docs → build/
npm run docs:dev          # Docs dev server
npm run quality           # Format + lint + docs build + tests + validate
npm run validate:skills   # Validate all skills (strict)
npm run validate:refs     # Validate file references
npm run test:install      # Test the installer
npm run rebundle          # Rebuild web bundles
```

### 13.2 package.json scripts mapping

```json
{
  "scripts": {
    "bmad:install": "node tools/installer/bmad-cli.js install",
    "bmad:uninstall": "node tools/installer/bmad-cli.js uninstall",
    "docs:build": "node tools/build-docs.mjs",
    "docs:dev": "astro dev --root website",
    "docs:preview": "astro preview --root website",
    "docs:validate-links": "node tools/validate-doc-links.js",
    "format:check": "prettier --check \"**/*.{js,cjs,mjs,json,yaml}\"",
    "format:fix": "prettier --write \"**/*.{js,cjs,mjs,json,yaml}\"",
    "lint": "eslint . --ext .js,.cjs,.mjs,.yaml --max-warnings=0",
    "lint:md": "markdownlint-cli2 \"**/*.md\"",
    "quality": "npm run format:check && npm run lint && npm run lint:md && npm run docs:build && npm run test:install && npm run validate:refs && npm run validate:skills",
    "rebundle": "node tools/installer/bundlers/bundle-web.js rebundle",
    "test:install": "node test/test-installation-components.js",
    "test:refs": "node test/test-file-refs-csv.js",
    "validate:refs": "node tools/validate-file-refs.js --strict",
    "validate:skills": "node tools/validate-skills.js --strict"
  }
}
```

### 13.3 Release flow

1. Conventional commits → `git push`
2. Every push → npm `next` tag (auto)
3. Weekly release cut → npm `latest` tag (stable)

---

## 14. Original design principles (for reimplementation)

If you want to **rewrite BMad from scratch**, here are the 10 core principles:

1. **Filesystem is truth** — all state lives in files, no DB/runtime
2. **Declarative over imperative** — YAML/TOML/Markdown, not code
3. **Document as interface** — output files are the API between phases/agents
4. **Micro-file workflows** — each step = 1 file, loaded just-in-time
5. **Sequential by default** — no parallel; agents follow step-by-step
6. **Encapsulated skills** — a skill is a black box, only invoke, don't read files
7. **Config-driven paths** — every path uses a variable, not hardcoded
8. **Declarative validation** — rules written as markdown, enforced by JS
9. **Layered customization** — default → team → user (TOML overrides)
10. **Human-in-the-loop** — HALT at menus, wait for user input at checkpoints

### How to reimplement the framework (A-Z)

1. **Define Agents** → personas with communication styles in `module.yaml`
2. **Create Skills** → directory-based, each skill has SKILL.md + workflow.md + steps/
3. **Link Agents → Skills** → agent menu invokes skills
4. **Build Installer** → interactive setup flow (prompts → config.yaml → directories)
5. **Define Phases** → organize skills into phases (analysis → planning → solutioning → implementation)
6. **Validation System** → deterministic rules (validate-skills.js) + inference rules (catalog)
7. **Module System** → package skills into modules, support custom modules
8. **Customization** → 3-level TOML override system
9. **Documentation** → multi-language docs, website build
10. **Testing** → regression tests for installer, references, workflows

---

## 15. Official docs to read in order

1. [AGENTS.md](../AGENTS.md) — original framework rules (13 lines)
2. [CONTRIBUTING.md](../CONTRIBUTING.md) — PR process (183 lines)
3. [tools/skill-validator.md](../tools/skill-validator.md) — **full spec of 30+ rules** (386 lines) — **the most important document**
4. [tools/installer/README.md](../tools/installer/README.md) — module registration (60 lines)
5. [src/core-skills/bmad-brainstorming/](../src/core-skills/bmad-brainstorming/) — **canonical example** of a complete skill
6. [src/bmm-skills/module.yaml](../src/bmm-skills/module.yaml) — example module.yaml
7. [docs/vi-vn/bmad-developer-guide.md](../docs/vi-vn/bmad-developer-guide.md) — developer guide overview (Vietnamese)

---

## Appendix A: Detailed src/ structure

### A.1 core-skills/ (12 Core Skills)

```
core-skills/
├── bmad-brainstorming          # Facilitated ideation sessions (multi-technique)
├── bmad-advanced-elicitation   # Surface assumptions & edge cases
├── bmad-customize              # Customize BMad for an org/team
├── bmad-distillator            # Summarize & analyze documents
├── bmad-editorial-review-prose
├── bmad-editorial-review-structure
├── bmad-help                   # Guided help & recommendation
├── bmad-index-docs             # Build an index from docs
├── bmad-party-mode             # Multi-agent collaboration sessions
├── bmad-review-adversarial-general
├── bmad-review-edge-case-hunter
├── bmad-shard-doc              # Split large docs into chunks
└── module.yaml                 # Defines the "core" module
```

**Notable:** There's no `agents` folder because the core skills don't represent a specific agent — they're generic tools callable from any agent.

### A.2 bmm-skills/ (27 BMM Phase-Based Skills)

```
bmm-skills/
├── 1-analysis/                         # Phase 1: Understand the problem
│   ├── bmad-agent-analyst              # Agent/skill: Business Analyst persona
│   ├── bmad-document-project           # Extract knowledge from codebase/docs
│   ├── bmad-prfaq                      # Working Backwards press release
│   ├── bmad-product-brief              # Executive summary of the product
│   └── research/                       # Market/domain/technical research
│
├── 2-plan-workflows/                   # Phase 2: Plan the solution
│   ├── bmad-agent-pm                   # Product Manager persona
│   ├── bmad-agent-ux-designer          # UX Designer persona
│   ├── bmad-create-prd                 # Create Product Requirements Doc
│   ├── bmad-create-ux-design           # Create UX design documents
│   ├── bmad-edit-prd                   # Edit PRD (loop back)
│   └── bmad-validate-prd               # Validate PRD completeness
│
├── 3-solutioning/                      # Phase 3: Design the architecture
│   ├── bmad-agent-architect            # System Architect persona
│   ├── bmad-create-architecture        # Design system architecture
│   ├── bmad-create-epics-and-stories   # Break down into epics
│   ├── bmad-generate-project-context   # Generate technical context
│   └── bmad-check-implementation-readiness  # Pre-flight checks
│
├── 4-implementation/                   # Phase 4: Build & ship
│   ├── bmad-agent-dev                  # Senior Engineer persona
│   ├── bmad-dev-story                  # Implement single story (key workflow)
│   ├── bmad-create-story               # Create detailed story file
│   ├── bmad-quick-dev                  # Unified quick flow (concept→ship)
│   ├── bmad-code-review                # Comprehensive code review
│   ├── bmad-checkpoint-preview         # Preview changes before shipping
│   ├── bmad-correct-course             # Course correction mid-sprint
│   ├── bmad-sprint-planning            # Sprint planning
│   ├── bmad-sprint-status              # Sprint status report
│   ├── bmad-retrospective              # Post-sprint retrospective
│   └── bmad-qa-generate-e2e-tests      # QA test generation
│
└── module.yaml                         # Defines "bmm" module + all 6 agents
```

---

## Appendix B: Complete SKILL.md example

### B.1 Example from `bmad-brainstorming`

**SKILL.md:**

```yaml
---
name: bmad-brainstorming
description: 'Facilitate interactive brainstorming sessions using diverse creative techniques and ideation methods. Use when the user says help me brainstorm or help me ideate.'
---

Follow the instructions in ./workflow.md.
```

**workflow.md:**

```yaml
---
context_file: ''
---

# Brainstorming Session Workflow
**Goal:** Facilitate interactive brainstorming sessions...
**Your Role:** You are a brainstorming facilitator...

## INITIALIZATION
Load config from `{project-root}/_bmad/core/config.yaml`:
- `project_name`, `output_folder`, `user_name`
- `communication_language`, `document_output_language`
- `date` = system-generated datetime

## Paths
- `brainstorming_session_output_file` = `{output_folder}/brainstorming/...`

## EXECUTION
Read fully and follow: `./steps/step-01-session-setup.md`
```

**Structure:**

```
bmad-brainstorming/
├── SKILL.md
├── workflow.md
├── template.md
└── steps/
    ├── step-01-session-setup.md
    ├── step-01b-continue.md
    ├── step-02a-user-selected.md
    ├── step-02b-ai-recommended.md
    ├── step-02c-random-selection.md
    ├── step-02d-progressive-flow.md
    ├── step-03-technique-execution.md
    └── step-04-idea-organization.md
```

---

## Appendix C: Glossary

| Term | Definition |
|-----------|-----------|
| **Skill** | A self-contained unit of work; a folder containing `SKILL.md` |
| **Agent** | A persona with a communication style + menu of skills |
| **Module** | A package of skills + agents + config, with `module.yaml` |
| **Workflow** | The logic in a skill's `workflow.md` |
| **Step** | A micro file inside the `steps/` folder |
| **Config variable** | A variable pulled from `_bmad/core/config.yaml` |
| **Runtime variable** | A variable set during workflow execution |
| **Artifact** | A phase output file (PRD, Architecture, Story, ...) |
| **Invoke** | How a skill calls another skill (not via direct file reads) |
| **Customize.toml** | File that overrides agent/workflow |
| **Planning artifact** | Output of phases 1-3 |
| **Implementation artifact** | Output of phase 4 |
| **BMM** | Breakthrough Method of Agile AI-driven Development |
| **Diátaxis** | Documentation framework classifying docs as tutorial / how-to / explanation / reference |
