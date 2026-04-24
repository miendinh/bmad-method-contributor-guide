# 📐 KIẾN TRÚC BMAD-METHOD - ĐẶC TẢ CHI TIẾT

> ⚠️ **UNOFFICIAL THIRD-PARTY DOCUMENTATION**
> Không phải official BMad docs. Xem [DISCLAIMER.md](DISCLAIMER.md) | Licensed MIT — xem [LICENSE](LICENSE) và [NOTICE](NOTICE)
> Official BMAD-METHOD: <https://github.com/bmad-code-org/BMAD-METHOD>

---

> ⚠️ **FILE CŨ - CHỈ GIỮ CHO REFERENCE**
>
> File này là **tổng hợp đầu tiên** (v1) của bộ tài liệu developer deep dive. Nội dung đã được **mở rộng và cập nhật** trong các files 01-14 mới hơn.
>
> **Khuyến nghị:** Đọc [README.md](README.md) để navigate bộ tài liệu mới. Các file chi tiết hơn:
> - **[01-philosophy.md](01-philosophy.md)** — Triết lý + 10 nguyên lý (thay thế section 14 file này)
> - **[02-environment-and-variables.md](02-environment-and-variables.md)** — Biến môi trường (thay thế section 4-5 + 9)
> - **[03-skill-anatomy-deep.md](03-skill-anatomy-deep.md)** — Skill anatomy (thay thế section 3)
> - **[04-skills-catalog.md](04-skills-catalog.md)** + **[09a-d]** — Skills catalog + deep dive (thay thế section 10)
> - **[05-flows-and-diagrams.md](05-flows-and-diagrams.md)** — 16 Mermaid diagrams (bổ sung)
> - **[06 + 08]** — Installer internals (thay thế section 8)
> - **[07-extension-patterns.md](07-extension-patterns.md)** — Extension patterns (thay thế section 12)
> - **[11-14]** — Testing, migration, operations, rewrite blueprint (mới)
>
> File cũ này vẫn giữ lại cho ai muốn **tóm tắt nhanh** toàn bộ framework trong 1 file (~820 dòng).

---

> Tài liệu đặc tả toàn bộ kiến trúc framework BMAD-METHOD để hiểu, xây dựng và mở rộng framework.
>
> **Đối tượng:** Developer có kinh nghiệm muốn contribute vào framework, viết module/skill mới, hoặc tái hiện framework.

---

## Mục lục

