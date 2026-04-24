# 17. BMad Cheat Sheet - 1-Page Reference

> ⚠️ **UNOFFICIAL THIRD-PARTY DOCUMENTATION**
> NOT official BMad docs. See [DISCLAIMER.md](DISCLAIMER.md) | Licensed MIT — see [LICENSE](LICENSE) and [NOTICE](NOTICE)
> Official BMAD-METHOD: <https://github.com/bmad-code-org/BMAD-METHOD>

---

> A one-page quick reference for BMad-METHOD. Print-friendly. Stick it next to your monitor.

---

## 🏛️ 3 core concepts

| | Skill | Agent | Module |
|---|-------|-------|--------|
| **What it is** | A unit of work | A persona with a menu | A package of skills+agents |
| **File** | SKILL.md | customize.toml | module.yaml |
| **Example** | bmad-create-prd | Mary 📊 | core, bmm |

## 📋 10 architecture principles

1. Filesystem is Truth
2. Declarative > Imperative
3. Document-as-Interface
4. Micro-file Workflows
5. Sequential by Default
6. Encapsulated Skills (PATH-05)
7. Config-Driven Paths
8. Declarative Validation
9. Layered Customization
10. Human-in-the-Loop

## 👥 6 agents

| Code | Name | Role | Icon | Phase |
|------|------|------|------|-------|
| agent-analyst | Mary | Business Analyst | 📊 | 1 |
| agent-tech-writer | Paige | Tech Writer | 📚 | 1 |
| agent-pm | John | PM | 📋 | 2 |
| agent-ux-designer | Sally | UX | 🎨 | 2 |
| agent-architect | Winston | Architect | 🏗️ | 3 |
| agent-dev | Amelia | Senior Eng | 💻 | 4 |

## 🔄 4 BMM phases

```
Analysis → Planning → Solutioning → Implementation
 (brief)   (PRD)       (arch+epics)   (code+tests)
```

Each phase produces artifacts → input to the next phase.

## 📂 Project structure (after install)

```
_bmad/
├── _config/
│   ├── manifest.yaml           # Install metadata
│   ├── skill-manifest.csv      # Skills registry
│   └── files-manifest.csv      # File hashes
├── core/                        # Core skills
├── bmm/                         # BMM skills + agents
│   └── config.yaml             # Module config
├── custom/                      # Overrides
│   ├── config.toml             # Team central
│   ├── config.user.toml        # Personal central (.gitignore)
│   ├── {skill}.toml            # Team skill override
│   └── {skill}.user.toml       # Personal skill override (.gitignore)
├── scripts/
│   └── resolve_customization.py
└── config.yaml                  # Installer answers
```

## 🔧 Commands

```bash
# Install
npx bmad-method install
npx bmad-method install --modules bmm,bmb --tools claude-code --yes
npx bmad-method install --custom-source https://github.com/x/y

# Uninstall / Upgrade
npx bmad-method uninstall
npx bmad-method upgrade

# Validation
npm run validate:skills
npm run validate:skills --strict
node tools/validate-skills.js path/to/skill --json

# Quality (CI)
npm run quality

# Docs
npm run docs:build
npm run docs:dev

# Tests
npm test
```

## 📝 Skill structure

```
bmad-my-skill/
├── SKILL.md               # Required, frontmatter + body
├── workflow.md            # Logic (or inline in SKILL.md)
├── customize.toml         # Agent persona / workflow hooks
├── template.md            # Optional output template
├── checklist.md           # Optional validation
├── steps/                 # Optional micro-files
│   ├── step-01-init.md
│   └── step-02-next.md    # Sequential, 2-10 files
├── resources/             # Optional reference docs
└── agents/                # Optional sub-agent prompts
```

## 📋 SKILL.md template

```yaml
---
name: bmad-my-skill    # Match dir, regex ^bmad-[a-z0-9]+(-[a-z0-9]+)*$
description: 'Does X. Use when Y.'  # Max 1024 chars, "Use when" required
---

Follow the instructions in ./workflow.md.
```

## 🔑 Key variables

| Variable | Type | Resolve when |
|----------|------|--------------|
| `{project-root}` | System macro | On demand |
| `{planning_artifacts}` | Config | Activation |
| `{implementation_artifacts}` | Config | Activation |
| `{project_knowledge}` | Config | Activation |
| `{user_name}` | Config | Activation |
| `{communication_language}` | Config | Activation |
| `{document_output_language}` | Config | Activation |
| `{user_skill_level}` | Config | Activation |
| `{date}` / `{time}` | Macro | Lazy |
| `{story_key}`, `{spec_file}` | Runtime | Workflow state |
| `{{variable}}` (double) | Template | Execution-time |

## ⚠️ 27 Validation Rules (14 deterministic + 13 inference)

### Critical severity
- SKILL-01: SKILL.md exists
- SKILL-02: frontmatter has `name`
- SKILL-03: frontmatter has `description`
- PATH-05: No reach into other skill

### High severity
- SKILL-04: `name` regex `^bmad-[a-z0-9]+(-[a-z0-9]+)*$`
- SKILL-05: `name` matches dir
- SKILL-07: body non-empty
- WF-01/02: non-SKILL.md no name/desc
- WF-03: frontmatter vars are config/runtime only
- PATH-01: internal refs relative
- PATH-02: no `{installed_path}`
- PATH-03: external refs use config vars
- STEP-01: filename format
- STEP-02: has goal
- STEP-03: has NEXT
- STEP-04: HALT at menus
- STEP-05: no forward-load
- STEP-06: no name/desc
- STEP-07: 2-10 steps
- SEQ-01: "Invoke the skill"
- REF-01: vars defined
- REF-02: refs resolve
- REF-03: invoke language

