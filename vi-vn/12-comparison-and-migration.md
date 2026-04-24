# 12. Comparison & Migration

> ⚠️ **UNOFFICIAL THIRD-PARTY DOCUMENTATION**
> Không phải official BMad docs. Xem [DISCLAIMER.md](DISCLAIMER.md) | Licensed MIT — xem [LICENSE](LICENSE) và [NOTICE](NOTICE)
> Official BMAD-METHOD: <https://github.com/bmad-code-org/BMAD-METHOD>

---

> Chi tiết so sánh BMad với các framework AI agent khác (code-level) + migration paths từ vanilla Claude Code sang BMad, từ v5 sang v6.

---

## Mục lục

1. [BMad vs LangGraph](#1-bmad-vs-langgraph)
2. [BMad vs CrewAI](#2-bmad-vs-crewai)
3. [BMad vs AutoGen](#3-bmad-vs-autogen)
4. [BMad vs vanilla Claude Code / Cursor](#4-bmad-vs-vanilla-claude-code--cursor)
5. [BMad vs Bazel/Make (structural)](#5-bmad-vs-bazelmake-structural)
6. [Migration: vanilla → BMad](#6-migration-vanilla--bmad)
7. [Migration: v5 → v6](#7-migration-v5--v6)
8. [Future-proofing considerations](#8-future-proofing-considerations)

---

## 1. BMad vs LangGraph

### Positioning

| | LangGraph | BMad |
|---|-----------|------|
| **Layer** | Runtime engine cho agents | Prompt framework guiding agents |
| **Target user** | ML engineers, agent developers | Product teams (PM, Architect, Dev) |
| **Language** | Python | Markdown + YAML + TOML |
| **Execution** | Python runtime | Nothing — AI reads files directly |

### LangGraph example

```python
from langgraph.graph import StateGraph, END
from typing import TypedDict

class AgentState(TypedDict):
    messages: list
    next_action: str

def analyzer_node(state: AgentState) -> AgentState:
    # Python code to analyze
    return {"messages": [...], "next_action": "designer"}

def designer_node(state: AgentState) -> AgentState:
    # Python code
    return {"messages": [...], "next_action": "dev"}

graph = StateGraph(AgentState)
graph.add_node("analyzer", analyzer_node)
graph.add_node("designer", designer_node)
graph.add_edge("analyzer", "designer")
graph.add_edge("designer", END)

app = graph.compile()
result = app.invoke({"messages": [HumanMessage(content="Build a todo app")]})
```

### BMad equivalent

```markdown
# src/bmm-skills/1-analysis/bmad-agent-analyst/SKILL.md
---
name: bmad-agent-analyst
description: '...'
---

Follow activation workflow...
```

```toml
# customize.toml
[[agent.menu]]
code = "CB"
skill = "bmad-product-brief"  # Invoke next phase
```

### Key differences

| Aspect | LangGraph | BMad |
|--------|-----------|------|
| **State management** | In-memory graph state | Filesystem files |
| **Transitions** | Explicit edges in code | File-based handoff |
| **Debug** | Python debugger, state inspection | Read output files, git diff |
| **Parallelism** | Native (async nodes) | Sequential (by design) |
| **Extensibility** | Write Python classes | Write markdown files |
| **Human-in-loop** | Explicit interrupt mechanism | Built into workflows (HALT + menu) |

### When to choose

**LangGraph:** You're building custom agentic infrastructure, need complex state transitions, have ML engineers.

**BMad:** You're building products with PM/Architect/Dev workflow, team not ML-focused, want git-native artifacts.

---

## 2. BMad vs CrewAI

### Positioning

Both: Multi-agent frameworks với roles.

### CrewAI example

```python
from crewai import Agent, Task, Crew

researcher = Agent(
    role="Senior Researcher",
    goal="Uncover cutting-edge developments",
    backstory="You are a researcher at a top tech think tank.",
    verbose=True
)

writer = Agent(
    role="Tech Content Writer",
    goal="Craft compelling tech content",
    backstory="You are a renowned Tech Content Writer."
)

research_task = Task(
    description="Investigate AI developments in Q1 2026",
    agent=researcher
)

write_task = Task(
    description="Develop an engaging article about the research",
    agent=writer,
    context=[research_task]
)

crew = Crew(
    agents=[researcher, writer],
    tasks=[research_task, write_task]
)

result = crew.kickoff()
```

### BMad equivalent

```yaml
# src/bmm-skills/module.yaml
agents:
  - code: bmad-agent-analyst
    name: Mary
    title: Business Analyst
    description: "..."
  - code: bmad-agent-tech-writer
    name: Paige
    title: Technical Writer
    description: "..."
```

```toml
# Mary's customize.toml
[[agent.menu]]
code = "DR"
skill = "bmad-domain-research"
```

### Comparison

| | CrewAI | BMad |
|---|--------|------|
| **Agent definition** | Python class với role, goal, backstory | YAML + TOML với name, title, role, identity, principles |
| **Task chaining** | `context=[prev_task]` | File-based handoff (PRD.md → architecture.md) |
| **Memory** | Agent memory (configurable) | `persistent_facts` + project-context.md |
| **Tool use** | Langchain tools | No tools; agents invoke other skills |
| **Collaboration** | Crew (all agents) runs task sequence | party-mode skill (spawn subagents) |

### When to choose

**CrewAI:** Quick multi-agent prototypes, Python codebase, LLM-native tools.

**BMad:** Structured product dev, artifact-driven workflow, team of humans + AI.

---

## 3. BMad vs AutoGen

### Positioning

**AutoGen (Microsoft):** Multi-agent conversation framework. Agents chat with each other.

### AutoGen example

```python
from autogen import AssistantAgent, UserProxyAgent, config_list_from_json

config_list = config_list_from_json("OAI_CONFIG_LIST")

assistant = AssistantAgent(
    name="assistant",
    llm_config={"config_list": config_list}
)

user_proxy = UserProxyAgent(
    name="user_proxy",
    human_input_mode="TERMINATE",
    code_execution_config={"work_dir": "coding"}
)

user_proxy.initiate_chat(
    assistant,
    message="Plot stock price of NVDA and TSLA for last month."
)
```

### BMad equivalent: party-mode

```markdown
# Invoke party-mode skill
/bmad-party-mode

User: "Should we refactor auth to OAuth?"

[Party mode spawns Winston + Amelia + John]

🏗️ **Winston:** Current API key auth has limits...
💻 **Amelia:** Implementation effort: 35 story points...
📋 **John:** From PM view, OAuth enables SSO for enterprise...
```

### Comparison

| | AutoGen | BMad party-mode |
|---|---------|-----------------|
| **Agents** | Generic AssistantAgent / UserProxyAgent | Specialized personas (Mary, John, Winston...) |
| **Conversation** | Agent ↔ Agent in a loop | Orchestrator picks 2-4 agents per round |
| **Independence** | All agents share same LLM instance | Each agent = separate subagent process |
| **Tools** | Langchain-style tool calls | No tools; pure prompt reasoning |
| **Code execution** | `UserProxyAgent` executes code | No code execution (dev agent writes, user runs) |

### Key insight

**AutoGen:** Agents talk **to each other** automatically.
**BMad:** User orchestrates, agents report **to user**.

BMad is human-centered, AutoGen is agent-centered.

### When to choose

**AutoGen:** Research into agent collaboration, automated coding, conversational AI.

**BMad:** Product development workflow, human-in-loop, artifact production.

---

## 4. BMad vs vanilla Claude Code / Cursor

### Vanilla Claude Code

```bash
claude
> Help me build a user auth feature
```

### BMad with Claude Code

```bash
claude
> /bmad-agent-pm "let's create a PRD for user auth"

📋 Hi! I'm John. Let's build a PRD together.
[12-step guided workflow...]
```

### Comparison

| | Vanilla Claude Code | BMad |
|---|---------------------|------|
| **Interaction** | Free-form chat | Structured workflows |
| **Output** | Code snippets, answers | Code + PRD + Architecture + Stories + Tests + Retrospective |
| **Agents** | None (single LLM) | 6+ named personas with personalities |
| **Persistence** | Chat history (can be lost) | Filesystem artifacts (git-tracked) |
| **Learning curve** | Minimal | 1-2 weeks to get fluent |
| **Time to value** | Immediate | Higher for small tasks, much higher for product work |

### BMad đi kèm với Claude Code

BMad **doesn't replace** Claude Code — nó **layers on top**:
- Claude Code provides: LLM, IDE integration, slash commands
- BMad provides: Workflow structure, personas, artifacts

```
User
  ↓
Claude Code (IDE UI)
  ↓
BMad skill (workflow logic)
  ↓
Claude LLM (inference)
```

### When to choose

**Vanilla Claude Code:**
- Quick prototypes
- Learning, exploration
- Solo dev, small scripts
- Familiar workflow (just type what you want)

**BMad:**
- Product development (PRD, Architecture, Stories)
- Team with PM/Architect/Dev roles
- Long-lived projects (months/years)
- Need audit trail via git

### Hybrid use case

Many teams use both:
- Vanilla Claude Code: ad-hoc fixes, exploration
- BMad: formal feature development from idea → ship

---

## 5. BMad vs Bazel/Make (structural)

Surprising comparison: BMad và Bazel/Make đều là **declarative orchestration tools**.

### Similarities

| | Bazel/Make | BMad |
|---|------------|------|
| **Declarative** | BUILD files / Makefiles | module.yaml + workflow.md |
| **File-based** | Targets produce files | Skills produce artifacts |
| **Dependency graph** | Target → dependencies | Phase → previous phase outputs |
| **Parallelism** | Parallel targets | Sequential (by design) |
| **Reproducibility** | Hermetic builds | Git-tracked artifacts |
| **Extensibility** | Rules in Starlark/rules | Skills in Markdown |

### Key difference

**Bazel/Make:** Execute deterministic actions (compile, link, test).
**BMad:** Execute LLM reasoning (analyze, design, implement).

**Same pattern, different actions.**

### Takeaway

If bạn thích Bazel/Make's declarative style, BMad's philosophy should feel familiar.

---

## 6. Migration: vanilla → BMad

Step-by-step migration path for teams currently using vanilla Claude Code/Cursor.

### Phase 1: Install + Explore (Week 1)

**Day 1-2: Install**
```bash
cd your-existing-project
npx bmad-method install
# Choose: core + bmm modules
# Choose: your IDE (Claude Code, Cursor)
# Answer prompts (user_name, language, etc.)
```

**Day 3-5: Run tutorials**
- Invoke `/bmad-help` — see what's available
- Try `/bmad-agent-analyst` → brainstorming
- Read [docs/vi-vn/bmad-developer-guide.md](../docs/vi-vn/bmad-developer-guide.md)

### Phase 2: First feature with Quick Flow (Week 2)

**Use Quick Dev path** (không qua full PRD/Architecture):

```bash
/bmad-agent-dev "build [feature description]"
# Amelia invokes bmad-quick-dev
```

5 steps: Clarify → Plan → Implement → Review → Present.

**Purpose:** Experience BMad workflow without overhead.

### Phase 3: First feature with Full Flow (Week 3-4)

```
Week 3:
  /bmad-agent-analyst → bmad-brainstorming + bmad-product-brief
  /bmad-agent-pm → bmad-create-prd
  
Week 4:
  /bmad-agent-architect → bmad-create-architecture
  /bmad-agent-pm → bmad-create-epics-and-stories
  /bmad-agent-dev → bmad-sprint-planning + bmad-dev-story
```

**Artifacts created:** brief.md, prd.md, architecture.md, epics.md, stories/*.md, code.

**Commit everything to git.** You now have full audit trail.

### Phase 4: Customize (Week 5+)

Start overriding agents to match your team:

```toml
# _bmad/custom/bmad-agent-dev.toml
[agent]
principles = [
  "Our team uses TDD strict — tests FIRST always",
  "All API endpoints require Zod validation",
]

persistent_facts = [
  "file:{project-root}/docs/coding-standards.md",
  "Vitest is the only test runner (no Jest)",
]
```

### Phase 5: Full adoption (Month 2+)

Now:
- All new features go through BMad
- Retrospectives at epic boundaries
- Sprint status as source of truth
- Code reviews via `bmad-code-review`

### Migration anti-patterns

**❌ Don't:**
- Force BMad on bugfixes (overhead not worth it)
- Skip customization (you'll fight defaults)
- Use BMad AND random chat without coordination

**✅ Do:**
- Start small (1 feature, Quick Flow)
- Customize agents for your team
- Use `/bmad-help` often
- Commit artifacts to git

---

## 7. Migration: v5 → v6

BMad v6 introduced breaking changes. Migration path for v5 users.

### Breaking changes summary

| v5 | v6 |
|---|---|
| No skills architecture | Skills architecture |
| Team-wide `.bmad/` | Per-project `_bmad/` |
| No customization system | 3-level TOML customization |
| No manifest | `_config/manifest.yaml` + CSV files |
| Manual IDE setup | `platform-codes.yaml` config-driven |
| Mixed file naming | Strict `bmad-*` naming |

### Migration steps

**Step 1: Backup current v5 install**
```bash
cp -r .bmad .bmad-v5-backup
```

**Step 2: Uninstall v5**
```bash
# v5 uninstall command (if available)
npx bmad-method@5 uninstall

# Or manually
rm -rf .bmad
```

**Step 3: Install v6**
```bash
npx bmad-method@latest install
```

**Step 4: Migrate customizations**

v5 custom agents → v6 `_bmad/custom/{agent-name}.toml`

```bash
# v5 custom agent file (example)
# .bmad-v5-backup/custom-agents/my-pm.md

# v6 equivalent
cat > _bmad/custom/bmad-agent-pm.toml <<'EOF'
[agent]
principles = [
  "[v5 customization content]"
]
EOF
```

**Step 5: Migrate custom modules**

v5 custom module structure varies. v6 requires:
- `module.yaml`
- `SKILL.md` per skill
- Compliant naming

Use `tools/migrate-custom-module-paths.js` if available.

**Step 6: Update IDE configs**

v5 IDE configs in `.claude/bmad-*` → v6 `.claude/skills/*` (auto-managed).

Let v6 installer handle it.

**Step 7: Validate**

```bash
npm run validate:skills --strict
# Fix any issues reported
```

**Step 8: Test**

Try a workflow to verify everything works:
```bash
/bmad-agent-pm "create a test PRD"
```

### What to keep from v5

**Keep:**
- Your custom module source (adapt to v6 format)
- Custom agent personality descriptions
- Project-specific context files

**Discard:**
- v5-specific path variables (e.g., `{installed_path}`)
- Old manifest format
- v5-specific IDE configs

### Compatibility checklist

Sau migration, verify:
- [ ] `npm run validate:skills --strict` passes
- [ ] `_bmad/_config/manifest.yaml` exists
- [ ] `_bmad/_config/skill-manifest.csv` exists
- [ ] Customizations from backup applied correctly
- [ ] All agents greet correctly (test `/bmad-agent-*`)
- [ ] Skill invocation works end-to-end (test `bmad-create-prd`)
- [ ] Git doesn't show unexpected changes

### Rollback plan

If migration fails:
```bash
rm -rf _bmad
mv .bmad-v5-backup .bmad
# Reinstall v5
npx bmad-method@5 install
```

---

## 8. Future-proofing considerations

BMad v6 features evolving. Patterns to future-proof your customizations.

### Upcoming features (from roadmap)

From [docs/roadmap.mdx](../docs/roadmap.mdx):

**Near-term (3-6 months):**
- **BMad Builder v1** — Create custom modules + skills interactively
- **Dev Loop Automation** — Optional autopilot (user still in control)
- **Project Context System** — Framework-aware, evolves with codebase
- **Centralized Skills** — Install once, use everywhere
- **Adaptive Skills** — Variants per LLM (Claude, Kimi, GPT-4, etc.)

**Medium-term (6-12 months):**
- **Skill Marketplace** — Discover, install, update community skills
- **Workflow Customization** — Integrate Jira, Linear, custom outputs
- **Phase 1-3 Optimization** — Lightning-fast planning + guided excellence
- **Enterprise Ready** — SSO, audit logs, team workspaces

### Future-proofing patterns

**1. Use stable APIs only**

✅ **Stable (safe to use):**
- `module.yaml` structure (code, name, agents, directories)
- `customize.toml` `[agent]` and `[workflow]` blocks
- Skill frontmatter (name, description)
- Config variable names (`{project-root}`, `{planning_artifacts}`)

⚠️ **Evolving (may change):**
- Manifest CSV format (may add columns)
- `platform-codes.yaml` schema (may add IDEs)
- Step-file architecture internals (may be replaced by DSL)

❌ **Unstable (avoid):**
- Direct filesystem access to other skills (PATH-05 violation anyway)
- Hardcoded paths (use config variables)
- Scraping internals of installer

**2. Structure customizations for portability**

```toml
# Good: lean override, additive
[agent]
principles = ["Team principle 1", "Team principle 2"]

# Bad: overrides read-only or framework internals
[agent]
name = "Custom Name"          # Ignored anyway
activation_steps_prepend = [
  "Do internal framework thing"  # Fragile
]
```

**3. Don't replace framework skills**

If you want a different behavior, create new skill (`my-org-skill`) invoke from agent menu.

❌ Don't:
```toml
# Override code "CP" with completely different skill
[[agent.menu]]
code = "CP"
skill = "my-totally-different-skill"
```

✅ Do:
```toml
# Add new code for your custom skill
[[agent.menu]]
code = "CX"
description = "Custom PRD for healthcare domain"
skill = "my-healthcare-prd"
```

**4. Use persistent_facts for org knowledge**

```toml
persistent_facts = [
  "file:{project-root}/docs/org-standards.md",  # Evolves with org
  "All code must pass SOC2 audit",  # Org-wide rule
]
```

When framework updates, your facts preserved.

**5. Version-pin in CI**

```json
{
  "devDependencies": {
    "bmad-method": "6.3.0"  // Pin exact version
  }
}
```

Prevents automatic upgrade breaking your custom setup.

### Migration strategy cho upcoming BMad Builder

When BMad Builder ships:
- Your custom skills (manually written) → migrate via Builder guided flow
- Your customizations → preserved as-is
- Your modules → adapt to Builder's module format (likely similar)

### Preparing for Skill Marketplace

When Marketplace ships:
- Publish your org's skills if generic enough
- Use community skills for common patterns (compliance, security, testing)
- Contribute back fixes/improvements

---

## Summary

### BMad's unique positioning

BMad is **uniquely positioned** as:
- **Not a runtime** (like LangGraph) — no code execution
- **Not a quick-start** (like vanilla Claude Code) — structured workflow
- **Not agent-to-agent** (like AutoGen) — human-centered
- **Not template generator** (like Yeoman) — ongoing workflow

**Closest analog:** Bazel/Make nhưng cho AI reasoning instead of compilation.

### When to use what

| Use case | Best fit |
|----------|----------|
| ML engineering, custom agentic infra | LangGraph |
| Multi-agent research | AutoGen |
| Quick prototypes | CrewAI |
| Ad-hoc coding help | Vanilla Claude Code |
| Team product development | **BMad** |
| Agile teams with PM/Architect/Dev | **BMad** |
| Long-lived projects needing audit | **BMad** |

### Migration principles

1. **Start small** — 1 feature, Quick Flow
2. **Customize incrementally** — don't fight defaults day 1
3. **Preserve your work** — backup before migration
4. **Use stable APIs** — avoid framework internals
5. **Contribute back** — share customizations with community

---

**Đọc tiếp:** [13-operational-runbook.md](13-operational-runbook.md) — Release process, troubleshooting, security.
