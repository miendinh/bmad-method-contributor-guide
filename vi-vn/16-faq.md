# 16. FAQ - Câu hỏi thường gặp cho Developer

> ⚠️ **UNOFFICIAL THIRD-PARTY DOCUMENTATION**
> Không phải official BMad docs. Xem [DISCLAIMER.md](DISCLAIMER.md) | Licensed MIT — xem [LICENSE](LICENSE) và [NOTICE](NOTICE)
> Official BMAD-METHOD: <https://github.com/bmad-code-org/BMAD-METHOD>

---

> 40+ câu hỏi thường gặp khi develop/contribute vào BMAD-METHOD. Dành cho dev mới và dev quen framework.

---

## Mục lục

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

### Q1: Tôi mới bắt đầu đọc docs này, nên đọc file nào trước?

Tùy mục tiêu:

| Mục tiêu | Starting point |
|----------|----------------|
| Hiểu framework tổng quan | [01-philosophy.md](01-philosophy.md) → [05-flows-and-diagrams.md](05-flows-and-diagrams.md) |
| Viết skill đầu tiên | [03-skill-anatomy-deep.md](03-skill-anatomy-deep.md) → [07-extension-patterns.md](07-extension-patterns.md) §2 |
| Customize cho team | [02-environment-and-variables.md](02-environment-and-variables.md) §7 → [07 §5](07-extension-patterns.md) |
| Contribute framework | [06-installer-internals.md](06-installer-internals.md) → [08-installer-code-level-spec.md](08-installer-code-level-spec.md) |
| Rewrite sang ngôn ngữ khác | [14-rewrite-blueprint.md](14-rewrite-blueprint.md) |

Xem [README.md](README.md) cho reading paths chi tiết.

### Q2: BMad khác gì với vanilla Claude Code?

BMad **layer trên top** Claude Code, không thay thế. BMad cung cấp:
- Structured workflows (not free-form chat)
- Named agent personas (not single "AI assistant")
- Artifact-driven development (PRD → Architecture → Stories → Code)
- Git-tracked documentation
- Multi-agent collaboration (party mode)

Chi tiết: [12-comparison-and-migration.md §4](12-comparison-and-migration.md)

### Q3: Tôi chỉ muốn fix 1 bug nhỏ, có cần BMad không?

**Không cần.** BMad optimal cho:
- Feature development (PRD → Implementation)
- Team với PM/Architect/Dev roles
- Long-lived projects

**Dùng Quick Dev** (`bmad-quick-dev`) nếu đã install BMad và muốn flow nhanh.
**Hoặc skip BMad** nếu < 30 phút work.

### Q4: BMad có require LLM gì?

BMad là prompt framework — hoạt động với bất kỳ LLM nào hỗ trợ Skills standard. Tested trên:
- Claude (Sonnet, Opus, Haiku) via Claude Code
- Cursor (với Claude backend)
- Khác: VSCode extensions, JetBrains (configurable)

Quality tốt nhất với Claude Sonnet/Opus.

### Q5: Tôi có thể dùng BMad offline không?

**Không.** BMad rely on LLM API. Local LLMs (Llama, Mistral) có thể work nếu:
- Support Skills standard
- Context window ≥ 32k tokens
- Instruction-following quality tốt

Hiện tại không tested.

---

## B. Skill development

### Q6: Tạo skill mới bắt đầu từ đâu?

1. Đọc [03-skill-anatomy-deep.md](03-skill-anatomy-deep.md) (anatomy)
2. Đọc [09a-skills-core-deep.md](09a-skills-core-deep.md) example (skill tương tự)
3. Follow [07 §2 Pattern 1](07-extension-patterns.md)
4. Validate với `npm run validate:skills`

### Q7: Skill phải đặt ở đâu?

```
src/
├── core-skills/        # Cross-phase utilities
└── bmm-skills/
    ├── 1-analysis/     # Phase 1 skills
    ├── 2-plan-workflows/
    ├── 3-solutioning/
    └── 4-implementation/
```

