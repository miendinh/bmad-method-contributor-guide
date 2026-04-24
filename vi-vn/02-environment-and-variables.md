# 02. Biến môi trường, Config & Customization

> ⚠️ **UNOFFICIAL THIRD-PARTY DOCUMENTATION**
> Không phải official BMad docs. Xem [DISCLAIMER.md](DISCLAIMER.md) | Licensed MIT — xem [LICENSE](LICENSE) và [NOTICE](NOTICE)
> Official BMAD-METHOD: <https://github.com/bmad-code-org/BMAD-METHOD>

---

> Đặc tả CHI TIẾT hệ thống biến của BMad: config variables, runtime variables, macro, resolve mechanism, 3/4-level customization. Đủ chi tiết để tự viết parser/resolver.

---

## Mục lục

1. [Tổng quan hệ thống biến](#1-tổng-quan-hệ-thống-biến)
2. [Config variables (Module-level)](#2-config-variables-module-level)
3. [Runtime variables](#3-runtime-variables)
4. [System macros](#4-system-macros)
5. [Resolution mechanism](#5-resolution-mechanism)
6. [customize.toml - Anatomy](#6-customizetoml---anatomy)
7. [3-level customization system](#7-3-level-customization-system)
8. [4-level central config](#8-4-level-central-config)
9. [Merge semantics (deep dive)](#9-merge-semantics-deep-dive)
10. [bmad-customize skill flow](#10-bmad-customize-skill-flow)
11. [Edge cases & gotchas](#11-edge-cases--gotchas)
12. [Checklist để tự viết resolver](#12-checklist-để-tự-viết-resolver)

---

## 1. Tổng quan hệ thống biến

BMad có **4 tầng biến** được resolve ở các thời điểm khác nhau:

```
┌─────────────────────────────────────────────────────────┐
│ TẦNG 4: Runtime variables (workflow-specific)           │
│   {story_key}, {spec_file}, {epic_num}, ...             │
│   Source: generated during execution                    │
└─────────────────────────────────────────────────────────┘
                         ▲
┌─────────────────────────────────────────────────────────┐
│ TẦNG 3: System macros                                   │
│   {project-root}, {skill-root}, {date}, {time}, {value} │
│   Source: system computed                               │
└─────────────────────────────────────────────────────────┘
                         ▲
┌─────────────────────────────────────────────────────────┐
│ TẦNG 2: Config variables (loaded at activation)         │
│   {user_name}, {planning_artifacts}, {project_name}...  │
│   Source: _bmad/config.yaml (from module.yaml prompts)  │
└─────────────────────────────────────────────────────────┘
                         ▲
┌─────────────────────────────────────────────────────────┐
│ TẦNG 1: Customization overrides (skill-level)           │
│   Agent persona, menu, principles, persistent_facts     │
│   Source: _bmad/custom/*.toml (3-level merge)           │
└─────────────────────────────────────────────────────────┘
```

**Quy tắc chung:**
- Tầng cao hơn **có thể reference** tầng thấp hơn
- Unresolved `{var}` = **literal text** (không error, không empty)
- Kebab-case là standard: `{planning-artifacts}`, không `{PLANNING_ARTIFACTS}`

---

## 2. Config variables (Module-level)

Config variables được **declare trong `module.yaml`**, **user trả lời khi install**, và **lưu vào `_bmad/config.yaml`**.

### 2.1 Core Module Variables

Từ [src/core-skills/module.yaml](../src/core-skills/module.yaml):

| Biến | Scope | Prompt | Default | Result Template | Ý nghĩa |
|------|-------|--------|---------|-----------------|---------|
| `user_name` | user | "What should agents call you?" | `"BMad"` | `{value}` | Tên user/team, agent dùng xưng hô |
| `communication_language` | user | "What language should agents use when chatting?" | `"English"` | `{value}` | Ngôn ngữ agent **nói chuyện** |
| `document_output_language` | (none) | "Preferred document output language?" | `"English"` | `{value}` | Ngôn ngữ **file output** |
| `output_folder` | (none) | "Where should output files be saved?" | `"_bmad-output"` | `{project-root}/{value}` | Gốc cho mọi output |

### 2.2 BMM Module Variables

Từ [src/bmm-skills/module.yaml](../src/bmm-skills/module.yaml):

| Biến | Scope | Prompt | Default | Result Template | Ý nghĩa |
|------|-------|--------|---------|-----------------|---------|
| `project_name` | (none) | "What is your project called?" | `{directory_name}` | `{value}` | Tên dự án |
| `user_skill_level` | user | "What is your development experience level?" | `"intermediate"` | `{value}` | beginner/intermediate/expert (ảnh hưởng cách giải thích) |
| `planning_artifacts` | (none) | "Where should planning artifacts be stored?" | `{output_folder}/planning-artifacts` | `{project-root}/{value}` | Phase 1-3 outputs |
| `implementation_artifacts` | (none) | "Where should implementation artifacts be stored?" | `{output_folder}/implementation-artifacts` | `{project-root}/{value}` | Phase 4 outputs |
| `project_knowledge` | (none) | "Where should long-term project knowledge be stored?" | `"docs"` | `{project-root}/{value}` | Long-lived knowledge (tech stack, standards) |

**Kế thừa từ Core:** BMM tự động kế thừa `user_name`, `communication_language`, `document_output_language`, `output_folder`.

### 2.3 Prompt field structure

Mỗi config variable trong `module.yaml` có schema:

```yaml
<variable_name>:
  prompt: "Câu hỏi user"              # String hoặc array (multi-line)
  scope: user                          # Optional: "user" (per-user) hoặc default (team)
  default: "giá trị mặc định"          # Có thể dùng macro như {directory_name}
  result: "template cuối"              # Cách compute giá trị cuối từ {value}
  single-select:                       # Optional: chọn từ list
    - value: "beginner"
      label: "Beginner - Explain things clearly"
    - value: "intermediate"
      label: "Intermediate - Balance detail with speed"
    - value: "expert"
      label: "Expert - Be direct and technical"
```

**Scope:**
- `user`: lưu vào `_bmad/config.user.toml` (personal, gitignored)
- (default): lưu vào `_bmad/config.toml` (team, committed)

**Result template giải thích:**

```yaml
planning_artifacts:
  prompt: "Where should planning artifacts be stored?"
  default: "{output_folder}/planning-artifacts"
  result: "{project-root}/{value}"
```

Resolve flow:
```
1. Default expand:     "{output_folder}/planning-artifacts"
                    →  "_bmad-output/planning-artifacts"

2. User accepts default hoặc nhập khác. Giả sử user giữ default:
   {value} = "_bmad-output/planning-artifacts"

3. Apply result template: "{project-root}/{value}"
                        → "/home/alice/project/_bmad-output/planning-artifacts"

4. Lưu vào config.yaml:
   planning_artifacts: "/home/alice/project/_bmad-output/planning-artifacts"
```

### 2.4 Module yaml - sections khác

```yaml
# code và name - identity của module
code: bmm
name: "BMad Method Agile-AI Driven-Development"
description: "AI-driven agile development framework"
default_selected: true              # Auto-check khi install

# header / subheader - hiển thị trong installer UI
header: "BMad Core Configuration"
subheader: "Configure the core settings..."

# directories - installer tự tạo
directories:
  - "{planning_artifacts}"
  - "{implementation_artifacts}"
  - "{project_knowledge}"

# agents - roster agent thuộc module
agents:
  - code: bmad-agent-pm
    name: John
    title: Product Manager
    icon: "📋"
    team: software-development
    description: "Drives Jobs-to-be-Done..."

# post-install-notes - hiển thị sau install xong
post-install-notes: |
  Thank you for choosing BMM...
```

---

## 3. Runtime variables

Khác config variables (có sẵn khi activate), runtime variables được **sinh ra trong khi chạy**.

### 3.1 Phân loại

| Nhóm | Ví dụ | Source | Lifecycle |
|------|-------|--------|-----------|
| **Workflow state** | `{status}`, `{story_key}`, `{current_step}` | Logic workflow set | Per-execution |
| **User input runtime** | `{story_path}`, `{spec_file}` | User nhập trong prompt | Per-execution |
| **File system discovery** | `{latest_prd}`, `{sprint_status_summary}` | Workflow scan files | Per-execution |
| **Computed** | `{story_key}` từ filename, `{acceptance_status}` từ parse | Logic derive | Per-execution |

### 3.2 Declare runtime variable

Trong `workflow.md` frontmatter:

```yaml
---
context_file: ''                    # Optional, user provides at invocation
spec_file: ''                       # Optional
story_path: ''                      # Runtime, may be empty initially
---
```

Quy tắc WF-03: frontmatter variables trong workflow.md chỉ được là:
- Config variable reference (e.g., `{planning_artifacts}`)
- Empty hoặc placeholder (runtime will fill)
- Legitimate external path

**KHÔNG được:** hardcode path hoặc path vào skill khác (PATH-05).

### 3.3 Ví dụ runtime vars trong `bmad-dev-story`

```yaml
# workflow.md frontmatter
---
story_path: ''
---
```

Trong execution:
```xml
<check if="{{story_path}} is provided">
  <action>Use {{story_path}} directly</action>
</check>

<check if="{{sprint_status}} file exists">
  <action>Parse development_status to find story_key</action>
  <action>Store {{story_key}} for later</action>
</check>
```

**Lưu ý syntax:**
- `{config_var}` — single curly = config/runtime variable
- `{{runtime_var}}` — double curly = template placeholder (XML-style, dùng trong workflow steps)

Hai syntax khác nhau, resolver phân biệt:
- `{}`: resolved by config merger
- `{{}}`: resolved at execution time by workflow engine (tức là LLM khi nó đọc)

### 3.4 Biến runtime "universe" thường gặp

Đây là các biến phổ biến, xuất hiện trong nhiều skill:

| Biến | Ý nghĩa | Xuất hiện trong |
|------|---------|-----------------|
| `{date}` | Ngày hiện tại, format MM-DD-YYYY | Mọi workflow output file |
| `{time}` | Giờ hiện tại, HH:MM | Brainstorming, session logs |
| `{story_key}` | VD "1-2-user-auth" | dev-story, create-story, sprint-* |
| `{story_file}`, `{story_path}` | Full path story file | dev-story, code-review |
| `{spec_file}` | Path spec file | Quick-dev, correct-course |
| `{epic_num}` | Epic number | Sprint planning, retrospective |
| `{current_status}` | Status hiện tại của story | dev-story |
| `{resolved_review_items}` | Review items đã xử lý | dev-story (review continuation) |
| `{pending_review_items}` | Review items chưa xử lý | dev-story |
| `{sprint_status_summary}` | Summary sprint status | sprint-status, dev-story |

**Không có danh sách chính thức** — mỗi skill tự declare biến nó cần.

---

## 4. System macros

Macros là biến **được hệ thống compute**, luôn có sẵn.

### 4.1 Danh sách đầy đủ

| Macro | Cách resolve | Ví dụ |
|-------|-------------|-------|
| `{project-root}` | Tìm directory chứa `_bmad/` hoặc `.git/` từ cwd đi lên | `/home/alice/project` |
| `{skill-root}` | Path của skill đang chạy | `/home/alice/project/_bmad/skills/bmm/bmad-create-prd` |
| `{skill-name}` | Basename của skill directory | `bmad-create-prd` |
| `{directory_name}` | Basename của `{project-root}` | `project` |
| `{date}` | System date, format `MM-DD-YYYY` | `04-24-2026` |
| `{time}` | System time, format `HH:MM` | `14:30` |
| `{value}` | User input cho prompt hiện tại | (contextual) |

**Không có macros khác.** Nếu workflow cần compute gì, phải dùng runtime logic (xml `<action>`).

### 4.2 project-root detection

Logic trong `tools/installer/project-root.js`:

```javascript
function findProjectRoot(startPath) {
  let currentPath = startPath;
  while (currentPath !== rootPath) {
    // Check: package.json with {name: "bmad-method"}
    // Check: _bmad/ directory exists
    // Check: .git/ directory exists
    if (found) return currentPath;
    currentPath = parent(currentPath);
  }
  return process.cwd();  // Fallback
}
```

**Priority:**
1. `_bmad/` directory (BMad-installed project)
2. `.git/` directory (git repo root)
3. `process.cwd()` fallback

### 4.3 Dùng macros trong templates

```yaml
# module.yaml
planning_artifacts:
  default: "{output_folder}/planning-artifacts"
  result: "{project-root}/{value}"
```

```toml
# customize.toml
persistent_facts = [
  "file:{project-root}/**/project-context.md",
  "file:{project-root}/docs/coding-standards.md",
]
```

```markdown
# step file
## Paths
- `output_file` = `{planning_artifacts}/my-feature-{date}.md`
```

---

## 5. Resolution mechanism

### 5.1 Full resolution order

Khi skill activate, resolver chạy 5 bước:

```
┌─────────────────────────────────────────────────────────┐
│ Step 1: Find project-root (find _bmad/ upward from cwd) │
└─────────────────────────────────────────────────────────┘
                         ▼
┌─────────────────────────────────────────────────────────┐
│ Step 2: Load central config (4-layer merge)             │
│   1. _bmad/config.toml         (installer team)        │
│   2. _bmad/config.user.toml    (installer user)        │
│   3. _bmad/custom/config.toml      (team override)     │
│   4. _bmad/custom/config.user.toml (user override)     │
└─────────────────────────────────────────────────────────┘
                         ▼
┌─────────────────────────────────────────────────────────┐
│ Step 3: Resolve system macros                           │
│   {project-root}, {skill-root}, {date}, {time}          │
└─────────────────────────────────────────────────────────┘
                         ▼
┌─────────────────────────────────────────────────────────┐
│ Step 4: Load skill customization (3-layer merge)        │
│   1. {skill-root}/customize.toml (skill default)        │
│   2. _bmad/custom/{skill-name}.toml (team)              │
│   3. _bmad/custom/{skill-name}.user.toml (user)         │
└─────────────────────────────────────────────────────────┘
                         ▼
┌─────────────────────────────────────────────────────────┐
│ Step 5: Expand variables in text (lazy)                 │
│   Khi đọc workflow/step, replace {var} với giá trị      │
│   {undefined} → literal text (no error)                 │
└─────────────────────────────────────────────────────────┘
```

### 5.2 Lazy vs Eager expansion

- **Config variables**: eager (resolve hết khi activate)
- **Runtime variables**: lazy (resolve khi execute step chứa nó)
- **Macros**: lazy cho `{date}`/`{time}` (mỗi lần đọc), eager cho `{project-root}` (cache)

### 5.3 Nested variable expansion

Templates có thể nested:

```yaml
planning_artifacts:
  default: "{output_folder}/planning-artifacts"    # Uses macro
  result: "{project-root}/{value}"                 # Uses macro + {value}
```

Resolver expand **inside-out**:
```
"{project-root}/{value}"
  → {value} = "{output_folder}/planning-artifacts"
  → expand {output_folder} = "_bmad-output"
  → "{project-root}/_bmad-output/planning-artifacts"
  → {project-root} = "/home/alice/project"
  → "/home/alice/project/_bmad-output/planning-artifacts"
```

### 5.4 Python resolver - ý tưởng implementation

```python
def deep_merge(base, override):
    """Merge theo shape, KHÔNG theo tên field."""
    if isinstance(base, dict) and isinstance(override, dict):
        result = dict(base)
        for key, val in override.items():
            if key in result:
                result[key] = deep_merge(result[key], val)
            else:
                result[key] = val
        return result
    
    if isinstance(base, list) and isinstance(override, list):
        # Detect keyed merge: all items in BOTH lists có cùng key
        keyed_field = detect_keyed_field(base + override)
        if keyed_field:
            return merge_by_key(base, override, keyed_field)
        else:
            return base + override  # Append
    
    # Scalar: override wins
    return override


def detect_keyed_field(items):
    """Returns 'code' hoặc 'id' nếu ALL items có field đó. Else None."""
    if not items:
        return None
    for candidate in ['code', 'id']:
        if all(isinstance(item, dict) and item.get(candidate) is not None 
               for item in items):
            return candidate
    return None


def merge_by_key(base, override, key_field):
    """Merge arrays bằng key field. Matching keys replace, new keys append."""
    result = []
    by_key = {}
    for item in base:
        k = item.get(key_field)
        by_key[k] = item
        result.append(k)
    
    for item in override:
        k = item.get(key_field)
        if k in by_key:
            by_key[k] = deep_merge(by_key[k], item)  # Replace existing
        else:
            by_key[k] = item
            result.append(k)  # Append new
    
    return [by_key[k] for k in result]
```

Đây là ý tưởng của `_bmad/scripts/resolve_customization.py` trong project đã install.

---

## 6. customize.toml - Anatomy

File `customize.toml` định nghĩa persona, menu, và hooks của agent hoặc workflow.

### 6.1 Full schema

```toml
# ====================================================
# AGENT BLOCK (cho skill đóng vai agent như bmad-agent-pm)
# ====================================================
[agent]
# --- Read-only (hardcoded, override bị ignore) ---
name = "John"
title = "Product Manager"

# --- Configurable scalars (override thắng) ---
icon = "📋"
role = "Product manager driven PRD creation..."
identity = "Drives Jobs-to-be-Done over template filling..."
communication_style = "Detective interrogating a cold case..."

# --- Append arrays (team + user append vào defaults) ---
principles = [
  "User value first.",
  "Technical feasibility is constraint, not driver.",
]

persistent_facts = [
  "file:{project-root}/**/project-context.md",
  "Our org uses Jobs-to-be-Done framework.",
  "file:{project-root}/docs/standards/compliance.md",
]

activation_steps_prepend = [
  "Load compliance docs before greeting.",
]

activation_steps_append = [
  "Offer to run PRD validation after greeting.",
]

# --- Keyed array of tables (merge by `code`) ---
[[agent.menu]]
code = "CP"
description = "Create a new PRD"
skill = "bmad-create-prd"

[[agent.menu]]
code = "VP"
description = "Validate existing PRD"
skill = "bmad-validate-prd"

[[agent.menu]]
code = "EP"
description = "Edit existing PRD"
skill = "bmad-edit-prd"

# ====================================================
# WORKFLOW BLOCK (cho skill không phải agent)
# ====================================================
[workflow]
activation_steps_prepend = [
  "Check if user has current story context.",
]
activation_steps_append = []

persistent_facts = [
  "file:{project-root}/**/project-context.md",
]

# Scalar: hook chạy sau workflow complete
on_complete = "Suggest running code-review next."
```

### 6.2 Giải thích từng section

**`[agent]` block:**

| Field | Type | Read-only? | Merge rule |
|-------|------|------------|-----------|
| `name` | string | ✅ Yes | Ignored if overridden |
| `title` | string | ✅ Yes | Ignored if overridden |
| `icon` | string | ❌ | Override wins |
| `role` | string | ❌ | Override wins |
| `identity` | string | ❌ | Override wins |
| `communication_style` | string | ❌ | Override wins |
| `principles` | array of strings | ❌ | **Append** |
| `persistent_facts` | array of strings | ❌ | **Append**, support `file:` prefix |
| `activation_steps_prepend` | array of strings | ❌ | **Append** |
| `activation_steps_append` | array of strings | ❌ | **Append** |
| `[[agent.menu]]` | array of tables | ❌ | **Merge by `code`** |

**`[[agent.menu]]` entry:**

```toml
[[agent.menu]]
code = "XX"          # Required, unique within skill
description = "..."  # Required
skill = "bmad-..."   # Either skill OR prompt, not both
# OR
prompt = "Ask user: What is your..."  # Custom prompt instead of invoking skill
```

**`[workflow]` block:**

| Field | Type | Merge rule |
|-------|------|-----------|
| `activation_steps_prepend` | array | Append |
| `activation_steps_append` | array | Append |
| `persistent_facts` | array | Append |
| `on_complete` | string | Override |

### 6.3 `persistent_facts` với `file:` prefix

```toml
persistent_facts = [
  "Always estimate in story points, not hours.",  # Literal fact
  "file:{project-root}/**/project-context.md",    # File glob
  "file:{project-root}/docs/standards/*.md",      # Folder glob
  "file:{project-root}/CONTRIBUTING.md",           # Single file
]
```

Resolver expand glob, load nội dung, concat làm facts. File không tồn tại thì skip silent.

### 6.4 Override file - chỉ deltas

```toml
# _bmad/custom/bmad-agent-pm.toml  (team override)
[agent]
icon = "🏥"                         # Change icon
principles = [
  "Healthcare compliance first.",   # Added
]

[[agent.menu]]
code = "CP"
description = "Create HIPAA-aware PRD"  # Override existing
skill = "bmad-create-prd-healthcare"    # Point to custom skill
```

Kết quả sau merge:
- `icon` = `"🏥"` (overridden)
- `title`, `name` = unchanged (read-only)
- `principles` = base + `["Healthcare compliance first."]` (appended)
- Menu `CP` replaced với "Create HIPAA-aware PRD" + custom skill

---

## 7. 3-level customization system

### 7.1 Các tầng

```
┌─────────────────────────────────────────────────────────┐
│ Level 1: DEFAULT                                        │
│   {skill-root}/customize.toml                           │
│   Shipped with skill, read-only (overwritten on update) │
└─────────────────────────────────────────────────────────┘
                         ▼
┌─────────────────────────────────────────────────────────┐
│ Level 2: TEAM                                           │
│   {project-root}/_bmad/custom/{skill-name}.toml         │
│   Committed to git, shared across team                  │
└─────────────────────────────────────────────────────────┘
                         ▼
┌─────────────────────────────────────────────────────────┐
│ Level 3: USER                                           │
│   {project-root}/_bmad/custom/{skill-name}.user.toml    │
│   Gitignored, individual customization                  │
└─────────────────────────────────────────────────────────┘
                         ▼
                  FINAL MERGED CONFIG
```

### 7.2 Merge order

Resolver apply top-down:
1. Load Level 1 → base config
2. Deep-merge Level 2 vào base
3. Deep-merge Level 3 vào result
4. Return final

**User override luôn thắng team, team thắng default.**

### 7.3 Khi nào dùng tầng nào

| Use case | Level | File |
|----------|-------|------|
| Framework ship default persona | Level 1 | skill customize.toml |
| Team add compliance rules | Level 2 | `{skill}.toml` |
| Team rename icon | Level 2 | `{skill}.toml` |
| Team thêm menu item mới | Level 2 | `{skill}.toml` |
| Alice prefer Vietnamese agent | Level 3 | `{skill}.user.toml` |
| Bob add personal shortcut | Level 3 | `{skill}.user.toml` |

### 7.4 Git strategy

```gitignore
# .gitignore
_bmad/custom/*.user.toml
_bmad/config.user.toml
```

Team files (`.toml`) committed → shared convention.
User files (`.user.toml`) gitignored → private.

---

## 8. 4-level central config

Khác với skill-level (3-level), **central config** (identity agents, install answers) dùng **4-level**:

```
┌─────────────────────────────────────────────────────────┐
│ Level 1: INSTALLER TEAM ANSWERS                         │
│   {project-root}/_bmad/config.toml                      │
│   Từ prompts module.yaml, scope không phải user         │
└─────────────────────────────────────────────────────────┘
                         ▼
┌─────────────────────────────────────────────────────────┐
│ Level 2: INSTALLER USER ANSWERS                         │
│   {project-root}/_bmad/config.user.toml                 │
│   Từ prompts scope: user (user_name, user_skill_level)  │
└─────────────────────────────────────────────────────────┘
                         ▼
┌─────────────────────────────────────────────────────────┐
│ Level 3: CENTRAL TEAM OVERRIDES                         │
│   {project-root}/_bmad/custom/config.toml               │
│   Add/override agent roster, global facts               │
└─────────────────────────────────────────────────────────┘
                         ▼
┌─────────────────────────────────────────────────────────┐
│ Level 4: CENTRAL USER OVERRIDES                         │
│   {project-root}/_bmad/custom/config.user.toml          │
│   Personal: custom agents, personal preferences         │
└─────────────────────────────────────────────────────────┘
```

**Note:** Central config chỉ dùng cho identity/roster. Skill-level customization vẫn là 3-level.

### 8.1 Ví dụ central config

```yaml
# _bmad/config.toml (Level 1)
core:
  user_name: "Development Team"
  communication_language: "English"
  output_folder: "_bmad-output"

modules:
  bmm:
    project_name: "My Project"
    planning_artifacts: "_bmad-output/planning-artifacts"

agents:
  bmad-agent-pm:
    code: "bmad-agent-pm"
    name: "John"
    title: "Product Manager"
    icon: "📋"
```

```toml
# _bmad/custom/config.toml (Level 3 - team)
[agents.bmad-agent-pm]
icon = "🏥"
description = "Healthcare-aware Product Manager"

[agents.security_bot]           # Thêm agent mới
code = "security-bot"
name = "Sentinel"
title = "Security Specialist"
icon = "🛡️"
```

```toml
# _bmad/custom/config.user.toml (Level 4 - personal)
[core]
user_name = "Alice"              # Override install answer

[agents.kirk]                    # Thêm personal fun agent
code = "kirk"
name = "Captain Kirk"
icon = "🖖"
```

---

## 9. Merge semantics (deep dive)

### 9.1 Shape-based rules (KHÔNG field-name-based)

Resolver KHÔNG biết tên field nào append, field nào override. Nó decide dựa trên **shape (kiểu dữ liệu)**:

| Shape | Rule |
|-------|------|
| Scalar (string, int, bool, float) | Override replaces |
| Table (dict) | Deep recursive merge |
| Array of tables, ALL items có cùng `code` field | **Keyed merge** (replace by code, append new) |
| Array of tables, ALL items có cùng `id` field | **Keyed merge** (replace by id, append new) |
| Bất kỳ array khác | **Append** (no dedup) |

### 9.2 Detection logic

```python
def detect_keyed_field(items):
    # items phải là list of dicts
    if not all(isinstance(x, dict) for x in items):
        return None
    
    # Check: ALL items có 'code'?
    if all(x.get('code') is not None for x in items):
        return 'code'
    
    # Check: ALL items có 'id'?
    if all(x.get('id') is not None for x in items):
        return 'id'
    
    # Mixed hoặc neither → append
    return None
```

**Critical:** Nếu base có items với `code`, nhưng override có item KHÔNG có `code` → fallback về append. Tức là base giữ nguyên, new item thêm vào cuối.

### 9.3 Minh họa

**Case 1: Scalars**
```toml
# Base
icon = "📋"

# Override
icon = "🏥"

# Result
icon = "🏥"
```

**Case 2: Array of strings → APPEND**
```toml
# Base
principles = ["A", "B"]

# Override  
principles = ["C", "D"]

# Result
principles = ["A", "B", "C", "D"]
```

**Case 3: Array of tables with `code` → KEYED MERGE**
```toml
# Base
[[menu]]
code = "X"
description = "Action X"

[[menu]]
code = "Y"
description = "Action Y"

# Override
[[menu]]
code = "Y"                    # Match base → replace
description = "Better Y"

[[menu]]
code = "Z"                    # New → append
description = "Action Z"

# Result
[[menu]]
code = "X"
description = "Action X"

[[menu]]
code = "Y"
description = "Better Y"      # Replaced

[[menu]]
code = "Z"
description = "Action Z"      # Appended
```

**Case 4: Mixed keys → APPEND (gotcha)**
```toml
# Base
[[menu]]
code = "X"
description = "..."

# Override
[[menu]]
id = "custom"                 # id, not code → mixed!
description = "..."

# Result: APPEND (not keyed merge)
[[menu]]
code = "X"
description = "..."

[[menu]]
id = "custom"
description = "..."
```

### 9.4 Không có removal mechanism

**Bạn KHÔNG thể xóa menu item qua override.** Workaround:

```toml
# Base có menu code "BP"
# Override "disable" nó:
[[agent.menu]]
code = "BP"
description = "[Disabled]"
prompt = "This option is not available in your team's config."
```

---

## 10. bmad-customize skill flow

Skill `bmad-customize` guide user viết override files **mà không cần biết TOML**.

### 10.1 User flow

```
User: "I want to customize the PM agent"
           ↓
Step 1: Classify intent
  - Directed (skill + change known) → Skip to Step 3
  - Exploratory ("what can I customize?") → Step 2
  - Audit ("review my overrides") → Step 2
           ↓
Step 2: Discovery
  Run: python3 {skill-root}/scripts/list_customizable_skills.py \
       --project-root {project-root}
  Output: List skills + has_team_override + has_user_override flags
           ↓
Step 3: Determine surface
  - [agent] block? (persona, menu)
  - [workflow] block? (hooks, facts)
           ↓
Step 4: Compose override
  User nói plain English, AI translate sang TOML
  Apply merge semantics đúng
           ↓
Step 5: Team or user placement
  Team override committed hay personal?
           ↓
Step 6: Show, confirm, write, verify
  1. Hiển thị TOML sắp write
  2. User confirm
  3. Write file
  4. Chạy resolve_customization.py verify
  5. Show merged result
```

### 10.2 Scope v1 (hiện tại)

**Covered:**
- Per-skill agent overrides
- Per-skill workflow overrides
- Team vs user placement

**Out of scope:**
- Central config (`_bmad/custom/config.toml`)
- Step logic changes (cần `bmad-builder`)
- Ordering changes

### 10.3 Verify command

```bash
python3 {project-root}/_bmad/scripts/resolve_customization.py \
  --skill {project-root}/_bmad/skills/bmm/bmad-agent-pm \
  --key agent
```

Output JSON: merged agent config. Developer check đã merge đúng chưa.

---

## 11. Edge cases & gotchas

### 11.1 Undefined variable

```toml
persistent_facts = [
  "Always respect {undefined_variable}.",
]
```

**Behavior:** String literal. Agent sees `"Always respect {undefined_variable}."`.

**Không throw error** — intentional design để graceful degradation.

### 11.2 Circular reference

```toml
a = "{b}"
b = "{a}"
```

**Behavior:** Order-dependent, last-write-wins, có thể infinite loop nếu implementation naive.

**Best practice:** Đừng tạo circular. Resolver production nên detect và warn.

### 11.3 Case sensitivity

```
{project-root}     ≠ {PROJECT-ROOT}
{user_name}        ≠ {User_Name}
```

Tên biến **case-sensitive**.

### 11.4 Kebab vs snake

Standard: `{kebab-case}`. Nhưng BMad codebase có cả:
- `{project-root}` (kebab)
- `{user_name}` (snake)

**Resolver phải support cả hai.** Khi declare biến mới, stick to one convention.

### 11.5 Glob trong file references

```toml
persistent_facts = [
  "file:{project-root}/**/project-context.md",  # Recursive glob
  "file:{project-root}/docs/*.md",              # Single level
]
```

Resolver expand qua `glob.glob(pattern, recursive=True)`. File không tồn tại = skip silent.

### 11.6 Multi-language split

```yaml
communication_language: "Vietnamese"
document_output_language: "English"
```

Agent chat bằng tiếng Việt, nhưng PRD/stories viết tiếng Anh.

**Use case:** team Việt, product global. 

### 11.7 Read-only fields ignored silently

```toml
# _bmad/custom/bmad-agent-pm.toml
[agent]
name = "Bob"          # IGNORED — name hardcoded "John"
title = "CEO"         # IGNORED
icon = "🏥"           # Honored
```

Resolver **không throw** khi override read-only field — chỉ ignore. Developer phải biết field nào read-only (xem section 6.2).

### 11.8 Spaces in paths

```toml
"file:{project-root}/my folder/standards.md"
```

Resolver không auto-escape. Nếu pass vào shell, caller phải quote.

### 11.9 No dedup on append

```toml
# Base
principles = ["Be clear.", "Be concise."]

# Override (accidentally duplicate)
principles = ["Be clear.", "Be helpful."]

# Result (duplicates!)
principles = ["Be clear.", "Be concise.", "Be clear.", "Be helpful."]
```

Resolver **không dedup**. User phải cẩn thận.

---

## 12. Checklist để tự viết resolver

Nếu muốn implement resolver/parser riêng:

- [ ] **TOML parser** — Python 3.11+ dùng `tomllib`, hoặc `tomli`/`toml` cho older
- [ ] **project-root detection** — tìm `_bmad/` upward
- [ ] **4-level central config merge** — installer team/user + custom team/user
- [ ] **3-level skill customization merge** — skill default + custom team/user
- [ ] **Shape-based merge rules** — scalars override, tables deep merge, arrays append, keyed arrays merge by `code`/`id`
- [ ] **Keyed field detection** — ALL items phải có cùng field (code hoặc id), mixed → fallback append
- [ ] **Macro expansion** — `{project-root}`, `{skill-root}`, `{skill-name}`, `{directory_name}`, `{date}`, `{time}`, `{value}`
- [ ] **Nested variable expansion** — inside-out resolution
- [ ] **Lazy expansion** — resolve khi đọc, không precompute all
- [ ] **Glob expansion** — `file:` references với `**` support
- [ ] **Dotted-key extraction** — CLI flag `--key agent.menu` để lấy subset
- [ ] **Error handling**:
  - Missing file → skip silent
  - Parse error → warn but continue
  - Undefined variable → literal text
  - Circular reference → detect + warn (optional)
- [ ] **CLI interface**:
  ```bash
  python3 resolve_customization.py \
    --skill /path/to/skill \
    --key agent \
    --project-root /path/to/project \
    --format json
  ```
- [ ] **Output JSON với `ensure_ascii=False`** (multi-language support)
- [ ] **Tests**: unit tests cho merge edge cases (empty arrays, mixed keys, nested tables)

---

## Tài nguyên

- [src/core-skills/module.yaml](../src/core-skills/module.yaml) — Core config variables
- [src/bmm-skills/module.yaml](../src/bmm-skills/module.yaml) — BMM config variables + agent roster
- [src/core-skills/bmad-customize/](../src/core-skills/bmad-customize/) — Skill customize (xem workflow + steps)
- [tools/installer/core/config.js](../tools/installer/core/config.js) — Config builder (installer-side)
- `_bmad/scripts/resolve_customization.py` — Có trong project đã install (copy từ `src/scripts/`)

---

**Đọc tiếp:** [03-skill-anatomy-deep.md](03-skill-anatomy-deep.md) — Anatomy của skill với canonical examples.
