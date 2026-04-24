# 03. Skill Anatomy - Đặc tả sâu

> ⚠️ **UNOFFICIAL THIRD-PARTY DOCUMENTATION**
> Không phải official BMad docs. Xem [DISCLAIMER.md](DISCLAIMER.md) | Licensed MIT — xem [LICENSE](LICENSE) và [NOTICE](NOTICE)
> Official BMAD-METHOD: <https://github.com/bmad-code-org/BMAD-METHOD>

---

> Deep dive vào **anatomy của một skill**: SKILL.md, workflow.md, steps/, sub-files, syntax XML mở rộng, canonical examples (`bmad-brainstorming`, `bmad-dev-story`, `bmad-create-prd`).

---

## Mục lục

1. [Cấu trúc directory chuẩn](#1-cấu-trúc-directory-chuẩn)
2. [SKILL.md - L1 metadata](#2-skillmd---l1-metadata)
3. [workflow.md - logic chính](#3-workflowmd---logic-chính)
4. [steps/ - micro-file architecture](#4-steps---micro-file-architecture)
5. [XML workflow syntax (cho step logic)](#5-xml-workflow-syntax-cho-step-logic)
6. [Sub-files: template, checklist, resources, agents](#6-sub-files-template-checklist-resources-agents)
7. [Canonical example 1: bmad-brainstorming](#7-canonical-example-1-bmad-brainstorming-micro-file)
8. [Canonical example 2: bmad-dev-story](#8-canonical-example-2-bmad-dev-story-xml-workflow)
9. [Canonical example 3: bmad-agent-pm](#9-canonical-example-3-bmad-agent-pm-agent-skill)
10. [Skill validation rules reference](#10-skill-validation-rules-reference)

---

## 1. Cấu trúc directory chuẩn

```
bmad-my-skill/
├── SKILL.md                  # L1 metadata (BẮT BUỘC)
├── workflow.md               # Logic chính (BẮT BUỘC nếu skill có workflow)
├── customize.toml            # Agent persona hoặc workflow hooks (nếu là agent-skill)
├── template.md               # Template output (optional)
├── checklist.md              # Checklist validation (optional)
├── steps/                    # Micro-file architecture (optional, nếu dùng pattern này)
│   ├── step-01-init.md
│   ├── step-02a-branch-a.md
│   ├── step-02b-branch-b.md
│   └── step-03-finalize.md
├── resources/                # Reference docs LLM cần load (optional)
│   ├── compression-rules.md
│   └── format-reference.md
├── agents/                   # Sub-agent prompts (optional, cho skill complex)
│   ├── sub-agent-a.md
│   └── sub-agent-b.md
├── scripts/                  # Helper scripts (optional)
│   └── helper.py
└── *.csv, *.yaml             # Data files (optional, như brain-methods.csv)
```

### 1.1 Required vs Optional

| File | Required | Ghi chú |
|------|----------|---------|
| `SKILL.md` | ✅ **BẮT BUỘC** | Entry point, frontmatter có `name` + `description` |
| `workflow.md` | ⚠️ Hầu như luôn | Trừ skill simple như review — có thể chỉ vào workflow.md hoặc inline trong SKILL.md |
| `customize.toml` | Tùy | Agent-skill BẮT BUỘC có. Workflow-skill có thể có để customize hooks |
| `template.md` | Tùy | Nếu output có format cố định |
| `steps/` | Tùy | Nếu workflow phức tạp > 2 phases |
| `resources/` | Tùy | Reference docs cho LLM |
| `agents/` | Tùy | Sub-agent prompts (dùng Agent tool) |
| `scripts/` | Tùy | Python/Node helper |

### 1.2 Naming conventions

- **Directory name** = `bmad-*` format, regex `^bmad-[a-z0-9]+(-[a-z0-9]+)*$`
- **Step files** = `step-NN[-variant]-description.md` (NN zero-padded)
- **Agent persona skill** = `bmad-agent-<role>` (e.g., `bmad-agent-pm`)
- **Uppercase** chỉ dùng cho: `SKILL.md`, `CSV.md`, acronyms

---

## 2. SKILL.md - L1 metadata

### 2.1 Frontmatter (BẮT BUỘC)

```yaml
---
name: bmad-my-skill
description: 'Does X using Y technique. Use when the user says "do X" or asks for Y.'
---
```

**Quy tắc:**

| Field | Bắt buộc | Rule | Validator |
|-------|---------|------|-----------|
| `name` | ✅ | Match regex `^bmad-[a-z0-9]+(-[a-z0-9]+)*$`, **match tên directory** | SKILL-02, SKILL-04, SKILL-05 |
| `description` | ✅ | Max 1024 chars, phải chứa **"what"** + **"when to use"** (trigger phrases như "Use when", "Use if") | SKILL-03, SKILL-06 |

### 2.2 Body

SKILL.md body là **L2 instructions**. Có 2 pattern:

**Pattern A: Skill có workflow.md (phổ biến nhất)**

```markdown
---
name: bmad-my-skill
description: '...'
---

Follow the instructions in ./workflow.md.
```

Body cực ngắn — chỉ redirect sang workflow.md.

**Pattern B: Skill inline (cho skill đơn giản)**

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

Body chứa luôn logic. Dùng khi skill có <100 dòng logic.

### 2.3 SKILL-07: Body không được trống

Nếu chỉ có frontmatter mà không có body → validation fail (SKILL-07).

---

## 3. workflow.md - logic chính

### 3.1 Frontmatter

```yaml
---
context_file: ''              # Optional runtime variable
spec_file: ''
story_path: ''
---
```

**Quy tắc WF-01, WF-02:**
- KHÔNG được có `name:`
- KHÔNG được có `description:`

Đây là runtime variable declarations. Empty string = chưa có giá trị, sẽ fill khi execute.

**WF-03:** Values phải là:
- Config variable reference `{planning_artifacts}`
- Empty/placeholder
- Legitimate external path
- **KHÔNG** được là path vào skill khác (PATH-05)

### 3.2 Body structure

```markdown
# [Skill Name] Workflow

**Goal:** [1-2 câu mô tả mục tiêu]

**Your Role:** [Persona AI đóng khi chạy skill này]

**Critical Mindset:** [Nếu cần — ví dụ anti-bias protocol]

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

[HOẶC inline XML workflow cho skill đơn giản]
```

### 3.3 Các section "architecture sections" (optional)

Một số workflow.md có thêm:

```markdown
## WORKFLOW ARCHITECTURE

This uses **micro-file architecture** for disciplined execution:
- Each step is a self-contained file with embedded rules
- Sequential progression with user control at each step
- Document state tracked in frontmatter
- Append-only document building through conversation
- Brain techniques loaded on-demand from CSV
```

Giải thích cho LLM hiểu pattern skill.

### 3.4 Paths declaration

**Paths section** là nơi declare output file paths, dùng config variables:

```markdown
## Paths
- `brainstorming_session_output_file` = `{output_folder}/brainstorming/brainstorming-session-{{date}}-{{time}}.md`
- `sprint_status` = `{implementation_artifacts}/sprint-status.yaml`

All steps MUST reference `{brainstorming_session_output_file}` instead of the full path pattern.
```

**Lưu ý syntax:**
- `{config_var}` single curly — resolved by config merger
- `{{runtime_macro}}` double curly — resolved at runtime by workflow engine

### 3.5 EXECUTION section

Cách trỏ sang step đầu tiên:

```markdown
## EXECUTION

Read fully and follow: `./steps/step-01-session-setup.md` to begin the workflow.
```

**Ngôn từ quan trọng:** "Read fully and follow" — không phải "execute" hoặc "invoke" (intra-skill, không phải cross-skill).

---

## 4. steps/ - micro-file architecture

### 4.1 Nguyên tắc micro-file

- **Mỗi step = 1 file**, ~2-5KB
- **Self-contained** — load một file là có đủ context cho step đó
- **Sequential** — không nhảy cóc, phải follow NEXT
- **No forward-loading** — không đọc future step sớm
- **Tổng 2-10 steps** (STEP-07)

### 4.2 Step file anatomy

```markdown
# Step NN: [Step Name]

## YOUR TASK
[Goal section — BẮT BUỘC, STEP-02]
Rõ ràng mục tiêu của step này.

## CONTEXT
[Optional — context needed]

## ACTION
[Instructions chi tiết]

1. Làm việc A
2. Làm việc B
3. ...

### Sub-section 1
Detail...

### Sub-section 2
Detail...

## HALT CONDITIONS
[Optional — khi nào dừng]
- If user input missing → HALT: "Please provide..."
- If file not found → HALT: "Cannot proceed without..."

## NEXT
Read fully and follow: `./step-02-execute.md`
```

### 4.3 Step naming

**Format:** `step-NN[-variant]-description.md`

- `NN` = 2-digit zero-padded (01, 02, 10, 99)
- `variant` = lowercase letter cho branching (02a, 02b, 02c)
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

Step `01` có thể trỏ tới 1 trong nhiều nhánh:

```markdown
## NEXT

Based on user choice:
- If user selects [1] → Read fully and follow: `./step-02a-user-selected.md`
- If user selects [2] → Read fully and follow: `./step-02b-ai-recommended.md`
- If user selects [3] → Read fully and follow: `./step-02c-random-selection.md`
- If user selects [4] → Read fully and follow: `./step-02d-progressive-flow.md`
```

Mỗi nhánh là 1 file. LLM chỉ load file tương ứng với user choice.

### 4.5 Frontmatter trong step files

**Quy tắc STEP-06:**
- KHÔNG được có `name:`
- KHÔNG được có `description:`

Step files thường không có frontmatter (chỉ body). Nếu có thì chỉ runtime variables.

### 4.6 HALT pattern

```markdown
## HALT CONDITIONS

- **Missing required input**: HALT and ask user for {{spec_file}}
- **Validation fails**: HALT with error message, explain what's wrong
- **3 consecutive failures**: HALT and request guidance
- **Ambiguity detected**: HALT, ask user to clarify
```

HALT = AI dừng lại, đợi user input. Không tự tiếp tục.

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

Hoặc inline trong step body. Goto cho phép loop (Ví dụ step 5 → 5 → 5 → 9 khi hết task).

---

## 5. XML workflow syntax (cho step logic)

BMad có một **mini DSL** dùng XML tags trong workflow/steps. Dùng khi logic phức tạp hơn markdown thuần.

### 5.1 Core tags

```xml
<workflow>
  <critical>CRITICAL RULE đặt đầu tiên — AI phải tuân thủ tuyệt đối</critical>
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

| Tag | Dùng để |
|-----|---------|
| `<workflow>` | Root của workflow inline |
| `<step n="N" goal="..." tag="...">` | Define step (thay cho file riêng) |
| `<critical>` | Rule quan trọng AI phải tuân |
| `<action>` | Instruction — AI làm gì |
| `<action if="condition">` | Conditional action |
| `<check if="condition">...</check>` | Conditional block |
| `<ask>...</ask>` | Prompt user, HALT đợi response |
| `<output>...</output>` | Hiển thị message cho user |
| `<goto step="N">` hoặc `<goto anchor="name">` | Jump tới step/anchor |
| `<anchor id="name" />` | Đích jump trong step |
| `<!-- comment -->` | HTML comment |

### 5.4 Patterns điển hình

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

**Pattern: loop với goto**
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

### 5.5 Khi nào dùng XML vs Markdown thuần

| Tình huống | Dùng |
|-----------|------|
| Step đơn giản, tuần tự | Markdown |
| Nhiều điều kiện if/else | XML tags |
| Loop (goto) | XML tags |
| Critical rules cần nhấn mạnh | XML `<critical>` |
| Cần HALT với prompt | XML `<ask>` |
| Decision tree phức tạp | XML tags |

Framework khuyến nghị: **đơn giản trước**. Chỉ dùng XML khi markdown không đủ biểu đạt.

---

## 6. Sub-files: template, checklist, resources, agents

### 6.1 template.md

Template output file, dùng khi skill sinh ra file có format cố định.

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

Step file sẽ:
1. Load template
2. Fill placeholders với runtime values
3. Write ra output file

### 6.2 checklist.md

Checklist validation hoặc checklist analysis:

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

Dùng trong `bmad-correct-course`, `bmad-check-implementation-readiness`.

### 6.3 resources/

Reference docs LLM load khi cần context sâu.

```
bmad-distillator/
└── resources/
    ├── compression-rules.md        # Quy tắc nén
    ├── distillate-format-reference.md  # Format chuẩn
    └── splitting-strategy.md       # Khi nào split
```

Step file reference:
```markdown
## ACTION

Read fully and follow the compression rules:
`./resources/compression-rules.md`

Apply the format from:
`./resources/distillate-format-reference.md`
```

### 6.4 agents/

Sub-agent prompts. Dùng khi skill complex cần spawn child agent qua Agent tool.

```
bmad-distillator/
└── agents/
    ├── distillate-compressor.md          # Sub-agent: nén nội dung
    └── round-trip-reconstructor.md       # Sub-agent: verify roundtrip
```

Mỗi file là **full prompt** cho sub-agent. Workflow step invoke:

```markdown
## ACTION

Spawn sub-agent via Agent tool:
- Prompt: Read fully and apply `./agents/distillate-compressor.md`
- Pass: source_file, target_file, compression_ratio
```

Party-mode (`bmad-party-mode`) dùng pattern này để spawn nhiều agent đồng thời.

### 6.5 scripts/

Python/Node helper scripts cho việc cần deterministic logic:

```
bmad-customize/
└── scripts/
    └── list_customizable_skills.py
```

Workflow step call:
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

Skill canonical cho **micro-file architecture**.

### 7.1 Structure

```
bmad-brainstorming/
├── SKILL.md                       (7 dòng)
├── workflow.md                    (55 dòng)
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
step-01-session-setup       ← user vào → check continuation?
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

### 7.5 Điểm học được

- **Micro-file cho nhánh rõ ràng** — 4 branches tại step 02 là 4 file riêng
- **Continuation pattern** — step-01b cho phép resume session
- **External data file** — `brain-methods.csv` load theo demand
- **Anti-bias explicit** — viết thành protocol rõ ràng trong workflow

---

## 8. Canonical example 2: bmad-dev-story (XML workflow)

Skill canonical cho **XML workflow pattern**. Logic phức tạp (branching, loops, validation gates).

### 8.1 Structure

```
bmad-dev-story/
├── SKILL.md       (7 dòng)
├── workflow.md    (~450 dòng — TOÀN BỘ logic inline XML)
└── checklist.md   (definition of done)
```

Không có `steps/` folder — tất cả trong `workflow.md`.

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

### 8.3 Điểm học được

- **10 steps inline XML** — không dùng steps/ folder
- **Critical rules** lập đầu — AI phải tuân
- **Anchor + goto** — jump giữa steps (step 1 anchor "task_check")
- **Nested check** — conditional bên trong conditional
- **Validation gate nhiều tầng** — step 8 có nhiều `<check>` bọc hành động mark-complete
- **Loop** — step 5 ↔ step 8, chạy cho từng task
- **Red-green-refactor** encoded trong step 5
- **Tag attribute** — `tag="sprint-status"` cho step liên quan sprint tracking

---

## 9. Canonical example 3: bmad-agent-pm (agent-skill)

Skill canonical cho **agent persona** pattern.

### 9.1 Structure

```
bmad-agent-pm/
├── SKILL.md           (agent activation logic)
├── workflow.md        (agent activation workflow)
├── customize.toml     (persona + menu)
└── steps/             (optional, cho activation flow)
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

Khi user gọi agent qua slash command `/bmad-agent-pm`:

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
   - If user intent clear → invoke matching skill directly
   - Else → render menu
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

User gõ `CP` → invoke `bmad-create-prd` skill.
User gõ `BD` → execute the prompt (switch to Mary).

### 9.5 Điểm học được

- **Agent = skill có customize.toml với [agent] block**
- **Persona 4-field**: role, identity, communication_style, principles
- **Menu = shortcuts** — code ngắn gọn cho user nhanh
- **Menu item có skill hoặc prompt** (không cả hai)
- **persistent_facts** inject context suốt session
- **activation_steps_** là hooks prepend/append

---

## 10. Skill validation rules reference

### 10.1 Nhóm rules

| Nhóm | Tổng số | Deterministic | Inference |
|------|---------|---------------|-----------|
| SKILL-* | 7 | 7 | 0 |
| WF-* | 3 | 2 | 1 |
| PATH-* | 5 | 1 | 4 |
| STEP-* | 7 | 3 | 4 |
| SEQ-* | 2 | 1 | 1 |
| REF-* | 3 | 0 | 3 |
| **Tổng** | **27** | **14** | **13** |

### 10.2 Bảng quick reference

| Rule | Severity | Rule |
|------|----------|------|
| SKILL-01 | CRITICAL | SKILL.md must exist |
| SKILL-02 | CRITICAL | SKILL.md frontmatter must have `name` |
| SKILL-03 | CRITICAL | SKILL.md frontmatter must have `description` |
| SKILL-04 | HIGH | `name` format: `^bmad-[a-z0-9]+(-[a-z0-9]+)*$` |
| SKILL-05 | HIGH | `name` must match directory name |
| SKILL-06 | MEDIUM | `description` quality: max 1024 chars, có "Use when" |
| SKILL-07 | HIGH | SKILL.md phải có body |
| WF-01 | HIGH | Only SKILL.md may have `name` in frontmatter |
| WF-02 | HIGH | Only SKILL.md may have `description` in frontmatter |
| WF-03 | HIGH | workflow.md frontmatter vars phải là config/runtime only |
| PATH-01 | HIGH | Internal references phải relative |
| PATH-02 | HIGH | Không dùng `{installed_path}` variable |
| PATH-03 | HIGH | External references phải dùng config variables |
| PATH-04 | MEDIUM | Không intra-skill path variables |
| PATH-05 | CRITICAL | Không reach vào folder skill khác |
| STEP-01 | HIGH | Step filename format: `step-NN[-variant]-description.md` |
| STEP-02 | HIGH | Step phải có goal section |
| STEP-03 | HIGH | Step phải reference next step (trừ final) |
| STEP-04 | HIGH | Menu steps phải HALT & wait input |
| STEP-05 | HIGH | No forward loading |
| STEP-06 | HIGH | Step frontmatter không có `name`/`description` |
| STEP-07 | HIGH | Workflow nên 2-10 steps |
| SEQ-01 | HIGH | "Invoke the `skill-name`" (không "execute", "run") |
| SEQ-02 | MEDIUM | Không estimate thời gian (như "~5 minutes") |
| REF-01 | HIGH | Variables phải defined |
| REF-02 | HIGH | File references phải resolve |
| REF-03 | HIGH | Skill invocation phải dùng "invoke" language |

### 10.3 Chạy validator

```bash
# Toàn bộ
npm run validate:skills

# 1 skill
node tools/validate-skills.js src/core-skills/bmad-brainstorming

# JSON output
node tools/validate-skills.js --json > findings.json

# Strict mode (exit 1 if HIGH+ findings)
node tools/validate-skills.js --strict
```

---

## Tóm lược

Một skill BMad có:
1. **SKILL.md** — frontmatter (name, description) + body redirect tới workflow
2. **workflow.md** — Logic chính, INITIALIZATION + EXECUTION
3. **steps/** — Micro-files nếu logic phức tạp (hoặc XML inline)
4. **customize.toml** — Nếu là agent persona
5. **template.md, checklist.md, resources/, agents/, scripts/** — Sub-files tùy nhu cầu

3 canonical patterns:
- **Micro-file** (`bmad-brainstorming`) — nhiều branches rõ ràng
- **XML workflow** (`bmad-dev-story`) — logic phức tạp, validation gates
- **Agent persona** (`bmad-agent-pm`) — customize.toml với [agent] block

27 validation rules, 14 deterministic + 13 inference.

---

**Đọc tiếp:** [04-skills-catalog.md](04-skills-catalog.md) — Catalog chi tiết 39 skills.