Chọn vị trí theo phase logic. Cross-phase → `core-skills/`.

### Q8: SKILL.md phải có gì?

Bắt buộc:
```yaml
---
name: bmad-my-skill      # Match dir name, regex ^bmad-[a-z0-9]+(-[a-z0-9]+)*$
description: 'Does X. Use when Y.'  # Phải có "Use when" clause
---

Follow the instructions in ./workflow.md.
```

Ngắn hơn: có thể inline logic trong SKILL.md cho skill đơn giản (<100 lines).

### Q9: Khi nào dùng micro-file (steps/) vs XML inline?

| Dùng micro-file | Dùng XML inline |
|-----------------|-----------------|
| > 3 phases với branching | Linear flow, 2-3 steps |
| User control at each step | Continuous execution |
| State tracked via frontmatter | State ephemeral |
| Reusable sub-steps | Single-use logic |
| Ví dụ: brainstorming, create-prd | Ví dụ: dev-story, create-story |

### Q10: Step file tối đa bao nhiêu dòng?

**~2-5KB mỗi step** (~50-150 dòng). Rule STEP-07: tổng 2-10 steps.

Nếu step quá dài → tách branching (step-02a, step-02b).
Nếu quá nhiều steps (>10) → tách skill.

### Q11: Skill của tôi cần invoke skill khác, làm sao?

**Option 1: Via agent menu** (khuyến nghị cho user-facing):
```toml
# customize.toml
[[agent.menu]]
code = "XX"
description = "..."
skill = "bmad-other-skill"
```

**Option 2: Text invocation** trong workflow:
```markdown
## Step 03: Run advanced elicitation
Invoke the `bmad-advanced-elicitation` skill to refine output.
Then return here for step-04.
```

**Rule REF-03:** Phải dùng word "Invoke" (không "execute", "run", "load").

### Q12: Skill có data file (.csv, .yaml), load thế nào?

Đặt cùng skill folder, reference relative:

```
bmad-my-skill/
├── SKILL.md
├── workflow.md
└── my-data.csv
```

Trong workflow:
```markdown
Load `./my-data.csv` (relative to skill root).
```

KHÔNG hardcode path hoặc dùng `{installed_path}`.

### Q13: Workflow có cần approve hay review trước merge?

**Có.** CONTRIBUTING.md bắt buộc:
- Discord discussion trước nếu feature lớn (> 200 LOC)
- PR size ideal 200-400, max 800 LOC
- One feature/fix per PR
- Must pass `npm run quality`

---

## C. Agent customization

### Q14: Làm sao để thay đổi persona agent (ví dụ Mary icon)?

Tạo override file:
```toml
# _bmad/custom/bmad-agent-analyst.toml
[agent]
icon = "🔍"  # New icon
```

Run verifier:
```bash
python3 _bmad/scripts/resolve_customization.py --skill _bmad/bmm/agents/bmad-agent-analyst --key agent
```

### Q15: Tôi muốn thêm principles cho agent, làm sao?

Arrays **append** trong override:
```toml
# _bmad/custom/bmad-agent-dev.toml
[agent]
principles = [
  "TDD is non-negotiable",
  "All commits must pass CI",
]
```

Result: base principles + 2 new ones. (Không override base).

### Q16: Thay đổi menu code của agent?

Match by `code` field:
```toml
[[agent.menu]]
code = "DS"                    # Matches base's DS
description = "Strict TDD story implementation"  # Override description
skill = "bmad-dev-story"       # Keep same skill or point to new
```

### Q17: Có thể xóa menu item không?

**Không có remove mechanism.** Workaround: override to make it no-op:
```toml
[[agent.menu]]
code = "BP"
description = "[Disabled — use external tool]"
prompt = "This option is not available in your team's config. Use external brainstorming tool."
```

