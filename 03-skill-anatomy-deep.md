# 03. Skill Anatomy - Deep specification

> ⚠️ **UNOFFICIAL THIRD-PARTY DOCUMENTATION**
> NOT official BMad docs. See [DISCLAIMER.md](DISCLAIMER.md) | Licensed MIT — see [LICENSE](LICENSE) and [NOTICE](NOTICE)
> Official BMAD-METHOD: <https://github.com/bmad-code-org/BMAD-METHOD>

---

> A deep dive into the **anatomy of a skill**: SKILL.md, workflow.md, steps/, sub-files, extended XML syntax, canonical examples (`bmad-brainstorming`, `bmad-dev-story`, `bmad-create-prd`).

---

## Table of Contents

1. [Standard directory structure](#1-standard-directory-structure)
2. [SKILL.md - L1 metadata](#2-skillmd---l1-metadata)
3. [workflow.md - the main logic](#3-workflowmd---the-main-logic)
4. [steps/ - micro-file architecture](#4-steps---micro-file-architecture)
5. [XML workflow syntax (for step logic)](#5-xml-workflow-syntax-for-step-logic)
6. [Sub-files: template, checklist, resources, agents](#6-sub-files-template-checklist-resources-agents)
7. [Canonical example 1: bmad-brainstorming](#7-canonical-example-1-bmad-brainstorming-micro-file)
8. [Canonical example 2: bmad-dev-story](#8-canonical-example-2-bmad-dev-story-xml-workflow)
9. [Canonical example 3: bmad-agent-pm](#9-canonical-example-3-bmad-agent-pm-agent-skill)
10. [Skill validation rules reference](#10-skill-validation-rules-reference)

---

## 1. Standard directory structure

```
bmad-my-skill/
├── SKILL.md                  # L1 metadata (REQUIRED)
├── workflow.md               # Main logic (REQUIRED if the skill has a workflow)
├── customize.toml            # Agent persona or workflow hooks (if it's an agent-skill)
├── template.md               # Output template (optional)
├── checklist.md              # Validation checklist (optional)
├── steps/                    # Micro-file architecture (optional, if using this pattern)
│   ├── step-01-init.md
│   ├── step-02a-branch-a.md
│   ├── step-02b-branch-b.md
│   └── step-03-finalize.md
├── resources/                # Reference docs the LLM needs to load (optional)
│   ├── compression-rules.md
│   └── format-reference.md
├── agents/                   # Sub-agent prompts (optional, for complex skills)
│   ├── sub-agent-a.md
│   └── sub-agent-b.md
├── scripts/                  # Helper scripts (optional)
│   └── helper.py
└── *.csv, *.yaml             # Data files (optional, like brain-methods.csv)
```

### 1.1 Required vs Optional

| File | Required | Notes |
|------|----------|---------|
| `SKILL.md` | ✅ **REQUIRED** | Entry point; frontmatter must have `name` + `description` |
| `workflow.md` | ⚠️ Almost always | Except for simple skills like reviews — it can point to workflow.md or inline inside SKILL.md |
| `customize.toml` | Optional | Agent-skills MUST have it. Workflow-skills may have it to customize hooks |
| `template.md` | Optional | When the output has a fixed format |
| `steps/` | Optional | When the workflow has > 2 phases |
| `resources/` | Optional | Reference docs for the LLM |
| `agents/` | Optional | Sub-agent prompts (used with the Agent tool) |
| `scripts/` | Optional | Python/Node helpers |

### 1.2 Naming conventions

- **Directory name** = `bmad-*` format, regex `^bmad-[a-z0-9]+(-[a-z0-9]+)*$`
- **Step files** = `step-NN[-variant]-description.md` (NN zero-padded)
- **Agent persona skill** = `bmad-agent-<role>` (e.g., `bmad-agent-pm`)
- **Uppercase** only for: `SKILL.md`, `CSV.md`, acronyms

---

## 2. SKILL.md - L1 metadata

### 2.1 Frontmatter (REQUIRED)

```yaml
---
name: bmad-my-skill
description: 'Does X using Y technique. Use when the user says "do X" or asks for Y.'
---
```

**Rules:**

| Field | Required | Rule | Validator |
|-------|---------|------|-----------|
| `name` | ✅ | Match regex `^bmad-[a-z0-9]+(-[a-z0-9]+)*$`, **must match directory name** | SKILL-02, SKILL-04, SKILL-05 |
| `description` | ✅ | Max 1024 chars, must contain **"what"** + **"when to use"** (trigger phrases like "Use when", "Use if") | SKILL-03, SKILL-06 |

### 2.2 Body

The SKILL.md body is the **L2 instructions**. There are 2 patterns:

**Pattern A: Skill with a workflow.md (the most common)**

```markdown
---
name: bmad-my-skill
description: '...'
---

Follow the instructions in ./workflow.md.
```

The body is minimal — it just redirects to workflow.md.

**Pattern B: Inline skill (for simple skills)**

```markdown
---
name: bmad-review-adversarial-general
description: 'Cynically review content and produce findings report...'
---

# Adversarial Review

You are a jaded, skeptical reviewer who has seen too much bad code.

## Execution

1. Receive content
2. Find AT LEAST 10 issues (HALT if zero findings)
3. Output as markdown list
```

The body holds the logic directly. Use this when the skill has <100 lines of logic.

### 2.3 SKILL-07: The body must not be empty

If only frontmatter is present and there is no body → validation fails (SKILL-07).

---

## 3. workflow.md - the main logic

### 3.1 Frontmatter

```yaml
---
context_file: ''              # Optional runtime variable
spec_file: ''
story_path: ''
---
```

**Rules WF-01, WF-02:**
- Must NOT have `name:`
- Must NOT have `description:`

These are runtime variable declarations. An empty string = no value yet; will be filled during execution.

**WF-03:** Values must be:
- A config variable reference `{planning_artifacts}`
- Empty/placeholder
- A legitimate external path
- **NOT** a path into another skill (PATH-05)

### 3.2 Body structure

```markdown
# [Skill Name] Workflow

**Goal:** [1-2 sentence description of the goal]

**Your Role:** [The persona the AI adopts when running this skill]

**Critical Mindset:** [If needed — e.g. an anti-bias protocol]

---

## INITIALIZATION

### Configuration Loading
Load config from `{project-root}/_bmad/{module}/config.yaml` and resolve:
- `project_name`, `output_folder`, `user_name`
- `communication_language`, `document_output_language`
- `date` as system-generated current datetime

### Paths
- `my_output_file` = `{planning_artifacts}/my-output-{{date}}.md`

### Context
- `project_context` = `**/project-context.md` (load if exists)

---

## EXECUTION

Read fully and follow: `./steps/step-01-init.md` to begin the workflow.

[OR an inline XML workflow for simple skills]
```

### 3.3 "Architecture sections" (optional)

Some workflow.md files also have:

```markdown
## WORKFLOW ARCHITECTURE

This uses **micro-file architecture** for disciplined execution:
- Each step is a self-contained file with embedded rules
- Sequential progression with user control at each step
- Document state tracked in frontmatter
- Append-only document building through conversation
- Brain techniques loaded on-demand from CSV
```

This explains the skill's pattern to the LLM.

### 3.4 Paths declaration

The **Paths section** is where output file paths are declared using config variables:

```markdown
## Paths
- `brainstorming_session_output_file` = `{output_folder}/brainstorming/brainstorming-session-{{date}}-{{time}}.md`
- `sprint_status` = `{implementation_artifacts}/sprint-status.yaml`

All steps MUST reference `{brainstorming_session_output_file}` instead of the full path pattern.
```

**Syntax note:**
- `{config_var}` single curly — resolved by the config merger
- `{{runtime_macro}}` double curly — resolved at runtime by the workflow engine

### 3.5 EXECUTION section

How to point to the first step:

```markdown
## EXECUTION

Read fully and follow: `./steps/step-01-session-setup.md` to begin the workflow.
```

**Wording matters:** "Read fully and follow" — not "execute" or "invoke" (this is intra-skill, not cross-skill).

---

## 4. steps/ - micro-file architecture

### 4.1 Micro-file principles

- **One step = one file**, ~2-5KB
- **Self-contained** — loading one file gives you enough context for that step
- **Sequential** — no skipping ahead; you must follow NEXT
- **No forward-loading** — don't read future steps early
- **Total 2-10 steps** (STEP-07)

### 4.2 Step file anatomy

```markdown
# Step NN: [Step Name]

## YOUR TASK
[Goal section — REQUIRED, STEP-02]
Clearly state the goal of this step.

## CONTEXT
[Optional — needed context]

## ACTION
[Detailed instructions]

1. Do A
2. Do B
3. ...

### Sub-section 1
Detail...

### Sub-section 2
Detail...

## HALT CONDITIONS
[Optional — when to stop]
- If user input missing → HALT: "Please provide..."
- If file not found → HALT: "Cannot proceed without..."

## NEXT
Read fully and follow: `./step-02-execute.md`
```

### 4.3 Step naming

**Format:** `step-NN[-variant]-description.md`

- `NN` = 2-digit zero-padded (01, 02, 10, 99)
- `variant` = lowercase letter for branching (02a, 02b, 02c)
- `description` = kebab-case

**Examples:**
```
step-01-session-setup.md
step-01b-continue.md          ← continuation variant
step-02a-user-selected.md     ← branch A
step-02b-ai-recommended.md    ← branch B
step-02c-random-selection.md  ← branch C
step-02d-progressive-flow.md  ← branch D
step-03-technique-execution.md
step-04-idea-organization.md
```

### 4.4 Branching

Step `01` can point to one of several branches:

```markdown
## NEXT

Based on user choice:
- If user selects [1] → Read fully and follow: `./step-02a-user-selected.md`
- If user selects [2] → Read fully and follow: `./step-02b-ai-recommended.md`
- If user selects [3] → Read fully and follow: `./step-02c-random-selection.md`
- If user selects [4] → Read fully and follow: `./step-02d-progressive-flow.md`
```

Each branch is one file. The LLM only loads the file corresponding to the user's choice.

### 4.5 Frontmatter in step files

**Rule STEP-06:**
- Must NOT have `name:`
- Must NOT have `description:`

Step files typically have no frontmatter (body only). If present, only runtime variables.

### 4.6 HALT pattern

```markdown
## HALT CONDITIONS

- **Missing required input**: HALT and ask user for {{spec_file}}
- **Validation fails**: HALT with error message, explain what's wrong
- **3 consecutive failures**: HALT and request guidance
- **Ambiguity detected**: HALT, ask user to clarify
```

HALT = the AI stops and waits for user input. It does not auto-continue.

### 4.7 Loop-back pattern

```markdown
## NEXT

<action if="more tasks remain">
  <goto step="5">Next task</goto>
</action>

<action if="no tasks remain">
  <goto step="9">Completion</goto>
</action>
```

Or inlined inside a step body. `goto` allows loops (e.g. step 5 → 5 → 5 → 9 when tasks run out).

---

## 5. XML workflow syntax (for step logic)

BMad has a **mini DSL** using XML tags inside workflows/steps. Used when the logic is too complex for plain markdown.

### 5.1 Core tags

```xml
<workflow>
  <critical>CRITICAL RULE placed first — the AI must follow it absolutely</critical>
  <critical>Execute ALL steps in exact order</critical>
  
  <step n="1" goal="Do something" tag="optional-tag">
    [Step content]
  </step>
</workflow>
```

### 5.2 Conditional & action tags

```xml
<check if="{{story_path}} is provided">
  <action>Use {{story_path}} directly</action>
  <action>Read COMPLETE story file</action>
  <goto anchor="task_check" />
</check>

<check if="no ready-for-dev stories found">
  <output>📋 No ready-for-dev stories found...</output>
  <ask>Choose option [1], [2], [3], or [4]:</ask>
</check>

<action>Parse sections: Story, Acceptance Criteria, Tasks/Subtasks</action>
<action if="regression tests fail">STOP and fix before continuing</action>
```

### 5.3 Tag reference

| Tag | Used for |
|-----|---------|
| `<workflow>` | Root of an inline workflow |
| `<step n="N" goal="..." tag="...">` | Define a step (instead of a separate file) |
| `<critical>` | A critical rule the AI must follow |
| `<action>` | An instruction — what the AI should do |
| `<action if="condition">` | A conditional action |
| `<check if="condition">...</check>` | A conditional block |
| `<ask>...</ask>` | Prompt the user, HALT awaiting a response |
| `<output>...</output>` | Display a message to the user |
| `<goto step="N">` or `<goto anchor="name">` | Jump to a step/anchor |
| `<anchor id="name" />` | A jump target within a step |
| `<!-- comment -->` | HTML comment |

### 5.4 Typical patterns

**Pattern: input validation**
```xml
<action if="story file inaccessible">HALT: "Cannot develop story without access to story file"</action>
<action if="incomplete task or subtask requirements ambiguous">ASK user to clarify or HALT</action>
```

**Pattern: branching logic**
```xml
<check if="current status == 'ready-for-dev' OR review_continuation == true">
  <action>Update the story in the sprint status report to = "in-progress"</action>
  <action>Update last_updated field to current date</action>
  <output>🚀 Starting work on story {{story_key}}</output>
</check>

<check if="current status == 'in-progress'">
  <output>⏯️ Resuming work on story {{story_key}}</output>
</check>
```

**Pattern: loop with goto**
```xml
<action>Determine if more incomplete tasks remain</action>
<action if="more tasks remain">
  <goto step="5">Next task</goto>
</action>
<action if="no tasks remain">
  <goto step="9">Completion</goto>
</action>
```

**Pattern: validation gate**
```xml
<critical>NEVER mark a task complete unless ALL conditions are met - NO LYING OR CHEATING</critical>

<action>Verify ALL tests for this task ACTUALLY EXIST and PASS 100%</action>
<action>Confirm implementation matches EXACTLY what the task specifies</action>

<check if="ALL validation gates pass">
  <action>ONLY THEN mark the task checkbox with [x]</action>
</check>

<check if="ANY validation fails">
  <action>DO NOT mark task complete - fix issues first</action>
  <action>HALT if unable to fix validation failures</action>
</check>
```

### 5.5 When to use XML vs plain Markdown

| Situation | Use |
|-----------|------|
| Simple sequential step | Markdown |
| Many if/else branches | XML tags |
| Loop (goto) | XML tags |
| Critical rules needing emphasis | XML `<critical>` |
| Need HALT with a prompt | XML `<ask>` |
| Complex decision tree | XML tags |

Framework recommendation: **keep it simple first**. Only use XML when markdown cannot express what you need.

---

## 6. Sub-files: template, checklist, resources, agents

### 6.1 template.md

An output template, used when the skill produces a file with a fixed format.

```markdown
# [Story Title]

## Story
As a {{user_type}}, I want {{functionality}}, so that {{benefit}}.

## Acceptance Criteria
- AC1: {{criterion_1}}
- AC2: {{criterion_2}}

## Tasks/Subtasks
- [ ] Task 1: {{task_description}}
  - [ ] Subtask 1.1
  - [ ] Subtask 1.2

## Dev Notes
{{dev_notes}}

## Dev Agent Record
### Implementation Plan
{{implementation_plan}}

### Debug Log
{{debug_log}}

## File List
{{file_list}}

## Change Log
{{change_log}}

## Status
{{status}}
```

The step file will:
1. Load the template
2. Fill placeholders with runtime values
3. Write to an output file

### 6.2 checklist.md

A validation checklist or analysis checklist:

```markdown
# Change Analysis Checklist

## Trigger Classification
- [ ] What type of change: requirement / architecture / scope / blocker?
- [ ] Who reported: stakeholder / developer / QA?
- [ ] Urgency: block current sprint / next sprint / future?

## Impact Analysis
- [ ] Which artifacts affected: PRD / UX / Architecture / Stories?
- [ ] Which epics/stories affected?
- [ ] Downstream impact on in-progress stories?

## Options
- [ ] Option A: [description]
  - Pros:
  - Cons:
- [ ] Option B: [description]
  - Pros:
  - Cons:

## Recommendation
[...]
```

Used in `bmad-correct-course`, `bmad-check-implementation-readiness`.

### 6.3 resources/

Reference docs the LLM loads when deep context is needed.

```
bmad-distillator/
└── resources/
    ├── compression-rules.md        # Compression rules
    ├── distillate-format-reference.md  # Standard format
    └── splitting-strategy.md       # When to split
```

Referenced from a step file:
```markdown
## ACTION

Read fully and follow the compression rules:
`./resources/compression-rules.md`

Apply the format from:
`./resources/distillate-format-reference.md`
```

### 6.4 agents/

Sub-agent prompts. Used when a complex skill needs to spawn child agents via the Agent tool.

```
bmad-distillator/
└── agents/
    ├── distillate-compressor.md          # Sub-agent: compress content
    └── round-trip-reconstructor.md       # Sub-agent: verify roundtrip
```

Each file is a **full prompt** for the sub-agent. A workflow step invokes it:

```markdown
## ACTION

Spawn sub-agent via Agent tool:
- Prompt: Read fully and apply `./agents/distillate-compressor.md`
- Pass: source_file, target_file, compression_ratio
```

Party-mode (`bmad-party-mode`) uses this pattern to spawn several agents concurrently.

### 6.5 scripts/

Python/Node helper scripts for things that require deterministic logic:

```
bmad-customize/
└── scripts/
    └── list_customizable_skills.py
```

A workflow step calls it:
```markdown
## ACTION

Run discovery script:
```bash
python3 {skill-root}/scripts/list_customizable_skills.py --project-root {project-root}
```

Parse JSON output for next step.
```

---

## 7. Canonical example 1: bmad-brainstorming (micro-file)

The canonical skill for **micro-file architecture**.

### 7.1 Structure

```
bmad-brainstorming/
├── SKILL.md                       (7 lines)
├── workflow.md                    (55 lines)
├── template.md                    (session output template)
├── brain-methods.csv              (30+ brainstorming techniques)
└── steps/
    ├── step-01-session-setup.md
    ├── step-01b-continue.md       (continuation variant)
    ├── step-02a-user-selected.md  (branch: user picks technique)
    ├── step-02b-ai-recommended.md (branch: AI recommends)
    ├── step-02c-random-selection.md (branch: random)
    ├── step-02d-progressive-flow.md (branch: progressive)
    ├── step-03-technique-execution.md
    └── step-04-idea-organization.md
```

### 7.2 SKILL.md

```yaml
---
name: bmad-brainstorming
description: 'Facilitate interactive brainstorming sessions using diverse creative techniques and ideation methods. Use when the user says help me brainstorm or help me ideate.'
---

Follow the instructions in ./workflow.md.
```

### 7.3 workflow.md snippet

```markdown
---
context_file: ''
---

# Brainstorming Session Workflow

**Goal:** Facilitate interactive brainstorming sessions using diverse creative techniques

**Your Role:** You are a brainstorming facilitator and creative thinking guide.
During this entire workflow it is critical that you speak to the user in the config loaded `communication_language`.

**Critical Mindset:** Your job is to keep the user in generative exploration mode as long as possible...

**Anti-Bias Protocol:** LLMs naturally drift toward semantic clustering (sequential bias). 
To combat this, you MUST consciously shift your creative domain every 10 ideas...

**Quantity Goal:** Aim for 100+ ideas before any organization.

---

## WORKFLOW ARCHITECTURE

This uses **micro-file architecture** for disciplined execution:
- Each step is a self-contained file with embedded rules
- Sequential progression with user control at each step
- Document state tracked in frontmatter
- Append-only document building through conversation
- Brain techniques loaded on-demand from CSV

---

## INITIALIZATION

### Configuration Loading
Load config from `{project-root}/_bmad/core/config.yaml` and resolve:
- `project_name`, `output_folder`, `user_name`
- `communication_language`, `document_output_language`, `user_skill_level`
- `date` as system-generated current datetime

### Paths
- `brainstorming_session_output_file` = `{output_folder}/brainstorming/brainstorming-session-{{date}}-{{time}}.md`

All steps MUST reference `{brainstorming_session_output_file}` instead of the full path pattern.

---

## EXECUTION

Read fully and follow: `./steps/step-01-session-setup.md` to begin the workflow.
```

### 7.4 Flow logic

```
step-01-session-setup       ← user enters → check continuation?
      ↓                         ↓
      ↓                    step-01b-continue
      ↓
Choose approach:
      ↓
┌─────┼─────┬─────┬─────┐
↓     ↓     ↓     ↓     ↓
02a   02b   02c   02d   (4 branches)
user  AI    rand  prog
pick  rec   om    ress
      ↓
      ↓ (all converge)
step-03-technique-execution   ← run techniques, collect ideas
      ↓
step-04-idea-organization     ← group, prioritize, finalize output
```

### 7.5 Takeaways

- **Micro-files for clear branches** — the 4 branches at step 02 are 4 separate files
- **Continuation pattern** — step-01b enables resuming a session
- **External data file** — `brain-methods.csv` loaded on demand
- **Anti-bias made explicit** — written as a clear protocol in the workflow

---

## 8. Canonical example 2: bmad-dev-story (XML workflow)

The canonical skill for the **XML workflow pattern**. The logic is complex (branching, loops, validation gates).

### 8.1 Structure

```
bmad-dev-story/
├── SKILL.md       (7 lines)
├── workflow.md    (~450 lines — ALL inline XML logic)
└── checklist.md   (definition of done)
```

No `steps/` folder — everything is inside `workflow.md`.

### 8.2 workflow.md - XML structure

```xml
<workflow>
  <critical>Communicate all responses in {communication_language}</critical>
  <critical>Generate all documents in {document_output_language}</critical>
  <critical>Only modify the story file in these areas: Tasks/Subtasks...</critical>
  <critical>Execute ALL steps in exact order; do NOT skip steps</critical>
  <critical>Absolutely DO NOT stop because of "milestones"... Continue in a single execution until the story is COMPLETE</critical>
  
  <step n="1" goal="Find next ready story and load it" tag="sprint-status">
    <check if="{{story_path}} is provided">
      <action>Use {{story_path}} directly</action>
      <action>Read COMPLETE story file</action>
      <goto anchor="task_check" />
    </check>
    
    <check if="{{sprint_status}} file exists">
      <action>Load the FULL file: {{sprint_status}}</action>
      <action>Find the FIRST story where status equals "ready-for-dev"</action>
      
      <check if="no ready-for-dev story found">
        <output>📋 No ready-for-dev stories found
          1. Run `create-story` to create next story
          2. Run `*validate-create-story` to improve existing stories
          3. Specify a particular story file
        </output>
        <ask>Choose option [1], [2], [3], or [4]:</ask>
        <!-- ... handling each choice -->
      </check>
    </check>
    
    <anchor id="task_check" />
    
    <action>Parse sections: Story, Acceptance Criteria, Tasks/Subtasks, Dev Notes, ...</action>
    <action>Identify first incomplete task (unchecked [ ]) in Tasks/Subtasks</action>
    
    <action if="no incomplete tasks">
      <goto step="6">Completion sequence</goto>
    </action>
  </step>
  
  <step n="2" goal="Load project context and story information">
    ...
  </step>
  
  <step n="3" goal="Detect review continuation and extract review context">
    <action>Check if "Senior Developer Review (AI)" section exists</action>
    <check if="Senior Developer Review section exists">
      <action>Set review_continuation = true</action>
      ...
    </check>
  </step>
  
  <step n="4" goal="Mark story in-progress" tag="sprint-status">
    ...
  </step>
  
  <step n="5" goal="Implement task following red-green-refactor cycle">
    <critical>FOLLOW THE STORY FILE TASKS/SUBTASKS SEQUENCE EXACTLY</critical>
    
    <!-- RED PHASE -->
    <action>Write FAILING tests first</action>
    <action>Confirm tests fail before implementation</action>
    
    <!-- GREEN PHASE -->
    <action>Implement MINIMAL code to make tests pass</action>
    <action>Run tests to confirm they now pass</action>
    
    <!-- REFACTOR PHASE -->
    <action>Improve code structure while keeping tests green</action>
    
    <action if="3 consecutive implementation failures occur">HALT and request guidance</action>
    
    <critical>NEVER implement anything not mapped to a specific task</critical>
    <critical>NEVER proceed to next task until current task is complete AND tests pass</critical>
  </step>
  
  <step n="6" goal="Author comprehensive tests">...</step>
  <step n="7" goal="Run validations and tests">...</step>
  
  <step n="8" goal="Validate and mark task complete ONLY when fully done">
    <critical>NEVER mark a task complete unless ALL conditions are met - NO LYING OR CHEATING</critical>
    
    <action>Verify ALL tests ACTUALLY EXIST and PASS 100%</action>
    <action>Confirm implementation matches EXACTLY what task specifies</action>
    <action>Validate ALL acceptance criteria are satisfied</action>
    <action>Run full test suite to ensure NO regressions</action>
    
    <check if="ALL validation gates pass">
      <action>ONLY THEN mark the task checkbox with [x]</action>
      <action>Update File List section</action>
      <action>Add completion notes to Dev Agent Record</action>
    </check>
    
    <check if="ANY validation fails">
      <action>DO NOT mark task complete - fix issues first</action>
      <action>HALT if unable to fix validation failures</action>
    </check>
    
    <action if="more tasks remain">
      <goto step="5">Next task</goto>
    </action>
    <action if="no tasks remain">
      <goto step="9">Completion</goto>
    </action>
  </step>
  
  <step n="9" goal="Story completion and mark for review" tag="sprint-status">
    <action>Verify ALL tasks and subtasks are marked [x]</action>
    <action>Run the full regression suite</action>
    <action>Update story Status to: "review"</action>
    ...
  </step>
  
  <step n="10" goal="Completion communication and user support">
    ...
  </step>
</workflow>
```

### 8.3 Takeaways

- **10 inline XML steps** — no steps/ folder used
- **Critical rules up front** — the AI must obey
- **Anchor + goto** — jumping between steps (step 1 has anchor "task_check")
- **Nested check** — a conditional inside a conditional
- **Multi-layer validation gate** — step 8 wraps mark-complete in several `<check>` blocks
- **Loop** — step 5 ↔ step 8, run per task
- **Red-green-refactor** encoded in step 5
- **Tag attribute** — `tag="sprint-status"` for steps that touch sprint tracking

---

## 9. Canonical example 3: bmad-agent-pm (agent-skill)

The canonical skill for the **agent persona** pattern.

### 9.1 Structure

```
bmad-agent-pm/
├── SKILL.md           (agent activation logic)
├── workflow.md        (agent activation workflow)
├── customize.toml     (persona + menu)
└── steps/             (optional, for the activation flow)
```

### 9.2 customize.toml

```toml
[agent]
name = "John"
title = "Product Manager"
icon = "📋"
role = "Product manager driving PRD creation through user interviews + requirements discovery + stakeholder alignment."
identity = "Drives Jobs-to-be-Done over template filling, user value first, technical feasibility is a constraint not the driver."
communication_style = "Detective interrogating a cold case: short questions, sharper follow-ups, every 'why?' tightening the net."

principles = [
  "User value first. Every feature has a job-to-be-done.",
  "Start with user interviews, not templates.",
  "Ruthlessly prioritize. Cut what doesn't move the needle.",
  "Technical feasibility is a constraint, not the driver.",
]

persistent_facts = [
  "file:{project-root}/**/project-context.md",
]

activation_steps_prepend = []
activation_steps_append = [
  "If planning_artifacts has existing PRD, offer to validate or edit instead of create.",
]

# Menu: shortcuts user can type
[[agent.menu]]
code = "CP"
description = "Create a new PRD from scratch"
skill = "bmad-create-prd"

[[agent.menu]]
code = "EP"
description = "Edit existing PRD"
skill = "bmad-edit-prd"

[[agent.menu]]
code = "VP"
description = "Validate PRD against BMAD standards"
skill = "bmad-validate-prd"

[[agent.menu]]
code = "BD"
description = "Discuss product brief with Mary first"
prompt = "Switch to Mary (Analyst) to work on product brief before PRD."

[[agent.menu]]
code = "EX"
description = "Exit back to main menu"
prompt = "Returning to main BMad interface."
```

### 9.3 Agent activation flow

When the user invokes the agent via the slash command `/bmad-agent-pm`:

```
1. Load customize.toml (3-level merge: default + team + user)
2. Execute activation_steps_prepend (if any)
3. Adopt persona:
   - name, title, icon → prefix messages
   - role, identity → identity shaping
   - communication_style → how to speak
   - principles → internal values
4. Load persistent_facts:
   - Expand file: globs
   - Load matching files
   - Treat as "always-true" knowledge
5. Load config:
   - user_name, communication_language, etc.
   - Switch language if needed
6. Greet user:
   - Use icon prefix: "📋 Hello Alice! I'm John, your PM..."
   - Speak in communication_language
7. Execute activation_steps_append (if any)
8. Dispatch:
   - If user intent is clear → invoke the matching skill directly
   - Else → render the menu
```

### 9.4 Menu rendering

```
📋 Hello Alice! I'm John, your Product Manager.

What would you like to do?

  [CP] Create a new PRD from scratch
  [EP] Edit existing PRD
  [VP] Validate PRD against BMAD standards
  [BD] Discuss product brief with Mary first
  [EX] Exit back to main menu

Type the code or describe what you need:
```

User types `CP` → invokes the `bmad-create-prd` skill.
User types `BD` → executes the prompt (switch to Mary).

### 9.5 Takeaways

- **Agent = a skill with a customize.toml containing an [agent] block**
- **4-field persona**: role, identity, communication_style, principles
- **Menu = shortcuts** — short codes for quick user input
- **Menu items have either skill or prompt** (never both)
- **persistent_facts** injects context for the whole session
- **activation_steps_** are prepend/append hooks

---

## 10. Skill validation rules reference

### 10.1 Rule groups

| Group | Total | Deterministic | Inference |
|------|---------|---------------|-----------|
| SKILL-* | 7 | 7 | 0 |
| WF-* | 3 | 2 | 1 |
| PATH-* | 5 | 1 | 4 |
| STEP-* | 7 | 3 | 4 |
| SEQ-* | 2 | 1 | 1 |
| REF-* | 3 | 0 | 3 |
| **Total** | **27** | **14** | **13** |

### 10.2 Quick reference table

| Rule | Severity | Rule |
|------|----------|------|
| SKILL-01 | CRITICAL | SKILL.md must exist |
| SKILL-02 | CRITICAL | SKILL.md frontmatter must have `name` |
| SKILL-03 | CRITICAL | SKILL.md frontmatter must have `description` |
| SKILL-04 | HIGH | `name` format: `^bmad-[a-z0-9]+(-[a-z0-9]+)*$` |
| SKILL-05 | HIGH | `name` must match the directory name |
| SKILL-06 | MEDIUM | `description` quality: max 1024 chars, contains "Use when" |
| SKILL-07 | HIGH | SKILL.md must have a body |
| WF-01 | HIGH | Only SKILL.md may have `name` in frontmatter |
| WF-02 | HIGH | Only SKILL.md may have `description` in frontmatter |
| WF-03 | HIGH | workflow.md frontmatter vars must be config/runtime only |
| PATH-01 | HIGH | Internal references must be relative |
| PATH-02 | HIGH | Do not use the `{installed_path}` variable |
| PATH-03 | HIGH | External references must use config variables |
| PATH-04 | MEDIUM | No intra-skill path variables |
| PATH-05 | CRITICAL | Do not reach into another skill's folder |
| STEP-01 | HIGH | Step filename format: `step-NN[-variant]-description.md` |
| STEP-02 | HIGH | Step must have a goal section |
| STEP-03 | HIGH | Step must reference the next step (except the final one) |
| STEP-04 | HIGH | Menu steps must HALT & wait for input |
| STEP-05 | HIGH | No forward loading |
| STEP-06 | HIGH | Step frontmatter must not have `name`/`description` |
| STEP-07 | HIGH | Workflow should have 2-10 steps |
| SEQ-01 | HIGH | "Invoke the `skill-name`" (not "execute", "run") |
| SEQ-02 | MEDIUM | Do not estimate time (like "~5 minutes") |
| REF-01 | HIGH | Variables must be defined |
| REF-02 | HIGH | File references must resolve |
| REF-03 | HIGH | Skill invocation must use "invoke" language |

### 10.3 Running the validator

```bash
# Everything
npm run validate:skills

# A single skill
node tools/validate-skills.js src/core-skills/bmad-brainstorming

# JSON output
node tools/validate-skills.js --json > findings.json

# Strict mode (exit 1 if HIGH+ findings)
node tools/validate-skills.js --strict
```

---

## Summary

A BMad skill has:
1. **SKILL.md** — frontmatter (name, description) + body redirecting to the workflow
2. **workflow.md** — the main logic, INITIALIZATION + EXECUTION
3. **steps/** — micro-files if the logic is complex (or inline XML)
4. **customize.toml** — if it's an agent persona
5. **template.md, checklist.md, resources/, agents/, scripts/** — sub-files as needed

3 canonical patterns:
- **Micro-file** (`bmad-brainstorming`) — many clear branches
- **XML workflow** (`bmad-dev-story`) — complex logic, validation gates
- **Agent persona** (`bmad-agent-pm`) — customize.toml with an [agent] block

27 validation rules, 14 deterministic + 13 inference.

---

**Read next:** [04-skills-catalog.md](04-skills-catalog.md) — a detailed catalog of the 39 skills.
