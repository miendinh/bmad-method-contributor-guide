# 01. Triết lý & Nguyên lý thiết kế BMAD-METHOD

> ⚠️ **UNOFFICIAL THIRD-PARTY DOCUMENTATION**
> Không phải official BMad docs. Xem [DISCLAIMER.md](DISCLAIMER.md) | Licensed MIT — xem [LICENSE](LICENSE) và [NOTICE](NOTICE)
> Official BMAD-METHOD: <https://github.com/bmad-code-org/BMAD-METHOD>

---

> Hiểu **VÌ SAO** framework được thiết kế như vậy. Không có phần này, mọi kỹ thuật phía sau sẽ trông arbitrary.

---

## Mục lục

1. [Triết lý gốc: "Human Amplification, Not Replacement"](#1-triết-lý-gốc-human-amplification-not-replacement)
2. [Nguyên lý kiến trúc (10 nguyên lý)](#2-nguyên-lý-kiến-trúc-10-nguyên-lý)
3. [Các tách biệt cốt lõi](#3-các-tách-biệt-cốt-lõi)
4. [Concepts đặc thù](#4-concepts-đặc-thù)
5. [So sánh với hệ khác](#5-so-sánh-với-hệ-khác)
6. [Khi nào KHÔNG nên dùng BMad](#6-khi-nào-không-nên-dùng-bmad)

---

## 1. Triết lý gốc: "Human Amplification, Not Replacement"

Câu này xuất hiện ở dòng đầu của [CONTRIBUTING.md](../CONTRIBUTING.md). Nó không chỉ là slogan marketing — nó lèo lái mọi quyết định kỹ thuật trong framework.

### 1.1 Ba câu hỏi BMad hỏi trước mỗi feature

> *Every contribution should answer: "Does this make humans and AI better together?"*

Ba kiểm thử mà contributor phải pass:

1. **✅ Strengthens collaboration?** — AI giỏi lên khi hợp tác với human, human giỏi lên khi hợp tác với AI
2. **❌ Sidelines human?** — Feature tự động hóa hoàn toàn bị từ chối
3. **❌ Creates adoption barrier?** — Complexity mà user phải leo dốc quá cao không được chấp nhận

### 1.2 Hệ quả cụ thể lên code

Triết lý này thể hiện ra code qua 4 pattern:

| Pattern | Mô tả | Nơi thấy |
|---------|-------|----------|
| **HALT at checkpoints** | AI phải dừng tại menu, đợi user chọn | Mọi `workflow.md` steps có `<ask>` hoặc menu |
| **Confirm before destructive** | AI confirm trước khi delete/overwrite | `bmad-dev-story` step 8 (validation gates) |
| **Skill-level-aware communication** | AI điều chỉnh cách nói theo `{user_skill_level}` | Frontmatter `user_skill_level`: beginner/intermediate/expert |
| **Explicit handoff** | Mỗi phase kết thúc bằng user approval | Giữa Planning → Solutioning → Implementation |

### 1.3 Anti-pattern bị từ chối thẳng tay

Trích nguyên văn từ CONTRIBUTING.md:

> *We will reject PRs that read like raw LLM output: bulk refactors nobody asked for, unsolicited "improvements" across many files, or changes where the submitter clearly hasn't read the existing code. Using AI to write code is normal here; **using AI as a substitute for thinking is not**.*

BMad coi AI như một **thợ lành nghề** cần human curation, không phải **oracle** ra quyết định.

---

## 2. Nguyên lý kiến trúc (10 nguyên lý)

### Nguyên lý 1: Filesystem là Truth

**Phát biểu:** Mọi state (workflow state, agent memory, phase artifact) đều lưu trong file. Không có DB, không có in-memory state giữa session.

**Vì sao:**
- **AI session ngắn, user task dài** — conversation có thể bị compact, reset, switch IDE. Nếu state lưu trong chat history thì sẽ mất.
- **Git-native** — file trong filesystem → git track được → rollback, diff, PR review hoạt động ngay
- **Portable** — user có thể đem `_bmad/` sang máy khác, IDE khác, agent khác

**Trade-off:**
- ✅ Reliable, debuggable, diffable
- ❌ Chậm hơn in-memory; user thấy nhiều file "rác"

**Pattern cụ thể:**
```
Story file lưu ở:       {implementation_artifacts}/1-2-user-auth.md
Sprint status lưu ở:    {implementation_artifacts}/sprint-status.yaml
Brainstorm output lưu ở: {output_folder}/brainstorming/brainstorming-session-{date}.md
```

### Nguyên lý 2: Declarative > Imperative

**Phát biểu:** Workflow được viết bằng **Markdown + YAML/TOML**, không phải code. Validator cũng viết bằng Markdown (`skill-validator.md`), enforce bằng JS deterministic tối thiểu.

**Vì sao:**
- **LLM đọc Markdown tự nhiên** — không cần parser đặc biệt
- **User đọc được** — một PM không biết code vẫn hiểu workflow
- **Diff dễ review** — thay đổi 1 step = thay đổi 1 file nhỏ

**Ví dụ:**

❌ Imperative (cách KHÔNG dùng):
```js
async function brainstorm() {
  const topic = await askUser("What topic?");
  const techniques = loadTechniques();
  // ...
}
```

✅ Declarative (cách BMad dùng):
```markdown
## YOUR TASK
Ask the user for a topic, then load brain-methods.csv and select techniques...
## NEXT
Read fully and follow: `./step-02a-user-selected.md`
```

### Nguyên lý 3: Document-as-Interface

**Phát biểu:** Các phase giao tiếp với nhau **qua file output**, không qua biến, memory, hay API.

```
Phase 1 output: product-brief.md
              ↓ (file handoff)
Phase 2 input: product-brief.md → tạo prd.md
              ↓ (file handoff)
Phase 3 input: prd.md → tạo architecture.md + stories/*.md
              ↓ (file handoff)
Phase 4 input: stories/*.md → code
```

**Vì sao:**
- **Asynchronous** — Phase 1 có thể xong tháng trước, phase 2 làm tháng sau
- **Multi-agent friendly** — PM agent và Architect agent không cần chạy cùng lúc
- **Auditable** — mọi quyết định lưu lại trong file, không phải trong chat
- **Resume-able** — workflow dừng giữa chừng vẫn tiếp được

### Nguyên lý 4: Micro-file Workflows

**Phát biểu:** Workflow không phải 1 file khổng lồ, mà là tập hợp **step files độc lập** ~2-5KB mỗi file.

```
bmad-brainstorming/
└── steps/
    ├── step-01-session-setup.md      (2.3KB)
    ├── step-01b-continue.md          (1.8KB)
    ├── step-02a-user-selected.md     (2.1KB)
    ├── step-02b-ai-recommended.md    (2.4KB)
    ├── step-02c-random-selection.md  (1.9KB)
    ├── step-02d-progressive-flow.md  (2.2KB)
    ├── step-03-technique-execution.md (4.1KB)
    └── step-04-idea-organization.md  (2.8KB)
```

**Vì sao:**
- **LLM context window** — load just-in-time, giảm token usage
- **Sequential discipline** — AI không thể "nhảy cóc" nếu mỗi step là file riêng
- **Parallel branching** — step-02a/02b/02c/02d là 4 nhánh, chỉ load 1 khi chạy
- **Editable** — fix lỗi 1 step không đụng chạm step khác

**Quy tắc thiết kế:**
- Mỗi step **≤ 5KB**
- Step đầu PHẢI có `YOUR TASK`
- Step cuối PHẢI chỉ step NEXT (trừ step kết thúc)
- Tổng số steps **2-10** (không nhiều hơn)
- Không forward-loading (không đọc future step)

### Nguyên lý 5: Sequential by Default

**Phát biểu:** Workflow chạy tuần tự. Không có parallel execution, không có async branching ở runtime (chỉ conditional branching declarative).

**Vì sao:**
- **LLM dễ lạc** khi có nhiều thread song song
- **Human-in-the-loop** cần điểm dừng rõ ràng
- **State đơn giản** — không race condition, không merge conflict

**Trường hợp ngoại lệ:** `bmad-party-mode` — multi-agent collaboration session, nhưng nó orchestrate sequential conversations chứ không parallel execution.

### Nguyên lý 6: Encapsulated Skills (PATH-05)

**Phát biểu:** Một skill **KHÔNG được đọc file của skill khác**. Muốn dùng thì phải **invoke** skill đó qua `bmad-agent` hoặc `skill:` reference.

```
❌ SAI: {project-root}/_bmad/skills/bmm/bmad-create-prd/template.md
✅ ĐÚNG: Invoke the `bmad-create-prd` skill
```

**Vì sao:**
- **Encapsulation** — skill có thể refactor internals mà không break dependents
- **Testable** — skill test như black box
- **Versionable** — skill bumped version không phá consumer
- **Analog: microservices** — không reach vào DB của service khác

**Hệ quả:** Muốn share template giữa skills → tách ra thành 1 skill thứ 3 mà cả hai invoke.

### Nguyên lý 7: Config-Driven Paths

**Phát biểu:** Mọi path phải dùng **biến config** (`{planning_artifacts}`, `{project-root}`), không hardcode.

```
❌ SAI:  /Users/alice/project/docs/prd.md
❌ SAI:  ~/project/docs/prd.md
❌ SAI:  ./docs/prd.md  (khi chạy từ skill ở nơi khác)
✅ ĐÚNG: {planning_artifacts}/prd.md
```

**Vì sao:**
- **Multi-user** — Alice lưu ở `docs/`, Bob lưu ở `planning/`, cả hai cùng chạy skill
- **Relocatable** — đổi output folder không cần sửa 100 files
- **Installer-controllable** — installer prompt user chọn, ghi vào config

### Nguyên lý 8: Declarative Validation

**Phát biểu:** Rules viết bằng **Markdown** (`tools/skill-validator.md`), enforce bằng:
- **JS deterministic** (`tools/validate-skills.js`) — 14 rules có thể check bằng regex/AST
- **LLM inference** — 16+ rules cần judgment (đọc spec và review)

**Vì sao:**
- **Self-documenting** — rule cũng là docs
- **Extensible** — thêm rule không cần code, chỉ viết markdown
- **LLM-reviewable** — validator CHÍNH NÓ có thể được AI đọc và apply

**Ví dụ rule:**

```markdown
### SKILL-04 - `name` Format
- **Severity:** HIGH
- **Applies to:** SKILL.md
- **Rule:** The `name` value must start with `bmad-`, use only lowercase letters, numbers, and single hyphens...
- **Detection:** Regex test: `^bmad-[a-z0-9]+(-[a-z0-9]+)*$`
- **Fix:** Rename to comply with the format (e.g., `bmad-my-skill`).
```

Rule này vừa là **human spec** vừa là **machine check** (regex viết sẵn) vừa là **LLM prompt** (fix guidance).

### Nguyên lý 9: Layered Customization (3-level)

**Phát biểu:** Mỗi skill/agent có 3 tầng override:

```
Level 1: {skill-root}/customize.toml            ← Default (shipped)
Level 2: {project-root}/_bmad/custom/skill.toml  ← Team
Level 3: {project-root}/_bmad/custom/skill.user.toml ← Individual
```

**Merge semantics:**
- Scalars: user wins (override)
- Arrays (`persistent_facts`): append (không override)
- Array-of-tables có `code`/`id`: match thì replace, mới thì append

**Vì sao:**
- **Team có thể đặt standard** (Level 2) mà không đụng framework source
- **Individual có thể tùy biến** (Level 3) mà không phá team convention
- **Framework update** không xóa customization

### Nguyên lý 10: Human-in-the-Loop tại Checkpoints

**Phát biểu:** AI không chạy xuyên suốt. Nó HALT tại các điểm quan trọng và đợi user.

**Các checkpoint điển hình:**

| Checkpoint | Thời điểm | Hành động user |
|-----------|-----------|----------------|
| **Menu chọn option** | Đầu workflow, chia nhánh | Chọn [1/2/3/...] |
| **Approval chuyển phase** | PRD xong → Architecture | "Approve" hoặc "Revise" |
| **Story review** | Dev xong story → ready-for-review | Code review, approve/request changes |
| **Correct course** | Sprint giữa chừng có issue | Confirm thay đổi scope |
| **Validation gate** | Trước khi commit/ship | Confirm tests pass |
| **Ambiguity detected** | Workflow gặp spec mơ hồ | Clarify |

**Pattern code trong workflow.md:**

```xml
<check if="new dependencies required">
  HALT: "Additional dependencies need user approval"
</check>

<action if="3 consecutive implementation failures occur">
  HALT and request guidance
</action>
```

---

## 3. Các tách biệt cốt lõi

BMad kiên quyết tách bạch vài cặp mà nhiều team làm lẫn.

### 3.1 "XÂY GÌ" vs "XÂY NHƯ THẾ NÀO"

Đây là **tách biệt quan trọng nhất** của BMad, được nhắc trong [docs/vi-vn/bmad-developer-guide.md](../docs/vi-vn/bmad-developer-guide.md):

| Câu hỏi | Phase | Output | Agent |
|---------|-------|--------|-------|
| **XÂY GÌ? Vì sao?** | Phase 2 (Planning) | PRD, UX Design | John (PM), Sally (UX) |
| **XÂY NHƯ THẾ NÀO?** | Phase 3 (Solutioning) | Architecture, Stories | Winston (Architect) |

> *Nhiều dự án thất bại vì triển khai khi chưa thống nhất được "XÂY GÌ", hoặc bắt đầu code mà chưa quyết định "XÂY NHƯ THẾ NÀO"*

**Hệ quả thực tế:**
- PRD không được chứa technical decisions (no "use React", no "use Postgres")
- Architecture không được chứa requirements (không "user phải login được")
- Nếu PM viết tech → lỗi; nếu Architect viết req → lỗi

### 3.2 Agent vs Skill vs Workflow

| | Agent | Skill | Workflow |
|---|-------|-------|----------|
| **Là gì** | Persona (nhân vật) | Đơn vị công việc | Logic trong 1 skill |
| **Có tên** | Mary, John, Amelia... | `bmad-create-prd` | (không tên riêng) |
| **Có menu** | Có (list of skills) | Không | Không |
| **Invoke ai** | Invoke skill | Invoke sub-skill | Invoke next step |
| **Ví dụ** | `bmad-agent-pm` | `bmad-create-prd` | `workflow.md` trong skill |

### 3.3 Planning artifact vs Implementation artifact vs Project knowledge

| | Planning artifacts | Implementation artifacts | Project knowledge |
|---|-------------------|--------------------------|-------------------|
| **Lưu ở** | `{planning_artifacts}` | `{implementation_artifacts}` | `{project_knowledge}` |
| **Sinh bởi phase** | Phase 1-3 | Phase 4 | Research, document-project |
| **Tần suất update** | Ít (lock sau approval) | Liên tục | Theo batch |
| **Ví dụ** | brief, PRFAQ, PRD, architecture, epics | sprint-status.yaml, stories, reviews | tech-stack.md, coding-standards.md |
| **Default folder** | `_bmad-output/planning-artifacts` | `_bmad-output/implementation-artifacts` | `docs/` |

### 3.4 Config variable vs Runtime variable

| | Config variable | Runtime variable |
|---|----------------|------------------|
| **Nguồn** | `_bmad/{module}/config.yaml` | Set trong lúc execute |
| **Khi có** | Install-time (user answer prompt) | Runtime |
| **Ví dụ** | `{user_name}`, `{planning_artifacts}` | `{date}`, `{story_key}`, `{spec_file}` |
| **Declare ở** | `module.yaml` | `workflow.md` frontmatter |
| **Stable** | Có, cả session | Không, per-execution |

### 3.5 Invoke vs Read

Đây là điểm **SEQ-01 / REF-03** — ngôn từ có ý nghĩa:

| Cách nói | Ý nghĩa | Dùng khi |
|----------|---------|----------|
| "**Invoke the** `bmad-xxx` **skill**" | Gọi skill như black box | Cross-skill |
| "Read fully and follow `./step-02.md`" | Đọc file cùng skill | Intra-skill (step → next step) |
| "Load `{project-root}/.../config.yaml`" | Đọc config data file | Load data |

**Dùng sai = validation fail.** Ví dụ:

```
❌ "Execute bmad-create-prd"            (SEQ-01 fail)
❌ "Read fully: bmad-create-prd"         (PATH-05 + REF-03 fail)
✅ "Invoke the `bmad-create-prd` skill"
```

---

## 4. Concepts đặc thù

BMad có vài concept riêng mà không tìm thấy ở framework khác. Liệt kê để bạn ghi nhớ.

### 4.1 Named Agents (Persona)

Mỗi agent có **tên riêng + icon + personality + communication style**:

| Agent | Tên | Style giao tiếp |
|-------|-----|-----------------|
| Analyst | Mary 📊 | "Treasure hunter narrating the find: thrilled by every clue, precise once the pattern emerges" |
| PM | John 📋 | "Detective interrogating a cold case: short questions, sharper follow-ups, every 'why?' tightening the net" |
| UX | Sally 🎨 | "Filmmaker pitching the scene before the code exists" |
| Architect | Winston 🏗️ | "Seasoned engineer at the whiteboard: measured, laying out trade-offs" |
| Dev | Amelia 💻 | "Terminal prompt: exact file paths, AC IDs, commit-message brevity" |
| Tech Writer | Paige 📚 | "Patient teacher, using analogies that make complex things feel simple" |

**Vì sao đặt tên?**
- **Mental model** — user dễ nhớ "hỏi John" hơn "hỏi PM agent"
- **Context switching** — "switching from John to Winston" rõ hơn "switching from PM mode to Architect mode"
- **Behavioral cue cho AI** — LLM adopt style khi có persona cụ thể (xem [docs/explanation/named-agents.md](../docs/explanation/named-agents.md))

### 4.2 Party Mode

**Multi-agent collaboration session** — nhiều agent cùng bàn luận một vấn đề, user đóng vai orchestrator.

**Khi dùng:**
- Cross-functional problems (PM + Architect + UX cùng discuss)
- Trade-off nặng cần nhiều góc nhìn
- Brainstorm cấp cao (không dùng `bmad-brainstorming` đơn lẻ)

**Cơ chế:** Không parallel execution. Agent này nói xong, agent khác phản hồi, theo lượt (round-robin hoặc user-directed).

### 4.3 Adversarial Review

**Review có mục đích TÌM LỖI**, không phải validate.

Khác với code review thông thường:

| Code review thường | Adversarial review |
|-------------------|---------------------|
| "Có vẻ OK" | "Nếu user nhập null thì sao?" |
| Confirm design works | Thử phá design |
| Focus: best practices | Focus: edge cases, failure modes |

**Skills:**
- `bmad-review-adversarial-general` — general adversarial
- `bmad-review-edge-case-hunter` — chuyên edge case
- `bmad-editorial-review-prose` — review văn bản
- `bmad-editorial-review-structure` — review cấu trúc doc

**Philosophy:** "AI có tendency validate những gì nó đã viết. Adversarial mindset phải được **inject explicitly**."

### 4.4 Advanced Elicitation

**Kỹ thuật hỏi user để lộ ra giả định ngầm.**

Các kỹ thuật điển hình:
- **Five Whys** — hỏi "why?" 5 lần
- **Pre-mortem** — "Giả sử dự án thất bại, lý do là gì?"
- **Rubber duck** — user giải thích cho "duck" (AI)
- **Inversion** — "Ngược lại với mục tiêu, ta làm gì?"
- **Red team** — "Ai sẽ ghét feature này và tại sao?"

Dùng khi user **nghĩ mình đã rõ** nhưng thực chất còn mơ hồ.

### 4.5 Checkpoint Preview

**Xem trước thay đổi sẽ commit, review trước khi ship.**

Không phải `git diff` thuần — nó bao gồm:
- Code diff
- Ảnh hưởng đến stories khác
- Tests bị ảnh hưởng
- Acceptance criteria còn thiếu

Đóng vai trò: **last human gate** trước khi code ship.

### 4.6 Correct Course

**Điều chỉnh giữa sprint khi phát hiện sai hướng.**

Tình huống:
- Story đang dev thì realize spec sai
- Architecture gặp constraint mới
- Stakeholder đổi yêu cầu

Skill `bmad-correct-course` xử lý rollback artifact, update sprint, log reason.

**Không phải "reset"** — nó preserve context và document rõ vì sao đổi hướng.

### 4.7 Quick Dev vs Full Flow

Hai luồng, khác nhau ở **độ nặng**:

| Quick Dev | Full Flow |
|-----------|-----------|
| Skill: `bmad-quick-dev` | Skills: `bmad-create-story` → `bmad-dev-story` → ... |
| 1-15 stories | 10-50+ stories |
| Không cần PRD formal | Cần PRD + Architecture |
| Agent: Amelia only | All 6 agents |
| Dùng khi: bugfix, small feature | Dùng khi: product/platform |

**Rule chọn:** Nếu không chắc, dùng `bmad-help` — nó sẽ recommend.

### 4.8 Shard Doc

**Chia tài liệu lớn thành chunks** để LLM xử lý.

Vấn đề: PRD 20 trang → exceeds context window của step nhỏ.

Giải pháp: `bmad-shard-doc` split thành files nhỏ, giữ metadata để re-assemble.

### 4.9 Project Context

**Khác PRD, khác Architecture, khác README.**

Là file chứa:
- Tech stack (ngôn ngữ, framework, lib chính)
- Coding standards
- Repository layout
- Workflow git
- Build/deploy commands

Được sinh bởi `bmad-generate-project-context` (một lần hoặc periodically), dùng bởi dev agent làm context khi code.

### 4.10 Implementation Readiness

**Pre-flight check trước khi bắt đầu phase 4.**

Skill: `bmad-check-implementation-readiness`

Checklist gồm:
- Architecture có đủ detail không?
- Stories có acceptance criteria rõ không?
- Dev environment setup xong chưa?
- Dependencies đã approved?

Nếu fail → quay lại phase 3 bổ sung.

### 4.11 Distillator

**Nén tài liệu** (compression). Khác shard-doc (chia):

| Shard doc | Distillator |
|-----------|-------------|
| Chia file to → files nhỏ | Nén file to → file nhỏ hơn |
| Preserve 100% info | Lose info, keep essence |
| Reversible | One-way (có round-trip reconstructor) |

Skill: `bmad-distillator` với `agents/distillate-compressor.md` và `agents/round-trip-reconstructor.md`.

### 4.12 Brainstorming Techniques

`bmad-brainstorming` có **CSV file** `brain-methods.csv` chứa **~30+ kỹ thuật**:

- SCAMPER, Six Thinking Hats, Mind Mapping
- Brainwriting, Reverse Brainstorming
- Analogy, Morphological Analysis
- Random Stimulation, Force Fitting
- ...

Mỗi technique có: name, description, when-to-use, example.

Anti-bias protocol: pivot kỹ thuật mỗi 10 ideas để tránh semantic clustering.

---

## 5. So sánh với hệ khác

### 5.1 BMad vs IDE AI (Cursor / Copilot / Claude Code raw)

| | Cursor/Copilot | BMad |
|---|---------------|------|
| **Scope** | Line-level suggestions | Feature-level workflows |
| **State** | Conversation only | Filesystem artifacts |
| **Phase separation** | Không | Planning ≠ Implementation |
| **Multi-agent** | Single agent | 6 personas |
| **Artifacts** | Không sinh ra | PRD, Architecture, Stories |

BMad **dùng chung với Cursor/Copilot** — nó layer trên top. User vẫn dùng Cursor để code, nhưng BMad cung cấp workflow có cấu trúc.

### 5.2 BMad vs Agent frameworks (LangGraph / CrewAI / AutoGen)

| | LangGraph/CrewAI | BMad |
|---|------------------|------|
| **Language** | Python code | Markdown + YAML |
| **State** | In-memory (graph state) | Filesystem |
| **Execution** | Runtime engine | AI đọc và follow |
| **Target user** | ML engineers | Product teams |
| **Extensibility** | Code new nodes | Write new markdown |
| **Debug** | Debug Python | Read output files |

**Khác biệt cốt lõi:** LangGraph là **engine chạy agent**, BMad là **prompt framework guiding agent**. Không có "BMad runtime" — AI tự đọc và follow.

### 5.3 BMad vs Template-based (rails generators, yeoman)

| | Template generators | BMad |
|---|--------------------|------|
| **Output** | File structure (one-shot) | Ongoing workflow |
| **Interactive** | Minimal prompt | Deep interactive |
| **Update** | Regenerate (phá custom) | Layered override |
| **AI-native** | Không | Có (designed for LLM) |

---

## 6. Khi nào KHÔNG nên dùng BMad

Thành thật mà nói, BMad không phải **one-size-fits-all**.

**Đừng dùng BMad nếu:**

1. **Hotfix cấp bách** (< 30 phút) — overhead install/workflow không xứng
2. **Solo dev, project < 500 LOC** — PRD/Architecture không cần thiết
3. **Research/spike** — BMad value ở structured delivery, không ở exploration
4. **Đã có process nặng** (SAFe, Scrum strict) — có thể conflict
5. **Team chống đổi** — BMad yêu cầu adopt mindset mới

**Dùng BMad khi:**

1. **Product/platform development** — có PRD, có stakeholders, có sprint
2. **Team 2-10 người** — cần shared artifacts
3. **Lifecycle dài** (tháng/năm) — artifact-based workflow có giá trị lâu dài
4. **AI-first workflow** — team muốn AI là first-class collaborator
5. **Cross-functional** — PM, Designer, Dev, QA cùng workflow

---

## 7. Roadmap (V6 & Beyond)

Từ [docs/vi-vn/index.md](../docs/vi-vn/index.md):

> *V6 đã ra mắt và chúng tôi mới chỉ bắt đầu!*
> *Kiến trúc Skills, BMad Builder v1, Dev Loop Automation, và nhiều thứ khác nữa đang được phát triển.*

**Hướng phát triển:**
- **BMad Builder** — tool để build module/skill mới (meta-framework)
- **Dev Loop Automation** — auto dev-review-deploy chain
- **Skills architecture v2** — enhanced skill spec

Xem [docs/roadmap.mdx](../docs/roadmap.mdx) cho chi tiết.

---

## Tóm lược

BMad không phải framework kỹ thuật đơn thuần. Nó là **biểu hiện của một triết lý**:

> *AI là lực tăng cường, không phải thay thế. Document là ngôn ngữ chung. Filesystem là truth. Tách GÌ với NHƯ THẾ NÀO. Dừng tại checkpoint để con người quyết.*

Hiểu triết lý này → hiểu vì sao mọi quyết định kỹ thuật (PATH-05, micro-file, 3-level override, named agents) tồn tại.

---

**Đọc tiếp:** [02-environment-and-variables.md](02-environment-and-variables.md) — đi sâu hệ thống biến môi trường.
