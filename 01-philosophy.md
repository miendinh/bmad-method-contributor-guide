# 01. Philosophy & Design Principles of BMAD-METHOD

> ⚠️ **UNOFFICIAL THIRD-PARTY DOCUMENTATION**
> NOT official BMad docs. See [DISCLAIMER.md](DISCLAIMER.md) | Licensed MIT — see [LICENSE](LICENSE) and [NOTICE](NOTICE)
> Official BMAD-METHOD: <https://github.com/bmad-code-org/BMAD-METHOD>

---

> Understand **WHY** the framework was designed this way. Without this section, every technique that follows will look arbitrary.

---

## Table of Contents

1. [Core philosophy: "Human Amplification, Not Replacement"](#1-core-philosophy-human-amplification-not-replacement)
2. [Architectural principles (10 principles)](#2-architectural-principles-10-principles)
3. [Core separations](#3-core-separations)
4. [Distinctive concepts](#4-distinctive-concepts)
5. [Comparison with other systems](#5-comparison-with-other-systems)
6. [When NOT to use BMad](#6-when-not-to-use-bmad)

---

## 1. Core philosophy: "Human Amplification, Not Replacement"

This statement appears on the first line of [CONTRIBUTING.md](../CONTRIBUTING.md). It is not just a marketing slogan — it steers every technical decision in the framework.

### 1.1 Three questions BMad asks before every feature

> *Every contribution should answer: "Does this make humans and AI better together?"*

Three tests a contributor must pass:

1. **✅ Strengthens collaboration?** — AI gets better when collaborating with humans; humans get better when collaborating with AI
2. **❌ Sidelines human?** — Fully-automated features are rejected
3. **❌ Creates adoption barrier?** — Complexity that forces the user up too steep a learning curve is not accepted

### 1.2 Concrete consequences for the code

This philosophy manifests in the code through 4 patterns:

| Pattern | Description | Where to see it |
|---------|-------|----------|
| **HALT at checkpoints** | AI must stop at menus, wait for user choice | Every `workflow.md` step with `<ask>` or a menu |
| **Confirm before destructive** | AI confirms before delete/overwrite | `bmad-dev-story` step 8 (validation gates) |
| **Skill-level-aware communication** | AI adapts tone by `{user_skill_level}` | Frontmatter `user_skill_level`: beginner/intermediate/expert |
| **Explicit handoff** | Each phase ends with user approval | Between Planning → Solutioning → Implementation |

### 1.3 Anti-patterns rejected outright

Verbatim from CONTRIBUTING.md:

> *We will reject PRs that read like raw LLM output: bulk refactors nobody asked for, unsolicited "improvements" across many files, or changes where the submitter clearly hasn't read the existing code. Using AI to write code is normal here; **using AI as a substitute for thinking is not**.*

BMad treats AI as a **skilled craftsman** needing human curation, not an **oracle** making decisions.

---

## 2. Architectural principles (10 principles)

### Principle 1: Filesystem is Truth

**Statement:** All state (workflow state, agent memory, phase artifacts) is stored in files. No DB, no in-memory state between sessions.

**Why:**
- **AI sessions are short, user tasks are long** — a conversation may be compacted, reset, or switched to another IDE. State kept in chat history would be lost.
- **Git-native** — files in the filesystem → git tracks them → rollback, diff, PR review all work out of the box
- **Portable** — the user can carry `_bmad/` to another machine, IDE, or agent

**Trade-off:**
- ✅ Reliable, debuggable, diffable
- ❌ Slower than in-memory; user sees many "junk" files

**Concrete pattern:**
```
Story file saved at:      {implementation_artifacts}/1-2-user-auth.md
Sprint status saved at:   {implementation_artifacts}/sprint-status.yaml
Brainstorm output at:     {output_folder}/brainstorming/brainstorming-session-{date}.md
```

### Principle 2: Declarative > Imperative

**Statement:** Workflows are written in **Markdown + YAML/TOML**, not code. Validators are also written in Markdown (`skill-validator.md`), enforced by a minimal deterministic JS layer.

**Why:**
- **LLMs read Markdown natively** — no special parser needed
- **Users can read it** — a PM who can't code still understands the workflow
- **Diffs are easy to review** — changing 1 step = changing 1 small file

**Example:**

❌ Imperative (NOT how BMad does it):
```js
async function brainstorm() {
  const topic = await askUser("What topic?");
  const techniques = loadTechniques();
  // ...
}
```

✅ Declarative (how BMad does it):
```markdown
## YOUR TASK
Ask the user for a topic, then load brain-methods.csv and select techniques...
## NEXT
Read fully and follow: `./step-02a-user-selected.md`
```

### Principle 3: Document-as-Interface

**Statement:** Phases communicate with each other **through output files**, not through variables, memory, or APIs.

```
Phase 1 output: product-brief.md
              ↓ (file handoff)
Phase 2 input: product-brief.md → produces prd.md
              ↓ (file handoff)
Phase 3 input: prd.md → produces architecture.md + stories/*.md
              ↓ (file handoff)
Phase 4 input: stories/*.md → code
```

**Why:**
- **Asynchronous** — Phase 1 can finish last month, phase 2 next month
- **Multi-agent friendly** — the PM agent and the Architect agent don't need to run at the same time
- **Auditable** — every decision is stored in a file, not in a chat
- **Resume-able** — workflows interrupted mid-way can be resumed

### Principle 4: Micro-file Workflows

**Statement:** A workflow is not a giant single file, but a collection of **independent step files** ~2-5KB each.

```
bmad-brainstorming/
└── steps/
    ├── step-01-session-setup.md      (2.3KB)
    ├── step-01b-continue.md          (1.8KB)
    ├── step-02a-user-selected.md     (2.1KB)
    ├── step-02b-ai-recommended.md    (2.4KB)
    ├── step-02c-random-selection.md  (1.9KB)
    ├── step-02d-progressive-flow.md  (2.2KB)
    ├── step-03-technique-execution.md (4.1KB)
    └── step-04-idea-organization.md  (2.8KB)
```

**Why:**
- **LLM context window** — just-in-time loading reduces token usage
- **Sequential discipline** — the AI cannot "skip ahead" when each step is its own file
- **Parallel branching** — step-02a/02b/02c/02d are 4 branches; only 1 is loaded at runtime
- **Editable** — fixing one step does not touch the others

**Design rules:**
- Each step **≤ 5KB**
- The first step MUST have `YOUR TASK`
- The final step MUST point to NEXT (except terminal steps)
- Total steps **2-10** (no more)
- No forward-loading (don't read future steps)

### Principle 5: Sequential by Default

**Statement:** Workflows run sequentially. No parallel execution, no async branching at runtime (only declarative conditional branching).

**Why:**
- **LLMs get lost easily** when there are many parallel threads
- **Human-in-the-loop** needs clear stopping points
- **State is simpler** — no race conditions, no merge conflicts

**Exception:** `bmad-party-mode` — a multi-agent collaboration session, but it orchestrates sequential conversations rather than parallel execution.

### Principle 6: Encapsulated Skills (PATH-05)

**Statement:** A skill **MUST NOT read files from another skill**. To use one, you must **invoke** that skill through `bmad-agent` or a `skill:` reference.

```
❌ WRONG: {project-root}/_bmad/skills/bmm/bmad-create-prd/template.md
✅ RIGHT: Invoke the `bmad-create-prd` skill
```

**Why:**
- **Encapsulation** — a skill can refactor internals without breaking dependents
- **Testable** — a skill is tested as a black box
- **Versionable** — bumping a skill's version does not break consumers
- **Analog: microservices** — don't reach into another service's DB

**Consequence:** To share a template between skills → extract it into a third skill that both invoke.

### Principle 7: Config-Driven Paths

**Statement:** Every path must use a **config variable** (`{planning_artifacts}`, `{project-root}`), never hardcoded.

```
❌ WRONG:  /Users/alice/project/docs/prd.md
❌ WRONG:  ~/project/docs/prd.md
❌ WRONG:  ./docs/prd.md  (when run from a skill elsewhere)
✅ RIGHT:  {planning_artifacts}/prd.md
```

**Why:**
- **Multi-user** — Alice stores at `docs/`, Bob at `planning/`; both run the same skill
- **Relocatable** — change the output folder without editing 100 files
- **Installer-controllable** — the installer prompts the user to choose and writes into config

### Principle 8: Declarative Validation

**Statement:** Rules are written in **Markdown** (`tools/skill-validator.md`), enforced by:
- **Deterministic JS** (`tools/validate-skills.js`) — 14 rules that can be checked via regex/AST
- **LLM inference** — 16+ rules needing judgment (read the spec and review)

**Why:**
- **Self-documenting** — the rule is also the docs
- **Extensible** — adding a rule requires no code, just markdown
- **LLM-reviewable** — the validator itself can be read and applied by AI

**Example rule:**

```markdown
### SKILL-04 - `name` Format
- **Severity:** HIGH
- **Applies to:** SKILL.md
- **Rule:** The `name` value must start with `bmad-`, use only lowercase letters, numbers, and single hyphens...
- **Detection:** Regex test: `^bmad-[a-z0-9]+(-[a-z0-9]+)*$`
- **Fix:** Rename to comply with the format (e.g., `bmad-my-skill`).
```

This rule is simultaneously a **human spec**, a **machine check** (pre-written regex), and an **LLM prompt** (fix guidance).

### Principle 9: Layered Customization (3-level)

**Statement:** Each skill/agent has 3 override layers:

```
Level 1: {skill-root}/customize.toml            ← Default (shipped)
Level 2: {project-root}/_bmad/custom/skill.toml  ← Team
Level 3: {project-root}/_bmad/custom/skill.user.toml ← Individual
```

**Merge semantics:**
- Scalars: user wins (override)
- Arrays (`persistent_facts`): append (not override)
- Array-of-tables with `code`/`id`: match replaces, new entries append

**Why:**
- **The team can set standards** (Level 2) without touching framework source
- **Individuals can customize** (Level 3) without breaking team conventions
- **Framework updates** don't erase customizations

### Principle 10: Human-in-the-Loop at Checkpoints

**Statement:** The AI does not run end-to-end. It HALTs at key moments and waits for the user.

**Typical checkpoints:**

| Checkpoint | When | User action |
|-----------|-----------|----------------|
| **Menu option selection** | Start of workflow, branching | Choose [1/2/3/...] |
| **Phase approval** | PRD done → Architecture | "Approve" or "Revise" |
| **Story review** | Dev finished story → ready-for-review | Code review, approve/request changes |
| **Correct course** | Issue detected mid-sprint | Confirm scope change |
| **Validation gate** | Before commit/ship | Confirm tests pass |
| **Ambiguity detected** | Workflow hits an unclear spec | Clarify |

**Code pattern in workflow.md:**

```xml
<check if="new dependencies required">
  HALT: "Additional dependencies need user approval"
</check>

<action if="3 consecutive implementation failures occur">
  HALT and request guidance
</action>
```

---

## 3. Core separations

BMad insists on drawing several lines that many teams blur.

### 3.1 "WHAT TO BUILD" vs "HOW TO BUILD IT"

This is **BMad's most important separation**, mentioned in [docs/vi-vn/bmad-developer-guide.md](../docs/vi-vn/bmad-developer-guide.md):

| Question | Phase | Output | Agent |
|---------|-------|--------|-------|
| **WHAT TO BUILD? Why?** | Phase 2 (Planning) | PRD, UX Design | John (PM), Sally (UX) |
| **HOW TO BUILD IT?** | Phase 3 (Solutioning) | Architecture, Stories | Winston (Architect) |

> *Many projects fail because they start building before agreeing on "WHAT TO BUILD", or start coding before deciding "HOW TO BUILD IT".*

**Practical consequences:**
- The PRD must not contain technical decisions (no "use React", no "use Postgres")
- The Architecture must not contain requirements (no "users must be able to log in")
- If the PM writes tech → error; if the Architect writes requirements → error

### 3.2 Agent vs Skill vs Workflow

| | Agent | Skill | Workflow |
|---|-------|-------|----------|
| **What it is** | Persona (character) | Unit of work | Logic inside one skill |
| **Has a name** | Mary, John, Amelia... | `bmad-create-prd` | (no proper name) |
| **Has a menu** | Yes (list of skills) | No | No |
| **Invokes what** | Invokes skills | Invokes sub-skills | Invokes the next step |
| **Example** | `bmad-agent-pm` | `bmad-create-prd` | `workflow.md` inside a skill |

### 3.3 Planning artifact vs Implementation artifact vs Project knowledge

| | Planning artifacts | Implementation artifacts | Project knowledge |
|---|-------------------|--------------------------|-------------------|
| **Stored at** | `{planning_artifacts}` | `{implementation_artifacts}` | `{project_knowledge}` |
| **Produced by phase** | Phase 1-3 | Phase 4 | Research, document-project |
| **Update frequency** | Rare (locked after approval) | Continuous | In batches |
| **Example** | brief, PRFAQ, PRD, architecture, epics | sprint-status.yaml, stories, reviews | tech-stack.md, coding-standards.md |
| **Default folder** | `_bmad-output/planning-artifacts` | `_bmad-output/implementation-artifacts` | `docs/` |

### 3.4 Config variable vs Runtime variable

| | Config variable | Runtime variable |
|---|----------------|------------------|
| **Source** | `_bmad/{module}/config.yaml` | Set during execution |
| **Available when** | Install-time (user answers prompts) | Runtime |
| **Example** | `{user_name}`, `{planning_artifacts}` | `{date}`, `{story_key}`, `{spec_file}` |
| **Declared in** | `module.yaml` | `workflow.md` frontmatter |
| **Stable** | Yes, across the whole session | No, per-execution |

### 3.5 Invoke vs Read

This is the **SEQ-01 / REF-03** point — wording matters:

| Phrase | Meaning | Use when |
|----------|---------|----------|
| "**Invoke the** `bmad-xxx` **skill**" | Call a skill as a black box | Cross-skill |
| "Read fully and follow `./step-02.md`" | Read a file in the same skill | Intra-skill (step → next step) |
| "Load `{project-root}/.../config.yaml`" | Read a config data file | Load data |

**Using the wrong one = validation fails.** Examples:

```
❌ "Execute bmad-create-prd"            (SEQ-01 fail)
❌ "Read fully: bmad-create-prd"         (PATH-05 + REF-03 fail)
✅ "Invoke the `bmad-create-prd` skill"
```

---

## 4. Distinctive concepts

BMad has a few concepts not found in other frameworks. They're listed here so you remember them.

### 4.1 Named Agents (Persona)

Each agent has a **proper name + icon + personality + communication style**:

| Agent | Name | Communication style |
|-------|-----|-----------------|
| Analyst | Mary 📊 | "Treasure hunter narrating the find: thrilled by every clue, precise once the pattern emerges" |
| PM | John 📋 | "Detective interrogating a cold case: short questions, sharper follow-ups, every 'why?' tightening the net" |
| UX | Sally 🎨 | "Filmmaker pitching the scene before the code exists" |
| Architect | Winston 🏗️ | "Seasoned engineer at the whiteboard: measured, laying out trade-offs" |
| Dev | Amelia 💻 | "Terminal prompt: exact file paths, AC IDs, commit-message brevity" |
| Tech Writer | Paige 📚 | "Patient teacher, using analogies that make complex things feel simple" |

**Why name them?**
- **Mental model** — users remember "ask John" more easily than "ask the PM agent"
- **Context switching** — "switching from John to Winston" is clearer than "switching from PM mode to Architect mode"
- **Behavioral cue for the AI** — LLMs adopt a style more reliably when given a concrete persona (see [docs/explanation/named-agents.md](../docs/explanation/named-agents.md))

### 4.2 Party Mode

**A multi-agent collaboration session** — several agents discuss the same problem while the user acts as orchestrator.

**When to use:**
- Cross-functional problems (PM + Architect + UX all weigh in)
- Heavy trade-offs needing multiple perspectives
- High-level brainstorming (not a single-agent `bmad-brainstorming`)

**Mechanism:** No parallel execution. One agent speaks, then another responds, taking turns (round-robin or user-directed).

### 4.3 Adversarial Review

**A review whose purpose is to FIND FLAWS**, not to validate.

Different from typical code review:

| Typical code review | Adversarial review |
|-------------------|---------------------|
| "Looks OK" | "What if the user passes null?" |
| Confirm the design works | Try to break the design |
| Focus: best practices | Focus: edge cases, failure modes |

**Skills:**
- `bmad-review-adversarial-general` — general adversarial
- `bmad-review-edge-case-hunter` — specialized on edge cases
- `bmad-editorial-review-prose` — prose review
- `bmad-editorial-review-structure` — document structure review

**Philosophy:** "AI has a tendency to validate what it has written. An adversarial mindset must be **injected explicitly**."

### 4.4 Advanced Elicitation

**Techniques for questioning users to expose hidden assumptions.**

Typical techniques:
- **Five Whys** — ask "why?" 5 times
- **Pre-mortem** — "Assume the project failed. What's the reason?"
- **Rubber duck** — the user explains it to the "duck" (AI)
- **Inversion** — "What's the opposite of the goal? What would we do?"
- **Red team** — "Who would hate this feature, and why?"

Use when the user **thinks they're clear** but actually has unresolved ambiguity.

### 4.5 Checkpoint Preview

**Preview the changes to be committed, review before ship.**

It is not plain `git diff` — it includes:
- Code diff
- Impact on other stories
- Affected tests
- Acceptance criteria still missing

Its role: **the last human gate** before code ships.

### 4.6 Correct Course

**Mid-sprint adjustment when the wrong direction is detected.**

Situations:
- A story is under development and the spec turns out to be wrong
- The architecture hits a new constraint
- A stakeholder changes requirements

The `bmad-correct-course` skill handles artifact rollback, sprint updates, and logs the reason.

**Not a "reset"** — it preserves context and documents precisely why the direction changed.

### 4.7 Quick Dev vs Full Flow

Two flows, differing by **heaviness**:

| Quick Dev | Full Flow |
|-----------|-----------|
| Skill: `bmad-quick-dev` | Skills: `bmad-create-story` → `bmad-dev-story` → ... |
| 1-15 stories | 10-50+ stories |
| No formal PRD needed | Requires PRD + Architecture |
| Agent: Amelia only | All 6 agents |
| Use for: bugfix, small feature | Use for: product/platform |

**Rule of thumb:** If unsure, use `bmad-help` — it will recommend.

### 4.8 Shard Doc

**Splits large documents into chunks** for the LLM to process.

Problem: a 20-page PRD → exceeds the context window of a small step.

Solution: `bmad-shard-doc` splits it into smaller files, retaining metadata for re-assembly.

### 4.9 Project Context

**Not a PRD, not an Architecture, not a README.**

It is a file containing:
- Tech stack (languages, framework, main libraries)
- Coding standards
- Repository layout
- Git workflow
- Build/deploy commands

Produced by `bmad-generate-project-context` (once or periodically) and used by the dev agent as context during coding.

### 4.10 Implementation Readiness

**Pre-flight check before starting phase 4.**

Skill: `bmad-check-implementation-readiness`

Checklist covers:
- Does the Architecture have enough detail?
- Do the stories have clear acceptance criteria?
- Is the dev environment set up?
- Are dependencies approved?

If it fails → go back to phase 3 to fill in the gaps.

### 4.11 Distillator

**Compresses documents** (compression). Different from shard-doc (split):

| Shard doc | Distillator |
|-----------|-------------|
| Split large file → small files | Compress large file → smaller file |
| Preserves 100% of info | Loses some info, keeps essence |
| Reversible | One-way (with round-trip reconstructor) |

Skill: `bmad-distillator` with `agents/distillate-compressor.md` and `agents/round-trip-reconstructor.md`.

### 4.12 Brainstorming Techniques

`bmad-brainstorming` has a **CSV file** `brain-methods.csv` containing **~30+ techniques**:

- SCAMPER, Six Thinking Hats, Mind Mapping
- Brainwriting, Reverse Brainstorming
- Analogy, Morphological Analysis
- Random Stimulation, Force Fitting
- ...

Each technique has: name, description, when-to-use, example.

Anti-bias protocol: pivot techniques every 10 ideas to avoid semantic clustering.

---

## 5. Comparison with other systems

### 5.1 BMad vs IDE AI (Cursor / Copilot / Claude Code raw)

| | Cursor/Copilot | BMad |
|---|---------------|------|
| **Scope** | Line-level suggestions | Feature-level workflows |
| **State** | Conversation only | Filesystem artifacts |
| **Phase separation** | None | Planning ≠ Implementation |
| **Multi-agent** | Single agent | 6 personas |
| **Artifacts** | None produced | PRD, Architecture, Stories |

BMad is **used together with Cursor/Copilot** — it layers on top. You still use Cursor to code, but BMad provides the structured workflow.

### 5.2 BMad vs Agent frameworks (LangGraph / CrewAI / AutoGen)

| | LangGraph/CrewAI | BMad |
|---|------------------|------|
| **Language** | Python code | Markdown + YAML |
| **State** | In-memory (graph state) | Filesystem |
| **Execution** | Runtime engine | AI reads and follows |
| **Target user** | ML engineers | Product teams |
| **Extensibility** | Code new nodes | Write new markdown |
| **Debug** | Debug Python | Read output files |

**Core difference:** LangGraph is an **engine that runs agents**; BMad is a **prompt framework guiding the agent**. There is no "BMad runtime" — the AI reads and follows.

### 5.3 BMad vs Template-based (Rails generators, Yeoman)

| | Template generators | BMad |
|---|--------------------|------|
| **Output** | File structure (one-shot) | Ongoing workflow |
| **Interactive** | Minimal prompting | Deep interactive |
| **Update** | Regenerate (destroys customization) | Layered override |
| **AI-native** | No | Yes (designed for LLMs) |

---

## 6. When NOT to use BMad

Honestly, BMad is not **one-size-fits-all**.

**Don't use BMad if:**

1. **Urgent hotfix** (< 30 minutes) — install/workflow overhead isn't worth it
2. **Solo dev, project < 500 LOC** — PRD/Architecture are unnecessary
3. **Research/spike** — BMad's value is in structured delivery, not exploration
4. **Heavy existing process** (SAFe, strict Scrum) — may conflict
5. **Change-averse team** — BMad asks for a new mindset

**Do use BMad when:**

1. **Product/platform development** — you have a PRD, stakeholders, and sprints
2. **A team of 2-10** — shared artifacts are needed
3. **Long lifecycle** (months/years) — artifact-based workflow pays dividends over time
4. **AI-first workflow** — the team wants AI as a first-class collaborator
5. **Cross-functional** — PM, Designer, Dev, QA share the workflow

---

## 7. Roadmap (V6 & Beyond)

From [docs/vi-vn/index.md](../docs/vi-vn/index.md):

> *V6 has shipped and we're only just getting started!*
> *Skills architecture, BMad Builder v1, Dev Loop Automation, and much more are in development.*

**Direction:**
- **BMad Builder** — a tool to build new modules/skills (a meta-framework)
- **Dev Loop Automation** — automatic dev-review-deploy chains
- **Skills architecture v2** — enhanced skill spec

See [docs/roadmap.mdx](../docs/roadmap.mdx) for details.

---

## Summary

BMad is not merely a technical framework. It is the **expression of a philosophy**:

> *AI is an amplifier, not a replacement. Documents are the common language. The filesystem is truth. Separate WHAT from HOW. Halt at checkpoints so humans decide.*

Understand this philosophy → you understand why every technical decision (PATH-05, micro-files, 3-level override, named agents) exists.

---

**Read next:** [02-environment-and-variables.md](02-environment-and-variables.md) — a deep dive into the environment variable system.
