# 15. Glossary - Thuật ngữ BMAD-METHOD

> ⚠️ **UNOFFICIAL THIRD-PARTY DOCUMENTATION**
> Không phải official BMad docs. Xem [DISCLAIMER.md](DISCLAIMER.md) | Licensed MIT — xem [LICENSE](LICENSE) và [NOTICE](NOTICE)
> Official BMAD-METHOD: <https://github.com/bmad-code-org/BMAD-METHOD>

---

> Từ điển tập trung các thuật ngữ BMad-specific. Quy ước tiếng Việt-Anh. Dùng khi đọc tài liệu gặp term không rõ.

---

## Mục lục

- [A. Core concepts](#a-core-concepts)
- [B. Architecture terms](#b-architecture-terms)
- [C. Variables & config](#c-variables--config)
- [D. Workflow terms](#d-workflow-terms)
- [E. Validation rules](#e-validation-rules)
- [F. File types & artifacts](#f-file-types--artifacts)
- [G. Agent personas](#g-agent-personas)
- [H. Tiếng Việt - tiếng Anh mapping](#h-tiếng-việt---tiếng-anh-mapping)

---

## A. Core concepts

| Term | Định nghĩa | File chi tiết |
|------|-----------|---------------|
| **Agent** | Persona (nhân vật) với tên, icon, communication style, và menu các skill. Ví dụ: Mary (Analyst 📊), John (PM 📋) | [03 §9](03-skill-anatomy-deep.md), [09b §1-1](09b-skills-phase1-2-deep.md) |
| **Skill** | Đơn vị công việc tự chứa. Thư mục chứa `SKILL.md` (bắt buộc), optional `workflow.md`, `steps/`, `customize.toml`. Tên luôn prefix `bmad-*` | [03](03-skill-anatomy-deep.md) |
| **Module** | Gói skills + agents + config. Được define bằng `module.yaml`. Built-in: `core`, `bmm`. External: `tea`, `bmb`... | [02 §2](02-environment-and-variables.md) |
| **Workflow** | Logic trong `workflow.md` của một skill. Có thể dùng micro-file architecture (steps/) hoặc XML inline | [03 §3](03-skill-anatomy-deep.md) |
| **Step** | Micro-file trong `steps/` folder, ~2-5KB. Sequential, no-forward-loading | [03 §4](03-skill-anatomy-deep.md) |
| **Artifact** | File output của một phase: PRD, Architecture, Stories, etc. Stored in `{planning_artifacts}` hoặc `{implementation_artifacts}` | [01 §3.3](01-philosophy.md) |
| **Invoke** | Cách skill gọi skill khác (qua agent menu hoặc "Invoke the `skill-name` skill" text). KHÔNG đọc file trực tiếp | [03 §10](03-skill-anatomy-deep.md) |

---

## B. Architecture terms

| Term | Định nghĩa |
|------|-----------|
| **Micro-file architecture** | Pattern tách workflow thành nhiều step files ~2-5KB, load just-in-time. Ngược với monolithic workflow file. |
| **Filesystem as truth** | Nguyên lý: mọi state lưu trong file, không DB/runtime. Git-native, portable, debuggable |
| **Declarative > Imperative** | Workflow viết Markdown/YAML/TOML, không code. LLM đọc và follow |
| **Document-as-interface** | Các phase giao tiếp qua file output, không qua memory/API |
| **Encapsulated skills** | Skill không được đọc file skill khác (PATH-05). Chỉ invoke |
| **Human-in-the-loop** | AI HALT tại checkpoint quan trọng, đợi user input |
| **4-phase lifecycle** | Analysis → Planning → Solutioning → Implementation |
| **Sprint tracking** | Sprint state lưu trong `sprint-status.yaml` (file-based, không Jira) |
| **Party mode** | Multi-agent collaboration qua real subagents (Agent tool) |
| **RED-GREEN-REFACTOR** | TDD cycle của dev-story: failing tests → minimal code → improve |
| **8-level validation gate** | Checklist dev-story step 8 before marking task complete |
| **Capture-don't-interrupt** | Pattern trong product-brief: capture out-of-scope details silently, không derail |
| **Adversarial review** | Review mindset: assume bugs exist, find them. Khác confirmation bias |
| **Distillate** | Lossless LLM-optimized compression của documents. Khác summary |

---

## C. Variables & config

| Term | Định nghĩa |
|------|-----------|
| **Config variable** | Biến từ `_bmad/config.yaml`, declared in `module.yaml`, filled at install time. Ví dụ: `{planning_artifacts}` |
| **Runtime variable** | Biến set trong lúc workflow execute. Ví dụ: `{story_key}`, `{date}` |
| **System macro** | Variable computed by system: `{project-root}`, `{skill-root}`, `{date}`, `{time}`, `{directory_name}`, `{value}` |
| **customize.toml** | File override agent persona hoặc workflow hooks. 2 blocks: `[agent]` và `[workflow]` |
| **3-level customization** | Skill-level override: default → team → user |
| **4-level central config** | Installer answers team/user + custom team/user |
| **`{project-root}`** | Project root, detected via `_bmad/` or `.git/` upward |
| **`{planning_artifacts}`** | Phase 1-3 outputs location. Default: `{project-root}/_bmad-output/planning-artifacts` |
| **`{implementation_artifacts}`** | Phase 4 outputs: stories, sprint, reviews. Default: `_bmad-output/implementation-artifacts` |
| **`{project_knowledge}`** | Long-lived docs: tech stack, standards. Default: `docs/` |
| **`{communication_language}`** | Ngôn ngữ AI nói chuyện với user (e.g., Vietnamese) |
| **`{document_output_language}`** | Ngôn ngữ artifacts viết ra (e.g., English) |
| **`{user_skill_level}`** | beginner/intermediate/expert — ảnh hưởng explanation depth |
| **Keyed merge** | Array of tables có cùng field `code` hoặc `id` → merge by key. Mixed → append |
| **Deep merge** | Recursive merge for nested dicts |

---

## D. Workflow terms

| Term | Định nghĩa |
|------|-----------|
| **HALT** | AI dừng lại, đợi user input. Phổ biến tại menus |
| **Menu** | Choice UI trong step: [A]dvanced Elicitation / [P]arty Mode / [C]ontinue |
| **Goto** | XML workflow directive để jump steps (`<goto step="5">`) |
| **Anchor** | Điểm đích của goto (`<anchor id="task_check" />`) |
| **Sequential enforcement** | Steps chạy đúng thứ tự, không skip, không forward-load |
| **Append-only building** | Document grow section-by-section, never overwrite |
| **State tracking** | Frontmatter field `stepsCompleted: [1, 2, 3]` tracks progress |
| **Resume detection** | Check existing file's frontmatter → offer continue from last step |
| **Continuation** | `step-01b-continue.md` handle resuming existing workflow |
| **Branching** | Step-02a / 02b / 02c = 4 variants, chỉ load 1 based on user choice |
| **Fan-out** | Spawn parallel sub-agents (e.g., distillator, party mode) |
| **Graceful degradation** | If subagent unavailable, main agent does work inline |
| **DoD (Definition of Done)** | Checklist trước khi mark story complete |
| **Review continuation** | Dev-story resumes after code-review with [AI-Review] tasks |
| **Significant discovery** | Pattern in retrospective: findings require epic update before next epic |
| **Persistent facts** | Facts loaded at agent activation, "always-true" knowledge |
| **Activation steps** | Hooks: `_prepend` (before greet), `_append` (after greet) |
| **Sub-agent** | Prompt file trong `agents/` folder, spawned via Agent tool for parallel reasoning |

---

## E. Validation rules

| Rule | Nhóm | Severity | Mô tả |
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

**Total:** 27 rules (14 deterministic + 13 inference). Chi tiết: [03 §10](03-skill-anatomy-deep.md)

---

## F. File types & artifacts

| File | Purpose | Location |
|------|---------|----------|
| `SKILL.md` | Skill entry point, frontmatter metadata | In skill dir |
| `workflow.md` | Skill logic (XML inline hoặc redirect to steps/) | In skill dir |
| `customize.toml` | Agent persona / workflow hooks | In skill dir |
| `template.md` | Template cho output file | In skill dir |
| `checklist.md` | Validation checklist (e.g., DoD) | In skill dir |
| `step-NN-*.md` | Micro-file workflow step | `steps/` |
| `module.yaml` | Module definition (code, name, agents, config vars) | Module root |
| `manifest.yaml` | Installation metadata | `_bmad/_config/` |
| `skill-manifest.csv` | Skills registry | `_bmad/_config/` |
| `files-manifest.csv` | Files tracking với SHA-256 hashes | `_bmad/_config/` |
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

Built-in agents (in `bmm` module):

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
- Team defaults to module code unless specified

---

## H. Tiếng Việt - tiếng Anh mapping

Quy ước: **Technical terms giữ tiếng Anh**, giải thích bằng tiếng Việt.

| English (preferred) | Tiếng Việt tương đương | Ghi chú |
|--------------------|-------------------------|---------|
| **agent** | nhân vật, tác nhân | Dùng "agent" trong docs |
| **skill** | kỹ năng | Dùng "skill" |
| **workflow** | luồng công việc, quy trình | Dùng "workflow" |
| **step** | bước | "step" in filenames, "bước" in narrative OK |
| **config** | cấu hình | "config" when referring to file |
| **install** | cài đặt | "install" for command, "cài đặt" in narrative OK |
| **validate** | kiểm tra, xác thực | "validate" for CLI command |
| **override** | ghi đè, thay thế | "override" technical term |
| **merge** | gộp, trộn | "merge" technical |
| **artifact** | sản phẩm, tài liệu | "artifact" preferred |
| **persona** | tính cách, nhân vật | "persona" preferred |
| **module** | module, gói | "module" |
| **phase** | giai đoạn, phase | "phase" OK when talking about BMM phases |
| **loop** | lặp, vòng lặp | "loop" technical |
| **HALT** | dừng, ngừng | "HALT" (uppercase) specific pattern |
| **invoke** | gọi, khởi tạo | "invoke" preferred (specific meaning) |

### Mixed patterns (OK)

Phép sử dụng tiếng Việt + tiếng Anh trong cùng sentence:
- "Dùng pattern **micro-file architecture** để split workflow"
- "Agent **Mary** đóng vai **Business Analyst**"
- "Customize **agent persona** qua `customize.toml`"

### Avoid

❌ Dịch triệt để (confusing):
- "Agent Mary" NOT "Nhân vật Mary"
- "skill bmad-brainstorming" NOT "kỹ năng bmad-brainstorming"
- "workflow.md" NOT "quy-trình.md"

❌ English-only (when Vietnamese reader struggles):
- "Invoke the skill. Follow the workflow. Check the validation."
- Thay bằng: "Gọi skill. Theo workflow. Kiểm tra validation."

### Priority decision

Khi không chắc: **Xem docs chính thức** (`src/` files) hầu hết English → keep English.

---

## Quick alphabetical lookup

- **Acceptance Criteria (AC)** — Điều kiện nghiệm thu, format Given/When/Then
- **Activation steps** — Hooks chạy khi agent activate
- **Adversarial review** — Review với mindset tìm lỗi, không validate
- **Agent** — Persona với menu skills
- **Amelia 💻** — Senior Engineer persona
- **Anchor** — Điểm đích của goto trong XML workflow
- **Anti-bias protocol** — Brainstorming pattern: shift domain every 10 ideas
- **Append-only** — Document building without overwriting
- **Artifact** — File output (PRD, architecture, etc.)
- **BMM** — Breakthrough Method of Agile AI-driven Development (module)
- **Brainstorming techniques** — 30+ methods in `brain-methods.csv`
- **Capture-don't-interrupt** — Product-brief pattern
- **Catalog** — `bmad-help.csv` registry
- **Checkpoint preview** — Human-review walkthrough skill
- **Communication language** — AI chat language (`{communication_language}`)
- **Config variable** — Variable from `_bmad/config.yaml`
- **Continuation** — Resume existing workflow (e.g., `step-01b-continue.md`)
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
- **Filesystem as truth** — Core principle
- **Frontmatter** — YAML block at top of .md file
- **Goto** — XML workflow jump
- **Graceful degradation** — Work inline if subagent unavailable
- **HALT** — AI wait for user input
- **Human-in-the-loop** — User at strategic checkpoints
- **Icon** — Single emoji for agent (📊📚📋🎨🏗️💻)
- **Inference rule** — Validation rule requiring LLM judgment
- **Install paths** — Directory structure of `_bmad/`
- **Invoke** — Proper way to call another skill
- **Jobs-to-be-Done (JTBD)** — PM framework (John's principle)
- **John 📋** — PM persona
- **Keyed merge** — Array of tables merge by `code`/`id`
- **Mary 📊** — Analyst persona
- **Menu** — Agent command shortcuts
- **Micro-file** — 2-5KB step file
- **Module** — Package of skills + agents
- **module.yaml** — Module definition file
- **Named agent** — Agent with persona (Mary, John, etc.)
- **Paige 📚** — Tech Writer persona
- **Party mode** — Multi-agent collaboration
- **Persistent facts** — Always-loaded agent knowledge
- **Persona** — Agent's identity + communication style
- **Phase** — One of 4 BMM phases (Analysis/Planning/Solutioning/Implementation)
- **Planning artifacts** — Phase 1-3 outputs folder
- **PRD** — Product Requirements Document
- **PRFAQ** — Press Release + FAQ (Amazon method)
- **Product brief** — Executive summary 1-2 pages
- **Project context** — `project-context.md` with project rules
- **Quick dev** — Quick Flow path (skip formal PRD)
- **RED-GREEN-REFACTOR** — TDD cycle
- **Resolve variables** — Expand `{var}` to actual values
- **Retrospective** — Post-epic party-mode review
- **Resume detection** — Check existing file to continue
- **Review continuation** — Dev-story after code-review
- **Runtime variable** — Set during execution
- **Sally 🎨** — UX Designer persona
- **Sequential** — Step-by-step, no parallel
- **Shard doc** — Split large doc by H2 sections
- **Significant discovery** — Retrospective finding requiring epic update
- **SKILL.md** — Skill entry point
- **Skills manifest** — CSV of all installed skills
- **Smart selection** — Context-aware method picking
- **Sprint status** — `sprint-status.yaml` state file
- **State tracking** — `stepsCompleted` frontmatter array
- **Steps/** — Micro-file folder
- **Sub-agent** — Prompt spawned via Agent tool
- **System macro** — `{project-root}`, `{date}`, etc.
- **Template** — Output file template
- **Trunk-based dev** — Every push to main auto-publishes
- **UX-DR** — UX Design Requirement
- **Validation** — Check rules via validate-skills.js
- **Validation gate** — Multi-check before marking complete
- **Verbatim skills** — Installed unchanged to IDE folders
- **Winston 🏗️** — Architect persona
- **workflow.md** — Skill logic file
- **XML workflow** — Inline workflow with `<step>`, `<action>`, `<check>` tags

---

**Đọc tiếp:** [16-faq.md](16-faq.md) — Câu hỏi thường gặp cho dev mới.
