# 15. Glossary - BMAD-METHOD Terminology

> ⚠️ **UNOFFICIAL THIRD-PARTY DOCUMENTATION**
> NOT official BMad docs. See [DISCLAIMER.md](DISCLAIMER.md) | Licensed MIT — see [LICENSE](LICENSE) and [NOTICE](NOTICE)
> Official BMAD-METHOD: <https://github.com/bmad-code-org/BMAD-METHOD>

---

> A focused dictionary of BMad-specific terms. Use this when reading the docs and you run into a term that isn't clear.

---

## Table of Contents

- [A. Core concepts](#a-core-concepts)
- [B. Architecture terms](#b-architecture-terms)
- [C. Variables & config](#c-variables--config)
- [D. Workflow terms](#d-workflow-terms)
- [E. Validation rules](#e-validation-rules)
- [F. File types & artifacts](#f-file-types--artifacts)
- [G. Agent personas](#g-agent-personas)
- [H. BMad-specific terms](#h-bmad-specific-terms)

---

## A. Core concepts

| Term | Definition | Detail file |
|------|-----------|---------------|
| **Agent** | A persona (character) with a name, icon, communication style, and a menu of skills. Example: Mary (Analyst 📊), John (PM 📋) | [03 §9](03-skill-anatomy-deep.md), [09b §1-1](09b-skills-phase1-2-deep.md) |
| **Skill** | A self-contained unit of work. A folder containing `SKILL.md` (required), plus optional `workflow.md`, `steps/`, `customize.toml`. The name is always prefixed with `bmad-*` | [03](03-skill-anatomy-deep.md) |
| **Module** | A package of skills + agents + config. Defined via `module.yaml`. Built-in: `core`, `bmm`. External: `tea`, `bmb`... | [02 §2](02-environment-and-variables.md) |
| **Workflow** | The logic in a skill's `workflow.md`. May use the micro-file architecture (steps/) or inline XML | [03 §3](03-skill-anatomy-deep.md) |
| **Step** | A micro-file in the `steps/` folder, ~2-5KB. Sequential, no-forward-loading | [03 §4](03-skill-anatomy-deep.md) |
| **Artifact** | The output file of a phase: PRD, Architecture, Stories, etc. Stored in `{planning_artifacts}` or `{implementation_artifacts}` | [01 §3.3](01-philosophy.md) |
| **Invoke** | How a skill calls another skill (via agent menu or "Invoke the `skill-name` skill" text). Do NOT read the file directly | [03 §10](03-skill-anatomy-deep.md) |

---

## B. Architecture terms

| Term | Definition |
|------|-----------|
| **Micro-file architecture** | The pattern of splitting a workflow into multiple step files ~2-5KB, loaded just-in-time. The opposite of a monolithic workflow file. |
| **Filesystem as truth** | The principle that all state lives in files, with no DB/runtime. Git-native, portable, debuggable |
| **Declarative > Imperative** | Workflows written in Markdown/YAML/TOML, not code. The LLM reads and follows them |
| **Document-as-interface** | Phases communicate through output files, not memory/API |
| **Encapsulated skills** | A skill must not read files from another skill (PATH-05). Only invoke |
| **Human-in-the-loop** | The AI HALTs at important checkpoints and waits for user input |
| **4-phase lifecycle** | Analysis → Planning → Solutioning → Implementation |
| **Sprint tracking** | Sprint state is kept in `sprint-status.yaml` (file-based, no Jira) |
| **Party mode** | Multi-agent collaboration via real subagents (Agent tool) |
| **RED-GREEN-REFACTOR** | The TDD cycle of dev-story: failing tests → minimal code → improve |
| **8-level validation gate** | Dev-story step 8's checklist run before marking a task complete |
| **Capture-don't-interrupt** | A pattern in product-brief: silently capture out-of-scope details without derailing |
| **Adversarial review** | Review mindset: assume bugs exist and find them. Contrast with confirmation bias |
| **Distillate** | Lossless LLM-optimized compression of documents. Different from a summary |

---

## C. Variables & config

| Term | Definition |
|------|-----------|
| **Config variable** | A variable from `_bmad/config.yaml`, declared in `module.yaml`, and filled at install time. Example: `{planning_artifacts}` |
| **Runtime variable** | A variable set while a workflow executes. Example: `{story_key}`, `{date}` |
| **System macro** | A variable computed by the system: `{project-root}`, `{skill-root}`, `{date}`, `{time}`, `{directory_name}`, `{value}` |
| **customize.toml** | File that overrides agent persona or workflow hooks. Two blocks: `[agent]` and `[workflow]` |
| **3-level customization** | Skill-level override: default → team → user |
| **4-level central config** | Installer answers team/user + custom team/user |
| **`{project-root}`** | The project root, detected via `_bmad/` or `.git/` walking upward |
| **`{planning_artifacts}`** | Location of phase 1-3 outputs. Default: `{project-root}/_bmad-output/planning-artifacts` |
| **`{implementation_artifacts}`** | Phase 4 outputs: stories, sprint, reviews. Default: `_bmad-output/implementation-artifacts` |
| **`{project_knowledge}`** | Long-lived docs: tech stack, standards. Default: `docs/` |
| **`{communication_language}`** | The language the AI uses to talk with the user (e.g., Vietnamese) |
| **`{document_output_language}`** | The language artifacts are written in (e.g., English) |
| **`{user_skill_level}`** | beginner/intermediate/expert — influences explanation depth |
| **Keyed merge** | Arrays of tables that share a `code` or `id` field → merged by key. Mixed → appended |
| **Deep merge** | Recursive merge for nested dicts |

---

## D. Workflow terms

| Term | Definition |
|------|-----------|
| **HALT** | The AI stops and waits for user input. Common at menus |
| **Menu** | The choice UI inside a step: [A]dvanced Elicitation / [P]arty Mode / [C]ontinue |
| **Goto** | XML workflow directive for jumping between steps (`<goto step="5">`) |
| **Anchor** | The destination of a goto (`<anchor id="task_check" />`) |
| **Sequential enforcement** | Steps run in the correct order, no skipping, no forward-loading |
| **Append-only building** | Documents grow section-by-section and are never overwritten |
| **State tracking** | The frontmatter field `stepsCompleted: [1, 2, 3]` tracks progress |
| **Resume detection** | Check an existing file's frontmatter → offer to continue from the last step |
| **Continuation** | `step-01b-continue.md` handles resuming an existing workflow |
| **Branching** | Step-02a / 02b / 02c = variants, only 1 is loaded based on user choice |
| **Fan-out** | Spawn parallel sub-agents (e.g., distillator, party mode) |
| **Graceful degradation** | If a subagent is unavailable, the main agent does the work inline |
| **DoD (Definition of Done)** | Checklist to satisfy before marking a story complete |
| **Review continuation** | Dev-story resumes after code-review with [AI-Review] tasks |
| **Significant discovery** | Pattern in retrospective: findings that require an epic update before the next epic |
| **Persistent facts** | Facts loaded at agent activation — "always-true" knowledge |
| **Activation steps** | Hooks: `_prepend` (before greeting), `_append` (after greeting) |
| **Sub-agent** | A prompt file in the `agents/` folder, spawned via the Agent tool for parallel reasoning |

---

## E. Validation rules

| Rule | Group | Severity | Description |
|------|------|----------|-------|
| **SKILL-01** | SKILL-* | CRITICAL | SKILL.md must exist |
| **SKILL-02** | SKILL-* | CRITICAL | SKILL.md frontmatter has `name` |
| **SKILL-03** | SKILL-* | CRITICAL | SKILL.md frontmatter has `description` |
| **SKILL-04** | SKILL-* | HIGH | `name` matches regex `^bmad-[a-z0-9]+(-[a-z0-9]+)*$` |
| **SKILL-05** | SKILL-* | HIGH | `name` matches directory basename |
| **SKILL-06** | SKILL-* | MEDIUM | `description` max 1024 chars, has "Use when/if" |
| **SKILL-07** | SKILL-* | HIGH | SKILL.md has body content after frontmatter |
| **WF-01** | WF-* | HIGH | Non-SKILL.md file must NOT have `name` in frontmatter |
| **WF-02** | WF-* | HIGH | Non-SKILL.md file must NOT have `description` in frontmatter |
| **WF-03** | WF-* | HIGH | workflow.md frontmatter vars must be config/runtime only |
| **PATH-01** | PATH-* | HIGH | Internal refs relative (`./steps/step-01.md`) |
| **PATH-02** | PATH-* | HIGH | No `{installed_path}` variable |
| **PATH-03** | PATH-* | HIGH | External refs use config variables |
| **PATH-04** | PATH-* | MEDIUM | No intra-skill path variables |
| **PATH-05** | PATH-* | CRITICAL | Cannot reach into other skill's folder |
| **STEP-01** | STEP-* | HIGH | Filename format: `step-NN[-variant]-description.md` |
| **STEP-02** | STEP-* | HIGH | Step has goal section |
| **STEP-03** | STEP-* | HIGH | Step references next step (except final) |
| **STEP-04** | STEP-* | HIGH | Menu steps HALT & wait |
| **STEP-05** | STEP-* | HIGH | No forward loading |
| **STEP-06** | STEP-* | HIGH | Step frontmatter no `name`/`description` |
| **STEP-07** | STEP-* | HIGH | Workflow 2-10 steps |
| **SEQ-01** | SEQ-* | HIGH | Use "Invoke the skill" language |
| **SEQ-02** | SEQ-* | MEDIUM | No time estimates ("~5 min") |
| **REF-01** | REF-* | HIGH | Variables defined somewhere |
| **REF-02** | REF-* | HIGH | File references resolve |
| **REF-03** | REF-* | HIGH | Invocation uses "invoke" language |

**Total:** 27 rules (14 deterministic + 13 inference). Details: [03 §10](03-skill-anatomy-deep.md)

---

## F. File types & artifacts

| File | Purpose | Location |
|------|---------|----------|
| `SKILL.md` | Skill entry point, frontmatter metadata | In skill dir |
| `workflow.md` | Skill logic (inline XML or redirects to steps/) | In skill dir |
| `customize.toml` | Agent persona / workflow hooks | In skill dir |
| `template.md` | Template for the output file | In skill dir |
| `checklist.md` | Validation checklist (e.g., DoD) | In skill dir |
| `step-NN-*.md` | Micro-file workflow step | `steps/` |
| `module.yaml` | Module definition (code, name, agents, config vars) | Module root |
| `manifest.yaml` | Installation metadata | `_bmad/_config/` |
| `skill-manifest.csv` | Skills registry | `_bmad/_config/` |
| `files-manifest.csv` | File tracking with SHA-256 hashes | `_bmad/_config/` |
| `config.yaml` | Resolved config (installer answers) | `_bmad/{module}/` |
| `config.toml` | Team overrides | `_bmad/config.toml` |
| `config.user.toml` | User overrides (gitignored) | `_bmad/config.user.toml` |
| `{skill}.toml` | Skill team override | `_bmad/custom/` |
| `{skill}.user.toml` | Skill user override (gitignored) | `_bmad/custom/` |
| `project-context.md` | Long-lived project rules/patterns | `{project_knowledge}` |
| `prd.md` | Product Requirements Document | `{planning_artifacts}` |
| `architecture.md` | System architecture decisions | `{planning_artifacts}` |
| `epics.md` | Epics + stories breakdown | `{planning_artifacts}` |
| `product-brief-*.md` | Executive summary | `{planning_artifacts}` |
| `prfaq-*.md` | Working Backwards PRFAQ | `{planning_artifacts}` |
| `sprint-status.yaml` | Sprint state | `{implementation_artifacts}` |
| `{epic}-{story}-*.md` | Story file | `{implementation_artifacts}` |
| `epic-N-retro-*.md` | Retrospective document | `{implementation_artifacts}` |

---

## G. Agent personas

Built-in agents (in the `bmm` module):

| Code | Name | Title | Icon | Phase | Specialty |
|------|------|-------|------|-------|-----------|
| `bmad-agent-analyst` | Mary | Business Analyst | 📊 | 1-Analysis | Research, brainstorming, evidence-based |
| `bmad-agent-tech-writer` | Paige | Technical Writer | 📚 | 1-Analysis | Documentation, diagrams, explanations |
| `bmad-agent-pm` | John | Product Manager | 📋 | 2-Planning | PRD, requirements, Jobs-to-be-Done |
| `bmad-agent-ux-designer` | Sally | UX Designer | 🎨 | 2-Planning | User journeys, interaction design |
| `bmad-agent-architect` | Winston | System Architect | 🏗️ | 3-Solutioning | Architecture, trade-offs, boring tech |
| `bmad-agent-dev` | Amelia | Senior Engineer | 💻 | 4-Implementation | TDD, precision, file paths + AC IDs |

**Custom agents** (via `_bmad/custom/config.toml`):
- Users can add agents (real or fictional)
- Team defaults to the module code unless specified

---

## H. BMad-specific terms

Terms that are unique to BMAD-METHOD or used in a BMad-specific way. Use these names verbatim in code, configs, and conversation.

| Term | Notes |
|--------------------|---------|
| **agent** | A named persona, e.g., Mary, John, Winston |
| **skill** | A `bmad-*` folder with `SKILL.md` |
| **workflow** | The logic file (`workflow.md`) inside a skill |
| **step** | A micro-file under `steps/` |
| **config** | Refers to `_bmad/config.yaml` or `.toml` overrides |
| **install** | The `bmad-method install` command |
| **validate** | The `validate-skills` CLI command |
| **override** | Customization applied via `customize.toml` |
| **merge** | Combining default + team + user config layers |
| **artifact** | Any phase output file (PRD, architecture, story, etc.) |
| **persona** | The agent's identity + communication style |
| **module** | A distributable package (core, bmm, ...) |
| **phase** | One of the 4 BMM phases |
| **loop** | A repeat cycle, e.g., RED-GREEN-REFACTOR |
| **HALT** | Uppercase — the specific pattern where the AI stops and waits |
| **invoke** | The proper verb for calling another skill |

---

## Quick alphabetical lookup

- **Acceptance Criteria (AC)** — Acceptance condition, written in Given/When/Then format
- **Activation steps** — Hooks that run when an agent activates
- **Adversarial review** — Review with a bug-hunting mindset, not validation
- **Agent** — A persona with a skills menu
- **Amelia 💻** — Senior Engineer persona
- **Anchor** — The destination of a goto in an XML workflow
- **Anti-bias protocol** — Brainstorming pattern: shift the domain every 10 ideas
- **Append-only** — Document building without overwriting
- **Artifact** — Output file (PRD, architecture, etc.)
- **BMM** — Breakthrough Method of Agile AI-driven Development (module)
- **Brainstorming techniques** — 30+ methods in `brain-methods.csv`
- **Capture-don't-interrupt** — Product-brief pattern
- **Catalog** — `bmad-help.csv` registry
- **Checkpoint preview** — Human-review walkthrough skill
- **Communication language** — The AI chat language (`{communication_language}`)
- **Config variable** — A variable from `_bmad/config.yaml`
- **Continuation** — Resume an existing workflow (e.g., `step-01b-continue.md`)
- **Core skills** — 12 shared skills in `src/core-skills/`
- **Correct course** — Mid-sprint pivot skill
- **customize.toml** — Persona/workflow override file
- **Declarative** — Markdown/YAML/TOML, not code
- **Deep merge** — Recursive config merge
- **Definition of Done (DoD)** — Pre-complete checklist
- **Distillate** — Lossless document compression
- **Document output language** — Artifact language (`{document_output_language}`)
- **Document-as-interface** — Phase handoff via files
- **Edge case hunter** — Path-analysis review skill
- **Encapsulated skills** — PATH-05 rule
- **Epic** — Collection of stories delivering user value
- **Extension points** — Ways to customize (8 patterns)
- **Fan-out** — Parallel sub-agent spawning
- **Filesystem as truth** — A core principle
- **Frontmatter** — YAML block at the top of a .md file
- **Goto** — XML workflow jump
- **Graceful degradation** — Work inline if a subagent is unavailable
- **HALT** — AI waits for user input
- **Human-in-the-loop** — User at strategic checkpoints
- **Icon** — A single emoji for an agent (📊📚📋🎨🏗️💻)
- **Inference rule** — A validation rule that requires LLM judgment
- **Install paths** — The directory structure of `_bmad/`
- **Invoke** — The proper way to call another skill
- **Jobs-to-be-Done (JTBD)** — PM framework (John's principle)
- **John 📋** — PM persona
- **Keyed merge** — Array of tables merged by `code`/`id`
- **Mary 📊** — Analyst persona
- **Menu** — Agent command shortcuts
- **Micro-file** — A 2-5KB step file
- **Module** — Package of skills + agents
- **module.yaml** — Module definition file
- **Named agent** — Agent with a persona (Mary, John, etc.)
- **Paige 📚** — Tech Writer persona
- **Party mode** — Multi-agent collaboration
- **Persistent facts** — Always-loaded agent knowledge
- **Persona** — An agent's identity + communication style
- **Phase** — One of the 4 BMM phases (Analysis/Planning/Solutioning/Implementation)
- **Planning artifacts** — Folder for phase 1-3 outputs
- **PRD** — Product Requirements Document
- **PRFAQ** — Press Release + FAQ (Amazon method)
- **Product brief** — 1-2 page executive summary
- **Project context** — `project-context.md` containing project rules
- **Quick dev** — Quick Flow path (skip the formal PRD)
- **RED-GREEN-REFACTOR** — TDD cycle
- **Resolve variables** — Expand `{var}` to actual values
- **Retrospective** — Post-epic party-mode review
- **Resume detection** — Check an existing file to continue
- **Review continuation** — Dev-story after code-review
- **Runtime variable** — Set during execution
- **Sally 🎨** — UX Designer persona
- **Sequential** — Step-by-step, not parallel
- **Shard doc** — Split a large doc by H2 sections
- **Significant discovery** — Retrospective finding that requires an epic update
- **SKILL.md** — Skill entry point
- **Skills manifest** — CSV of all installed skills
- **Smart selection** — Context-aware method picking
- **Sprint status** — `sprint-status.yaml` state file
- **State tracking** — `stepsCompleted` frontmatter array
- **Steps/** — Micro-file folder
- **Sub-agent** — A prompt spawned via the Agent tool
- **System macro** — `{project-root}`, `{date}`, etc.
- **Template** — Output file template
- **Trunk-based dev** — Every push to main auto-publishes
- **UX-DR** — UX Design Requirement
- **Validation** — Check rules via validate-skills.js
- **Validation gate** — Multi-check before marking complete
- **Verbatim skills** — Installed unchanged into IDE folders
- **Winston 🏗️** — Architect persona
- **workflow.md** — Skill logic file
- **XML workflow** — Inline workflow with `<step>`, `<action>`, `<check>` tags

---

**Continue reading:** [16-faq.md](16-faq.md) — Frequently asked questions for new developers.
