# BMAD-METHOD Developer Deep Dive (Unofficial)

> ## ⚠️ IMPORTANT: UNOFFICIAL THIRD-PARTY DOCUMENTATION
>
> **This is NOT official BMAD-METHOD documentation.** It is an independent, unofficial, third-party deep dive created for educational purposes.
>
> - **NOT endorsed or reviewed by BMad Code, LLC** (the creator of BMAD-METHOD)
> - **Based on analysis of** [BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD) v6.3.0 (April 2026)
> - **For official docs:** <https://bmad-method.org>
> - **Full disclaimer:** See [DISCLAIMER.md](DISCLAIMER.md)
>
> **📜 Legal notices (required reading before use/redistribution):**
> - [DISCLAIMER.md](DISCLAIMER.md) — Full disclaimer, intended use, accuracy caveats
> - [LICENSE](LICENSE) — MIT License (derivative work of BMAD-METHOD)
> - [NOTICE](NOTICE) — Detailed attributions
>
> **™ Trademarks:** BMad™, BMad Method™, BMad Core™ are trademarks of BMad Code, LLC. Usage here is nominative fair use only. [See TRADEMARK.md](https://github.com/bmad-code-org/BMAD-METHOD/blob/main/TRADEMARK.md).

---

## 🌐 Available languages

This documentation is available in multiple languages:

| Language | Location | Status |
|----------|----------|--------|
| **English** (this folder) | [/dev/](./) | ✅ Primary |
| **Tiếng Việt** | [/vi-vn/](../vi-vn/) | ✅ Full translation |

---

## 📖 About this documentation

Detailed English documentation to **understand, build, extend, and reimplement** the BMAD-METHOD framework.

**Audience:** Senior developers wanting to contribute to the framework, customize it, or port to other languages.

**Total:** 23 files (+ validator script), ~23,500 lines, ~170,000 words, 35 Mermaid diagrams.

**Status:** ✅ All Mermaid validated, cross-links checked, code verified against source.

**License:** MIT (inherits from BMAD-METHOD's MIT License). See [LICENSE](LICENSE) and [NOTICE](NOTICE).

---

## 📚 Documentation structure

### 🏛️ Part I: Overview & principles (01-03)

| File | Content | Lines | Audience |
|------|---------|-------|----------|
| **[01-philosophy.md](01-philosophy.md)** | 10 architectural principles, "Human Amplification" philosophy, distinctive concepts (adversarial, party mode, elicitation, distillator), framework comparisons, roadmap | 594 | Everyone |
| **[02-environment-and-variables.md](02-environment-and-variables.md)** | Complete variable inventory (config + runtime + macros), resolver algorithm, 3/4-level customization, merge semantics, edge cases, checklist for writing your own resolver | 1073 | Developer + Maintainer |
| **[03-skill-anatomy-deep.md](03-skill-anatomy-deep.md)** | SKILL.md/workflow.md/steps/ structure, XML workflow syntax, 3 canonical examples (brainstorming, dev-story, agent-pm), 27 validation rules | 1094 | Developer |

### 📖 Part II: Skills deep dive (04, 09a-d)

| File | Content | Lines |
|------|---------|-------|
| **[04-skills-catalog.md](04-skills-catalog.md)** | Catalog overview of 39 skills, patterns, integration points | 916 |
| **[09a-skills-core-deep.md](09a-skills-core-deep.md)** | 12 core skills deep dive (advanced-elicitation, brainstorming, customize, distillator, editorial-review-*, help, index-docs, party-mode, adversarial-review, edge-case-hunter, shard-doc) | 1642 |
| **[09b-skills-phase1-2-deep.md](09b-skills-phase1-2-deep.md)** | 11 Phase 1+2 skills deep (Mary, Paige, John, Sally personas + document-project, prfaq, product-brief, create-prd, create-ux-design, edit-prd, validate-prd) | 1353 |
| **[09c-skills-phase3-deep.md](09c-skills-phase3-deep.md)** | 5 Phase 3 Solutioning skills deep (Winston persona + create-architecture, create-epics-and-stories, generate-project-context, check-implementation-readiness) | 1340 |
| **[09d-skills-phase4-deep.md](09d-skills-phase4-deep.md)** | 11 Phase 4 Implementation skills deep (Amelia persona + create-story, dev-story RED-GREEN-REFACTOR with 8-level gate, code-review, checkpoint-preview, correct-course, quick-dev, qa-tests, sprint-*, retrospective 12-step party mode) | 1947 |

### 🎨 Part III: Diagrams & flows (05, 10)

| File | Content | Lines |
|------|---------|-------|
| **[05-flows-and-diagrams.md](05-flows-and-diagrams.md)** | 18 user-facing Mermaid diagrams: architecture, lifecycle, sequences, state machines, story lifecycle, 4-phase handoff | 1157 |
| **[10-maintainer-diagrams.md](10-maintainer-diagrams.md)** | 13 maintainer diagrams: installer state machine, file data flow, resolver algorithm, validator execution, IDE class hierarchy, external module lifecycle, skill invocation, backup-restore, customization merge visualization, npm scripts dependency graph | 1016 |

### 🛠️ Part IV: Installer & infrastructure (06, 08, 11)

| File | Content | Lines |
|------|---------|-------|
| **[06-installer-internals.md](06-installer-internals.md)** | Installer CLI + validator + build pipeline internals (overview) | 1394 |
| **[08-installer-code-level-spec.md](08-installer-code-level-spec.md)** | **Code-level spec** with actual JS code, pseudo-code, data shapes, 14 validator rules complete, algorithm implementations — enough to rewrite | 1517 |
| **[11-testing-and-quality.md](11-testing-and-quality.md)** | Test structure, unit test patterns, fixture-based testing, integration tests, quality metrics, CI/CD, performance benchmarks | 608 |

### 🚀 Part V: Extensions & operations (07, 12, 13, 14)

| File | Content | Lines |
|------|---------|-------|
| **[07-extension-patterns.md](07-extension-patterns.md)** | 8 extension patterns: new skill, new agent, new module, customize, IDE, validation rule, sub-agent, external module | 1309 |
| **[12-comparison-and-migration.md](12-comparison-and-migration.md)** | Detailed comparisons with LangGraph/CrewAI/AutoGen/vanilla Claude Code, migration vanilla → BMad, migration v5 → v6, future-proofing | 704 |
| **[13-operational-runbook.md](13-operational-runbook.md)** | Release process, bug triage, security considerations, performance tuning, troubleshooting guide, incident response | 681 |
| **[14-rewrite-blueprint.md](14-rewrite-blueprint.md)** | **Blueprint to rewrite BMad in Go/Rust/Python**: MVF, interface specs, per-language recipes, migration plan | 1453 |

### 📚 Part VI: Reference materials (15-18)

| File | Content | Lines |
|------|---------|-------|
| **[15-glossary.md](15-glossary.md)** | 200+ BMad terms alphabetical + grouped (7 sections) | 400+ |
| **[16-faq.md](16-faq.md)** | 55+ FAQs across 9 sections (Getting started → Advanced) | 700+ |
| **[17-cheat-sheet.md](17-cheat-sheet.md)** | 1-page quick reference: commands, skill structure, variables, validation rules, extension patterns. Print-friendly | 250+ |
| **[18-workflow-deep-walkthrough.md](18-workflow-deep-walkthrough.md)** | Step-by-step walkthrough of 2 workflows: `bmad-create-prd` (15 steps) + `bmad-retrospective` (12 steps party-mode) with XML/dialogue examples | 700+ |

### 🛠️ Tools

| File | Purpose |
|------|---------|
| **[validate-dev-docs.sh](validate-dev-docs.sh)** | Bash script to validate internal consistency: Mermaid syntax, cross-links, terminology. Usage: `./validate-dev-docs.sh [--strict]` |

### 📄 Legacy (reference only)

| File | Content |
|------|---------|
| [bmad-architecture.md](bmad-architecture.md) | First-version summary file (818 lines) — kept for reference; content has been expanded into 01-18. Has a disclaimer at the top. |

---

## 🎯 Reading paths by goal

### Goal A: "I want to understand the framework overall" (3-4 hours)

```
1. 01-philosophy.md            (philosophy + 10 principles)
2. 05-flows-and-diagrams.md    (18 diagrams visualize architecture)
3. 04-skills-catalog.md        (catalog of 39 skills)
```

### Goal B: "I want to write a new skill/agent" (5-7 hours)

```
1. 01-philosophy.md §2-3       (principles + separations)
2. 03-skill-anatomy-deep.md    (anatomy + 3 canonical examples)
3. 02-environment-and-variables.md  (environment variables)
4. 09a or 09b-d                (deep dive similar skills)
5. 07-extension-patterns.md §2-3 (new skill/agent patterns)
```

### Goal C: "I want to customize for my team" (2-3 hours)

```
1. 02-environment-and-variables.md §6-7  (customize.toml + 3-level)
2. 07-extension-patterns.md §5  (Pattern 4: Customize)
3. 10-maintainer-diagrams.md §9  (Customization merge visualization)
```

### Goal D: "I want to contribute to framework core" (8-12 hours)

```
1. 01-philosophy.md                (full)
2. 03-skill-anatomy-deep.md        (full)
3. 06-installer-internals.md       (overview)
4. 08-installer-code-level-spec.md (code-level detail)
5. 10-maintainer-diagrams.md       (10 diagrams)
6. 11-testing-and-quality.md       (test patterns)
7. 13-operational-runbook.md       (release + security)
```

### Goal E: "I want to rewrite BMad in another language" (15-20 hours)

Read **ALL files in order 01 → 14**. Pay special attention to:

- **08-installer-code-level-spec.md** — actual code patterns + data shapes
- **14-rewrite-blueprint.md** — complete blueprint + per-language recipes
- **10-maintainer-diagrams.md** — visualize algorithms
- **11-testing-and-quality.md** — test strategy

### Goal F: "I want to understand each skill deeply" (10-15 hours)

```
1. 04-skills-catalog.md (overview)
2. 09a-skills-core-deep.md (12 core skills)
3. 09b-skills-phase1-2-deep.md (Phase 1+2)
4. 09c-skills-phase3-deep.md (Phase 3)
5. 09d-skills-phase4-deep.md (Phase 4)
```

Each skill includes: metadata, input/output schema, complete workflow logic, state machine, edge cases, code-ready spec.

---

## 🗺️ Concepts-to-files map

```mermaid
graph TB
    Philosophy[01-philosophy<br/>Philosophy]

    Env[02-environment<br/>Variables & Config]

    Anatomy[03-skill-anatomy<br/>Anatomy]

    Catalog[04-skills-catalog<br/>Catalog of 39 skills]
    Deep[09a-09d<br/>Deep dive skills]

    Diagrams[05-flows<br/>User diagrams]
    MaintDiag[10-maintainer<br/>Maintainer diagrams]

    Install[06-installer<br/>Overview]
    InstallSpec[08-installer-spec<br/>Code-level]

    Test[11-testing<br/>Testing + Quality]

    Ext[07-extension<br/>8 Patterns]

    Compare[12-comparison<br/>Comparison + Migration]

    Ops[13-operational<br/>Runbook]

    Rewrite[14-rewrite<br/>Blueprint]

    Philosophy --> Env
    Philosophy --> Anatomy

    Env --> Anatomy
    Anatomy --> Catalog
    Catalog --> Deep

    Philosophy --> Diagrams
    Anatomy --> Diagrams
    Deep --> Diagrams

    Install --> MaintDiag
    InstallSpec --> MaintDiag

    Anatomy --> Install
    Install --> InstallSpec
    InstallSpec --> Rewrite

    Anatomy --> Ext
    Env --> Ext

    Philosophy --> Compare
    Anatomy --> Compare

    Install --> Test
    Anatomy --> Test

    Install --> Ops
    Test --> Ops

    classDef foundation fill:#ffebee,stroke:#c62828
    classDef content fill:#e3f2fd,stroke:#1565c0
    classDef visual fill:#f3e5f5,stroke:#6a1b9a
    classDef infra fill:#fff3e0,stroke:#e65100
    classDef advanced fill:#e8f5e9,stroke:#2e7d32

    class Philosophy,Env,Anatomy foundation
    class Catalog,Deep content
    class Diagrams,MaintDiag visual
    class Install,InstallSpec,Test infra
    class Ext,Compare,Ops,Rewrite advanced
```

---

## 🔍 Quick reference

### Core concepts

| Term | Short definition | Detail in |
|------|-----------------|-----------|
| **Skill** | Self-contained unit of work (directory with SKILL.md) | [03](03-skill-anatomy-deep.md) |
| **Agent** | Persona with menu of skills | [03 §9](03-skill-anatomy-deep.md), [09b §1-1](09b-skills-phase1-2-deep.md) |
| **Module** | Package of skills + agents + config | [02 §2](02-environment-and-variables.md) |
| **Workflow** | Logic in workflow.md of a skill | [03 §3](03-skill-anatomy-deep.md) |
| **Step** | Micro-file in steps/ folder | [03 §4](03-skill-anatomy-deep.md) |
| **Config variable** | Variable from `_bmad/config.yaml` | [02 §2](02-environment-and-variables.md) |
| **Runtime variable** | Set during workflow execution | [02 §3](02-environment-and-variables.md) |
| **System macro** | `{project-root}`, `{date}`, etc. | [02 §4](02-environment-and-variables.md) |
| **customize.toml** | File to override agent/workflow | [03 §6](03-skill-anatomy-deep.md) |
| **Invoke** | How a skill calls another skill | [03 §10](03-skill-anatomy-deep.md) |

### 10 architectural principles

1. **Filesystem is Truth** — state stored in files, no DB
2. **Declarative > Imperative** — Markdown/YAML/TOML, not code
3. **Document-as-Interface** — phases communicate via file output
4. **Micro-file Workflows** — step = 1 file, load just-in-time
5. **Sequential by Default** — no runtime parallelism
6. **Encapsulated Skills (PATH-05)** — invoke, don't read other skills' files
7. **Config-Driven Paths** — use `{planning_artifacts}`, not hardcode
8. **Declarative Validation** — rules written in markdown
9. **Layered Customization** — 3-level (default → team → user)
10. **Human-in-the-Loop** — HALT at checkpoints

Details: [01-philosophy.md §2](01-philosophy.md#2-architectural-principles-10-principles)

### 27 validation rules (14 deterministic + 13 inference)

| Group | Count | Details |
|-------|-------|---------|
| SKILL-* | 7 | [03 §10](03-skill-anatomy-deep.md) |
| WF-* | 3 | [03 §10](03-skill-anatomy-deep.md) |
| PATH-* | 5 | [03 §10](03-skill-anatomy-deep.md) |
| STEP-* | 7 | [03 §10](03-skill-anatomy-deep.md) |
| SEQ-* | 2 | [03 §10](03-skill-anatomy-deep.md) |
| REF-* | 3 | [03 §10](03-skill-anatomy-deep.md) |

### 4 BMM phases

```
Phase 1: Analysis     → Product Brief, PRFAQ
Phase 2: Planning     → PRD, UX Design
Phase 3: Solutioning  → Architecture, Epics/Stories, Project Context
Phase 4: Implementation → Sprint, Stories, Code, Reviews, Retrospective
```

Details: [04 §II](04-skills-catalog.md) + [05 §2](05-flows-and-diagrams.md)

### 6 built-in agent personas

| Code | Name | Title | Icon | Deep dive |
|------|------|-------|------|-----------|
| analyst | Mary | Business Analyst | 📊 | [09b §1-1](09b-skills-phase1-2-deep.md) |
| tech-writer | Paige | Technical Writer | 📚 | [09b §1-2](09b-skills-phase1-2-deep.md) |
| pm | John | Product Manager | 📋 | [09b §2-1](09b-skills-phase1-2-deep.md) |
| ux-designer | Sally | UX Designer | 🎨 | [09b §2-2](09b-skills-phase1-2-deep.md) |
| architect | Winston | System Architect | 🏗️ | [09c §3-1](09c-skills-phase3-deep.md) |
| dev | Amelia | Senior Engineer | 💻 | [09d §4-1](09d-skills-phase4-deep.md) |

### Important commands

```bash
# Install
npx bmad-method install
npx bmad-method install --modules bmm --tools claude-code --yes

# Validation
npm run validate:skills --strict
node tools/validate-skills.js path/to/skill --json

# Quality check (CI)
npm run quality

# Docs
npm run docs:build
npm run docs:dev

# Tests
npm test
```

---

## 🎥 Video walkthrough (suggested viewing order)

BMad has a YouTube channel [@BMadCode](https://www.youtube.com/@BMadCode). If you prefer video, recommended order:

| Topic | Docs mapping | Priority |
|-------|-------------|----------|
| **Intro: What is BMad?** | [01-philosophy.md](01-philosophy.md) §1 | ⭐⭐⭐ Must watch |
| **Install + first skill** | [07-extension-patterns.md](07-extension-patterns.md) §1-2 | ⭐⭐⭐ Must watch |
| **4 phases lifecycle** | [05-flows-and-diagrams.md](05-flows-and-diagrams.md) §2 | ⭐⭐ Recommended |
| **Named agents (Mary/John/Winston...)** | [09b](09b-skills-phase1-2-deep.md), [09c](09c-skills-phase3-deep.md), [09d](09d-skills-phase4-deep.md) | ⭐⭐ |
| **Party mode demo** | [09a](09a-skills-core-deep.md) §C-9 | ⭐⭐ |
| **Dev story + TDD** | [09d §4-3](09d-skills-phase4-deep.md) | ⭐⭐⭐ (core workflow) |
| **Retrospective** | [18](18-workflow-deep-walkthrough.md) Part 2 | ⭐ |
| **Customization** | [02 §7](02-environment-and-variables.md), [07 §5](07-extension-patterns.md) | ⭐⭐ |
| **Troubleshooting** | [13](13-operational-runbook.md) §5, [16](16-faq.md) | ⭐ |

**Recommended flow:** Watch Intro → Install video → Try yourself → Watch Dev-story → Contribute.

---

## 🤝 Community

- **Discord:** <https://discord.gg/gk8jAdXWmj>
- **GitHub:** <https://github.com/bmad-code-org/BMAD-METHOD>
- **YouTube:** <https://www.youtube.com/@BMadCode>
- **Docs:** <https://bmad-method.org>

---

## 📜 License & Credits

### BMad Framework

- **License:** MIT License — see [LICENSE](../LICENSE) at repo root
- **Copyright:** © 2025 BMad Code, LLC
- **Creator:** Brian (BMad) Madison
- **Contributors:** See [CONTRIBUTORS.md](../CONTRIBUTORS.md)

### Trademark notice

**BMad™, BMad Method™, BMad Core™** (and all casings: BMAD, bmad, BMAD-METHOD, etc.) are **trademarks of BMad Code, LLC** — see [TRADEMARK.md](../TRADEMARK.md).

In this documentation, "BMad", "BMAD-METHOD" are used solely to **reference the original framework** — conforming with trademark guidelines ("Refer to BMad to accurately describe compatibility").

### This documentation

- **Nature:** ⚠️ **Unofficial third-party deep dive** — NOT official documentation
- **Languages:** English (this folder) + Vietnamese (see [/vi-vn/](../vi-vn/))
- **Based on:** BMAD-METHOD v6.3.0 source code (April 2026)
- **Purpose:** Learning + contributing + reimplementing the framework
- **Status:** Personal / team-internal documentation, does not claim official endorsement

**Source of truth when conflicts arise:**
1. Official docs in `../docs/` (user-facing)
2. `../tools/skill-validator.md` (validation rules)
3. `../CONTRIBUTING.md` (contribution guidelines)
4. This documentation (third-party reference)

### License for content in `/dev` folder

Content in this folder inherits **MIT License** from the BMad framework (as it documents/analyzes BMad). You may:
- ✅ Use, copy, modify, distribute
- ✅ Use internally in your team/company
- ✅ Share publicly (with license notice)
- ❌ NOT use "BMad" in your product/service name
- ❌ NOT claim this is official documentation

If publishing/distributing, please include MIT LICENSE notice (see [LICENSE-NOTICE.md](LICENSE-NOTICE.md)).

### Found a bug in this documentation?

- If it's an official framework bug: open an issue at [GitHub](https://github.com/bmad-code-org/BMAD-METHOD/issues)
- If it's a mistake in this `/dev` documentation: contact the maintainer of this documentation (not BMad Code, LLC)

---

## 📊 Stats

### BMad framework
- **39 skills** (12 core + 27 BMM)
- **6+ agents** (extensible via custom modules)
- **27 validation rules** (14 deterministic + 13 inference)
- **4 phases** BMM workflow
- **5 doc languages** (English, Vietnamese, Chinese, Czech, French)
- **4 IDE support** (Claude Code, Cursor, JetBrains, VS Code)
- **10 core principles**

### This documentation (`/dev` folder)
- **23 files** (170,000+ English words)
- **35 Mermaid diagrams** (all validated)
- **289 cross-links** (99% valid)
- **Validator script** included (`validate-dev-docs.sh`)

### Quality checks performed
- ✅ Mermaid syntax validation (35/35 render OK)
- ✅ Cross-link integrity (284/289 valid, 5 false positives in code examples)
- ✅ Code snippets verified against actual source
- ✅ Terminology consistency reviewed
- ✅ File inventory complete

---

## 🚀 Start reading

**First time:** [01-philosophy.md](01-philosophy.md) → [05-flows-and-diagrams.md](05-flows-and-diagrams.md)

**Want quick reference:** [17-cheat-sheet.md](17-cheat-sheet.md) (1 page)

**Have a problem / question:** [16-faq.md](16-faq.md) (55+ Q&A)

**Look up terminology:** [15-glossary.md](15-glossary.md) (200+ terms)

**Want to write a skill:** [03-skill-anatomy-deep.md](03-skill-anatomy-deep.md) → [09a-skills-core-deep.md](09a-skills-core-deep.md) → [07-extension-patterns.md](07-extension-patterns.md)

**See detailed example:** [18-workflow-deep-walkthrough.md](18-workflow-deep-walkthrough.md) (step-by-step create-prd + retrospective)

**Want to rewrite the framework:** [08-installer-code-level-spec.md](08-installer-code-level-spec.md) → [14-rewrite-blueprint.md](14-rewrite-blueprint.md)

**Want to contribute:** [07-extension-patterns.md](07-extension-patterns.md) → [11-testing-and-quality.md](11-testing-and-quality.md) → [13-operational-runbook.md](13-operational-runbook.md)

**Validate docs consistency:** `./validate-dev-docs.sh`

**Prefer Vietnamese?** See [/vi-vn/](../vi-vn/) folder.