### Q18: Custom agent hoàn toàn mới?

Add vào `_bmad/custom/config.toml`:
```toml
[agents.bmad-agent-security]
code = "bmad-agent-security"
name = "Sam"
title = "Security Expert"
icon = "🛡️"
team = "security"
description = "Threat modeling + OWASP rigor..."
```

Sau đó tạo skill folder `bmad-agent-security/` với `customize.toml` chi tiết.

### Q19: Override scope: team vs user?

| Scope | File | Git | Use case |
|-------|------|-----|----------|
| **Team** | `_bmad/custom/{skill}.toml` | Committed | Org policy, team convention |
| **User** | `_bmad/custom/{skill}.user.toml` | Gitignored | Personal preference |

User override thắng team override (precedence: user > team > default).

---

## D. Config & variables

### Q20: Tại sao dùng `{planning_artifacts}` thay vì hardcode `docs/`?

**Multi-user flexibility:** Alice lưu ở `docs/`, Bob ở `planning/`. Cả hai dùng cùng skill, mỗi người config riêng.

Installer prompts user khi install, store vào `_bmad/config.yaml`.

### Q21: Biến `{var}` resolve ở đâu?

3 tầng:
1. **Config variable** (từ `_bmad/config.yaml`) → resolve at activation
2. **System macro** (`{project-root}`, `{date}`) → resolve on-use
3. **Runtime variable** (`{story_key}`) → set during workflow execution

Chi tiết: [02-environment-and-variables.md §5](02-environment-and-variables.md)

### Q22: `{var}` vs `{{var}}` khác nhau thế nào?

- `{var}` single-brace — resolved by config merger (install-time or activation-time)
- `{{var}}` double-brace — template placeholder, resolved at runtime by workflow engine

Ví dụ:
```markdown
File output: {planning_artifacts}/prd-{{date}}.md
#                                    ↑ runtime (今日の日付)
#             ↑ config
```

### Q23: Nếu variable không defined, chuyện gì xảy ra?

**Literal text.** `{undefined_var}` không được replace, agent thấy exact string `"{undefined_var}"`.

Không throw error, không empty string. Graceful degradation.

### Q24: Multi-language: AI chat bằng Vietnamese, output bằng English — làm thế nào?

```yaml
# _bmad/config.yaml
communication_language: Vietnamese
document_output_language: English
```

Agent speaks Vietnamese, nhưng PRD.md / architecture.md viết English.

Skills tự handle via 2 config vars.

### Q25: `{project-root}` detect như thế nào?

Search upward từ current dir:
1. Has `_bmad/` directory?
2. Has `.git/` directory?
3. Fallback: `process.cwd()`

Logic: `tools/installer/project-root.js` findProjectRoot().

---

## E. Validation & quality

### Q26: `npm run validate:skills` fail, fix thế nào?

Đọc finding output:
```json
{
  "rule": "SKILL-04",
  "severity": "HIGH",
  "file": "src/bmm-skills/my-skill/SKILL.md",
  "detail": "name 'my-skill' does not match pattern",
  "fix": "Rename to bmad-my-skill"
}
```

Mỗi finding có `fix` field chỉ cách sửa.

14 deterministic rules: [03 §10](03-skill-anatomy-deep.md), [08 §5](08-installer-code-level-spec.md).

### Q27: Rule SKILL-04 — tên khác pattern, có exception?

Không exception. All skills MUST match `^bmad-[a-z0-9]+(-[a-z0-9]+)*$`.

Nếu bạn fork hoặc tạo custom non-BMad skill, đổi prefix (e.g., `myorg-*`) và dùng riêng validator.

### Q28: PATH-05 "cannot reach into other skill", tôi share template làm sao?

**Option A: Tách thành skill thứ 3 mà cả hai invoke**

```
bmad-skill-a → invoke bmad-shared-template
bmad-skill-b → invoke bmad-shared-template
```

