# 11. Testing & Quality

> ⚠️ **UNOFFICIAL THIRD-PARTY DOCUMENTATION**
> Không phải official BMad docs. Xem [DISCLAIMER.md](DISCLAIMER.md) | Licensed MIT — xem [LICENSE](LICENSE) và [NOTICE](NOTICE)
> Official BMAD-METHOD: <https://github.com/bmad-code-org/BMAD-METHOD>

---

> Testing infrastructure, test patterns, quality metrics của BMad framework. Cho developer muốn contribute test + maintainer muốn extend test coverage.

---

## Mục lục

1. [Test structure overview](#1-test-structure-overview)
2. [Test scripts & running](#2-test-scripts--running)
3. [Unit test patterns](#3-unit-test-patterns)
4. [Test fixtures](#4-test-fixtures)
5. [Integration tests cho skills](#5-integration-tests-cho-skills)
6. [Quality metrics](#6-quality-metrics)
7. [CI/CD pipeline](#7-cicd-pipeline)
8. [Adding new tests](#8-adding-new-tests)
9. [Performance benchmarks](#9-performance-benchmarks)

---

## 1. Test structure overview

```
test/
├── README.md
├── test-installation-components.js    # Installer component tests
├── test-file-refs-csv.js              # File reference validator tests
├── test-workflow-path-regex.js        # Path regex pattern tests
├── test-rehype-plugins.mjs            # Docs plugin tests
├── adversarial-review-tests/
│   ├── README.md
│   └── sample-content.md              # Sample content for testing review skill
└── fixtures/
    └── file-refs-csv/                 # Fixtures for ref tests
        ├── valid-csv-sample.csv
        ├── invalid-csv-sample.csv
        └── ...
```

### Test types

| Type | Location | Purpose |
|------|----------|---------|
| **Unit tests** | `test/test-*.js` | Component-level logic |
| **Fixture-based** | `test/fixtures/` | Data-driven testing |
| **Integration** | Manual via `bmad install` | End-to-end install flow |
| **Skill validation** | `tools/validate-skills.js` | Skill structure compliance |
| **Reference validation** | `tools/validate-file-refs.js` | File ref integrity |
| **Docs validation** | `tools/validate-doc-links.js` | Internal link integrity |

---

## 2. Test scripts & running

### From package.json

```json
{
  "scripts": {
    "test": "npm run test:refs && npm run test:install && npm run lint && npm run lint:md && npm run format:check",
    "test:install": "node test/test-installation-components.js",
    "test:refs": "node test/test-file-refs-csv.js",
    "quality": "npm run format:check && npm run lint && npm run lint:md && npm run docs:build && npm run test:install && npm run validate:refs && npm run validate:skills"
  }
}
```

### Command reference

```bash
# All tests + lint + format check
npm test

# Individual test suites
npm run test:install       # Installation components
npm run test:refs          # File references CSV

# Quality check (used in CI)
npm run quality            # Format + lint + docs build + tests + validate

# Validators
npm run validate:skills    # All skills (14 deterministic rules)
npm run validate:refs      # All file references
node tools/validate-skills.js path/to/skill --strict --json  # Single skill

# Docs
npm run docs:build
npm run docs:validate-links

# Specific test file
node test/test-installation-components.js
node test/test-workflow-path-regex.js
```

### Exit codes

| Code | Meaning |
|------|---------|
| `0` | All pass, or warnings only |
| `1` | Failures (test failed, lint errors, HIGH+ validation findings với `--strict`) |
| `2` | Tool error (invalid args, missing file) |

---

## 3. Unit test patterns

### Pattern: assertion-based

BMad **không dùng test framework** (jest, mocha, vitest). Plain Node.js `assert`:

```javascript
// test/test-workflow-path-regex.js
const assert = require('node:assert');

function testStepFilenameRegex() {
  const STEP_FILENAME_REGEX = /^step-\d{2}[a-z]?-[a-z0-9-]+\.md$/;
  
  // Valid filenames
  assert.match('step-01-init.md', STEP_FILENAME_REGEX);
  assert.match('step-02a-user-selected.md', STEP_FILENAME_REGEX);
  assert.match('step-10-finalize.md', STEP_FILENAME_REGEX);
  
  // Invalid filenames
  assert.doesNotMatch('step-1-init.md', STEP_FILENAME_REGEX);  // No leading zero
  assert.doesNotMatch('step-01.md', STEP_FILENAME_REGEX);       // No description
  assert.doesNotMatch('Step-01-init.md', STEP_FILENAME_REGEX);  // Uppercase
  assert.doesNotMatch('step-01_init.md', STEP_FILENAME_REGEX);  // Underscore
  
  console.log('✅ testStepFilenameRegex passed');
}

testStepFilenameRegex();

console.log('✅ All tests passed');
```

### Pattern: fixture-based CSV testing

```javascript
// test/test-file-refs-csv.js
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert');

const FIXTURES_DIR = path.join(__dirname, 'fixtures', 'file-refs-csv');

function testValidCSV() {
  const csvPath = path.join(FIXTURES_DIR, 'valid-csv-sample.csv');
  const content = fs.readFileSync(csvPath, 'utf8');
  
  // Test parser handles
  const lines = content.trim().split('\n');
  const [header, ...rows] = lines;
  
  assert.strictEqual(header, 'type,name,module,path,hash');
  assert.ok(rows.length > 0, 'Should have data rows');
  
  for (const row of rows) {
    const cols = parseCsvRow(row);
    assert.strictEqual(cols.length, 5, `Row should have 5 cols: ${row}`);
  }
  
  console.log('✅ testValidCSV passed');
}

testValidCSV();
```

### Pattern: error case testing

```javascript
function testInvalidFrontmatter() {
  const content = `---
name: bmad-test
description: [invalid YAML
---
Body
`;
  
  const result = parseFrontmatter(content);
  
  // Should return null (not throw)
  assert.strictEqual(result, null);
  
  console.log('✅ testInvalidFrontmatter passed');
}
```

---

## 4. Test fixtures

### Fixture structure

```
test/fixtures/
└── file-refs-csv/
    ├── valid-csv-sample.csv        # Well-formed CSV
    ├── invalid-csv-sample.csv      # Missing columns
    ├── unescaped-quotes.csv        # Edge case
    └── README.md                   # Explains each fixture
```

### Writing new fixtures

1. **Create dir for test suite:** `test/fixtures/{suite-name}/`
2. **Add fixtures với descriptive names:**
   - `valid-basic.csv` — happy path
   - `valid-edge-case-X.csv` — specific edge case
   - `invalid-missing-Y.csv` — negative test
3. **Add README.md** explaining each fixture's purpose
4. **Reference fixtures in tests:**
   ```javascript
   const fixturePath = path.join(__dirname, 'fixtures', 'file-refs-csv', 'valid-basic.csv');
   ```

### Good fixture practices

- **Keep small:** Fixtures easy to read manually
- **Comment intent:** `# This tests CSV with embedded quotes`
- **One concern per fixture:** Không test nhiều things in one file
- **Self-documenting:** Name tells you what it tests

---

## 5. Integration tests cho skills

BMad **không có automated integration tests** cho full skill execution (requires LLM). Manual flow:

### Test install + execution flow

**1. Setup test project:**
```bash
cd /tmp
rm -rf test-bmad-project
mkdir test-bmad-project && cd test-bmad-project
git init
```

**2. Install từ dev branch:**
```bash
# From BMad repo
npx --package=/path/to/BMAD-METHOD bmad-method install \
  --directory /tmp/test-bmad-project \
  --modules core,bmm \
  --tools claude-code \
  --yes
```

**3. Verify:**
```bash
cd /tmp/test-bmad-project
ls -la _bmad/                   # _bmad/ created
ls -la .claude/skills/          # Skills copied
cat _bmad/_config/manifest.yaml # Manifest correct
cat _bmad/core/config.yaml      # Config generated
```

**4. Test skill execution:**
- Open Claude Code in test project
- Invoke skill (e.g., `/bmad-agent-pm`)
- Verify output files created in correct paths
- Verify config variables resolved

**5. Test customization:**
```bash
# Create team override
cat > _bmad/custom/bmad-agent-pm.toml <<'EOF'
[agent]
icon = "🏥"
EOF

# Verify via resolver
python3 _bmad/scripts/resolve_customization.py \
  --skill _bmad/bmm/2-plan-workflows/bmad-agent-pm \
  --key agent
```

**6. Test update:**
```bash
# Modify framework source
# ... change a skill in src/

# Re-run install in update mode
npx --package=/path/to/BMAD-METHOD bmad-method install \
  --directory /tmp/test-bmad-project \
  --action update
```

Verify:
- Customizations preserved (`_bmad/custom/` intact)
- Framework updates applied
- Modified files detected

### Integration test checklist

**Fresh install:**
- [ ] `_bmad/` directory created
- [ ] `_bmad/_config/manifest.yaml` present
- [ ] `_bmad/_config/skill-manifest.csv` present
- [ ] `_bmad/_config/files-manifest.csv` present
- [ ] Each module's `config.yaml` present
- [ ] Each IDE's skills directory populated
- [ ] Skill count in manifest matches source

**Update install:**
- [ ] `_bmad/custom/` preserved
- [ ] User-modified files NOT overwritten (if still match framework)
- [ ] User-modified files in custom locations preserved
- [ ] New files from framework added
- [ ] Deleted files from framework removed
- [ ] Customization overrides still merge correctly

**Uninstall:**
- [ ] `_bmad/` directory removed
- [ ] IDE skills dirs cleaned up
- [ ] Git-tracked files NOT removed (if in custom/)

---

## 6. Quality metrics

### Code quality tools

| Tool | Purpose | Config |
|------|---------|--------|
| **prettier** | Code formatting | `prettier.config.mjs` |
| **eslint** | JS linting | `eslint.config.mjs` |
| **markdownlint-cli2** | MD linting | `.markdownlint-cli2.*` |

### Prettier config (prettier.config.mjs)

```javascript
export default {
  singleQuote: true,
  semi: true,
  trailingComma: 'all',
  printWidth: 100,
  tabWidth: 2,
  useTabs: false,
  arrowParens: 'always',
  endOfLine: 'lf'
};
```

### ESLint config (eslint.config.mjs)

Uses modern flat config. Max warnings: 0.

### Markdownlint rules

Disabled rules (đặc thù cho BMad):
- `MD013` (line-length) — Mermaid blocks dài
- `MD033` (inline-html) — XML workflow tags
- `MD041` (first-line-h1) — Some files có frontmatter only

### Metrics tracked (unofficial, observational)

| Metric | Target | Current (observed) |
|--------|--------|---------------------|
| Skill count | 30+ | 39 |
| Validation rules | 25+ | 27 (14 deterministic + 13 inference) |
| Test files | 4+ | 4 |
| Doc coverage | Multi-language | 5 languages |
| IDE support | 4+ | 4 (Claude Code, Cursor, JetBrains, VS Code) |
| Startup time | <2s | ~1s (empirical) |
| Install time | <30s | 5-15s (depends on modules) |

---

## 7. CI/CD pipeline

### GitHub Actions workflow

Location: `.github/workflows/quality.yaml`

```yaml
name: Quality

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run quality checks
        run: npm run quality
```

### Quality gate

`npm run quality` chạy:
1. `format:check` — Prettier
2. `lint` — ESLint
3. `lint:md` — markdownlint
4. `docs:build` — Astro build (catches broken links)
5. `test:install` — Installation tests
6. `validate:refs` — File reference validation (strict)
7. `validate:skills` — Skill validation (strict)

**PR fails if any step fails.**

### Release process

1. Conventional commits → push to `main`
2. Every push → npm `next` tag (automatic)
3. Weekly release cut → npm `latest` tag (stable)

**Release checklist:**
- [ ] All PRs merged to main pass quality
- [ ] CHANGELOG.md updated
- [ ] Version bumped in package.json
- [ ] Git tag created: `v6.3.0`
- [ ] npm publish

---

## 8. Adding new tests

### When to add tests

**Add a test when:**
- Fixing a bug (regression test)
- Adding deterministic logic (regex, parser, merger)
- Changing file operations (copy, sync, delete)
- Adding validation rule

**Don't bother with tests for:**
- Interactive prompts (hard to test, minimal logic)
- LLM-dependent skill execution
- IDE UI integration

### Test file template

```javascript
// test/test-my-feature.js
const assert = require('node:assert');
const { myFunction } = require('../tools/installer/my-module.js');

// ============================================================================
// Test: happy path
// ============================================================================
function testHappyPath() {
  const input = { /* ... */ };
  const result = myFunction(input);
  
  assert.strictEqual(result.status, 'success');
  assert.deepStrictEqual(result.data, expectedData);
  
  console.log('✅ testHappyPath passed');
}

// ============================================================================
// Test: edge case
// ============================================================================
function testEmptyInput() {
  const result = myFunction({});
  assert.strictEqual(result.status, 'noop');
  console.log('✅ testEmptyInput passed');
}

// ============================================================================
// Test: error case
// ============================================================================
function testInvalidInput() {
  assert.throws(
    () => myFunction(null),
    { message: /Input is required/ }
  );
  console.log('✅ testInvalidInput passed');
}

// Run all tests
testHappyPath();
testEmptyInput();
testInvalidInput();

console.log('\n✅ All tests in test-my-feature.js passed');
```

### Adding to test suite

1. **Create file:** `test/test-my-feature.js`
2. **Run locally:** `node test/test-my-feature.js`
3. **Add to npm script** (if part of common suite):
   ```json
   "test:my-feature": "node test/test-my-feature.js",
   "test": "... && npm run test:my-feature"
   ```
4. **Document in README.md:** `test/README.md`
5. **Commit + PR:**
   ```bash
   git add test/test-my-feature.js test/README.md package.json
   git commit -m "test: add my-feature regression tests"
   ```

### Testing new skill

Không có automated test framework cho skill execution. Pattern:

**1. Unit test parser nếu có:**
```javascript
// Test YAML frontmatter parsing
function testParseMySkillFrontmatter() {
  const content = fs.readFileSync('src/core-skills/bmad-my-skill/SKILL.md', 'utf8');
  const fm = parseFrontmatter(content);
  
  assert.strictEqual(fm.name, 'bmad-my-skill');
  assert.ok(fm.description.includes('Use when'));
}
```

**2. Validate skill structure:**
```bash
node tools/validate-skills.js src/core-skills/bmad-my-skill --strict
```

**3. Manual integration test** (see section 5).

---

## 9. Performance benchmarks

### Installer performance

Test setup:
```bash
# Cold install (no cache)
rm -rf ~/.bmad/cache
time npx bmad-method install --modules core,bmm --tools claude-code --yes

# Warm install (cache hit)
time npx bmad-method install --modules core,bmm --tools claude-code --action update --yes
```

Observed (on SSD, 8-core):
- **Cold install (core + bmm):** 8-12s
- **Warm update:** 3-5s
- **Full quality check:** 15-25s

Bottlenecks:
- File copy (300+ files per module)
- SHA-256 hashing (cho manifest)
- External module clone (if applicable, 10-30s for git clone)

### Validator performance

```bash
time node tools/validate-skills.js
# ~500ms for 39 skills
```

Very fast vì:
- Hand-rolled YAML parser (no library load)
- Regex-based checks
- Sequential processing (parallel not needed)

### Docs build

```bash
time npm run docs:build
# ~30-60s (Astro + Starlight + llms.txt generation)
```

### Optimization opportunities

1. **Parallel file copy:** Currently sequential, could parallelize
2. **Skip rehashing unchanged files:** Compare mtime first
3. **Parallel IDE setup:** Currently sequential, could parallelize
4. **Lazy module loading:** Only load modules when needed

---

## Summary

Testing philosophy:
- **Deterministic code:** Unit tests bắt buộc
- **Interactive code:** Manual integration tests
- **LLM-dependent:** Not automated, manual verification

Tools:
- Node.js `assert` (no framework)
- Custom validators (validate-skills, validate-refs, validate-doc-links)
- Prettier + ESLint + markdownlint
- GitHub Actions CI

Coverage:
- Unit: file refs parser, workflow path regex, installation components
- Integration: manual install/update/uninstall flows
- Validation: 14 deterministic skill rules + 13 inference rules

---

**Đọc tiếp:** [12-comparison-and-migration.md](12-comparison-and-migration.md) — So sánh chi tiết với các framework khác + migration paths.
