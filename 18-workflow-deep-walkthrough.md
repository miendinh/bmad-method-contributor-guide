# 18. Workflow Deep Walkthrough - create-prd & retrospective

> ⚠️ **UNOFFICIAL THIRD-PARTY DOCUMENTATION**
> NOT official BMad docs. See [DISCLAIMER.md](DISCLAIMER.md) | Licensed MIT — see [LICENSE](LICENSE) and [NOTICE](NOTICE)
> Official BMAD-METHOD: <https://github.com/bmad-code-org/BMAD-METHOD>

---

> A step-by-step deep dive into the 2 most important workflows: `bmad-create-prd` (15 steps, step-file architecture) and `bmad-retrospective` (12 steps, XML inline party-mode). For developers who want to understand the exact mechanics.

> **Note:** This file complements [09b](09b-skills-phase1-2-deep.md) and [09d](09d-skills-phase4-deep.md) — the focus here is on the MECHANICS of each step.

---

## Table of Contents

- [Part 1: bmad-create-prd (15 steps)](#part-1-bmad-create-prd-15-steps)
- [Part 2: bmad-retrospective (12 steps, party-mode)](#part-2-bmad-retrospective-12-steps-party-mode)
- [Common patterns observed](#common-patterns-observed)

---

# Part 1: bmad-create-prd (15 steps)

**Path:** `src/bmm-skills/2-plan-workflows/bmad-create-prd/steps-c/`

**Architecture:** Step-file (micro-file), 15 files, ~2900 lines total.

**Output:** `{planning_artifacts}/prd.md`

**State tracking:** Frontmatter `stepsCompleted: [1, 2, 3, ...]` + `inputDocuments: [...]`

---

## Step 01: Init (178 lines)

**Goal:** Initialize the PRD workflow, detect continuation, discover input docs, set up the document structure.

**Actions:**
1. Check if `{outputFile}` (prd.md) exists
2. If it exists:
   - Read the frontmatter
   - If `step-12-complete` is in `stepsCompleted` → ask overwrite/cancel
   - Otherwise → auto-route to `step-01b-continue` (resume)
3. If fresh:
   - Discover input documents:
     - Search: `{planning_artifacts}/**/**`, `{output_folder}/**/**`, `{project_knowledge}/**/**`, `docs/**`
     - Find: `*brief*.md`, `*prfaq*.md`, `*research*.md`, `project-context.md`
   - Present found docs to the user, ask which to load
   - Load confirmed docs
   - Copy `prd-template.md` → `{outputFile}`
   - Initialize frontmatter: `stepsCompleted: [1]`, `inputDocuments: [list]`, `documentCounts: {briefCount, researchCount, brainstormingCount, projectDocsCount}`

**Variables:**
- Sets: `{inputDocuments}`, `{documentCounts}`, `{outputFile}`
- Uses: `{planning_artifacts}`, `{project_name}`, `{user_name}`

**Menu:**
- `[C] Continue` to discovery (step-02)
- User can provide additional files → re-scan, update counts

**HALT:** Wait for the user to press 'C' before proceeding.

**Transition:** → step-02-discovery (normal) OR step-01b-continue (an existing workflow was detected)

---

## Step 01b: Continue (161 lines)

**Goal:** Resume the workflow from the last incomplete step.

**Actions:**
1. Analyze current state from the frontmatter:
   - `stepsCompleted` array → determine the last completed step
   - `inputDocuments` → reload these files
2. Offer options to the user:
   - `[R] Resume` from the next step (after the last completed one)
   - `[C] Continue` with the next logical step
   - `[O] Overview` — show the current PRD state
   - `[X] Start over` — archive the current PRD, start fresh
3. If R/C: Load `step-NN-*.md` for the next step
4. If O: Display a summary, re-present the menu
5. If X: Archive the current prd.md → prd-archived-{date}.md, goto step-01

**Variables:**
- Uses: `{stepsCompleted}`, `{inputDocuments}`

**HALT:** The user chooses R/C/O/X.

---

## Step 02: Discovery (208 lines)

**Goal:** Project classification + domain understanding.

**Actions:**
1. Classify the project type:
   - Greenfield / Brownfield?
   - Platform extension / Internal tool?
   - Industry domain?
2. Determine scope:
   - B2B SaaS / consumer / enterprise / developer tool?
   - Scale expectations?
3. Extract user context from the loaded input docs
4. Reflect that understanding back to the user for validation

**Output section:** "Project Context" appended to prd.md

**Menu:** `[A] Advanced Elicitation | [P] Party Mode | [C] Continue`

**Conditionals:**
- If vision is missing → offer step-02b-vision (sidecar)
- If exec summary is missing → offer step-02c-executive-summary (sidecar)

**HALT:** User 'C' to proceed.

**Transition:** → step-02b/02c (sidecar, if chosen) OR step-03

---

## Step 02b: Vision (142 lines, sidecar)

**Goal:** Articulate the product vision (optional).

**Actions:**
1. Prompt: "Imagine 2-3 years out, this product has succeeded. What does the world look like?"
2. Help the user articulate a vision in 1-2 sentences
3. Stress-test: Is it specific? Measurable? Inspiring?
4. Append the "Vision" section to prd.md

**Optional — skip if already in the brief.**

---

## Step 02c: Executive Summary (158 lines, sidecar)

**Goal:** Executive-level product summary (optional).

**Actions:**
1. Synthesize from input docs (brief, PRFAQ, vision)
2. Draft a 3-4 bullet executive summary:
   - Problem
   - Solution
   - Target users
   - Differentiation
3. User reviews, iterates
4. Append the "Executive Summary" section

---

## Step 03: Success (214 lines)

**Goal:** Success criteria — measurable, user-centric, time-bound.

**Actions:**
1. Facilitate the primary metric definition
2. Facilitate 2-3 supporting metrics
3. Validate criteria:
   - Specific? (not "improve UX")
   - Measurable? (quantified target)
   - Time-bound? (by when)
   - User-centric? (not just a dev metric)
4. Challenge vague metrics — force precision

**Example output:**
```markdown
## Success Criteria

### Primary Metric
- **User activation rate**: 40% of signups complete first task within 48 hours (target by Q2)

### Supporting Metrics
- **Retention D7**: 25% of activated users return within week
- **NPS**: 50+ from power users
- **Time-to-first-value**: <5 minutes from signup
```

**Menu:** `[A/P/C]`

---

## Step 04: Journeys (201 lines)

**Goal:** User journey mapping.

**Actions:**
1. Identify the primary user personas (1-3 max)
2. For each persona, map the journey:
   - Entry (how they arrive)
   - Key moments (actions, decisions)
   - Outcomes (success states)
   - Exit scenarios
3. Identify pain points + opportunities
4. Validate with the user

**Format:** Text-based flow or ASCII diagram.

**Menu:** `[A/P/C]`

---

## Step 05: Domain (194 lines)

**Goal:** Domain-specific requirements.

**Actions:**
1. Based on the classification from step-02:
   - **Healthcare:** HIPAA, patient data, audit logs
   - **Finance:** PCI-DSS, transaction integrity
   - **Education:** FERPA, accessibility
   - **Enterprise:** SSO, RBAC, audit
2. Extract applicable compliance + domain rules
3. Document constraints
4. Document industry-specific patterns

**Skip** if the product is domain-agnostic.

**Menu:** `[A/P/C]`

---

## Step 06: Innovation (211 lines)

**Goal:** Innovation + competitive differentiation.

**Actions:**
1. List 3-5 competitive alternatives (from research or the web)
2. For each, identify:
   - Their value prop
   - Their weakness
3. Identify your differentiation:
   - A unique angle? (not just "better UX")
   - A defensible moat? (network effect, data, cost, expertise)
   - Why now? (timing rationale)
4. Stress-test: Is the differentiation real or perceived?

**Menu:** `[A/P/C]`

---

## Step 07: Project Type (222 lines)

**Goal:** Project-type classification impacts.

**Actions:**
1. Classify more precisely than step-02:
   - Greenfield (new project) → full setup needed
   - Brownfield (existing codebase) → integration story needed
   - Platform extension → leverage existing
   - Internal tool → different UX priorities
2. Impact analysis:
   - What changes based on the type?
   - Foundation stories needed?
   - Existing patterns to respect?

**Menu:** `[A/P/C]`

---

## Step 08: Scoping (263 lines, LONGEST)

**Goal:** MVP scoping, scope boundaries.

**Actions:**
1. List everything the user wants (brainstorm)
2. Force a ruthless cut:
   - **In scope (MVP):** Must-haves for launch
   - **Out of scope:** Explicitly cut
   - **Future considerations:** Phase 2, 3
3. Apply MVP principles:
   - Minimum viable — the smallest thing that creates value
   - One primary use case
   - Cut features that don't hit the primary metric (step-03)
4. Document the rationale for each cut
5. Warn if scope looks large:
   - "This feels > 3 months. Reduce?"

**Key challenge:** User resistance to cutting. Coach with:
- "What's the one feature we can't ship without?"
- "If the budget were halved, what would survive?"

**Menu:** `[A/P/C]`

---

## Step 09: Functional Reqs (219 lines)

**Goal:** Functional requirements as a capability contract.

**Actions:**
1. From in-scope (step-08), extract FRs
2. Format each FR:
   ```markdown
   ### FR1: [Capability Name]
   
   **Description:** What capability this provides
   
   **Acceptance signals:**
   - How to verify this works
   - Measurable outcome
   
   **Dependencies:** FRx, FRy (if any)
   ```
3. Rules:
   - User-centric (not "API must return 200")
   - Independent (no tight coupling)
   - Testable (clear acceptance)
4. Cross-reference with journeys (step-04) — every journey step should have FR coverage

**Menu:** `[A/P/C]`

---

## Step 10: Non-Functional Reqs (230 lines)

**Goal:** NFRs covering performance, security, scalability, accessibility, observability.

**Actions:**
1. For each category, extract requirements:
   - **Performance:** Response time, throughput, load
   - **Security:** Auth, authz, data protection, audit
   - **Scalability:** User count, data volume, geographic
   - **Accessibility:** WCAG level, screen readers, keyboard nav
   - **Observability:** Logging, metrics, alerting, tracing
   - **Reliability:** Uptime SLO, recovery time
2. Format each NFR with a measurable target
3. Challenge generic NFRs — force specificity:
   - ❌ "Must be secure"
   - ✅ "OWASP Top 10 addressed, penetration test quarterly, data at rest encrypted with AES-256"

**Menu:** `[A/P/C]`

---

## Step 11: Polish (221 lines)

**Goal:** Polish for flow + coherence.

**Actions:**
1. Review the full document linearly
2. Check:
   - Consistent terminology?
   - FR numbers sequential?
   - Complete coverage (every journey → FR)?
   - No TBDs or placeholders?
3. Fix issues iteratively
4. User review + approval

**Menu:** `[A/P/C]`

---

## Step 12: Complete (121 lines)

**Goal:** Completion + validation options + next steps.

**Actions:**
1. Mark `stepsCompleted: [1..12]`, `status: 'complete'`
2. Offer next actions:
   - `[V] Validate PRD` → invoke `bmad-validate-prd`
   - `[E] Edit PRD` → invoke `bmad-edit-prd`
   - `[C] Create UX Design` → invoke `bmad-create-ux-design`
   - `[A] Create Architecture` → invoke `bmad-create-architecture`
   - `[D] Done` → exit with confirmation
3. Show the final file path

**Output:** `{planning_artifacts}/prd.md` with frontmatter `status: 'complete'`

---

## Summary: bmad-create-prd flow

```
step-01 (init)
  ├─ existing incomplete → step-01b (continue)
  ├─ existing complete → ask overwrite
  └─ new
      ↓
step-02 (discovery) [A/P/C]
  ├─ offer 02b (vision) if missing
  └─ offer 02c (exec summary) if missing
      ↓
step-03 (success) [A/P/C]
step-04 (journeys) [A/P/C]
step-05 (domain) [A/P/C] — skip if domain-agnostic
step-06 (innovation) [A/P/C]
step-07 (project-type) [A/P/C]
step-08 (scoping) [A/P/C] — longest step
step-09 (functional) [A/P/C]
step-10 (nonfunctional) [A/P/C]
step-11 (polish) [A/P/C]
step-12 (complete) — offer next actions
```

**Patterns observed:**
- Every main step has an `[A/P/C]` menu
- HALT at every menu
- Append-only document building
- Frontmatter tracks `stepsCompleted`
- Sidecars (02b, 02c) are optional
- The final step offers chaining to related skills

---

# Part 2: bmad-retrospective (12 steps, party-mode)

**Path:** `src/bmm-skills/4-implementation/bmad-retrospective/`

**Architecture:** XML inline workflow inside `workflow.md` (~1500 lines).

**Output:** `{implementation_artifacts}/epic-{{epic_num}}-retro-{date}.md`

**Unique feature:** Party-mode — ALL dialogue in the format `"Name (Role): dialogue"`.

**Party agents:**
- Amelia (Developer) — facilitator
- Alice (Product Owner)
- Charlie (Senior Dev)
- Dana (QA Engineer)
- Elena (Junior Dev)
- {{user_name}} (Project Lead) — active participant

---

## Step 1: Epic Discovery

**Goal:** Identify which epic to retrospect on.

**Actions:**
```xml
<step n="1" goal="Epic Discovery">
  <!-- Priority 1: sprint-status.yaml -->
  <check if="{sprint_status} exists">
    <action>Load FULL sprint-status.yaml</action>
    <action>Find highest epic with ≥1 story marked "done"</action>
    <action>Present: "Ready to retro epic {{epic_num}}?"</action>
    <ask>User confirms or provides different number</ask>
  </check>
  
  <!-- Priority 2: ask user -->
  <check if="no sprint_status">
    <ask>Which epic number to retrospect on?</ask>
  </check>
  
  <!-- Priority 3: scan stories folder -->
  <check if="user doesn't know">
    <action>Scan {implementation_artifacts} for story files</action>
    <action>Detect highest epic number with completed stories</action>
  </check>
  
  <!-- Verify completion -->
  <action>Count total/done stories in epic</action>
  <check if="incomplete stories">
    <ask>
      Options:
      [1] Complete remaining stories first
      [2] Do partial retrospective
      [3] Refresh sprint-planning
    </ask>
  </check>
</step>
```

**Dialogue example:**
```
Amelia (Developer): "Hi {user_name}! Let's retro epic 2. I see 
8/8 stories done. Ready?"

Alice (Product Owner): "Solid epic. Let me pull up the metrics..."

{user_name}: "Yes, let's go."
```

---

## Step 2a: Document Discovery + Load

**Goal:** Load input files strategically.

**Actions:**
- **Epics** (`SELECTIVE_LOAD epic_{{epic_num}}`): Just this epic
- **Architecture** (`FULL_LOAD`): The complete doc for context
- **PRD** (`FULL_LOAD`): The complete doc
- **Previous retro** (`SELECTIVE_LOAD epic_{{epic_num - 1}}`): Optional
- **Document project** (`INDEX_GUIDED`): Optional, load relevant sections

**No menu — auto-proceed.**

---

## Step 2: Deep Story Analysis

**Goal:** Extract patterns from ALL story records.

**Actions:**
```xml
<step n="2" goal="Deep Story Analysis">
  <action>For each story in epic {{epic_num}}:
    Read COMPLETE story file
    Extract:
    - Dev notes + struggles (where did devs struggle?)
    - Review feedback patterns (recurring themes)
    - Lessons learned (aha moments)
    - Technical debt (shortcuts taken)
    - Testing insights (bug patterns, coverage gaps)
  </action>
  
  <action>Synthesize patterns across stories:
    - Common struggles (2+ stories)
    - Recurring review feedback themes
    - Breakthrough moments
    - Velocity patterns
    - Team collaboration highlights
  </action>
</step>
```

**Output:**
```
Amelia (Developer): "I've analyzed all 8 stories. Key patterns:
  - Auth integration was tricky in 3 stories (2.1, 2.3, 2.5)
  - Tests for edge cases consistently forgotten initial commits
  - Great improvement in commit discipline by story 2.6"
```

---

## Step 3: Load + Integrate Previous Epic Retrospective

**Goal:** Check previous commitments.

**Actions:**
```xml
<check if="{{prev_epic_num}} >= 1">
  <action>Find epic-{{prev_epic_num}}-retro-*.md</action>
  
  <check if="found">
    <action>Extract from previous retro:
      - Action items committed
      - Lessons learned
      - Process improvements
      - Technical debt flagged
      - Team agreements
      - Preparation tasks
    </action>
    
    <action>Cross-reference with current epic:
      For each action item: ✅ Completed | ⏳ In Progress | ❌ Not Addressed
      For each lesson: Evidence of application?
      For each process change: Did it help?
      For each debt item: Addressed?
    </action>
  </check>
</check>
```

**Dialogue:**
```
Amelia: "Previous retro had 4 action items. Let me check:
  ✅ 'Add pre-commit hooks' — Done, seen in commit history
  ⏳ 'Improve test coverage' — Partial, 70% vs target 80%
  ❌ 'Monthly architecture sync' — Not started
  ❌ 'Junior dev mentorship program' — Deferred"

Charlie (Senior Dev): "The coverage ⏳ — we got stuck on integration tests. Need different approach."

Alice: "Architecture sync is critical for epic 3. Can't defer again."
```

---

## Step 4: Preview Next Epic

**Goal:** Analyze readiness for `{{next_epic_num}}`.

**Actions:**
```xml
<check if="{{next_epic_num}} exists in epics file">
  <action>SELECTIVE_LOAD epic_{{next_epic_num}}</action>
  <action>Extract:
    - Epic title + objectives
    - Planned stories + complexity
    - Dependencies on epic_{{epic_num}} work
    - New technical requirements
    - Risks/unknowns
    - Business goals + success criteria
  </action>
  <action>Identify preparation needed</action>
</check>
```

**Dialogue:**
```
Amelia: "Epic 3 is 'Payment Integration'. Key dependencies:
  - User auth (done in epic 2) ✓
  - Stripe SDK version decision (not decided)
  - PCI compliance review (not scheduled)
  - Database schema for transactions (architecture incomplete)"

Charlie: "PCI compliance is 2 weeks minimum. We need to start now if epic 3 starts in 4 weeks."
```

---

## Step 5: Initialize Retrospective

**Goal:** Rich context setup before the discussion.

**Actions:**
```xml
<step n="5" goal="Initialize Retrospective">
  <action>Load agent roster from config</action>
  <action>Identify participating agents (PO, Dev, QA, Architect, etc.)</action>
  <action>Ensure key roles present</action>
  
  <output>
    EPIC SUMMARY:
    - Completed: {X}/{Y} stories ({Z}%)
    - Velocity: {points/sprint}
    - Blockers overcome: {count}
    - Technical Debt incurred: {count}
    - Incidents: {count}
    
    GOALS ACHIEVED: {list}
    FEEDBACK: {summary}
    
    [If next_epic_exists]
    NEXT EPIC PREVIEW:
    - Dependencies: {list}
    - Preparation needed: {list}
    - Technical prerequisites: {list}
    
    PARTICIPATING AGENTS:
    📋 Alice (Product Owner)
    👨‍💻 Charlie (Senior Dev)
    🧪 Dana (QA Engineer)
    🎓 Elena (Junior Dev)
    🏗️ {user_name} (Project Lead)
    
    GROUND RULES:
    - Psychological safety paramount
    - Focus on systems + processes
    - Specific examples over generalization
    - Every voice heard
  </output>
</step>
```

---

## Step 6: Epic Review Discussion

**Goal:** Party-mode dialogue about successes + challenges.

**Actions:**
```xml
<step n="6" goal="Epic Review Discussion">
  <action>Ask team: "What went well?"</action>
  <action>Team contributes, Amelia turns to user_name</action>
  <critical>Wait for {user_name} response — KEY USER INTERACTION</critical>
  <action>1-2 team members react/build on user input</action>
  
  <action>Transition: "Where did we struggle?"</action>
  <action>Introduce conflict naturally if applicable</action>
  <critical>Amelia facilitates systemically, NOT blame</critical>
</step>
```

**Dialogue example (from the actual workflow):**
```
Amelia: "Let's start positive. What went well this epic?"

Alice (PO): "The communication loop was tighter than ever. 
    Every Monday sync actually had clear decisions by end."

Charlie (Senior Dev): "Agreed. And the new PR template helped 
    reviewers focus on right things."

Amelia: "{user_name}, what stood out for you?"

{user_name}: "I was impressed by how quickly we recovered from 
    the auth bug in story 2.3. Everyone jumped in."

Dana (QA): "That's a great point. The fast recovery shows our 
    testing culture is maturing."

Amelia: "Now, what challenges?"

Charlie: "The database migration in 2.5 — we underestimated 
    the complexity. 3 days over budget."

Alice: "From PO side, I pushed back on the estimate. I was wrong."

Amelia: "Let's unpack this systemically — what made the estimate 
    off? No blame on anyone."

Charlie: "Honestly? I didn't account for FK constraints 
    discovery during migration."

Dana: "We also didn't test migration on prod-like data upfront."

{user_name}: "What's the fix going forward?"

Amelia: "That's for step 8. Let's capture patterns first."
```

---

## Step 7: Next Epic Preparation Discussion

**Goal:** Plan for next epic success.

**Actions:**
```xml
<check if="{{next_epic_exists}}">
  <action>Ask team: "Are we ready? What do we need to prepare?"</action>
  <action>Alice surfaces dependency concerns</action>
  <action>Charlie surfaces technical prereqs</action>
  <action>Dana surfaces testing needs</action>
  <action>Elena surfaces knowledge gaps</action>
  <critical>Create healthy tension: business needs vs technical reality</critical>
  
  <action>Summarize preparation by category:
    CRITICAL (must complete before epic starts)
    PARALLEL (can happen during early stories)
    NICE-TO-HAVE (would help but not blocking)
  </action>
</check>
```

**Dialogue:**
```
Amelia: "For epic 3 (Payment), are we ready?"

Alice (PO): "Stakeholder alignment on pricing tiers — not done."

Charlie (Senior Dev): "PCI compliance review pending. Tech debt 
    from epic 2 (auth refactor) might complicate integration."

Dana (QA): "Payment testing infra setup needed — Stripe test mode 
    + fixtures."

Elena (Junior Dev): "I don't know Stripe well. Want to ramp up 
    during epic 3 start."

{user_name}: "My sense: we're not ready. 2-3 week prep sprint?"

Amelia: "Let's categorize:
  CRITICAL (before epic 3): PCI review, stakeholder alignment
  PARALLEL (with early stories): Stripe infra setup, Elena ramp-up
  NICE-TO-HAVE: Auth tech debt cleanup"
```

---

## Step 8: Synthesize Action Items + Significant Change Detection (CRITICAL STEP)

**Goal:** Concrete action items + detect whether the epic plan needs updating.

**Actions:**
```xml
<step n="8" goal="Synthesize + detect significant changes">
  <action>Create specific action items:
    - Process improvements (owner, deadline, success criteria)
    - Technical debt (owner, priority, effort)
    - Documentation (owner, deadline)
    - Team agreements
  </action>
  
  <!-- CRITICAL: Check for epic-update triggers -->
  <action>Analyze: do discoveries require epic update?
    - Architectural assumptions proven wrong?
    - Scope changes?
    - Approach change needed?
    - Dependencies discovered?
    - User needs different than understood?
    - Performance/scalability concerns?
    - Security/compliance issues?
    - Team capacity/skill gaps?
    - Technical debt unsustainable?
  </action>
  
  <check if="significant discoveries detected">
    <output>
      🚨 SIGNIFICANT DISCOVERY ALERT
      
      Changes identified:
      - [List]
      
      Impact on epic {{next_epic_num}}:
      - [Wrong assumptions exposed]
      - [Required plan updates]
      
      RECOMMEND: Review + update Epic {{next_epic_num}} definition 
      BEFORE starting.
      
      Add to critical path: Epic planning review session.
    </output>
    <ask>{{user_name}}, how do you want to handle this?</ask>
  </check>
</step>
```

**Action items example:**
```markdown
## Action Items

1. **PCI compliance review**
   - Owner: Charlie (Senior Dev) + external consultant
   - Deadline: 2 weeks
   - Success: Compliance sign-off document

2. **Monthly architecture sync (from previous retro)**
   - Owner: {user_name}
   - Deadline: First Monday each month
   - Success: 3 consecutive monthly syncs completed

3. **Migration testing on prod-like data**
   - Owner: Dana (QA) + Charlie
   - Deadline: Before next migration story
   - Success: Staging env with prod data snapshot

## 🚨 SIGNIFICANT DISCOVERY

Epic 3 assumed we'd use Stripe Connect. Story analysis shows 
we need Stripe Checkout first (Connect requires more auth). 
Epic 3 definition needs update — split into:
- Epic 3: Basic payment (Checkout)
- Epic 4: Multi-party payments (Connect)

RECOMMEND: Winston + Alice planning session before epic 3 starts.
```

---

## Step 9: Critical Readiness Exploration

**Goal:** Final verification across 5 dimensions.

**Actions:**
```xml
<step n="9" goal="Critical Readiness">
  <ask>Testing & Quality: Confident production-ready?</ask>
  <ask>Deployment: Deployed? Scheduled? Timeline OK?</ask>
  <ask>Stakeholder Acceptance: Seen + accepted?</ask>
  <ask>Technical Health: Codebase stable/maintainable?</ask>
  <ask>Unresolved Blockers: Carrying forward?</ask>
  
  <action>Synthesize readiness assessment</action>
</step>
```

---

## Step 10: Retrospective Closure

**Goal:** Celebrate + commit + close.

**Output format:**
```
✅ RETROSPECTIVE COMPLETE

Key Takeaways:
- Systems can handle fast recovery (auth bug)
- Estimation needs migration-specific framework
- Communication cadence is working

Commitments Made:
- 3 action items
- 4 preparation tasks
- 1 critical path item (PCI)

Next Steps:
1. Execute Prep Sprint (2 weeks)
2. Complete PCI review
3. Review action items in next standup
4. Epic 3 planning review session (Winston + Alice)

⚠️ REMINDER: Significant discovery requires Epic 3 update 
before start.
```

**Acknowledgment:**
```
Amelia: "Epic 2 delivered 8 stories with 24-point velocity. 
Great work by real people solving real problems. Let's use 
these insights to make epic 3 even better."

{user_name}: "Thanks everyone."
```

---

## Step 11: Save Retrospective + Update Sprint Status

**Goal:** Persist.

**Actions:**
- Generate the comprehensive retro document (see template in [09d §4-11](09d-skills-phase4-deep.md))
- Save: `{implementation_artifacts}/epic-{{epic_num}}-retro-{date}.md`
- Update `sprint-status.yaml`:
  - Mark `epic-{{epic_num}}-retrospective = "done"`
  - Update `last_updated`

---

## Step 12: Final Summary + Handoff

**Goal:** Wrap up.

**Output:**
```
✅ Retrospective Complete, {user_name}!

Epic review: completed
Retrospective saved: {path}
Commitments: {count}

Next Steps:
1. Execute prep sprint
2. Critical path items
3. Review action items
4. [Optional] Epic planning review

Team Performance:
Epic {{epic_num}} delivered {{completed_stories}} stories.
Retrospective surfaced {{insight_count}} insights + 
{{significant_discovery_count}} discoveries.
Team well-positioned for Epic {{next_epic_num}} success.

⚠️ REMINDER: If significant discoveries detected — Epic update 
required before starting Epic {{next_epic_num}}
```

---

## Party mode dialogue patterns

Observed from workflow.md:

### Pattern 1: Facilitator-led discussion

```
Amelia (Developer): [open question]
  ↓
[Team members respond in turn with role-specific perspectives]
  ↓
Amelia: [turns to user_name]
  ↓
{user_name}: [active input]
  ↓
[Team reacts/builds on user input]
```

### Pattern 2: Conflict introduction

```
[Normal discussion]
  ↓
Amelia: [introduces natural tension if applicable]
  ↓
Alice: [stakes position A]
  ↓
Charlie: [stakes position B]
  ↓
Amelia: "Let's unpack systemically — no blame"
  ↓
[Resolution through team dialogue]
  ↓
{user_name}: [final arbiter]
```

### Pattern 3: Synthesis with user validation

```
[Team surfaces multiple concerns]
  ↓
Amelia: [categorizes: CRITICAL / PARALLEL / NICE-TO-HAVE]
  ↓
{user_name}: "Does this match your understanding?"
  ↓
[Team + user finalize]
```

### Format conventions

- **"Name (Role): dialogue"** — universal format
- **Role icons** optional: 📋 Alice, 💻 Charlie, 🧪 Dana, 🎓 Elena
- **{user_name}** is always Project Lead
- **Amelia** is always the facilitator
- **Never blend** responses — preserve each voice
- **Each response** unabridged

---

## Common patterns observed

### Pattern 1: State tracking via frontmatter

```yaml
---
stepsCompleted: [1, 2, 3, 4, 5]
inputDocuments: ["path/to/brief.md"]
status: "in-progress"  # or "complete"
documentCounts:
  briefCount: 1
  researchCount: 2
---
```

### Pattern 2: Menu convention

- `[A]` Advanced Elicitation (invoke `bmad-advanced-elicitation`)
- `[P]` Party Mode (invoke `bmad-party-mode`)
- `[C]` Continue to the next step

### Pattern 3: Auto-proceed vs. HALT

| When | Behavior |
|------|----------|
| After an append-content step with an `[A/P/C]` menu | HALT, wait for C |
| Intermediate "load data" step | Auto-proceed |
| Validation-only step | Auto-proceed |
| User decision point | HALT |

### Pattern 4: Document building

- Always **append-only** (never overwrite)
- Update the frontmatter BEFORE loading the next step
- Each step owns **one H2 section**

### Pattern 5: Chained skill invocation

- The last step often offers a next skill:
  - create-prd → validate-prd / edit-prd / create-ux-design / create-architecture
  - create-architecture → create-epics-and-stories → generate-project-context → check-implementation-readiness
  - create-story → dev-story → code-review
  - retrospective → next epic prep

### Pattern 6: Graceful resume

Every skill with multiple steps:
1. Detects an existing output file
2. Offers a Resume option if incomplete
3. Reloads input documents from the frontmatter
4. Continues from the last completed step

---

## Takeaway: Skill maturity levels

Observed 2 levels in these 2 workflows:

**Level 1: Step-file architecture** (create-prd)
- Each step = a separate file (2-5KB)
- State tracked via frontmatter
- Linear or branched flow
- User control at each menu
- Resume-friendly

**Level 2: Inline XML workflow** (retrospective)
- Complex logic in a single workflow.md
- Multi-role party-mode dialogue
- Branching + significant-discovery detection
- Less granular (but richer context per step)

**Trade-off:**
- Step-file: modular, testable, but more files to maintain
- Inline XML: cohesive, richer, but harder to scan

Choose based on complexity + team size.

---

**Continue reading:** [17-cheat-sheet.md](17-cheat-sheet.md) — 1-page cheat sheet.