**Option B: Put template at project level**

`{project_knowledge}/my-template.md` — cả hai skill can reference via config var.

### Q29: Test skill trước khi PR?

```bash
# Validate
node tools/validate-skills.js src/path/to/my-skill --strict

# Full quality
npm run quality

# Manual integration test
cd /tmp && mkdir test-proj && cd test-proj && git init
npx --package=/path/to/BMAD-METHOD bmad-method install --modules core,bmm --yes
# Then invoke skill in Claude Code
```

### Q30: Linting vs validation khác nhau?

| | Linting (eslint + prettier + markdownlint) | Validation (validate-skills) |
|---|-------|---------|
| **Checks** | Code style | Skill structure |
| **Language** | JS, MD | BMad-specific |
| **Rules** | Standard linters | 27 BMad rules |
| **Target** | Framework code | Skill files |

Cả hai chạy trong `npm run quality`.

---

## F. Testing

### Q31: Làm sao test skill behavior (not just structure)?

**Không có automated integration test cho LLM-dependent behavior.**

Manual approach:
1. Install BMad in test project
2. Invoke skill (e.g., `/bmad-agent-pm`)
3. Verify output files produced
4. Check content quality (manual review)

Chi tiết: [11-testing-and-quality.md §5](11-testing-and-quality.md)

### Q32: Unit test cho validator?

Test fixtures trong `test/fixtures/`:
```
test/fixtures/
└── file-refs-csv/
    ├── valid-basic.csv
    ├── invalid-missing-col.csv
    └── ...
```

Run: `node test/test-file-refs-csv.js`

Pattern: Plain Node `assert`, no framework.

### Q33: Thêm regression test cho bug fix?

1. Reproduce bug trong test fixture
2. Add assertion trong new test file
3. Run, confirm fail
4. Apply fix, confirm test pass

Chi tiết: [11 §8](11-testing-and-quality.md)

### Q34: CI/CD fails, debug local?

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

Check first failing step.

---

## G. Contributing

### Q35: PR size limit?

- **Ideal:** 200-400 LOC
- **Max:** 800 LOC
- **One feature/fix per PR**

Nếu lớn hơn → split thành multiple PRs.

Chi tiết: [CONTRIBUTING.md](../CONTRIBUTING.md)

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

### Q37: PR checklist trước submit?

- [ ] Discord discussion (nếu lớn)
- [ ] Fork → branch → commit
- [ ] `npm run quality` passes
- [ ] Manual integration test
- [ ] Commit messages follow convention
- [ ] PR size ≤ 800 LOC
- [ ] PR description: What/Why/How/Testing
- [ ] Linked to issue

### Q38: PR bị reject, lý do thường là gì?

Common rejections:
1. **"Reads like raw LLM output"** — unsolicited refactors
2. **Too large** — > 800 LOC
3. **Multiple concerns** — not one feature
4. **No Discord discussion** for large features
5. **Quality check fails**
6. **Doesn't fit philosophy** — sidelines human, creates adoption barrier

Chi tiết: [CONTRIBUTING.md](../CONTRIBUTING.md)

### Q39: Tôi muốn contribute docs/translations?

Docs location: `docs/{lang}/` (vi-vn, zh-cn, cs, fr)

1. Copy English structure
2. Translate content
3. Keep technical terms English (agent, skill, workflow)
4. `npm run docs:build` verify
5. PR

---

## H. Troubleshooting

### Q40: "Cannot find module 'bmad-method'" khi chạy npx

```bash
npm cache clean --force
npx bmad-method@latest install
```

### Q41: Install fails on Windows

Known issue: WSL recommended. Windows native có issues với:
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

### Q43: Customization không apply

Debug với resolver:
```bash
python3 _bmad/scripts/resolve_customization.py \
  --skill _bmad/bmm/agents/bmad-agent-pm \
  --key agent
```

