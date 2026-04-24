# 09a. Core Skills - Deep Dive (12 Skills)

> ⚠️ **UNOFFICIAL THIRD-PARTY DOCUMENTATION**
> Không phải official BMad docs. Xem [DISCLAIMER.md](DISCLAIMER.md) | Licensed MIT — xem [LICENSE](LICENSE) và [NOTICE](NOTICE)
> Official BMAD-METHOD: <https://github.com/bmad-code-org/BMAD-METHOD>

---

> Đặc tả chi tiết từng core skill, đủ để hiểu hoặc reimplement. Mỗi skill có: schema, workflow logic, state machine, edge cases, data shapes.

---

## Mục lục

- [C-1. bmad-advanced-elicitation](#c-1-bmad-advanced-elicitation)
- [C-2. bmad-brainstorming](#c-2-bmad-brainstorming)
- [C-3. bmad-customize](#c-3-bmad-customize)
- [C-4. bmad-distillator](#c-4-bmad-distillator)
- [C-5. bmad-editorial-review-prose](#c-5-bmad-editorial-review-prose)
- [C-6. bmad-editorial-review-structure](#c-6-bmad-editorial-review-structure)
- [C-7. bmad-help](#c-7-bmad-help)
- [C-8. bmad-index-docs](#c-8-bmad-index-docs)
- [C-9. bmad-party-mode](#c-9-bmad-party-mode)
- [C-10. bmad-review-adversarial-general](#c-10-bmad-review-adversarial-general)
- [C-11. bmad-review-edge-case-hunter](#c-11-bmad-review-edge-case-hunter)
- [C-12. bmad-shard-doc](#c-12-bmad-shard-doc)

---

## C-1. bmad-advanced-elicitation

### Metadata
- **Path:** `src/core-skills/bmad-advanced-elicitation/`
- **Files:** `SKILL.md` (143 dòng), `methods.csv`
- **Loại:** Inline skill (logic trong SKILL.md, không có workflow.md)

### Frontmatter
```yaml
name: bmad-advanced-elicitation
description: 'Push the LLM to reconsider, refine, and improve its recent output. Use when user asks for deeper critique or mentions a known deeper critique method, e.g. socratic, first principles, pre-mortem, red team.'
```

### Mục đích sâu
Skill được design để **break LLM confirmation bias** — LLM có xu hướng validate output của chính nó. Bằng cách apply một **specific reasoning method**, force LLM nhìn lại output qua một **cụ thể angle** (vs vague "try again").

### Input schema
- `content` (required) — Content vừa được sinh ra, cần cải thiện
- Party-mode participants (optional) — Agents join qua `resolve_config.py`
- `methods.csv` — 28+ reasoning methods với category, method_name, description, output_pattern

### Output schema
- Enhanced version của content
- Elicitation history (track các method đã apply)

### methods.csv schema
```csv
category,method_name,description,output_pattern
core,Pre-mortem,"Assume project failed, work backward to find risks","risks -> root causes -> mitigations"
structural,First Principles,"Strip assumptions, rebuild from ground truth","assumptions -> truths -> implications"
risk,Red Team,"Attack your own work as adversary","attack vectors -> weaknesses -> defenses"
```

**Category:** core, structural, risk, creative, perspective, validation
**Output pattern:** flexible guide, không strict format

### Workflow logic (3 steps)

#### Step 1: Method Registry Loading
```
1. Load ./methods.csv
2. If party-mode active, resolve agent roster:
   python3 {project-root}/_bmad/scripts/resolve_config.py --project-root {project-root} --key agents
3. Context analysis:
   - Conversation history
   - Content type, complexity, risk level
4. Smart selection of 5 methods:
   - Match context to descriptions
   - Balance foundational + specialized
```

#### Step 2: Present Options + Handle Response

**Display:**
```
**Advanced Elicitation Options**
_If party mode is active, agents will join in._
Choose a number (1-5), [r] to Reshuffle, [a] List All, or [x] to Proceed:

1. [Method Name]
2. [Method Name]
3. [Method Name]
4. [Method Name]
5. [Method Name]
r. Reshuffle
a. List all methods
x. Proceed
```

**Response handling:**

| User input | Action |
|-----------|--------|
| `1-5` | Execute method, show enhanced version, ask y/n to apply, HALT |
| `r` | Reshuffle 5 new diverse methods |
| `a` | List all with descriptions, user picks any |
| `x` | Return enhanced content, exit |
| Direct feedback | Apply, re-present |
| Multiple numbers | Execute sequence, re-offer |

#### Step 3: Execution Guidelines
- Method execution: use CSV description
- Output pattern: flexible guide
- Dynamic adaptation: simple → sophisticated based on content
- Content preservation: track all enhancements
- Iterative: each method builds on previous

### State machine

```
[Entry]
  ↓
[Load methods + roster]
  ↓
[Select 5 methods] ← context analysis
  ↓
[Present menu]
  ↓
[User response]
  ├─ 1-5 → [Execute method] → [Show enhanced] → [Ask apply?]
  │          ↓                                     ↓
  │       [Apply y/n]                          [HALT wait]
  │          ↓
  │       [Update content] → back to [Present menu]
  ├─ r → [Pick 5 new] → back to [Present menu]
  ├─ a → [List all] → [User picks] → [Execute]
  └─ x → [Return enhanced content]
```

### Code-ready spec

```typescript
interface ElicitationMethod {
  category: 'core' | 'structural' | 'risk' | 'creative' | 'perspective' | 'validation';
  method_name: string;
  description: string;
  output_pattern: string;
}

interface ElicitationContext {
  content: string;
  methods: ElicitationMethod[];
  history: Array<{method: string; applied: boolean; result: string}>;
  partyMode: boolean;
  agentRoster?: Agent[];
}

async function runElicitation(ctx: ElicitationContext): Promise<string> {
  let current = ctx.content;
  
  while (true) {
    const selected = selectMethods(ctx.methods, current, 5);
    const choice = await prompt.menu({ 
      options: [...selected, 'r', 'a', 'x'] 
    });
    
    if (choice === 'x') return current;
    if (choice === 'r') continue;
    if (choice === 'a') continue;  // Show all, pick
    
    const method = selected[parseInt(choice) - 1];
    const enhanced = await applyMethod(method, current, ctx);
    const apply = await prompt.confirm('Apply changes?');
    if (apply) {
      current = enhanced;
      ctx.history.push({ method: method.method_name, applied: true, result: enhanced });
    }
  }
}
```

---

## C-2. bmad-brainstorming

### Metadata
- **Path:** `src/core-skills/bmad-brainstorming/`
- **Files:** SKILL.md (7 dòng), workflow.md (55 dòng), template.md, brain-methods.csv, 8 step files
- **Loại:** Micro-file workflow

### Frontmatter
```yaml
name: bmad-brainstorming
description: 'Facilitate interactive brainstorming sessions using diverse creative techniques and ideation methods. Use when the user says help me brainstorm or help me ideate.'
```

### Mục đích sâu
**Anti-bias protocol:** LLM có xu hướng semantic clustering (ideas hội tụ). Skill này force AI **shift domain every 10 ideas** để maintain divergence.

**Quantity goal:** 100+ ideas before organizing — first 20 obvious, magic happens 50-100.

### Input schema
- `context_file` (optional) — Project-specific guidance
- Config: `project_name`, `output_folder`, `user_name`, `communication_language`, `document_output_language`, `user_skill_level`

### Output schema
- File: `{output_folder}/brainstorming/brainstorming-session-{date}-{time}.md`
- Structure:
  ```markdown
  # Brainstorming Session — {date}
  
  ## Topic
  ## Goals
  ## Techniques Used
  ## Ideas Generated
  - [100+ ideas grouped by theme]
  ## Organization & Prioritization
  ## Next Steps
  ```

### Brain methods CSV

Schema:
```csv
name,category,description,steps,when_to_use,example
SCAMPER,modification,"Substitute Combine Adapt Modify Put-to-use Eliminate Reverse","1. For each dim, apply to topic...","When mature concept needs iteration","..."
Lateral Thinking,creative,"...","...","...","..."
Reverse Brainstorming,inversion,"...","...","...","..."
Mind Mapping,structural,"...","...","...","..."
Random Word Association,random,"...","...","...","..."
Role-playing,perspective,"Think as customer/competitor/alien","...","...","..."
Constraint Relaxation,lateral,"...","...","...","..."
...
```

**Categories:** modification, creative, inversion, structural, random, perspective, lateral, decomposition.

~30+ techniques total.

### Workflow logic (step-file architecture)

```
step-01-session-setup
  ├─ Define topic, goals, constraints
  ├─ Check continuation?
  │   └─ YES → step-01b-continue
  └─ Choose approach:
      ├─ step-02a-user-selected (manual pick)
      ├─ step-02b-ai-recommended (AI suggests 5)
      ├─ step-02c-random-selection (pick random from CSV)
      └─ step-02d-progressive-flow (structured progression)
           ↓
     step-03-technique-execution (run techniques, pivot every 10 ideas)
           ↓
     step-04-idea-organization (group, prioritize, finalize)
```

### Step details

**step-01-session-setup.md:**
- Welcome user in `{communication_language}`
- Ask topic, goals, constraints
- Check if existing session file exists → continuation option
- Ask approach: 1 (user pick) / 2 (AI recommend) / 3 (random) / 4 (progressive)
- Initialize session file với frontmatter

**step-01b-continue.md:**
- Load existing session file
- Show previous ideas summary
- Ask user: continue adding or finalize?

**step-02a-user-selected.md:**
- List all techniques from brain-methods.csv
- User picks 1-3 techniques
- Load selected technique descriptions

**step-02b-ai-recommended.md:**
- Analyze topic + goals
- AI picks 5 most relevant techniques
- User confirms or reshuffles

**step-02c-random-selection.md:**
- Random pick 3-5 techniques
- Diverse categories guarantee

**step-02d-progressive-flow.md:**
- Structured sequence: divergent → lateral → structural → convergent
- 4-5 techniques chained

**step-03-technique-execution.md:**
- For each selected technique:
  - Apply protocol from CSV
  - Generate ideas (aim 20+ per technique)
  - **Every 10 ideas: pivot domain** (anti-bias)
  - Append to session file
- Total goal: 100+ ideas

**step-04-idea-organization.md:**
- Group ideas by theme
- Prioritize (user input: impact × feasibility)
- Action next steps
- Save final session

### Anti-bias protocol (detail)

**Quy tắc:** After every 10 ideas in a technique, force domain shift:
- Technical ⇌ UX
- Business ⇌ Edge cases
- Mainstream ⇌ Edge cases
- Orthogonal category

**Reason:** LLM sequential bias makes later ideas cluster semantically. Forced pivot maintains divergence.

### State machine

```
[Setup]
  ↓
[Continuation check]
  ├─ existing → [Continue]
  └─ fresh → [Approach choice]
              ↓
          ┌───┴───┬───┬───┐
          ↓       ↓   ↓   ↓
         02a     02b 02c 02d
          └───┬───┴───┴───┘
              ↓
          [Execute techniques]
              ↓ loop
          [Pivot every 10 ideas]
              ↓
          [100+ ideas generated]
              ↓
          [Organize + prioritize]
              ↓
          [Save session file]
```

### Code-ready spec

```typescript
interface BrainstormSession {
  topic: string;
  goals: string[];
  constraints: string[];
  techniques: string[];
  ideas: Array<{ text: string; technique: string; theme?: string }>;
  outputPath: string;
}

async function runBrainstorm(session: BrainstormSession) {
  while (session.ideas.length < 100) {
    for (const technique of session.techniques) {
      const initialCount = session.ideas.length;
      let pivotCount = 0;
      
      while (pivotCount < 10 && session.ideas.length - initialCount < 20) {
        const newIdeas = await generateIdeas(technique, session);
        session.ideas.push(...newIdeas);
        pivotCount++;
      }
      
      // Pivot domain after 10 ideas
      shiftDomain(session);
    }
  }
  
  return organizeAndSave(session);
}
```

---

## C-3. bmad-customize

### Metadata
- **Path:** `src/core-skills/bmad-customize/`
- **Files:** SKILL.md, `scripts/list_customizable_skills.py`, `scripts/tests/`
- **Loại:** Interactive skill with Python helper

### Frontmatter
```yaml
name: bmad-customize
description: 'Author and update customization overrides for installed BMad skills. Use when "customize bmad", "override a skill", "change agent behavior", "customize a workflow".'
```

### Mục đích sâu
Guide user viết **customize override TOML** mà không cần biết TOML syntax. Skill translate plain English → TOML fragments, handle merge semantics correctly.

### Input schema
- User intent (natural language)
- Project root (must have `_bmad/` directory)
- Target skill's `customize.toml` (default)

### Output schema
- Override file: `_bmad/custom/{skill-name}.toml` (team) hoặc `.user.toml` (user)
- Verification via `resolve_customization.py`

### Workflow (6 steps)

**Step 1: Preflight**
- Check `_bmad/` exists
- Check resolver script exists: `{project-root}/_bmad/scripts/resolve_customization.py`
- If missing → HALT: "BMad not installed or resolver missing"

**Step 2: Classify Intent**
- **Directed:** User says "customize PM agent to use Jobs-to-be-Done framework" → skip discovery
- **Exploratory:** "What can I customize?" → run discovery
- **Audit:** "Review my current overrides" → show existing
- **Cross-cutting:** "Apply org policy across agents" → multiple files

**Step 3: Discovery** (if exploratory)
```bash
python3 {skill-root}/scripts/list_customizable_skills.py \
  --project-root {project-root}
```

Output JSON:
```json
[
  {
    "skill_name": "bmad-agent-pm",
    "path": "_bmad/bmm/agents/bmad-agent-pm",
    "has_team_override": true,
    "has_user_override": false,
    "customize_sections": ["agent"]
  },
  ...
]
```

Present skill list with override status flags.

**Step 4: Determine Surface**
- Agent surface: `[agent]` block (persona, menu, principles)
- Workflow surface: `[workflow]` block (hooks, facts, on_complete)
- Read existing override if present

**Step 5: Compose Override**
- Translate plain English → TOML
- Apply merge semantics:
  - Scalars (icon, role) → override
  - Arrays (principles, persistent_facts) → append
  - Keyed arrays (agent.menu) → match by code, replace or append

**Step 6: Show, Confirm, Write, Verify**
1. Show TOML diff
2. Wait for user confirm
3. Write to `_bmad/custom/{skill-name}.toml` or `.user.toml`
4. Run verifier:
```bash
python3 {project-root}/_bmad/scripts/resolve_customization.py \
  --skill {skill-install-path} --key agent
```
5. Show merged JSON, highlight changes

### Team vs User placement decision

| Change type | Level | Committed? |
|------------|-------|-----------|
| Org policy (compliance, standards) | Team (`.toml`) | Yes |
| Shared convention | Team (`.toml`) | Yes |
| Personal preference (language, tone) | User (`.user.toml`) | No (gitignored) |
| Experiment/temp | User (`.user.toml`) | No |

### Edge cases
- **Read-only fields** (name, title) — silent ignore when user tries to override
- **Menu item without `code`** — validator fails, guide user to add
- **Circular references** in TOML — not detected by resolver, warn
- **Array duplicates** — not deduped, warn if potential duplicate

### Code-ready spec

```python
from dataclasses import dataclass
from pathlib import Path

@dataclass
class CustomizeIntent:
    target_skill: str
    section: Literal["agent", "workflow"]
    changes: dict
    level: Literal["team", "user"]

def compose_toml(intent: CustomizeIntent) -> str:
    """Translate intent → TOML."""
    lines = [f"[{intent.section}]"]
    
    for key, value in intent.changes.items():
        if isinstance(value, list):
            lines.append(f"{key} = {toml_array(value)}")
        elif isinstance(value, dict):
            lines.append(f"[[{intent.section}.{key}]]")
            for k, v in value.items():
                lines.append(f"{k} = {toml_value(v)}")
        else:
            lines.append(f"{key} = {toml_value(value)}")
    
    return "\n".join(lines)

def verify_merge(skill_path: Path, project_root: Path) -> dict:
    """Run resolver, return merged JSON."""
    result = subprocess.run([
        "python3",
        str(project_root / "_bmad" / "scripts" / "resolve_customization.py"),
        "--skill", str(skill_path),
        "--key", "agent"
    ], capture_output=True)
    return json.loads(result.stdout)
```

---

## C-4. bmad-distillator

### Metadata
- **Path:** `src/core-skills/bmad-distillator/`
- **Files:** SKILL.md (176 dòng), `scripts/analyze_sources.py`, `agents/distillate-compressor.md`, `agents/round-trip-reconstructor.md`, `resources/compression-rules.md`, `resources/distillate-format-reference.md`, `resources/splitting-strategy.md`
- **Loại:** Multi-agent spawning skill

### Frontmatter
```yaml
name: bmad-distillator
description: 'Lossless LLM-optimized compression of source documents. Use when the user requests to "distill documents" or "create a distillate".'
```

### Mục đích sâu
**Compression (lossless)** != Summarization (lossy).
- **Summary:** bỏ details, keep essence
- **Distillate:** keep every fact, decision, constraint, relationship. Strip formatting overhead.

**Use case:** Context for downstream LLM workflow, e.g., PRD creation receiving distilled product brief + research.

### Input schema
- `source_documents` (required) — File paths, folder paths, glob patterns
- `downstream_consumer` (optional) — e.g., "PRD creation", "architecture design"
- `token_budget` (optional) — Target size
- `output_path` (optional) — Default: adjacent to source
- `--validate` (flag) — Round-trip validation

### Output schema

**Single distillate** (≤5000 tokens):
```yaml
---
type: bmad-distillate
sources:
  - "path/to/source1.md"
  - "path/to/source2.md"
downstream_consumer: "PRD creation"
created: "2026-04-24"
token_estimate: 4500
parts: 1
---

## Theme 1
- Fact 1 (specific, self-contained)
- Fact 2

## Theme 2
...
```

**Split distillate** (>5000 tokens):
```
base-name-distillate/
├── _index.md           # Orientation + section manifest + cross-cutting items
├── 01-topic-slug.md    # Self-contained section
├── 02-topic-slug.md
└── 03-topic-slug.md
```

### 4 stages

**Stage 1: Analyze**
```bash
python3 scripts/analyze_sources.py {source_paths}
```
Output: routing recommendation (`single` vs `fan-out`) + groupings + token estimate.

**Stage 2: Compress**

**Single mode** (routing=`single`, ≤3 files, ≤15K tokens):
- Spawn 1 subagent with `agents/distillate-compressor.md`
- Pass all source paths
- Receive JSON: content, headings, named entities, token estimate

**Fan-out mode** (routing=`fan-out`):
- Spawn 1 compressor per group (parallel)
- Each produces intermediate distillate
- Spawn final **merge compressor** với intermediate distillates as input
- Final compressor: cross-group dedup, thematic regroup, final compression

**Graceful degradation:** If subagent unavailable, main agent reads sources and compresses inline.

**Stage 3: Verify & Output**
1. **Completeness check:** Every heading + named entity in original must appear in distillate
2. **Format check:**
   - No prose paragraphs (bullets only)
   - No decorative formatting
   - No repeated info
   - Bullets self-contained
   - Themes with `##` headings
3. **Save output** (single file hoặc split folder)
4. **Measure** — run `analyze_sources.py` on distillate để get actual token count
5. **Report JSON:**
```json
{
  "status": "complete",
  "distillate": "path",
  "source_total_tokens": 12000,
  "distillate_total_tokens": 3500,
  "compression_ratio": "3.4:1",
  "completeness_check": "pass"
}
```

**Stage 4: Round-Trip Validation** (only if `--validate`)
- Spawn reconstructor agent (`agents/round-trip-reconstructor.md`)
- Reconstructor ONLY sees distillate (not originals)
- Receives reconstruction
- Semantic diff:
  - Core info present?
  - Specific details preserved (numbers, names, decisions)?
  - Relationships intact?
  - Hallucinations detected?
- Produce `-validation-report.md`

### Distillate format rules (from resources/compression-rules.md)
- **Bullets only** — no prose paragraphs
- **Self-contained bullets** — each bullet makes sense alone
- **Dense but specific** — `"Node.js 20.x (strict mode enabled, Vitest for testing, not Jest)"` not `"Use Node.js"`
- **Themes delineated with ##** — no nested ###
- **No decorative formatting** — no bold, italic, tables unless data-bearing
- **No chronology** — organize by theme, not date
- **Include rejected ideas** — with rationale (future value)
- **Include open questions** — flag unresolved

### Splitting strategy (from resources/splitting-strategy.md)
- **Threshold:** ~5000 tokens for single file
- **Beyond threshold:** Semantic split by theme
- **_index.md:**
  - 3-5 bullet orientation
  - Section manifest (filename + 1-line description)
  - Cross-cutting items (span multiple sections)
- **Section files:** Self-contained, loadable independently, 1-line context header

### Compressor agent prompt (summary)
```markdown
# Distillate Compressor Sub-Agent

## Input
- source_files: [paths]
- downstream_consumer: "string"
- token_budget: number

## Task
1. Read ALL source files completely
2. Extract every fact, decision, constraint, relationship
3. Strip formatting overhead:
   - Remove prose that doesn't carry new info
   - Collapse examples to one if redundant
   - Remove transitional phrases ("In this document...", "As we've seen...")
4. Organize by THEME (not chronology)
5. Write dense bullets, self-contained
6. Return JSON: { content, headings, named_entities, token_estimate }
```

### Round-trip reconstructor prompt (summary)
```markdown
# Round-Trip Reconstructor Sub-Agent

## Input
- distillate_file (ONLY)

## Task
1. Read distillate
2. Try to reconstruct original source documents from distillate alone
3. Write full-prose reconstruction
4. Flag possible gap markers where distillate had insufficient info

## Critical
- You must NOT have access to originals
- Gaps indicate distillate lost info
- Hallucinations indicate you filled gaps with confabulation
```

### Code-ready spec

```python
async def distill(
    source_documents: list[Path],
    downstream_consumer: str | None = None,
    token_budget: int | None = None,
    output_path: Path | None = None,
    validate: bool = False
) -> DistillResult:
    # Stage 1: Analyze
    analysis = run_analyze_sources(source_documents)
    
    # Stage 2: Compress
    if analysis.routing == "single":
        result = await spawn_compressor(source_documents, downstream_consumer)
    else:  # fan-out
        intermediates = await asyncio.gather(*[
            spawn_compressor(group, downstream_consumer)
            for group in analysis.groupings
        ])
        result = await spawn_merge_compressor(intermediates)
    
    # Stage 3: Verify & Output
    check_completeness(result, analysis)
    check_format(result)
    
    if result.token_estimate > 5000 or token_budget:
        save_split_distillate(result, output_path)
    else:
        save_single_distillate(result, output_path)
    
    # Stage 4: Validate (optional)
    if validate:
        await round_trip_validate(result)
    
    return DistillResult(
        status="complete",
        distillate=output_path,
        compression_ratio=f"{source_tokens / result.token_estimate:.1f}:1"
    )
```

---

## C-5. bmad-editorial-review-prose

### Metadata
- **Path:** `src/core-skills/bmad-editorial-review-prose/`
- **Files:** Chỉ SKILL.md
- **Loại:** Inline single-pass review

### Mục đích sâu
**CONTENT IS SACROSANCT.** Skill review TEXT (prose), không ideas.
- ❌ Không challenge ideas: "This argument is weak"
- ✅ Challenge expression: "This sentence is ambiguous"

Microsoft Writing Style Guide là baseline (unless `style_guide` overrides).

### Input schema
- `content` (required, ≥3 words)
- `style_guide` (optional) — override all principles
- `reader_type` (optional, default `humans`) — hoặc `llm`

### Output schema

3-column markdown table:
```markdown
| Original Text | Revised Text | Changes |
|--------------|--------------|---------|
| "We utilize this tool" | "We use this tool" | Replaced verbose "utilize" with "use" |
| "In order to run..." | "To run..." | Removed filler "In order to" |
```

Or if nothing to change: **"No editorial issues identified."**

### Workflow logic

**Step 1: Validate input**
- content ≥3 words → continue, else HALT
- reader_type ∈ {'humans', 'llm'} → continue

**Step 2: Analyze style**
- Detect intentional stylistic choices (e.g., sentence fragments for emphasis)
- Don't "fix" style user chose deliberately

**Step 3: Editorial review** (based on reader_type)

**reader_type='humans'** (default):
- Clarity issues: ambiguous references, unclear antecedents
- Concision: wordiness, redundancy, filler
- Voice: active vs passive (prefer active where clearer)
- Parallel structure
- Subject-verb agreement
- Punctuation (comma splices, run-ons)

**reader_type='llm'**:
- Unambiguous references (no "this" referring to multiple things)
- Consistent terminology (don't use synonyms for same concept)
- Explicit structure (prefer lists over prose for enumerable items)
- Avoid cultural references LLM might miss
- Reference standards explicitly (not "as convention dictates")

**Step 4: Output**
- Deduplicate: same issue in multiple places → one entry với locations listed
- Minimal fix: smallest edit that resolves issue
- Skip code blocks, frontmatter, structural markup

### State machine

```
[Input]
  ↓
[Validate]
  ├─ Invalid → HALT
  └─ Valid
      ↓
[Analyze style (detect intentional choices)]
  ↓
[Review by reader_type]
  ↓
[Dedupe issues]
  ↓
[Output table OR "No issues"]
```

### Code-ready spec

```typescript
interface ProseReviewInput {
  content: string;
  style_guide?: string;
  reader_type?: 'humans' | 'llm';
}

interface ProseReviewFinding {
  original: string;
  revised: string;
  change_description: string;
  locations: string[];  // If multiple
}

async function reviewProse(input: ProseReviewInput): Promise<ProseReviewFinding[] | string> {
  if (input.content.trim().split(/\s+/).length < 3) {
    throw new Error('Content must be ≥3 words');
  }
  
  const style = detectIntentionalStyle(input.content);
  const readerType = input.reader_type ?? 'humans';
  const findings = await analyzeContent(input.content, readerType, style);
  const deduplicated = dedupe(findings);
  
  return deduplicated.length > 0 ? deduplicated : 'No editorial issues identified.';
}
```

---

## C-6. bmad-editorial-review-structure

### Metadata
- **Path:** `src/core-skills/bmad-editorial-review-structure/`
- **Files:** Chỉ SKILL.md
- **Loại:** Inline multi-step analysis

### Mục đích sâu
Structural editor. Propose **cuts, reorgs, simplifications** preserving comprehension.

**Run BEFORE prose review** — no point copy-editing content that should be cut.

### Input schema
- `content` (required, ≥3 words)
- `style_guide` (optional) — override
- `purpose` (optional) — infer from content if missing
- `target_audience` (optional) — infer if missing
- `reader_type` (optional, default `humans`)
- `length_target` (optional) — e.g., "30% shorter"

### Output schema

```markdown
## Document Summary
[Overview of content, current structure, purpose]

## Recommendations

### CUT - "Intro paragraph para 1"
Rationale: Redundant with abstract
Impact: -50 words
Risk: Low

### MERGE - "Sections 2.1 and 2.2"
Rationale: Same topic split artificially
Impact: Cleaner flow
Risk: Low

### MOVE - "Section 3 to before Section 2"
Rationale: Reader needs context from 3 before 2
Impact: Better reader journey
Risk: Medium

### CONDENSE - "Examples in section 4"
Rationale: 5 examples, 2 would suffice
Impact: -30% length
Risk: Low

### QUESTION - "Section 5 purpose"
Rationale: Unclear why included
Impact: Remove if answer = no clear reason

### PRESERVE - "Section 6"
Rationale: Critical, don't touch

## Summary
Total reduction: 25%
Recommendations: 6 (4 Cut/Merge, 1 Move, 1 Condense)
```

### Workflow logic (6 steps)

**Step 1: Validate input**

**Step 2: Understand purpose**
- Infer purpose if not provided
- Identify target audience if not provided

**Step 3: Structural analysis**
- Map sections
- Pick best structure model:

| Model | Use case |
|-------|----------|
| **Tutorial / Linear** | Step-by-step, beginner audience |
| **Reference / Database** | Lookup, expert audience |
| **Explanation / Conceptual** | Understanding, mixed audience |
| **Prompt / Task** | AI consumption |
| **Strategic / Pyramid** (Minto) | Executive audience, top-down |

**Step 4: Flow analysis**
- Reader journey (entry → exit)
- Pacing (dense vs breath)
- Transitions (smooth vs jarring)

**Step 5: Generate recommendations**

Action types:
- **CUT** — remove entirely
- **MERGE** — combine sections
- **MOVE** — reorder
- **CONDENSE** — shorten
- **QUESTION** — challenge inclusion
- **PRESERVE** — explicit don't touch

Each has: rationale, impact, risk.

**Step 6: Output**

### reader_type differences

**reader_type='humans':**
- Preserve visual aids (diagrams, tables)
- Preserve examples (learning aids)
- Preserve warmth (not just facts)
- Preserve summaries (recap for memory)

**reader_type='llm':**
- Cut emotional language
- Use structured formats (lists, tables)
- Reference standards explicitly
- Remove motivational sections

### Code-ready spec

```typescript
interface StructureReviewInput {
  content: string;
  style_guide?: string;
  purpose?: string;
  target_audience?: string;
  reader_type?: 'humans' | 'llm';
  length_target?: string;  // e.g., "30% shorter"
}

type ActionType = 'CUT' | 'MERGE' | 'MOVE' | 'CONDENSE' | 'QUESTION' | 'PRESERVE';

interface StructureRecommendation {
  action: ActionType;
  section: string;
  rationale: string;
  impact: string;
  risk: 'Low' | 'Medium' | 'High';
}
```

---

## C-7. bmad-help

### Metadata
- **Path:** `src/core-skills/bmad-help/`
- **Files:** Chỉ SKILL.md
- **Loại:** Catalog-driven routing skill

### Mục đích sâu
Smart orientation: user không cần biết catalog of skills, chỉ cần ask "what next". Skill analyzes state + query → recommend next step.

### Data sources

**1. Catalog:** `{project-root}/_bmad/_config/bmad-help.csv`

```csv
module,skill,display-name,menu-code,description,action,args,phase,after,before,required,output-location,outputs
bmm,bmad-create-prd,Create PRD,CP,"Author PRD...",create,"",2-planning,bmad-product-brief,bmad-create-architecture,true,{planning_artifacts},prd.md
bmm,bmad-create-architecture,Create Architecture,CA,"Design...",create,"",3-solutioning,bmad-create-prd,bmad-create-epics-and-stories,true,{planning_artifacts},architecture.md
...
bmm,_meta,BMM docs,,,,,,,,,bmm-docs-url,llms.txt
```

**Phases:** `anytime` hoặc numbered (`1-analysis`, `2-planning`, `3-solutioning`, `4-implementation`).
**Dependencies:** `after`, `before` — format `skill-name` hoặc `skill-name:action`.
**Required:** gates — `required=true` blocks later phases.
**`_meta` rows:** module documentation URLs.

**2. Config:**
- `config.yaml` + `user-config.yaml` in `_bmad/` và subfolders
- Resolve `output-location` variables, `communication_language`, `project_knowledge`

**3. Artifacts:**
- Files matching `outputs` patterns at `output-location`
- Reveal completion status

**4. Project knowledge:**
- `{project_knowledge}` path → grounding context (never fabricate)

**5. Module docs:**
- `_meta` rows → llms.txt URL
- Fetch for general Q&A

### Workflow logic

**Step 1: Parse catalog**
- Load CSV
- Group by module, phase
- Map dependencies

**Step 2: Scan artifacts**
- For each skill, check if output exists
- Fuzzy-match filenames to `outputs` pattern
- User may state completion explicitly

**Step 3: Analyze user query**
- Simple "help" → show phase-relevant skills
- Specific question ("how do I X") → search meta docs
- "What's next" → recommend based on completion state

**Step 4: Recommend**
- Optional items first
- Required item (gate) last
- Format:
  ```
  [CP] **Create PRD** — `bmad-create-prd`
  Description from CSV
  Required: Yes
  ```

**Step 5: Offer quick-start**
- If single clear next step → offer to run NOW
- "Shall I start the Create PRD workflow?"

### Rules
- Present in `{communication_language}`
- Recommend running in **fresh context window**
- Match user's tone
- Never dump entire catalog — surface relevant only

### Code-ready spec

```typescript
interface CatalogRow {
  module: string;
  skill: string;
  display_name: string;
  menu_code: string;
  description: string;
  action: string;
  args: string;
  phase: 'anytime' | string;
  after: string[];
  before: string[];
  required: boolean;
  output_location: string;  // Template like {planning_artifacts}
  outputs: string[];  // File patterns
}

async function bmadHelp(query: string): Promise<HelpResponse> {
  const catalog = await loadCatalog();
  const config = await loadConfig();
  const completed = await scanCompleted(catalog, config);
  
  if (isMetaQuestion(query)) {
    const metaDocs = catalog.filter(r => r.skill === '_meta');
    return answerFromDocs(query, metaDocs);
  }
  
  const nextSteps = inferNext(catalog, completed, query);
  return formatRecommendations(nextSteps, query);
}
```

---

## C-8. bmad-index-docs

### Metadata
- **Path:** `src/core-skills/bmad-index-docs/`
- **Files:** Chỉ SKILL.md
- **Loại:** Inline file operation

### Frontmatter
```yaml
name: bmad-index-docs
description: 'Generate or update an index.md to reference all files in a folder. Use when "create or update an index of all files".'
```

### Mục đích sâu
Generate navigation (`index.md`) cho folder chứa multiple markdown files.

### Input schema
- Target directory path

### Output schema
- `{target_dir}/index.md`

```markdown
# [Folder Name] Index

## Overview
[Brief description of folder's purpose]

## Files

### Category 1
- [file1.md](./file1.md) — Brief description (3-10 words)
- [file2.md](./file2.md) — Brief description

### Category 2
- [file3.md](./file3.md) — Brief description
```

### Workflow logic

**Step 1: Scan directory**
- List all `.md` files (skip hidden `.*`)
- Read each file briefly for description

**Step 2: Group content**
- By type (tutorial, reference, etc.)
- Or by subdirectory
- Or alphabetically if no clear grouping

**Step 3: Generate descriptions**
- Read file first N lines
- Extract 3-10 word summary
- Use frontmatter description if available

**Step 4: Create/update index.md**
- Relative paths (./)
- Alphabetical within groups
- Update instead of overwrite if exists

### Rules
- Skip hidden files
- 3-10 words description
- Relative paths
- Alphabetical within groups

---

## C-9. bmad-party-mode

### Metadata
- **Path:** `src/core-skills/bmad-party-mode/`
- **Files:** Chỉ SKILL.md (128 dòng)
- **Loại:** Orchestration skill spawning real subagents

### Frontmatter
```yaml
name: bmad-party-mode
description: 'Orchestrates group discussions between installed BMAD agents, enabling natural multi-agent conversations where each agent is a real subagent with independent thinking. Use when user requests party mode, wants multiple agent perspectives, group discussion, roundtable, or multi-agent conversation about their project.'
```

### Mục đích sâu
**Real independent thinking.** Nếu 1 LLM roleplay nhiều characters, "opinions" converge (performative). Spawn mỗi agent as **separate subagent process** → genuine diversity.

### Arguments
- `--model <model>` — Force model (haiku, opus, sonnet)
- `--solo` — No subagents, roleplay all agents yourself

### On activation

```
1. Parse arguments (--model, --solo)
2. Load config: {project-root}/_bmad/core/config.yaml
   - Use {user_name} for greeting
   - Use {communication_language}
3. Resolve agent roster:
   python3 {project-root}/_bmad/scripts/resolve_config.py --project-root {project-root} --key agents
   - Merge 4 layers: installer team/user + custom team/user
   - Each agent has: code, name, title, icon, description, module, team
4. Load project context: **/project-context.md
5. Welcome user, show agent roster
```

### Core loop (per user message)

**1. Pick voices (2-4 agents)**

| Situation | Choice |
|-----------|--------|
| Simple question | 2 agents with most relevant expertise |
| Complex/cross-cutting | 3-4 agents from different domains |
| User names specific agents | Include those + 1-2 complementary |
| User asks agent to respond to another | Just that agent với other's response as context |
| Rotate over time | Avoid same 2 dominating |

**2. Build context + spawn**

For each selected agent, spawn subagent via Agent tool với prompt:

```
You are {name} ({title}), a BMAD agent in a collaborative roundtable discussion.

## Your Persona
{icon} {name} — {description}

## Discussion Context
{summary of conversation so far — keep under 400 words}

{project context if relevant}

## What Other Agents Said This Round
{if cross-talk, include responses being reacted to}

## The User's Message
{user's actual message}

## Guidelines
- Respond authentically as {name}. Voice, ethos, speech from description.
- Start with: {icon} **{name}:**
- Speak in {communication_language}
- Scale response to substance — don't pad
- Disagree when your perspective says so. Don't hedge.
- If nothing substantive to add, say so in one sentence
- You may ask user direct questions for clarification
- Do NOT use tools. Just respond.
```

**Spawn in parallel** — all Agent tool calls in single response for concurrency.

**Solo mode:** Generate all responses yourself in single message, each agent's icon + name header.

**3. Present responses**
- **Each agent's full response** — distinct, complete, own voice
- **Never blend/paraphrase/condense**
- Format: responses one after another, blank line separated
- No introductions, no framing

**Optional Orchestrator Note** after: flag disagreement, suggest next agent. Brief + clearly labeled.

**4. Handle follow-ups**

| User says... | You do... |
|-----------|-----------|
| Continues general discussion | Pick fresh agents, repeat |
| "Winston, thoughts on Sally's?" | Spawn just Winston với Sally's response as context |
| "Bring in Amelia" | Spawn Amelia với summary |
| "I agree with John, go deeper" | Spawn John + 1-2 others |
| "What would Mary and Amelia think about Winston's?" | Spawn Mary + Amelia với Winston's response as context |
| Question for everyone | Back to step 1, all agents |

### Keeping context manageable
- Summary of prior rounds (vs full transcript)
- "Discussion Context" < 400 words
- Update every 2-3 rounds or on topic shift

### When things go sideways

| Problem | Fix |
|---------|-----|
| All agents saying same thing | Bring contrarian voice, or ask agent to play devil's advocate |
| Going in circles | Summarize impasse, ask user what angle |
| User disengaged | Ask directly — continue/change/wrap |
| Weak response | Present it, let user decide |

### Exit
Natural phrasing — "thanks", "end party mode", etc. Brief wrap-up of key takeaways, return to normal.

### Code-ready spec

```typescript
interface PartyModeContext {
  mode: 'subagent' | 'solo';
  model?: string;
  agents: Agent[];
  communicationLanguage: string;
  userName: string;
  projectContext?: string;
  discussionSummary: string;
  conversationHistory: Message[];
}

async function handleMessage(ctx: PartyModeContext, userMessage: string) {
  const selectedAgents = pickRelevantAgents(userMessage, ctx.agents, 2, 4);
  
  let responses: AgentResponse[];
  
  if (ctx.mode === 'subagent') {
    // Spawn in parallel
    responses = await Promise.all(
      selectedAgents.map(agent => 
        spawnAgent(agent, userMessage, ctx)
      )
    );
  } else {
    // Solo mode: roleplay all
    responses = await roleplayAll(selectedAgents, userMessage, ctx);
  }
  
  // Present unabridged
  for (const r of responses) {
    console.log(`${r.icon} **${r.name}:**\n${r.content}\n`);
  }
  
  // Optional orchestrator note
  const disagreement = detectDisagreement(responses);
  if (disagreement) {
    console.log(`\n> Orchestrator: ${disagreement}`);
  }
  
  // Update summary every 2-3 rounds
  if (ctx.conversationHistory.length % 3 === 0) {
    ctx.discussionSummary = await summarize(ctx.conversationHistory);
  }
}
```

---

## C-10. bmad-review-adversarial-general

### Metadata
- **Path:** `src/core-skills/bmad-review-adversarial-general/`
- **Files:** Chỉ SKILL.md
- **Loại:** Inline adversarial review

### Frontmatter
```yaml
name: bmad-review-adversarial-general
description: 'Cynically review content and produce findings report. Zero patience for sloppy work. Use when "review something" or "critical review".'
```

### Mục đích sâu
**Adversarial mindset.** Assume problems exist, go find them.

**Normal review:** "Looks OK" (confirmation bias).
**Adversarial:** Must find issues.

### Input schema
- `content` — diff, spec, story, doc, any artifact
- `also_consider` (optional) — areas to prioritize

### Output schema
Markdown list of findings, **at least 10 items**:

```markdown
## Review Findings

1. **[HIGH] No rate limiting on login endpoint** — Attackers can brute force credentials
2. **[HIGH] Session token in localStorage** — XSS can steal tokens (use httpOnly cookies)
3. **[MED] Password validation client-side only** — Trivially bypassed by curl
4. **[MED] No CSRF token on state-changing requests** — Cross-site forgery risk
5. **[LOW] Error messages leak user existence** — "User not found" vs "Wrong password"
...
```

### Rules

**CRITICAL:** HALT if zero findings (suspicious, re-analyze).

**Attitude guidelines:**
- Cynical, jaded, skeptical
- Zero patience for sloppy work
- Find at least 10 issues
- If only finding "nice-to-haves," dig deeper for real issues

**Output:** Markdown list only, no approval/rejection verdict.

### Code-ready spec

```typescript
interface AdversarialReviewInput {
  content: string;
  also_consider?: string;
}

interface AdversarialFinding {
  severity: 'HIGH' | 'MED' | 'LOW';
  description: string;
}

async function adversarialReview(input: AdversarialReviewInput): Promise<AdversarialFinding[]> {
  const findings = await analyzeAdversarially(input.content, input.also_consider);
  
  if (findings.length === 0) {
    throw new Error('HALT: Zero findings. Re-analyze.');
  }
  
  if (findings.length < 10) {
    console.warn('Fewer than 10 findings — dig deeper');
  }
  
  return findings;
}
```

---

## C-11. bmad-review-edge-case-hunter

### Metadata
- **Path:** `src/core-skills/bmad-review-edge-case-hunter/`
- **Files:** Chỉ SKILL.md
- **Loại:** Inline path-analysis review

### Frontmatter
```yaml
name: bmad-review-edge-case-hunter
description: 'Exhaustive path tracer. Walk every branching path and boundary condition, report ONLY unhandled edge cases. Orthogonal to adversarial review (method-driven, not attitude-driven). Use when user requests edge-case analysis of code, specs, or diffs.'
```

### Mục đích sâu
**Method-driven** (walks every path), not attitude-driven (adversarial).
**Orthogonal** to `bmad-review-adversarial-general` — can run both independently.

### Input schema
- `content` — diff, full file, or function
- `also_consider` (optional)

### Output schema

**Strict JSON** (no markdown wrapping, no extra text):

```json
[
  {
    "location": "src/auth/login.ts:42-48",
    "trigger_condition": "empty password submitted",
    "guard_snippet": "if (!password?.length) throw new Error('Password required');",
    "potential_consequence": "null pointer exception in hash function"
  },
  {
    "location": "src/api/users.ts:120",
    "trigger_condition": "concurrent update to same user",
    "guard_snippet": "use optimistic locking with version field",
    "potential_consequence": "lost updates, data corruption"
  }
]
```

**Empty array `[]` is valid** — no unhandled paths found.

### Rules
- No editorializing
- No filler
- Strict JSON
- Scope: if diff provided, only diff hunks + directly reachable boundaries

### Edge classes checked

| Class | Examples |
|-------|----------|
| **Missing else/default** | Switch without default, if-chain missing else |
| **Null/empty inputs** | Null dereference, empty array/string |
| **Off-by-one** | Array index, loop termination |
| **Overflow** | Integer overflow, string length |
| **Type coercion** | Implicit casts losing info |
| **Race conditions** | Concurrent access, TOCTOU |
| **Timeouts** | Unbounded operations |
| **Error paths** | Exception handling gaps |
| **Authentication** | Missing auth check on sensitive ops |
| **Authorization** | Vertical/horizontal privilege escalation |

### Code-ready spec

```typescript
interface EdgeCaseFinding {
  location: string;          // file:line-range
  trigger_condition: string; // ≤15 words
  guard_snippet: string;     // Minimal code that closes gap
  potential_consequence: string; // ≤15 words
}

async function edgeCaseHunter(content: string, alsoConsider?: string): Promise<EdgeCaseFinding[]> {
  const paths = extractAllPaths(content);
  const findings: EdgeCaseFinding[] = [];
  
  for (const path of paths) {
    for (const edgeClass of EDGE_CLASSES) {
      const unhandled = checkEdgeCase(path, edgeClass);
      if (unhandled) {
        findings.push(unhandled);
      }
    }
  }
  
  return findings;
}
```

---

## C-12. bmad-shard-doc

### Metadata
- **Path:** `src/core-skills/bmad-shard-doc/`
- **Files:** Chỉ SKILL.md
- **Loại:** External tool invocation

### Frontmatter
```yaml
name: bmad-shard-doc
description: 'Split large markdown documents into smaller, organized files based on level 2 sections. Use when "perform shard document".'
```

### Mục đích sâu
**Problem:** PRD 50+ pages exceeds LLM context window cho workflow cụ thể (e.g., one epic).
**Solution:** Split by H2 sections → smaller files, auto-generated index.

### Input schema
- Source markdown path (`.md` extension)

### Output schema

```
destination_folder/
├── index.md          (auto-generated master index)
├── section-1-title.md
├── section-2-title.md
├── section-3-title.md
...
```

Each file: full content of one H2 section, with metadata.

### Workflow logic (6 steps)

**Step 1: Get source**
- Verify path exists
- Verify `.md` extension
- If not .md → HALT

**Step 2: Get destination**
- Default: same location as source, folder named after source (without .md)
- User can override

**Step 3: Execute**
```bash
npx @kayvan/markdown-tree-parser explode {source} {destination}
```

**Step 4: Verify output**
- Count files generated
- Check `index.md` created
- Report count

**Step 5: Report completion**
- Show destination folder
- Show file count
- Show index.md path

**Step 6: Handle original**

Options presented:
- **Delete** (recommended) — Keep source vs shards defeats purpose
- **Move to archive** — Preserve but not in main location
- **Keep** (not recommended) — Duplicates info, confusing

### Rules

**Critical:** Keeping both original + sharded DEFEATS purpose. User should choose Delete (default recommendation).

Shards can always be recombined if needed (reverse operation).

### Code-ready spec

```typescript
interface ShardDocInput {
  sourcePath: string;
  destinationPath?: string;
}

interface ShardDocOutput {
  destinationPath: string;
  fileCount: number;
  indexPath: string;
}

async function shardDoc(input: ShardDocInput): Promise<ShardDocOutput> {
  if (!input.sourcePath.endsWith('.md')) {
    throw new Error('Source must be .md file');
  }
  
  const dest = input.destinationPath ?? 
    path.join(path.dirname(input.sourcePath), 
              path.basename(input.sourcePath, '.md'));
  
  await execa('npx', [
    '@kayvan/markdown-tree-parser',
    'explode',
    input.sourcePath,
    dest
  ]);
  
  const files = await fs.readdir(dest);
  
  return {
    destinationPath: dest,
    fileCount: files.length,
    indexPath: path.join(dest, 'index.md')
  };
}
```

---

## Tổng kết core skills

| # | Skill | Type | Primary use | Loại interaction |
|---|-------|------|-------------|------------------|
| 1 | advanced-elicitation | Inline | Refine LLM output | Menu-driven |
| 2 | brainstorming | Micro-file | Ideation | Conversational |
| 3 | customize | Interactive | Author overrides | Guided 6-step |
| 4 | distillator | Multi-agent | Lossless compression | Autonomous |
| 5 | editorial-review-prose | Inline | Copy-edit text | Single-pass |
| 6 | editorial-review-structure | Inline | Restructure docs | Analytical |
| 7 | help | Routing | Next-step guidance | Catalog-driven |
| 8 | index-docs | Inline | Generate folder index | Autonomous |
| 9 | party-mode | Orchestration | Multi-agent discussion | Interactive loop |
| 10 | review-adversarial-general | Inline | Find issues (attitude) | Single-pass |
| 11 | review-edge-case-hunter | Inline | Find edge cases (method) | Single-pass |
| 12 | shard-doc | External tool | Split large doc | One-shot |

**Common patterns:**
- **Config loading:** All skills load `{project-root}/_bmad/{module}/config.yaml`
- **Output in communication_language:** Speak user's preferred language
- **Document output in document_output_language:** Artifacts in configured doc language
- **Invoke syntax:** "Invoke the `skill-name` skill" (REF-03)
- **File references:** Relative within skill, config variables across skills

---

**Đọc tiếp:** [09b-skills-phase1-2-deep.md](09b-skills-phase1-2-deep.md) — Phase 1 + 2 skills chi tiết.
