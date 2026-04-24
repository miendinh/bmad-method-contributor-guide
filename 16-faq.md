# 16. FAQ - Frequently Asked Questions for Developers

> ⚠️ **UNOFFICIAL THIRD-PARTY DOCUMENTATION**
> NOT official BMad docs. See [DISCLAIMER.md](DISCLAIMER.md) | Licensed MIT — see [LICENSE](LICENSE) and [NOTICE](NOTICE)
> Official BMAD-METHOD: <https://github.com/bmad-code-org/BMAD-METHOD>

---

> 40+ frequently asked questions for developing on and contributing to BMAD-METHOD. Written for both new devs and those already familiar with the framework.

---

## Table of Contents

- [A. Getting started](#a-getting-started)
- [B. Skill development](#b-skill-development)
- [C. Agent customization](#c-agent-customization)
- [D. Config & variables](#d-config--variables)
- [E. Validation & quality](#e-validation--quality)
- [F. Testing](#f-testing)
- [G. Contributing](#g-contributing)
- [H. Troubleshooting](#h-troubleshooting)
- [I. Advanced topics](#i-advanced-topics)

---

## A. Getting started

### Q1: I'm just starting with this documentation. Which file should I read first?

It depends on your goal:

| Goal | Starting point |
|----------|----------------|
| Get a general understanding of the framework | [01-philosophy.md](01-philosophy.md) → [05-flows-and-diagrams.md](05-flows-and-diagrams.md) |
| Write your first skill | [03-skill-anatomy-deep.md](03-skill-anatomy-deep.md) → [07-extension-patterns.md](07-extension-patterns.md) §2 |
| Customize for your team | [02-environment-and-variables.md](02-environment-and-variables.md) §7 → [07 §5](07-extension-patterns.md) |
| Contribute to the framework | [06-installer-internals.md](06-installer-internals.md) → [08-installer-code-level-spec.md](08-installer-code-level-spec.md) |
| Rewrite in another language | [14-rewrite-blueprint.md](14-rewrite-blueprint.md) |

See [README.md](README.md) for detailed reading paths.

### Q2: How is BMad different from vanilla Claude Code?

BMad is a **layer on top of** Claude Code, not a replacement. BMad provides:
- Structured workflows (not free-form chat)
- Named agent personas (not a single "AI assistant")
- Artifact-driven development (PRD → Architecture → Stories → Code)
- Git-tracked documentation
- Multi-agent collaboration (party mode)

Details: [12-comparison-and-migration.md §4](12-comparison-and-migration.md)

### Q3: I only want to fix a small bug. Do I need BMad?

**No.** BMad is optimized for:
- Feature development (PRD → Implementation)
- Teams with PM/Architect/Dev roles
- Long-lived projects

**Use Quick Dev** (`bmad-quick-dev`) if BMad is already installed and you want a fast flow.
**Or skip BMad** for work under 30 minutes.

### Q4: What LLM does BMad require?

BMad is a prompt framework — it works with any LLM that supports the Skills standard. Tested on:
- Claude (Sonnet, Opus, Haiku) via Claude Code
- Cursor (with the Claude backend)
- Others: VSCode extensions, JetBrains (configurable)

Best quality is with Claude Sonnet/Opus.

### Q5: Can I use BMad offline?

**No.** BMad relies on an LLM API. Local LLMs (Llama, Mistral) may work if they:
- Support the Skills standard
- Have a context window of ≥ 32k tokens
- Have good instruction-following quality

Not currently tested.

---

## B. Skill development

### Q6: Where do I start when creating a new skill?

1. Read [03-skill-anatomy-deep.md](03-skill-anatomy-deep.md) (anatomy)
2. Read a [09a-skills-core-deep.md](09a-skills-core-deep.md) example (a similar skill)
3. Follow [07 §2 Pattern 1](07-extension-patterns.md)
4. Validate with `npm run validate:skills`

### Q7: Where does a skill need to live?

```
src/
├── core-skills/        # Cross-phase utilities
└── bmm-skills/
    ├── 1-analysis/     # Phase 1 skills
    ├── 2-plan-workflows/
    ├── 3-solutioning/
    └── 4-implementation/
```

Pick the location based on phase logic. Cross-phase → `core-skills/`.

### Q8: What must SKILL.md contain?

Required:
```yaml
---
name: bmad-my-skill      # Must match dir name, regex ^bmad-[a-z0-9]+(-[a-z0-9]+)*$
description: 'Does X. Use when Y.'  # Must include a "Use when" clause
---

Follow the instructions in ./workflow.md.
```

Shorter: you can inline the logic in SKILL.md for a simple skill (<100 lines).

### Q9: When should I use micro-file (steps/) vs. inline XML?

| Use micro-file | Use inline XML |
|-----------------|-----------------|
| > 3 phases with branching | Linear flow, 2-3 steps |
| User control at each step | Continuous execution |
| State tracked via frontmatter | Ephemeral state |
| Reusable sub-steps | Single-use logic |
| Example: brainstorming, create-prd | Example: dev-story, create-story |

### Q10: What's the maximum line count for a step file?

**~2-5KB per step** (~50-150 lines). Rule STEP-07: total of 2-10 steps.

If a step is too long → split into branches (step-02a, step-02b).
If there are too many steps (>10) → split the skill.

### Q11: How does my skill invoke another skill?

**Option 1: Via agent menu** (recommended for user-facing):
```toml
# customize.toml
[[agent.menu]]
code = "XX"
description = "..."
skill = "bmad-other-skill"
```

**Option 2: Text invocation** inside a workflow:
```markdown
## Step 03: Run advanced elicitation
Invoke the `bmad-advanced-elicitation` skill to refine output.
Then return here for step-04.
```

**Rule REF-03:** You must use the word "Invoke" (not "execute", "run", "load").

### Q12: My skill has data files (.csv, .yaml) — how do I load them?

Put them in the same skill folder and reference them relatively:

```
bmad-my-skill/
├── SKILL.md
├── workflow.md
└── my-data.csv
```

In the workflow:
```markdown
Load `./my-data.csv` (relative to skill root).
```

Do NOT hardcode paths or use `{installed_path}`.

### Q13: Does a workflow need approval or review before merging?

**Yes.** CONTRIBUTING.md requires:
- A Discord discussion first if the feature is large (> 200 LOC)
- Ideal PR size of 200-400, max 800 LOC
- One feature/fix per PR
- Must pass `npm run quality`

---

## C. Agent customization

### Q14: How do I change an agent's persona (e.g., Mary's icon)?

Create an override file:
```toml
# _bmad/custom/bmad-agent-analyst.toml
[agent]
icon = "🔍"  # New icon
```

Run the verifier:
```bash
python3 _bmad/scripts/resolve_customization.py --skill _bmad/bmm/agents/bmad-agent-analyst --key agent
```

### Q15: I want to add principles to an agent — how?

Arrays **append** inside the override:
```toml
# _bmad/custom/bmad-agent-dev.toml
[agent]
principles = [
  "TDD is non-negotiable",
  "All commits must pass CI",
]
```

Result: base principles + the 2 new ones. (It does not override the base.)

### Q16: How do I change an agent's menu code?

Match by the `code` field:
```toml
[[agent.menu]]
code = "DS"                    # Matches the base's DS
description = "Strict TDD story implementation"  # Overrides description
skill = "bmad-dev-story"       # Keep the same skill or point to a new one
```

### Q17: Can I delete a menu item?

**There's no remove mechanism.** Workaround: override it to be a no-op:
```toml
[[agent.menu]]
code = "BP"
description = "[Disabled — use external tool]"
prompt = "This option is not available in your team's config. Use external brainstorming tool."
```

### Q18: How do I create a completely new custom agent?

Add it to `_bmad/custom/config.toml`:
```toml
[agents.bmad-agent-security]
code = "bmad-agent-security"
name = "Sam"
title = "Security Expert"
icon = "🛡️"
team = "security"
description = "Threat modeling + OWASP rigor..."
```

Then create a skill folder `bmad-agent-security/` with a detailed `customize.toml`.

### Q19: Override scope — team vs. user?

| Scope | File | Git | Use case |
|-------|------|-----|----------|
| **Team** | `_bmad/custom/{skill}.toml` | Committed | Org policy, team convention |
| **User** | `_bmad/custom/{skill}.user.toml` | Gitignored | Personal preference |

User override wins over team override (precedence: user > team > default).

---

## D. Config & variables

### Q20: Why use `{planning_artifacts}` instead of a hardcoded `docs/`?

**Multi-user flexibility:** Alice stores things in `docs/`, Bob in `planning/`. Both use the same skill; each has their own config.

The installer prompts the user during install and stores answers in `_bmad/config.yaml`.

### Q21: Where do `{var}` references resolve?

3 layers:
1. **Config variable** (from `_bmad/config.yaml`) → resolved at activation
2. **System macro** (`{project-root}`, `{date}`) → resolved on use
3. **Runtime variable** (`{story_key}`) → set during workflow execution

Details: [02-environment-and-variables.md §5](02-environment-and-variables.md)

### Q22: What's the difference between `{var}` and `{{var}}`?

- `{var}` single-brace — resolved by the config merger (install-time or activation-time)
- `{{var}}` double-brace — a template placeholder, resolved at runtime by the workflow engine

Example:
```markdown
File output: {planning_artifacts}/prd-{{date}}.md
#                                    ↑ runtime (today's date)
#             ↑ config
```

### Q23: What happens if a variable isn't defined?

**Literal text.** `{undefined_var}` is not replaced; the agent sees the exact string `"{undefined_var}"`.

It doesn't throw an error, and it doesn't become an empty string. Graceful degradation.

### Q24: Multi-language: AI chats in Vietnamese but outputs in English — how?

```yaml
# _bmad/config.yaml
communication_language: Vietnamese
document_output_language: English
```

The agent speaks Vietnamese, but PRD.md / architecture.md are written in English.

Skills handle this themselves via the 2 config vars.

### Q25: How is `{project-root}` detected?

Search upward from the current directory:
1. Has a `_bmad/` directory?
2. Has a `.git/` directory?
3. Fallback: `process.cwd()`

Logic: `tools/installer/project-root.js` findProjectRoot().

---

## E. Validation & quality

### Q26: `npm run validate:skills` fails — how do I fix it?

Read the finding output:
```json
{
  "rule": "SKILL-04",
  "severity": "HIGH",
  "file": "src/bmm-skills/my-skill/SKILL.md",
  "detail": "name 'my-skill' does not match pattern",
  "fix": "Rename to bmad-my-skill"
}
```

Every finding has a `fix` field telling you how to fix it.

14 deterministic rules: [03 §10](03-skill-anatomy-deep.md), [08 §5](08-installer-code-level-spec.md).

### Q27: Rule SKILL-04 — the name doesn't match the pattern. Is there an exception?

No exception. All skills MUST match `^bmad-[a-z0-9]+(-[a-z0-9]+)*$`.

If you fork or create a custom non-BMad skill, change the prefix (e.g., `myorg-*`) and use your own validator.

### Q28: PATH-05 says "cannot reach into other skill" — how do I share a template?

**Option A: Split into a third skill that both invoke**

```
bmad-skill-a → invoke bmad-shared-template
bmad-skill-b → invoke bmad-shared-template
```

**Option B: Put the template at the project level**

`{project_knowledge}/my-template.md` — both skills can reference it via a config var.

### Q29: How do I test a skill before submitting a PR?

```bash
# Validate
node tools/validate-skills.js src/path/to/my-skill --strict

# Full quality
npm run quality

# Manual integration test
cd /tmp && mkdir test-proj && cd test-proj && git init
npx --package=/path/to/BMAD-METHOD bmad-method install --modules core,bmm --yes
# Then invoke the skill in Claude Code
```

### Q30: What's the difference between linting and validation?

| | Linting (eslint + prettier + markdownlint) | Validation (validate-skills) |
|---|-------|---------|
| **Checks** | Code style | Skill structure |
| **Language** | JS, MD | BMad-specific |
| **Rules** | Standard linters | 27 BMad rules |
| **Target** | Framework code | Skill files |

Both run inside `npm run quality`.

---

## F. Testing

### Q31: How do I test skill behavior (not just structure)?

**There's no automated integration test for LLM-dependent behavior.**

Manual approach:
1. Install BMad in a test project
2. Invoke the skill (e.g., `/bmad-agent-pm`)
3. Verify output files are produced
4. Check content quality (manual review)

Details: [11-testing-and-quality.md §5](11-testing-and-quality.md)

### Q32: Unit tests for the validator?

Test fixtures live in `test/fixtures/`:
```
test/fixtures/
└── file-refs-csv/
    ├── valid-basic.csv
    ├── invalid-missing-col.csv
    └── ...
```

Run: `node test/test-file-refs-csv.js`

Pattern: Plain Node `assert`, no framework.

### Q33: Adding a regression test for a bug fix?

1. Reproduce the bug in a test fixture
2. Add an assertion in a new test file
3. Run it, confirm it fails
4. Apply the fix, confirm the test passes

Details: [11 §8](11-testing-and-quality.md)

### Q34: CI/CD fails — how do I debug locally?

```bash
# Mimic CI
npm ci
npm run quality

# Each step:
npm run format:check
npm run lint
npm run lint:md
npm run docs:build
npm run test:install
npm run validate:refs
npm run validate:skills
```

Check the first failing step.

---

## G. Contributing

### Q35: What's the PR size limit?

- **Ideal:** 200-400 LOC
- **Max:** 800 LOC
- **One feature/fix per PR**

If it's larger → split into multiple PRs.

Details: [CONTRIBUTING.md](../CONTRIBUTING.md)

### Q36: Commit message format?

Conventional commits:
```
feat: add bmad-security-audit skill
fix: correct resolver merge order for keyed arrays
docs: update testing section in 11-testing-and-quality
refactor: extract manifest generation into separate class
test: add regression for sync directory edge case
```

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`.

### Q37: Pre-submit PR checklist?

- [ ] Discord discussion (if large)
- [ ] Fork → branch → commit
- [ ] `npm run quality` passes
- [ ] Manual integration test
- [ ] Commit messages follow convention
- [ ] PR size ≤ 800 LOC
- [ ] PR description: What/Why/How/Testing
- [ ] Linked to an issue

### Q38: What are common reasons a PR is rejected?

Common rejections:
1. **"Reads like raw LLM output"** — unsolicited refactors
2. **Too large** — > 800 LOC
3. **Multiple concerns** — not one feature
4. **No Discord discussion** for large features
5. **Quality check fails**
6. **Doesn't fit the philosophy** — sidelines the human, creates an adoption barrier

Details: [CONTRIBUTING.md](../CONTRIBUTING.md)

### Q39: I want to contribute docs/translations — how?

Docs location: `docs/{lang}/` (vi-vn, zh-cn, cs, fr)

1. Copy the English structure
2. Translate the content
3. Keep technical terms in English (agent, skill, workflow)
4. `npm run docs:build` to verify
5. PR

---

## H. Troubleshooting

### Q40: "Cannot find module 'bmad-method'" when running npx

```bash
npm cache clean --force
npx bmad-method@latest install
```

### Q41: Install fails on Windows

Known issue: WSL recommended. Windows native has issues with:
- Symlinks (need Developer Mode)
- Path separators
- Line endings (CRLF vs LF)

Workaround: Use WSL2.

### Q42: External module clone fails

```bash
# Test git manually
git clone --depth 1 https://github.com/org/module /tmp/test

# Check:
# - Network
# - GitHub token (if private)
# - Git installed
```

### Q43: Customization isn't applying

Debug with the resolver:
```bash
python3 _bmad/scripts/resolve_customization.py \
  --skill _bmad/bmm/agents/bmad-agent-pm \
  --key agent
```

Check the merged output:
- Is the override file in the right location?
- Are you trying to override a read-only field (name, title)?
- Any TOML syntax error?

### Q44: Skill doesn't show up in the IDE

```bash
ls -la .claude/skills/        # Verify skills were copied
cat .claude/skills/bmad-*/SKILL.md | head -5   # Verify content

# Restart the IDE
# Claude Code needs a restart after installation
```

### Q45: An update wiped my customizations

Normally this shouldn't happen — customizations in `_bmad/custom/` are protected.

If they were wiped:
```bash
# Check temp backup (may still exist)
ls /tmp/bmad-backup-* /tmp/bmad-modified-*

# If it exists, restore manually
```

Prevention: `_bmad/custom/*.user.toml` is gitignored = your overrides live only on disk. Back them up regularly.

### Q46: Merge conflict between team and user override

User override wins. If both set the same scalar, the user value is used.

Check the merged result with the resolver.

---

## I. Advanced topics

### Q47: Rewriting BMad in Go/Rust/Python — where do I start?

Read [14-rewrite-blueprint.md](14-rewrite-blueprint.md) — it has:
- Effort estimate (6-12 weeks)
- Per-language recipes
- MVF phases (start with the validator, then resolver, then installer)
- Code-level spec in [08](08-installer-code-level-spec.md)

### Q48: Does the framework have telemetry?

**No automatic telemetry.** The current version does not collect data.

If that ever changes in the future, it will be opt-in with clear disclosure.

### Q49: Performance optimization — the installer is slow?

Details: [13 §4](13-operational-runbook.md)

Current bottlenecks:
1. File copy (sequential) — potential: parallel
2. SHA-256 hashing — potential: cache with mtime
3. Git clone — already --depth 1
4. npm install — potential: skip if deps unchanged

### Q50: Security considerations when writing a skill?

Details: [13 §3](13-operational-runbook.md)

Key points:
- No executable code in skills (markdown only)
- Validate user input at trust boundaries
- External modules = supply chain risk
- No sandboxing — users review the generated code

### Q51: BMad v5 → v6 migration — are there any breaking changes?

Details: [12 §7](12-comparison-and-migration.md)

Main changes:
- Skills architecture introduced
- Directory structure: `.bmad/` → `_bmad/`
- Customization system (3-level TOML)
- Manifest files (manifest.yaml + CSV)
- Strict naming (bmad-* prefix)

### Q52: Can I run BMad without the installer (bare skills)?

Yes, manually:
1. Copy `src/core-skills/` and `src/bmm-skills/` to `_bmad/`
2. Create `_bmad/_config/config.yaml` by hand
3. Configure the IDE to find the skills

Not recommended — the installer handles edge cases.

### Q53: Skill marketplace — submitting a public skill?

Future feature. Currently:
1. Host the skill on a public GitHub repo with a `module.yaml`
2. Users install via `--custom-source <url>`
3. Fork `bmad-plugins-marketplace` + PR to officially register

### Q54: I want to build a business on top of BMad (SaaS, consulting)?

MIT License — free to use commercially. Attribution is appreciated (but not required).

Community guidelines:
- Share improvements back if they're generic
- Don't claim the BMad trademark
- Respect [TRADEMARK.md](../TRADEMARK.md)

### Q55: What's the framework roadmap — which features are in progress?

See [docs/roadmap.mdx](../docs/roadmap.mdx) or Discord announcements.

Near-term (3-6 months):
- BMad Builder v1 (create custom modules/skills)
- Dev Loop Automation
- Centralized Skills (install once, use everywhere)
- Adaptive Skills (LLM-specific variants)

Medium-term:
- Skill Marketplace
- Jira/Linear integration
- Enterprise features (SSO, audit logs)

---

## Couldn't find an answer?

1. **Search the docs:** `grep -r "your question" /home/miendq1/study/research/sdd/BMAD-METHOD/dev/`
2. **Read README.md** to navigate
3. **Discord:** <https://discord.gg/gk8jAdXWmj>
4. **GitHub Issues:** <https://github.com/bmad-code-org/BMAD-METHOD/issues>

---

**Continue reading:** [17-cheat-sheet.md](17-cheat-sheet.md) — A 1-page quick reference.