Check merged output:
- Override file in right location?
- Trying to override read-only field (name, title)?
- TOML syntax error?

### Q44: Skill không show trong IDE

```bash
ls -la .claude/skills/        # Verify skills copied
cat .claude/skills/bmad-*/SKILL.md | head -5   # Verify content

# Restart IDE
# Claude Code needs restart after install
```

### Q45: Update wiped my customizations

Normally shouldn't — customizations in `_bmad/custom/` protected.

If wiped:
```bash
# Check temp backup (may still exist)
ls /tmp/bmad-backup-* /tmp/bmad-modified-*

# If exists, manually restore
```

Prevention: `_bmad/custom/*.user.toml` gitignored = your override lives only on disk. Backup regularly.

### Q46: Merge conflict between team + user override

User override wins. If both set same scalar, user value used.

Check merged result with resolver.

---

## I. Advanced topics

### Q47: Rewrite BMad sang Go/Rust/Python — bắt đầu từ đâu?

Đọc [14-rewrite-blueprint.md](14-rewrite-blueprint.md) — có:
- Effort estimate (6-12 weeks)
- Per-language recipes
- MVF phases (start với validator, then resolver, then installer)
- Code-level spec trong [08](08-installer-code-level-spec.md)

### Q48: Framework có telemetry không?

**Không có automatic telemetry.** Current version không thu thập data.

Nếu future có, sẽ là opt-in với clear disclosure.

### Q49: Performance optimization — installer chậm?

Chi tiết: [13 §4](13-operational-runbook.md)

Current bottlenecks:
1. File copy (sequential) — potential: parallel
2. SHA-256 hashing — potential: cache với mtime
3. Git clone — already --depth 1
4. npm install — potential: skip if deps unchanged

### Q50: Security considerations khi viết skill?

Chi tiết: [13 §3](13-operational-runbook.md)

Key points:
- No executable code in skills (markdown only)
- Validate user input at trust boundaries
- External modules = supply chain risk
- No sandboxing — user reviews generated code

### Q51: BMad v5 → v6 migration, có breaking changes gì?

Chi tiết: [12 §7](12-comparison-and-migration.md)

Main changes:
- Skills architecture introduced
- Directory structure: `.bmad/` → `_bmad/`
- Customization system (3-level TOML)
- Manifest files (manifest.yaml + CSV)
- Strict naming (bmad-* prefix)

### Q52: Có thể chạy BMad không cần installer (bare skills)?

Yes, manually:
1. Copy `src/core-skills/` and `src/bmm-skills/` to `_bmad/`
2. Create `_bmad/_config/config.yaml` manually
3. Configure IDE to find skills

Không recommended — installer handle edge cases.

### Q53: Skill marketplace — submit public skill?

Future feature. Currently:
1. Host skill on GitHub public repo với `module.yaml`
2. Users install via `--custom-source <url>`
3. Fork `bmad-plugins-marketplace` + PR để officially register

### Q54: Tôi muốn build business trên BMad (SaaS, consulting)?

MIT License — free to use commercially. Attribution appreciated (not required).

Community guideline:
- Share improvements back if generic
- Don't claim BMad trademark
- Respect [TRADEMARK.md](../TRADEMARK.md)

### Q55: Framework roadmap, feature nào đang làm?

Xem [docs/roadmap.mdx](../docs/roadmap.mdx) hoặc Discord announcements.

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

## Không tìm thấy câu trả lời?

1. **Search docs:** `grep -r "your question" /home/miendq1/study/research/sdd/BMAD-METHOD/dev/`
2. **Read README.md** để navigate
3. **Discord:** <https://discord.gg/gk8jAdXWmj>
4. **GitHub Issues:** <https://github.com/bmad-code-org/BMAD-METHOD/issues>

---

**Đọc tiếp:** [17-cheat-sheet.md](17-cheat-sheet.md) — Quick reference 1-page.