1. [Tổng quan cấu trúc repository](#1-tổng-quan-cấu-trúc-repository)
2. [Ba khái niệm cốt lõi cần phân biệt](#2-ba-khái-niệm-cốt-lõi-cần-phân-biệt)
3. [Anatomy của một Skill](#3-anatomy-của-một-skill-agent-skills-spec)
4. [Hệ thống biến (Variables)](#4-hệ-thống-biến-variables)
5. [Quy tắc Path (PATH-01 → PATH-05)](#5-quy-tắc-path-path-01--path-05---rất-quan-trọng)
6. [Anatomy của một Agent](#6-anatomy-của-một-agent)
7. [Anatomy của một Module](#7-anatomy-của-một-module)
8. [Installer flow](#8-installer-flow-npx-bmad-method-install)
9. [Hệ thống Customization 3-level](#9-hệ-thống-customization-3-level)
10. [4 Phase của BMM](#10-4-phase-của-bmm-luồng-công-việc-end-to-end)
11. [Validation system](#11-validation-system-30-rules)
12. [ĐẶC TẢ MỞ RỘNG - Làm sao để…](#12-đặc-tả-mở-rộng---làm-sao-để)
13. [Build & Distribution](#13-build--distribution)
14. [Nguyên lý thiết kế gốc](#14-nguyên-lý-thiết-kế-gốc-để-bạn-tái-hiện)
15. [Tài liệu chính thức nên đọc theo thứ tự](#15-tài-liệu-chính-thức-nên-đọc-theo-thứ-tự)

---

## 1. Tổng quan cấu trúc repository

```
BMAD-METHOD/
├── src/                     # Source thực sự của framework
│   ├── core-skills/         # 12 skills dùng chung (brainstorm, help, shard-doc...)
│   ├── bmm-skills/          # 27 skills theo 4 phase (BMM module)
│   └── scripts/             # Resolve config, helpers
├── tools/
│   ├── installer/           # CLI `bmad` (entry: bmad-cli.js)
│   ├── validate-skills.js   # Validator deterministic (14 rules)
│   ├── skill-validator.md   # Catalog 30+ rules (spec gốc)
│   ├── build-docs.mjs       # Build Astro docs
│   └── validate-*.js        # Link, reference validators
├── docs/                    # Tài liệu (EN + vi-vn, zh-cn, cs, fr)
├── website/                 # Astro + Starlight
├── test/                    # Regression tests
├── build/                   # Output docs build
└── package.json             # npm scripts, version
```

**Mô hình vận hành:** Declarative, filesystem-based, không có runtime phức tạp. Framework = **structure + prompts + validator**. AI agent đọc file, làm theo workflow, ghi file output.

---

## 2. Ba khái niệm cốt lõi cần phân biệt

| Khái niệm | Định nghĩa | Ví dụ |
|-----------|-----------|-------|
| **Skill** | Đơn vị công việc tự chứa — thư mục có `SKILL.md` + `workflow.md` + `steps/` | `bmad-brainstorming`, `bmad-create-prd` |
| **Agent** | Persona (nhân vật) có menu các skill | `bmad-agent-pm` (John — Product Manager) |
| **Module** | Gói nhiều skill + agent + config, có `module.yaml` | `core`, `bmm` |

> **Skill = "tool"**, **Agent = "persona cầm nhiều tool"**, **Module = "package phân phối"**.

---

## 3. Anatomy của một Skill (Agent Skills spec)

### 3.1 Cấu trúc thư mục chuẩn

```
bmad-my-skill/
├── SKILL.md              # L1 metadata (BẮT BUỘC)
├── workflow.md           # Logic chính
├── template.md           # Template output (optional)
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
name: bmad-my-skill                    # Phải match tên folder, regex: ^bmad-[a-z0-9]+(-[a-z0-9]+)*$
description: 'Does X. Use when Y.'     # Max 1024 ký tự, PHẢI có cả "what" + "when to use"
---

Follow the instructions in ./workflow.md.
```

### 3.3 workflow.md - khung chính

```yaml
---
context_file: ''                       # Runtime variables (set khi chạy)
spec_file: ''
---

# My Skill Workflow
**Goal:** ...
**Your Role:** ...

## INITIALIZATION
Load config từ `{project-root}/_bmad/core/config.yaml`:
- {project_name}, {output_folder}, {user_name}
- {communication_language}, {document_output_language}

## Paths
- `output_file` = `{planning_artifacts}/my-output.md`

## EXECUTION
Read fully and follow: `./steps/step-01-init.md`
```

### 3.4 Micro-file steps

Mỗi step là **file độc lập** ~2-5KB, load just-in-time:

```markdown
# Step 01: Init

## YOUR TASK
[Mục tiêu rõ ràng]

## ACTION
[Hướng dẫn chi tiết]

## NEXT
Read fully and follow: `./step-02-execute.md`
```

**Quy luật:**
- Sequential (không skip)
- No forward-loading (không đọc step tương lai sớm)
- HALT tại menu để đợi user
- Filename format: `step-NN[-variant]-description.md` (NN zero-padded)
- Mỗi step phải có goal section (`## YOUR TASK`)
- Workflow nên có 2-10 steps

---

## 4. Hệ thống biến (Variables)

### 4.1 Config variables (từ `_bmad/core/config.yaml`)

| Variable | Ý nghĩa |
|----------|---------|
| `{project-root}` | Thư mục gốc project |
| `{output_folder}` | Nơi lưu output mặc định |
| `{planning_artifacts}` | Outputs của phase 1-3 (PRD, Architecture...) |
| `{implementation_artifacts}` | Outputs phase 4 (stories, code reviews...) |
| `{project_knowledge}` | Kiến thức dự án (tech stack, conventions) |
| `{communication_language}` | Ngôn ngữ agent nói chuyện |
| `{document_output_language}` | Ngôn ngữ file xuất ra |
| `{user_name}` | Tên user/team |

### 4.2 Runtime variables (set khi chạy)

`{date}`, `{status}`, `{spec_file}`, `{story_file}` — declare trong frontmatter, fill khi execute.

### 4.3 Quy tắc (REF-01 → REF-03)

- **REF-01:** Mọi `{variable}` phải được defined trong frontmatter, config, hoặc runtime
- **REF-02:** File references phải resolve được (file phải tồn tại)
- **REF-03:** Invoke skill khác phải dùng ngôn từ **"Invoke the `skill-name` skill"** — KHÔNG dùng "read/load/execute file"

---

## 5. Quy tắc Path (PATH-01 → PATH-05) - **rất quan trọng**

| Rule | Quy tắc | Đúng | Sai |
|------|---------|------|-----|
| PATH-01 | Reference trong skill phải **relative** | `./steps/step-01.md` | `/Users/.../step-01.md` |
| PATH-02 | Không dùng `{installed_path}` | (xóa biến này) | `{installed_path}/template.md` |
| PATH-03 | Reference ngoài skill phải dùng **config variable** | `{planning_artifacts}/prd.md` | `~/Documents/prd.md` |
| PATH-04 | Không lưu internal path vào variable | `./template.md` inline | `{template_path}` |
| PATH-05 | **KHÔNG reach vào folder skill khác** | Invoke skill | `{project-root}/_bmad/skills/other/template.md` |

**PATH-05 là nguyên lý encapsulation** — skill này muốn dùng skill khác thì phải **invoke nó**, không được đọc file của nó.

---

## 6. Anatomy của một Agent

Agent được định nghĩa trong **`module.yaml`** + thư mục skill persona riêng:

```yaml
# src/bmm-skills/module.yaml
agents:
  - code: bmad-agent-dev
    name: Amelia
    title: Senior Software Engineer
    icon: "💻"
    description: "Test-first discipline..."
```

Và file `customize.toml` trong skill persona:

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

# Menu shortcuts user có thể gõ
[[agent.menu]]
code = "DS"
description = "Write the next story's tests and code"
skill = "bmad-dev-story"

[[agent.menu]]
code = "QD"
description = "Unified quick flow"
skill = "bmad-quick-dev"
```

**6 agent BMM mặc định:**

| Agent code | Tên | Title | Icon |
|-----------|-----|-------|------|
| `bmad-agent-analyst` | Mary | Business Analyst | 📊 |
| `bmad-agent-pm` | John | Product Manager | 📋 |
| `bmad-agent-ux-designer` | Sally | UX Designer | 🎨 |
| `bmad-agent-architect` | Winston | System Architect | 🏗️ |
| `bmad-agent-dev` | Amelia | Senior Software Engineer | 💻 |
| `bmad-agent-tech-writer` | Paige | Technical Writer | 📚 |

---

## 7. Anatomy của một Module

```yaml
# module.yaml
code: bmm                              # ID duy nhất
name: "BMad Method Agile-AI"
description: "..."
default_selected: true                 # Tự chọn khi install

# Config variables module định nghĩa
project_name:
  prompt: "What is your project called?"
  default: "{directory_name}"

planning_artifacts:
  prompt: "Where should planning artifacts be stored?"
  default: "{output_folder}/planning-artifacts"
  result: "{project-root}/{value}"     # Cách compute giá trị cuối

# Thư mục installer sẽ tạo
directories:
  - "{planning_artifacts}"
  - "{implementation_artifacts}"
  - "{project_knowledge}"

# Agents thuộc module
agents:
  - code: bmad-agent-pm
    name: John
    # ...
```

**Hai module built-in:**
- `core` — shared config, paths, core variables
- `bmm` — 27 skills + 6 agents cho agile AI-driven dev

---

## 8. Installer flow (`npx bmad-method install`)

```
1. User gõ: npx bmad-method install
           ↓
2. CLI (tools/installer/bmad-cli.js) load commands
           ↓
3. Interactive prompts từ module.yaml config_vars
           ↓
4. Tạo cấu trúc _bmad/ trong project user:
   _bmad/
   ├── core/config.yaml           ← trả lời của user
   ├── bmm/config.yaml
   ├── skills/
   │   ├── core/                  ← copy từ src/core-skills/
   │   └── bmm/                   ← copy từ src/bmm-skills/
   ├── scripts/resolve_customization.py
   └── custom/                    ← user override
           ↓
5. Setup IDE (Claude Code, Cursor, JetBrains...)
           ↓
6. Hiển thị post-install-notes từ module.yaml
```

### Các file quan trọng trong `_bmad/` sau khi install

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

## 9. Hệ thống Customization 3-level

Mỗi skill/agent có 3 cấp override:

```
Level 1 (Default):    {skill-root}/customize.toml
Level 2 (Team):       {project-root}/_bmad/custom/{skill-name}.toml
Level 3 (User):       {project-root}/_bmad/custom/{skill-name}.user.toml
```

**Merge rules:**
- Scalars → user wins (override base)
- Arrays (ví dụ `persistent_facts`) → append
- Array-of-tables có `code`/`id` → replace khớp, append mới

---

## 10. 4 Phase của BMM (Luồng công việc end-to-end)

```
PHASE 1: Analysis                PHASE 2: Planning
(Hiểu bài toán)                  (Lập kế hoạch)
├── bmad-brainstorming           ├── bmad-create-prd
├── bmad-prfaq                   ├── bmad-create-ux-design
├── bmad-product-brief    →      ├── bmad-validate-prd
└── bmad-document-project        └── Agents: John, Sally
Agents: Mary
      ↓                                ↓
   Product Brief / PRFAQ              PRD + UX Design
      ↓                                ↓

PHASE 3: Solutioning             PHASE 4: Implementation
(Thiết kế kiến trúc)             (Xây & ship)
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

### Chi tiết từng phase

| Phase | Goal | Key Skills | Output |
|-------|------|-----------|--------|
| 1. Analysis | Understand the problem | Brainstorming, PRFAQ, Product Brief, Research | PRD input |
| 2. Planning | Plan the solution | Create PRD, UX Design, Validate PRD | PRD + UX specs |
| 3. Solutioning | Design architecture | Architecture, Epics/Stories, Context | Architecture docs |
| 4. Implementation | Build & ship | Dev Story, Code Review, Sprint Planning | Shipped code |

**Nguyên lý chuyển phase:** output phase trước → input phase sau (file-based handoff).

---

## 11. Validation system (30+ rules)

### 11.1 Deterministic (validate-skills.js)

```bash
node tools/validate-skills.js                  # toàn bộ
node tools/validate-skills.js path/to/skill    # 1 skill
node tools/validate-skills.js --strict --json  # CI mode
```

Check 14 rules: SKILL-01→07, WF-01, WF-02, PATH-02, STEP-01, STEP-06, STEP-07, SEQ-02.

### 11.2 Inference-based (skill-validator.md)

16+ rules cần LLM judgment: PATH-01, PATH-03→05, WF-03, STEP-02→05, SEQ-01, REF-01→03.

### 11.3 Rule catalog

| Nhóm | Mục đích |
|------|----------|
| **SKILL-*** | Cấu trúc SKILL.md + metadata |
| **WF-*** | workflow.md structure |
| **PATH-*** | File path resolution |
| **STEP-*** | Step file anatomy |
| **SEQ-*** | Sequential execution |
| **REF-*** | Variable references |

### 11.4 Chi tiết các rule quan trọng

#### SKILL-* (Skill metadata)

| Rule | Severity | Nội dung |
|------|----------|----------|
| SKILL-01 | CRITICAL | Skill directory PHẢI có `SKILL.md` |
| SKILL-02 | CRITICAL | `SKILL.md` PHẢI có `name` trong frontmatter |
| SKILL-03 | CRITICAL | `SKILL.md` PHẢI có `description` trong frontmatter |
| SKILL-04 | HIGH | `name` format: `^bmad-[a-z0-9]+(-[a-z0-9]+)*$` |
| SKILL-05 | HIGH | `name` PHẢI match tên thư mục |
| SKILL-06 | MEDIUM | `description` max 1024 chars, có "Use when..." |
| SKILL-07 | HIGH | `SKILL.md` PHẢI có body content sau frontmatter |

#### WF-* (Workflow)

| Rule | Severity | Nội dung |
|------|----------|----------|
| WF-01 | HIGH | Chỉ `SKILL.md` được có `name` trong frontmatter |
| WF-02 | HIGH | Chỉ `SKILL.md` được có `description` trong frontmatter |
| WF-03 | HIGH | `workflow.md` frontmatter variables phải là config hoặc runtime |

#### PATH-* (Path rules)

| Rule | Severity | Nội dung |
|------|----------|----------|
| PATH-01 | HIGH | Internal references PHẢI relative |
| PATH-02 | HIGH | KHÔNG dùng biến `installed_path` |
| PATH-03 | HIGH | External references PHẢI dùng config variables |
| PATH-04 | MEDIUM | KHÔNG lưu intra-skill paths trong variables |
| PATH-05 | CRITICAL | KHÔNG reach vào folder skill khác |

---

## 12. ĐẶC TẢ MỞ RỘNG - Làm sao để…

### 12.1 Thêm Skill mới

```bash
# 1. Tạo folder (tên phải match name frontmatter)
mkdir -p src/bmm-skills/4-implementation/bmad-my-skill/steps

# 2. Viết SKILL.md
cat > src/bmm-skills/4-implementation/bmad-my-skill/SKILL.md <<'EOF'
---
name: bmad-my-skill
description: 'Does X. Use when Y happens.'
---

Follow the instructions in ./workflow.md.
EOF

# 3. Viết workflow.md + steps/step-01-*.md + next steps

# 4. Validate
node tools/validate-skills.js src/bmm-skills/4-implementation/bmad-my-skill

# 5. Chạy full quality
npm run quality
```

**Checklist:**
- [ ] Tên folder = tên `name:` frontmatter, format `bmad-[a-z0-9-]+`
- [ ] Description có "Use when ..."
- [ ] workflow.md load config, tuyên bố paths qua config vars
- [ ] Steps numbered `step-NN-*.md`, mỗi step có NEXT reference
- [ ] Không dùng absolute paths hoặc `{installed_path}`
- [ ] Không reach vào folder skill khác (invoke thay vì read file)
- [ ] `npm run validate:skills --strict` pass

### 12.2 Thêm Agent mới

Thêm vào `module.yaml`:

```yaml
agents:
  - code: bmad-agent-security
    name: Sam
    title: Security Expert
    icon: "🔒"
    description: "Threat modeling + OWASP rigor..."
```

Tạo skill persona `bmad-agent-security/` với `customize.toml`:

```toml
[agent]
name = "Sam"
title = "Security Expert"
role = "Threat modeling và security review với OWASP rigor..."
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

### 12.3 Thêm Module hoàn toàn mới

```
my-org-skills/
├── module.yaml              # code, name, config_vars, agents, directories
├── category-1/
│   ├── bmad-skill-1/
│   └── bmad-skill-2/
└── category-2/
    └── bmad-skill-3/
```

**module.yaml tối thiểu:**

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

**Đăng ký:**
- **Official community**: PR vào `tools/installer/external-official-modules.yaml`
- **Private**: Install local qua CLI custom option
- **npm package**: Publish như một gói npm riêng

### 12.4 Customize skill có sẵn (không edit source)

Tạo override trong project user:

```toml
# {project-root}/_bmad/custom/bmad-dev-story.toml

[workflow]
persistent_facts = [
  "file:{project-root}/docs/coding-standards.md",
  "All tests must pass before commit.",
  "We use Vitest, not Jest.",
]

[[agent.menu]]                       # Thêm menu item mới
code = "QT"
description = "Quick test generation"
skill = "bmad-qa-generate-e2e-tests"
```

Core skill `bmad-customize` guide bạn làm việc này interactive.

---

## 13. Build & Distribution

### 13.1 npm Scripts Quan Trọng

```bash
npm run bmad:install      # Install vào project hiện tại
npm run docs:build        # Build Astro docs → build/
npm run docs:dev          # Dev server docs
npm run quality           # Format + lint + docs build + tests + validate
npm run validate:skills   # Validate all skills (strict)
npm run validate:refs     # Validate file references
npm run test:install      # Test installer
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

## 14. Nguyên lý thiết kế gốc (để bạn tái hiện)

Nếu muốn **viết lại BMad từ đầu**, 10 nguyên lý cốt lõi:

1. **Filesystem là truth** — tất cả state lưu trong file, không có DB/runtime
2. **Declarative over imperative** — YAML/TOML/Markdown, không phải code
3. **Document as interface** — output file là API giữa phase/agent
4. **Micro-file workflows** — mỗi step = 1 file, load just-in-time
5. **Sequential by default** — không parallel, agent follow step-by-step
6. **Encapsulated skills** — skill là black box, chỉ invoke không read file
7. **Config-driven paths** — mọi path dùng variable, không hardcode
8. **Declarative validation** — rules viết bằng markdown, enforce bằng JS
9. **Layered customization** — default → team → user (TOML override)
10. **Human-in-the-loop** — HALT tại menu, đợi user input tại checkpoint

### Quy trình tái hiện framework (A-Z)

1. **Define Agents** → Personas với communication styles trong `module.yaml`
2. **Create Skills** → Directory-based, mỗi skill có SKILL.md + workflow.md + steps/
3. **Link Agents → Skills** → Agent menu invoke skills
4. **Build Installer** → Interactive setup flow (prompts → config.yaml → directories)
5. **Define Phases** → Organize skills thành phases (analysis → planning → solutioning → implementation)
6. **Validation System** → Deterministic rules (validate-skills.js) + Inference rules (catalog)
7. **Module System** → Package skills vào modules, support custom modules
8. **Customization** → 3-level TOML override system
9. **Documentation** → Multi-language docs, website build
10. **Testing** → Regression tests cho installer, references, workflows

---

## 15. Tài liệu chính thức nên đọc theo thứ tự

1. [AGENTS.md](../AGENTS.md) — Rule gốc framework (13 dòng)
2. [CONTRIBUTING.md](../CONTRIBUTING.md) — Quy trình PR (183 dòng)
3. [tools/skill-validator.md](../tools/skill-validator.md) — **Đặc tả đầy đủ 30+ rules** (386 dòng) — **tài liệu quan trọng nhất**
4. [tools/installer/README.md](../tools/installer/README.md) — Module registration (60 dòng)
5. [src/core-skills/bmad-brainstorming/](../src/core-skills/bmad-brainstorming/) — **Example canonical** của một skill hoàn chỉnh
6. [src/bmm-skills/module.yaml](../src/bmm-skills/module.yaml) — Example module.yaml
7. [docs/vi-vn/bmad-developer-guide.md](../docs/vi-vn/bmad-developer-guide.md) — Developer guide tổng quan (tiếng Việt)

---

## Phụ lục A: Cấu trúc chi tiết src/

### A.1 core-skills/ (12 Core Skills)

```
core-skills/
├── bmad-brainstorming          # Facilitated ideation sessions (đa kỹ thuật)
├── bmad-advanced-elicitation   # Phát hiện giả định & edge cases
├── bmad-customize              # Customize BMad cho org/team
├── bmad-distillator            # Tóm tắt & phân tích tài liệu
├── bmad-editorial-review-prose
├── bmad-editorial-review-structure
├── bmad-help                   # Guided help & recommendation
├── bmad-index-docs             # Build index from docs
├── bmad-party-mode             # Multi-agent collaboration sessions
├── bmad-review-adversarial-general
├── bmad-review-edge-case-hunter
├── bmad-shard-doc              # Split large docs thành chunks
└── module.yaml                 # Defines "core" module
```

**Đặc điểm:** Không có `agents` folder vì core skills không biểu diễn một agent cụ thể — chúng là generic tools gọi được từ bất kỳ agent nào.

### A.2 bmm-skills/ (27 BMM Phase-Based Skills)

```
bmm-skills/
├── 1-analysis/                         # Phase 1: Understand the problem
│   ├── bmad-agent-analyst              # Agent/skill: Business Analyst persona
│   ├── bmad-document-project           # Extract knowledge từ codebase/docs
│   ├── bmad-prfaq                      # Working Backwards press release
│   ├── bmad-product-brief              # Executive summary của product
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

## Phụ lục B: Ví dụ SKILL.md hoàn chỉnh

### B.1 Ví dụ từ `bmad-brainstorming`

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
Load config từ `{project-root}/_bmad/core/config.yaml`:
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

## Phụ lục C: Glossary

| Thuật ngữ | Định nghĩa |
|-----------|-----------|
| **Skill** | Đơn vị công việc tự chứa, thư mục có `SKILL.md` |
| **Agent** | Persona với communication style + menu of skills |
| **Module** | Gói skills + agents + config, có `module.yaml` |
| **Workflow** | Logic trong `workflow.md` của một skill |
| **Step** | File micro trong `steps/` thư mục |
| **Config variable** | Biến lấy từ `_bmad/core/config.yaml` |
| **Runtime variable** | Biến set trong lúc thực thi workflow |
| **Artifact** | File output của một phase (PRD, Architecture, Story...) |
| **Invoke** | Cách skill gọi skill khác (không được đọc file trực tiếp) |
| **Customize.toml** | File override agent/workflow |
| **Planning artifact** | Output của phase 1-3 |
| **Implementation artifact** | Output của phase 4 |
| **BMM** | Breakthrough Method of Agile AI-driven Development |
| **Diátaxis** | Framework phân loại docs: tutorial / how-to / explanation / reference |
