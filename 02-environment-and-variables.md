# 02. Environment Variables, Config & Customization

> ⚠️ **UNOFFICIAL THIRD-PARTY DOCUMENTATION**
> NOT official BMad docs. See [DISCLAIMER.md](DISCLAIMER.md) | Licensed MIT — see [LICENSE](LICENSE) and [NOTICE](NOTICE)
> Official BMAD-METHOD: <https://github.com/bmad-code-org/BMAD-METHOD>

---

> A DETAILED specification of BMad's variable system: config variables, runtime variables, macros, the resolve mechanism, and 3/4-level customization. Detailed enough to write your own parser/resolver.

---

## Table of Contents

1. [Overview of the variable system](#1-overview-of-the-variable-system)
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
12. [Checklist to write your own resolver](#12-checklist-to-write-your-own-resolver)

---

## 1. Overview of the variable system

BMad has **4 tiers of variables** resolved at different points in time:

```
┌─────────────────────────────────────────────────────────┐
│ TIER 4: Runtime variables (workflow-specific)           │
│   {story_key}, {spec_file}, {epic_num}, ...             │
│   Source: generated during execution                    │
└─────────────────────────────────────────────────────────┘
                         ▲
┌─────────────────────────────────────────────────────────┐
│ TIER 3: System macros                                   │
│   {project-root}, {skill-root}, {date}, {time}, {value} │
│   Source: system computed                               │
└─────────────────────────────────────────────────────────┘
                         ▲
┌─────────────────────────────────────────────────────────┐
│ TIER 2: Config variables (loaded at activation)         │
│   {user_name}, {planning_artifacts}, {project_name}...  │
│   Source: _bmad/config.yaml (from module.yaml prompts)  │
└─────────────────────────────────────────────────────────┘
                         ▲
┌─────────────────────────────────────────────────────────┐
│ TIER 1: Customization overrides (skill-level)           │
│   Agent persona, menu, principles, persistent_facts     │
│   Source: _bmad/custom/*.toml (3-level merge)           │
└─────────────────────────────────────────────────────────┘
```

**General rules:**
- Higher tiers **can reference** lower tiers
- Unresolved `{var}` = **literal text** (no error, no empty string)
- Kebab-case is the standard: `{planning-artifacts}`, not `{PLANNING_ARTIFACTS}`

---

## 2. Config variables (Module-level)

Config variables are **declared in `module.yaml`**, **the user answers at install time**, and **they are stored in `_bmad/config.yaml`**.

### 2.1 Core Module Variables

From [src/core-skills/module.yaml](../src/core-skills/module.yaml):

| Variable | Scope | Prompt | Default | Result Template | Meaning |
|------|-------|--------|---------|-----------------|---------|
| `user_name` | user | "What should agents call you?" | `"BMad"` | `{value}` | User/team name; agents use it to address you |
| `communication_language` | user | "What language should agents use when chatting?" | `"English"` | `{value}` | The language agents **speak** in |
| `document_output_language` | (none) | "Preferred document output language?" | `"English"` | `{value}` | The language of **output files** |
| `output_folder` | (none) | "Where should output files be saved?" | `"_bmad-output"` | `{project-root}/{value}` | Root for all outputs |

### 2.2 BMM Module Variables

From [src/bmm-skills/module.yaml](../src/bmm-skills/module.yaml):

| Variable | Scope | Prompt | Default | Result Template | Meaning |
|------|-------|--------|---------|-----------------|---------|
| `project_name` | (none) | "What is your project called?" | `{directory_name}` | `{value}` | Project name |
| `user_skill_level` | user | "What is your development experience level?" | `"intermediate"` | `{value}` | beginner/intermediate/expert (affects how things are explained) |
| `planning_artifacts` | (none) | "Where should planning artifacts be stored?" | `{output_folder}/planning-artifacts` | `{project-root}/{value}` | Phase 1-3 outputs |
| `implementation_artifacts` | (none) | "Where should implementation artifacts be stored?" | `{output_folder}/implementation-artifacts` | `{project-root}/{value}` | Phase 4 outputs |
| `project_knowledge` | (none) | "Where should long-term project knowledge be stored?" | `"docs"` | `{project-root}/{value}` | Long-lived knowledge (tech stack, standards) |

**Inherited from Core:** BMM automatically inherits `user_name`, `communication_language`, `document_output_language`, `output_folder`.

### 2.3 Prompt field structure

Each config variable in `module.yaml` has this schema:

```yaml
<variable_name>:
  prompt: "Question to the user"       # String or array (multi-line)
  scope: user                          # Optional: "user" (per-user) or default (team)
  default: "default value"             # May use macros such as {directory_name}
  result: "final template"             # How the final value is computed from {value}
  single-select:                       # Optional: choose from a list
    - value: "beginner"
      label: "Beginner - Explain things clearly"
    - value: "intermediate"
      label: "Intermediate - Balance detail with speed"
    - value: "expert"
      label: "Expert - Be direct and technical"
```

**Scope:**
- `user`: written to `_bmad/config.user.toml` (personal, gitignored)
- (default): written to `_bmad/config.toml` (team, committed)

**Result template explained:**

```yaml
planning_artifacts:
  prompt: "Where should planning artifacts be stored?"
  default: "{output_folder}/planning-artifacts"
  result: "{project-root}/{value}"
```

Resolve flow:
```
1. Expand default:     "{output_folder}/planning-artifacts"
                    →  "_bmad-output/planning-artifacts"

2. User accepts the default or types something else. Assume the user keeps the default:
   {value} = "_bmad-output/planning-artifacts"

3. Apply the result template: "{project-root}/{value}"
                            → "/home/alice/project/_bmad-output/planning-artifacts"

4. Write to config.yaml:
   planning_artifacts: "/home/alice/project/_bmad-output/planning-artifacts"
```

### 2.4 Module yaml - other sections

```yaml
# code and name - module identity
code: bmm
name: "BMad Method Agile-AI Driven-Development"
description: "AI-driven agile development framework"
default_selected: true              # Auto-check on install

# header / subheader - shown in the installer UI
header: "BMad Core Configuration"
subheader: "Configure the core settings..."

# directories - created by the installer
directories:
  - "{planning_artifacts}"
  - "{implementation_artifacts}"
  - "{project_knowledge}"

# agents - agent roster for the module
agents:
  - code: bmad-agent-pm
    name: John
    title: Product Manager
    icon: "📋"
    team: software-development
    description: "Drives Jobs-to-be-Done..."

# post-install-notes - displayed after install
post-install-notes: |
  Thank you for choosing BMM...
```

---

## 3. Runtime variables

Unlike config variables (available at activation), runtime variables are **produced during execution**.

### 3.1 Categories

| Category | Example | Source | Lifecycle |
|------|-------|--------|-----------|
| **Workflow state** | `{status}`, `{story_key}`, `{current_step}` | Set by workflow logic | Per-execution |
| **Runtime user input** | `{story_path}`, `{spec_file}` | User types into a prompt | Per-execution |
| **File system discovery** | `{latest_prd}`, `{sprint_status_summary}` | Workflow scans files | Per-execution |
| **Computed** | `{story_key}` from a filename, `{acceptance_status}` from parsing | Derived by logic | Per-execution |

### 3.2 Declaring a runtime variable

In `workflow.md` frontmatter:

```yaml
---
context_file: ''                    # Optional, user provides at invocation
spec_file: ''                       # Optional
story_path: ''                      # Runtime, may be empty initially
---
```

Rule WF-03: frontmatter variables in workflow.md must be one of:
- A config variable reference (e.g., `{planning_artifacts}`)
- Empty or a placeholder (runtime will fill)
- A legitimate external path

**NOT allowed:** a hardcoded path or a path into another skill (PATH-05).

### 3.3 Runtime vars example in `bmad-dev-story`

```yaml
# workflow.md frontmatter
---
story_path: ''
---
```

During execution:
```xml
<check if="{{story_path}} is provided">
  <action>Use {{story_path}} directly</action>
</check>

<check if="{{sprint_status}} file exists">
  <action>Parse development_status to find story_key</action>
  <action>Store {{story_key}} for later</action>
</check>
```

**Syntax note:**
- `{config_var}` — single curly = config/runtime variable
- `{{runtime_var}}` — double curly = template placeholder (XML-style, used inside workflow steps)

The two syntaxes differ and the resolver distinguishes between them:
- `{}`: resolved by the config merger
- `{{}}`: resolved at execution time by the workflow engine (i.e., the LLM as it reads)

### 3.4 The common runtime-var "universe"

These are variables that appear in many skills:

| Variable | Meaning | Appears in |
|------|---------|-----------------|
| `{date}` | Current date, MM-DD-YYYY | Every workflow output file |
| `{time}` | Current time, HH:MM | Brainstorming, session logs |
| `{story_key}` | e.g. "1-2-user-auth" | dev-story, create-story, sprint-* |
| `{story_file}`, `{story_path}` | Full path to the story file | dev-story, code-review |
| `{spec_file}` | Path to the spec file | Quick-dev, correct-course |
| `{epic_num}` | Epic number | Sprint planning, retrospective |
| `{current_status}` | Current status of the story | dev-story |
| `{resolved_review_items}` | Review items already handled | dev-story (review continuation) |
| `{pending_review_items}` | Review items not yet handled | dev-story |
| `{sprint_status_summary}` | Summary of sprint status | sprint-status, dev-story |

**There is no official list** — each skill declares the variables it needs.

---

## 4. System macros

Macros are variables **computed by the system** and are always available.

### 4.1 Full list

| Macro | Resolution | Example |
|-------|-------------|-------|
| `{project-root}` | Walks up from cwd to find the directory containing `_bmad/` or `.git/` | `/home/alice/project` |
| `{skill-root}` | Path of the currently executing skill | `/home/alice/project/_bmad/skills/bmm/bmad-create-prd` |
| `{skill-name}` | Basename of the skill directory | `bmad-create-prd` |
| `{directory_name}` | Basename of `{project-root}` | `project` |
| `{date}` | System date, formatted `MM-DD-YYYY` | `04-24-2026` |
| `{time}` | System time, formatted `HH:MM` | `14:30` |
| `{value}` | User input for the current prompt | (contextual) |

**There are no other macros.** If a workflow needs to compute something else, it must use runtime logic (the XML `<action>` tag).

### 4.2 project-root detection

Logic in `tools/installer/project-root.js`:

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

### 4.3 Using macros in templates

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

When a skill activates, the resolver runs 5 steps:

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
│   When reading a workflow/step, replace {var} with value│
│   {undefined} → literal text (no error)                 │
└─────────────────────────────────────────────────────────┘
```

### 5.2 Lazy vs Eager expansion

- **Config variables**: eager (fully resolved at activation)
- **Runtime variables**: lazy (resolved when the step that uses them executes)
- **Macros**: lazy for `{date}`/`{time}` (every read), eager for `{project-root}` (cached)

### 5.3 Nested variable expansion

Templates may be nested:

```yaml
planning_artifacts:
  default: "{output_folder}/planning-artifacts"    # Uses macro
  result: "{project-root}/{value}"                 # Uses macro + {value}
```

The resolver expands **inside-out**:
```
"{project-root}/{value}"
  → {value} = "{output_folder}/planning-artifacts"
  → expand {output_folder} = "_bmad-output"
  → "{project-root}/_bmad-output/planning-artifacts"
  → {project-root} = "/home/alice/project"
  → "/home/alice/project/_bmad-output/planning-artifacts"
```

### 5.4 Python resolver - implementation idea

```python
def deep_merge(base, override):
    """Merge by shape, NOT by field name."""
    if isinstance(base, dict) and isinstance(override, dict):
        result = dict(base)
        for key, val in override.items():
            if key in result:
                result[key] = deep_merge(result[key], val)
            else:
                result[key] = val
        return result
    
    if isinstance(base, list) and isinstance(override, list):
        # Detect keyed merge: all items in BOTH lists share the same key
        keyed_field = detect_keyed_field(base + override)
        if keyed_field:
            return merge_by_key(base, override, keyed_field)
        else:
            return base + override  # Append
    
    # Scalar: override wins
    return override


def detect_keyed_field(items):
    """Returns 'code' or 'id' if ALL items have it. Else None."""
    if not items:
        return None
    for candidate in ['code', 'id']:
        if all(isinstance(item, dict) and item.get(candidate) is not None 
               for item in items):
            return candidate
    return None


def merge_by_key(base, override, key_field):
    """Merge arrays by key field. Matching keys replace, new keys append."""
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

This is the idea behind `_bmad/scripts/resolve_customization.py` in an installed project.

---

## 6. customize.toml - Anatomy

The `customize.toml` file defines the persona, menu, and hooks of an agent or workflow.

### 6.1 Full schema

```toml
# ====================================================
# AGENT BLOCK (for skills playing the role of an agent such as bmad-agent-pm)
# ====================================================
[agent]
# --- Read-only (hardcoded, overrides ignored) ---
name = "John"
title = "Product Manager"

# --- Configurable scalars (override wins) ---
icon = "📋"
role = "Product manager driven PRD creation..."
identity = "Drives Jobs-to-be-Done over template filling..."
communication_style = "Detective interrogating a cold case..."

# --- Append arrays (team + user append onto defaults) ---
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
# WORKFLOW BLOCK (for non-agent skills)
# ====================================================
[workflow]
activation_steps_prepend = [
  "Check if user has current story context.",
]
activation_steps_append = []

persistent_facts = [
  "file:{project-root}/**/project-context.md",
]

# Scalar: a hook that runs after the workflow completes
on_complete = "Suggest running code-review next."
```

### 6.2 Section-by-section explanation

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
| `persistent_facts` | array of strings | ❌ | **Append**, supports `file:` prefix |
| `activation_steps_prepend` | array of strings | ❌ | **Append** |
| `activation_steps_append` | array of strings | ❌ | **Append** |
| `[[agent.menu]]` | array of tables | ❌ | **Merge by `code`** |

**`[[agent.menu]]` entry:**

```toml
[[agent.menu]]
code = "XX"          # Required, unique within the skill
description = "..."  # Required
skill = "bmad-..."   # Either skill OR prompt, not both
# OR
prompt = "Ask user: What is your..."  # Custom prompt instead of invoking a skill
```

**`[workflow]` block:**

| Field | Type | Merge rule |
|-------|------|-----------|
| `activation_steps_prepend` | array | Append |
| `activation_steps_append` | array | Append |
| `persistent_facts` | array | Append |
| `on_complete` | string | Override |

### 6.3 `persistent_facts` with the `file:` prefix

```toml
persistent_facts = [
  "Always estimate in story points, not hours.",  # Literal fact
  "file:{project-root}/**/project-context.md",    # File glob
  "file:{project-root}/docs/standards/*.md",      # Folder glob
  "file:{project-root}/CONTRIBUTING.md",           # Single file
]
```

The resolver expands the glob, loads the contents, and concatenates the results as facts. Missing files are skipped silently.

### 6.4 Override file — deltas only

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

Result after merge:
- `icon` = `"🏥"` (overridden)
- `title`, `name` = unchanged (read-only)
- `principles` = base + `["Healthcare compliance first."]` (appended)
- Menu `CP` replaced with "Create HIPAA-aware PRD" + custom skill

---

## 7. 3-level customization system

### 7.1 The layers

```
┌─────────────────────────────────────────────────────────┐
│ Level 1: DEFAULT                                        │
│   {skill-root}/customize.toml                           │
│   Shipped with the skill, read-only (overwritten on update) │
└─────────────────────────────────────────────────────────┘
                         ▼
┌─────────────────────────────────────────────────────────┐
│ Level 2: TEAM                                           │
│   {project-root}/_bmad/custom/{skill-name}.toml         │
│   Committed to git, shared across the team              │
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

The resolver applies the layers top-down:
1. Load Level 1 → base config
2. Deep-merge Level 2 into the base
3. Deep-merge Level 3 into the result
4. Return final

**User overrides always beat team, team beats default.**

### 7.3 When to use which level

| Use case | Level | File |
|----------|-------|------|
| Framework-shipped default persona | Level 1 | skill customize.toml |
| Team adds compliance rules | Level 2 | `{skill}.toml` |
| Team renames an icon | Level 2 | `{skill}.toml` |
| Team adds a new menu item | Level 2 | `{skill}.toml` |
| Alice prefers a Vietnamese agent | Level 3 | `{skill}.user.toml` |
| Bob adds a personal shortcut | Level 3 | `{skill}.user.toml` |

### 7.4 Git strategy

```gitignore
# .gitignore
_bmad/custom/*.user.toml
_bmad/config.user.toml
```

Team files (`.toml`) are committed → shared convention.
User files (`.user.toml`) are gitignored → private.

---

## 8. 4-level central config

Unlike skill-level (3-level), **central config** (agent identities, install answers) uses **4 levels**:

```
┌─────────────────────────────────────────────────────────┐
│ Level 1: INSTALLER TEAM ANSWERS                         │
│   {project-root}/_bmad/config.toml                      │
│   From module.yaml prompts with non-user scope          │
└─────────────────────────────────────────────────────────┘
                         ▼
┌─────────────────────────────────────────────────────────┐
│ Level 2: INSTALLER USER ANSWERS                         │
│   {project-root}/_bmad/config.user.toml                 │
│   From prompts with scope: user (user_name, user_skill_level)  │
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

**Note:** Central config is only used for identity/roster. Skill-level customization is still 3-level.

### 8.1 Central config example

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

[agents.security_bot]           # Add a new agent
code = "security-bot"
name = "Sentinel"
title = "Security Specialist"
icon = "🛡️"
```

```toml
# _bmad/custom/config.user.toml (Level 4 - personal)
[core]
user_name = "Alice"              # Override the install answer

[agents.kirk]                    # Add a personal fun agent
code = "kirk"
name = "Captain Kirk"
icon = "🖖"
```

---

## 9. Merge semantics (deep dive)

### 9.1 Shape-based rules (NOT field-name-based)

The resolver does NOT know which field appends vs overrides. It decides based on **shape (data type)**:

| Shape | Rule |
|-------|------|
| Scalar (string, int, bool, float) | Override replaces |
| Table (dict) | Deep recursive merge |
| Array of tables where ALL items share a `code` field | **Keyed merge** (replace by code, append new) |
| Array of tables where ALL items share an `id` field | **Keyed merge** (replace by id, append new) |
| Any other array | **Append** (no dedup) |

### 9.2 Detection logic

```python
def detect_keyed_field(items):
    # items must be a list of dicts
    if not all(isinstance(x, dict) for x in items):
        return None
    
    # Check: do ALL items have 'code'?
    if all(x.get('code') is not None for x in items):
        return 'code'
    
    # Check: do ALL items have 'id'?
    if all(x.get('id') is not None for x in items):
        return 'id'
    
    # Mixed or neither → append
    return None
```

**Critical:** If the base has items with `code` but an override item lacks `code` → falls back to append. The base is kept as-is and the new item is added at the end.

### 9.3 Illustrations

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
code = "Y"                    # Matches base → replace
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

### 9.4 No removal mechanism

**You CANNOT delete a menu item via override.** Workaround:

```toml
# Base has menu code "BP"
# Override to "disable" it:
[[agent.menu]]
code = "BP"
description = "[Disabled]"
prompt = "This option is not available in your team's config."
```

---

## 10. bmad-customize skill flow

The `bmad-customize` skill guides a user to write override files **without needing to know TOML**.

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
  Output: List of skills + has_team_override + has_user_override flags
           ↓
Step 3: Determine surface
  - [agent] block? (persona, menu)
  - [workflow] block? (hooks, facts)
           ↓
Step 4: Compose override
  User speaks in plain English; AI translates to TOML
  Apply the merge semantics correctly
           ↓
Step 5: Team or user placement
  Is the override committed team-level or personal?
           ↓
Step 6: Show, confirm, write, verify
  1. Display the TOML about to be written
  2. User confirms
  3. Write the file
  4. Run resolve_customization.py to verify
  5. Show the merged result
```

### 10.2 Scope v1 (current)

**Covered:**
- Per-skill agent overrides
- Per-skill workflow overrides
- Team vs user placement

**Out of scope:**
- Central config (`_bmad/custom/config.toml`)
- Step logic changes (need `bmad-builder`)
- Ordering changes

### 10.3 Verify command

```bash
python3 {project-root}/_bmad/scripts/resolve_customization.py \
  --skill {project-root}/_bmad/skills/bmm/bmad-agent-pm \
  --key agent
```

Output JSON: the merged agent config. The developer checks that the merge is correct.

---

## 11. Edge cases & gotchas

### 11.1 Undefined variable

```toml
persistent_facts = [
  "Always respect {undefined_variable}.",
]
```

**Behavior:** Literal string. The agent sees `"Always respect {undefined_variable}."`.

**No error is thrown** — this is an intentional design choice for graceful degradation.

### 11.2 Circular reference

```toml
a = "{b}"
b = "{a}"
```

**Behavior:** Order-dependent, last-write-wins; may loop forever in a naive implementation.

**Best practice:** Don't create cycles. A production resolver should detect and warn.

### 11.3 Case sensitivity

```
{project-root}     ≠ {PROJECT-ROOT}
{user_name}        ≠ {User_Name}
```

Variable names are **case-sensitive**.

### 11.4 Kebab vs snake

Standard: `{kebab-case}`. But the BMad codebase has both:
- `{project-root}` (kebab)
- `{user_name}` (snake)

**The resolver must support both.** When declaring a new variable, stick to one convention.

### 11.5 Globs in file references

```toml
persistent_facts = [
  "file:{project-root}/**/project-context.md",  # Recursive glob
  "file:{project-root}/docs/*.md",              # Single level
]
```

The resolver expands via `glob.glob(pattern, recursive=True)`. Missing files = silently skipped.

### 11.6 Multi-language split

```yaml
communication_language: "Vietnamese"
document_output_language: "English"
```

The agent chats in Vietnamese, but the PRD/stories are written in English.

**Use case:** Vietnamese team, global product.

### 11.7 Read-only fields silently ignored

```toml
# _bmad/custom/bmad-agent-pm.toml
[agent]
name = "Bob"          # IGNORED — name is hardcoded as "John"
title = "CEO"         # IGNORED
icon = "🏥"           # Honored
```

The resolver **doesn't throw** when a read-only field is overridden — it just ignores. The developer has to know which fields are read-only (see section 6.2).

### 11.8 Spaces in paths

```toml
"file:{project-root}/my folder/standards.md"
```

The resolver does not auto-escape. If passed to a shell, the caller must quote it.

### 11.9 No dedup on append

```toml
# Base
principles = ["Be clear.", "Be concise."]

# Override (accidentally duplicate)
principles = ["Be clear.", "Be helpful."]

# Result (duplicates!)
principles = ["Be clear.", "Be concise.", "Be clear.", "Be helpful."]
```

The resolver **does not dedup**. Be careful.

---

## 12. Checklist to write your own resolver

If you want to implement your own resolver/parser:

- [ ] **TOML parser** — Python 3.11+ uses `tomllib`, or `tomli`/`toml` for older versions
- [ ] **project-root detection** — walk upward looking for `_bmad/`
- [ ] **4-level central config merge** — installer team/user + custom team/user
- [ ] **3-level skill customization merge** — skill default + custom team/user
- [ ] **Shape-based merge rules** — scalars override, tables deep merge, arrays append, keyed arrays merge by `code`/`id`
- [ ] **Keyed field detection** — ALL items must share the same field (code or id); mixed → fall back to append
- [ ] **Macro expansion** — `{project-root}`, `{skill-root}`, `{skill-name}`, `{directory_name}`, `{date}`, `{time}`, `{value}`
- [ ] **Nested variable expansion** — inside-out resolution
- [ ] **Lazy expansion** — resolve on read, don't precompute everything
- [ ] **Glob expansion** — `file:` references with `**` support
- [ ] **Dotted-key extraction** — CLI flag `--key agent.menu` to fetch a subset
- [ ] **Error handling**:
  - Missing file → skip silently
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
- [ ] **Output JSON with `ensure_ascii=False`** (multi-language support)
- [ ] **Tests**: unit tests for merge edge cases (empty arrays, mixed keys, nested tables)

---

## Resources

- [src/core-skills/module.yaml](../src/core-skills/module.yaml) — Core config variables
- [src/bmm-skills/module.yaml](../src/bmm-skills/module.yaml) — BMM config variables + agent roster
- [src/core-skills/bmad-customize/](../src/core-skills/bmad-customize/) — The customize skill (see workflow + steps)
- [tools/installer/core/config.js](../tools/installer/core/config.js) — Config builder (installer side)
- `_bmad/scripts/resolve_customization.py` — Present in installed projects (copied from `src/scripts/`)

---

**Read next:** [03-skill-anatomy-deep.md](03-skill-anatomy-deep.md) — the anatomy of a skill with canonical examples.