### Medium / Low
- SKILL-06: description quality
- PATH-04: no intra-skill var paths
- SEQ-02: no time estimates

## 🎨 Menu convention

```
[A] Advanced Elicitation   → invoke bmad-advanced-elicitation
[P] Party Mode             → invoke bmad-party-mode
[C] Continue               → next step
```

## 🚦 Customization 3-level

```
Default (skill ships)        {skill-root}/customize.toml
  ↓ merge
Team (shared, committed)     _bmad/custom/{skill}.toml
  ↓ merge
User (personal, .gitignore)  _bmad/custom/{skill}.user.toml
  ↓
Final merged config
```

Merge rules:
- Scalars → override
- Arrays → append
- Array of tables with a `code` field → merge by code

## 🔨 Extension patterns

| # | Pattern | Effort |
|---|---------|--------|
| 1 | New skill | ⭐⭐ |
| 2 | New agent persona | ⭐⭐⭐ |
| 3 | New module | ⭐⭐⭐⭐ |
| 4 | Customize existing | ⭐ |
| 5 | New IDE support | ⭐⭐⭐ |
| 6 | New validation rule | ⭐⭐ |
| 7 | Sub-agent prompt | ⭐⭐⭐ |
| 8 | External module | ⭐⭐⭐⭐ |

## 🧪 Dev-story RED-GREEN-REFACTOR

```
RED:      Write FAILING tests first
GREEN:    Minimal code to pass tests
REFACTOR: Improve while keeping green
```

8-level validation gate before marking a task complete:
1. Tests EXIST
2. Tests PASS 100%
3. Implementation matches spec
4. ALL ACs satisfied
5. Full test suite passes (no regressions)
6. File List updated
7. Dev Agent Record updated
8. Review follow-ups handled

## 🎭 Party mode dialogue

```
Format: "Name (Role): dialogue"

Amelia (Developer): [facilitator question]
Alice (PO): [perspective]
Charlie (Senior Dev): [technical view]
{user_name}: [active input]
```

## ⛔ PATH-05 (critical rule)

```
❌ /absolute/path or hardcoded
❌ ~/home-relative
❌ {project-root}/_bmad/skills/OTHER-SKILL/template.md  ← reach!
✅ {planning_artifacts}/my-output.md                    ← config var
✅ Invoke the `bmad-other-skill` skill                  ← proper
```

## 📖 Deployment modes

```
Install:       Fresh setup
Update:        Reconfigure existing
Quick-update:  Refresh module files only
```

## 🔄 Phase transitions

```
Phase 1 → Phase 2: Product Brief + PRFAQ  →  PRD
Phase 2 → Phase 3: PRD + UX               →  Architecture
Phase 3 → Phase 4: Architecture + Epics   →  Stories → Code
Phase 4 → Phase 4+1: Retrospective        →  Next Epic
```

Each transition: file-based handoff, NOT memory/API.

## 🛠️ Common commands cheat

```bash
# New skill
mkdir -p src/bmm-skills/4-implementation/bmad-my-skill/steps
cat > .../SKILL.md <<'EOF'
---
name: bmad-my-skill
description: 'Does X. Use when Y.'
---
Follow ./workflow.md.
EOF
npm run validate:skills --strict

# Debug customize
python3 _bmad/scripts/resolve_customization.py \
  --skill _bmad/bmm/agents/bmad-agent-pm \
  --key agent

# Inspect skill structure
find src/bmm-skills/bmad-create-prd -type f
```

## 🚨 HALT triggers in dev-story

1. New dependencies required beyond spec
2. 3 consecutive implementation failures
3. Required configuration missing
4. Regression tests fail
5. Ambiguity in task requirements
6. File inaccessible
7. Any validation gate fails

## 📊 Stats

- **39 skills** (12 core + 27 BMM)
- **6 agents** built-in
- **27 validation rules**
- **4 phases** BMM lifecycle
- **4 IDEs** supported (Claude Code, Cursor, JetBrains, VS Code)
- **5 doc languages**

## 🎯 Quick decision tree

```
Small fix/tweak (<30 min)? → Vanilla Claude Code
Established project + bug fix? → bmad-quick-dev (QD)
New feature + team workflow? → Full BMM (phases 1-4)
Big decision needing multiple views? → bmad-party-mode
Stuck on thinking? → bmad-brainstorming
Output needs refinement? → bmad-advanced-elicitation
Large doc exceeds context? → bmad-shard-doc
```

## 🔗 Navigation

- Start: [README.md](README.md)
- Philosophy: [01-philosophy.md](01-philosophy.md)
- Anatomy: [03-skill-anatomy-deep.md](03-skill-anatomy-deep.md)
- Variables: [02-environment-and-variables.md](02-environment-and-variables.md)
- Skills catalog: [04-skills-catalog.md](04-skills-catalog.md)
- Deep skills: [09a-d](09a-skills-core-deep.md)
- Glossary: [15-glossary.md](15-glossary.md)
- FAQ: [16-faq.md](16-faq.md)
- Rewrite: [14-rewrite-blueprint.md](14-rewrite-blueprint.md)

---

**🎯 Principle to remember:** *Human Amplification, Not Replacement.*

Every BMad feature answers: "Does this make humans and AI better together?"
