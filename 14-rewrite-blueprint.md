# 14. Rewrite Blueprint - Recreating BMad from Scratch

> ⚠️ **UNOFFICIAL THIRD-PARTY DOCUMENTATION**
> NOT official BMad docs. See [DISCLAIMER.md](DISCLAIMER.md) | Licensed MIT — see [LICENSE](LICENSE) and [NOTICE](NOTICE)
> Official BMAD-METHOD: <https://github.com/bmad-code-org/BMAD-METHOD>

---

> **Purpose:** A blueprint for rewriting the BMad framework in **Go / Rust / Python** or any other language. Interface specs + testing strategy + minimum viable framework.

> **Audience:** Engineers who want to build a BMad-compatible alternative, or teams who want BMad internally in a different language.

---

## Table of Contents

1. [Executive summary](#1-executive-summary)
2. [Minimum viable framework (MVF)](#2-minimum-viable-framework-mvf)
3. [Phase 1: Core data structures](#3-phase-1-core-data-structures)
4. [Phase 2: Installer state machine](#4-phase-2-installer-state-machine)
5. [Phase 3: Validator](#5-phase-3-validator)
6. [Phase 4: Customization resolver](#6-phase-4-customization-resolver)
7. [Phase 5: CLI + UI](#7-phase-5-cli--ui)
8. [Phase 6: IDE integration](#8-phase-6-ide-integration)
9. [Phase 7: External modules](#9-phase-7-external-modules)
10. [Testing strategy](#10-testing-strategy)
11. [Per-language recipe: Go](#11-per-language-recipe-go)
12. [Per-language recipe: Rust](#12-per-language-recipe-rust)
13. [Per-language recipe: Python](#13-per-language-recipe-python)
14. [Migration plan](#14-migration-plan)

---

## 1. Executive summary

### What to rewrite

The BMad framework consists of **3 main parts**:
1. **Installer** (~5000 LOC JS) — CLI, file ops, state machine
2. **Validator** (~500 LOC JS) — Deterministic skill validation
3. **Build tools** (~500 LOC JS) — Docs build, link validation

### What NOT to rewrite

**Keep as-is (framework assets):**
- Skills (SKILL.md, workflow.md, steps/, customize.toml)
- Module definitions (module.yaml)
- Documentation (docs/)
- Sub-agent prompts

These are **declarative content**, not code. The AI LLM reads them directly.

### Effort estimate

| Language | Skilled engineer | Novice |
|----------|------------------|--------|
| **Go** | 6-8 weeks | 3-4 months |
| **Rust** | 8-12 weeks | 5-6 months |
| **Python** | 4-6 weeks | 2-3 months |

### Why rewrite?

- **Performance:** Go/Rust faster than JS for file ops
- **Deployment:** Single binary, no Node.js runtime
- **Security:** Static typing, less injection surface
- **Ecosystem:** Match your org's primary language

---

## 2. Minimum viable framework (MVF)

Minimum features for a BMad-compatible alternative:

### Must have (MVF v1.0)

**Installer:**
- [ ] Install modules from local source
- [ ] Copy skills to the `_bmad/` directory
- [ ] Generate `config.yaml` from user prompts
- [ ] Update mode with user-file preservation
- [ ] Manifest generation (manifest.yaml + skill-manifest.csv + files-manifest.csv)

**Validator:**
- [ ] Parse YAML frontmatter (hand-rolled, no library)
- [ ] Check 14 deterministic rules (SKILL-01 through STEP-07)
- [ ] JSON + table output modes
- [ ] `--strict` mode with exit codes

**Customization:**
- [ ] 3-level TOML merge (default + team + user)
- [ ] 4-level central config merge
- [ ] Shape-based merge rules (scalars, arrays, keyed arrays)
- [ ] CLI tool to resolve: `resolve_customization --skill X --key agent`

**CLI:**
- [ ] `install`, `uninstall`, `update`, `status` commands
- [ ] Interactive prompts
- [ ] `--yes` for non-interactive
- [ ] Help text

### Nice to have (MVF v1.5)

- External module support (git clone + cache)
- Registry fetching (GitHub)
- IDE integration (at least Claude Code)
- Update detection with file hash diff

### Can skip (MVF v1.0)

- Docs build pipeline (docs already in markdown, host elsewhere)
- Multi-language docs (let users translate)
- Platform-specific optimizations
- Telemetry

---

## 3. Phase 1: Core data structures

### Config

```typescript
// Common interface across languages
interface Config {
  directory: string;                    // Target install dir
  modules: ReadonlyArray<string>;       // ['core', 'bmm', ...]
  ides: ReadonlyArray<string>;          // ['claude-code', ...]
  skipPrompts: boolean;
  actionType: 'install' | 'update' | 'quick-update';
  coreConfig: Record<string, any>;
  moduleConfigs: Record<string, Record<string, any>>;
}
```

**Frozen after creation.** No mutation mid-flow.

### InstallPaths

```typescript
interface InstallPaths {
  readonly projectRoot: string;
  readonly bmadDir: string;         // <projectRoot>/_bmad
  readonly configDir: string;       // <bmadDir>/_config
  readonly scriptsDir: string;      // <bmadDir>/scripts
  readonly customDir: string;       // <bmadDir>/custom
  
  moduleDir(name: string): string;
  moduleConfig(name: string): string;
  manifestFile(): string;
  filesManifest(): string;
  skillManifest(): string;
}
```

### Manifest files

```typescript
interface Manifest {
  installation: {
    version: string;
    installDate: string;      // ISO 8601
    lastUpdated: string;
  };
  modules: Array<{
    name: string;
    version: string;
    source: 'built-in' | 'official' | 'custom';
    installDate: string;
  }>;
  ides: string[];
  agentCustomizations?: Record<string, string>;  // path → hash
}

interface SkillManifestRow {
  canonicalId: string;    // = directory name
  name: string;           // from SKILL.md frontmatter
  description: string;
  module: string;
  path: string;           // relative to project root
}

interface FilesManifestRow {
  type: 'skill' | 'agent' | 'config' | 'resource';
  name: string;
  module: string;
  path: string;
  hash: string;           // SHA-256
}
```

### Validation finding

```typescript
interface Finding {
  rule: string;                     // 'SKILL-04'
  title: string;
  severity: 'CRITICAL' | 'HIGH' | 'MEDIUM' | 'LOW';
  file: string;
  line?: number;
  detail: string;
  fix: string;
}
```

### Customization toml

```typescript
interface CustomizeToml {
  agent?: AgentBlock;
  workflow?: WorkflowBlock;
}

interface AgentBlock {
  // Read-only (ignored if overridden)
  name?: string;
  title?: string;
  
  // Configurable scalars
  icon?: string;
  role?: string;
  identity?: string;
  communication_style?: string;
  
  // Append arrays
  principles?: string[];
  persistent_facts?: string[];
  activation_steps_prepend?: string[];
  activation_steps_append?: string[];
  
  // Keyed arrays (merge by code)
  menu?: MenuItem[];
}

interface MenuItem {
  code: string;         // merge key
  description: string;
  skill?: string;
  prompt?: string;
}

interface WorkflowBlock {
  activation_steps_prepend?: string[];
  activation_steps_append?: string[];
  persistent_facts?: string[];
  on_complete?: string;
}
```

---

## 4. Phase 2: Installer state machine

### 8-phase install (see diagram 1 in file 10)

```typescript
interface Installer {
  install(config: Config): Promise<InstallResult>;
  uninstall(config: UninstallConfig): Promise<void>;
  status(config: StatusConfig): Promise<Status>;
}

interface InstallResult {
  success: boolean;
  path: string;
  modules: string[];
  ides: string[];
  projectDir: string;
}
```

### Key algorithms

**1. syncDirectory** (file preservation):

```pseudo
function syncDirectory(source, dest):
  for each file in source:
    if dest file doesn't exist:
      copy to dest
    else:
      sourceHash = sha256(source file)
      destHash = sha256(dest file)
      if sourceHash == destHash:
        copy (identical, safe)
      else:
        if source.mtime > dest.mtime:
          copy (source newer)
        else:
          preserve (user modified)
  
  for each file in dest:
    if source file doesn't exist:
      remove (deleted in source)
```

**2. detectCustomFiles:**

```pseudo
function detectCustomFiles(bmadDir, manifest):
  customFiles = []
  modifiedFiles = []
  
  scan bmadDir recursively:
    for each file:
      skip _config/, _memory/, config.yaml
      
      if file not in manifest:
        customFiles.push(file)  # User added
      else:
        currentHash = sha256(file)
        if currentHash != manifest.originalHash:
          modifiedFiles.push({path: file, relativePath: ...})
  
  return {customFiles, modifiedFiles}
```

**3. Manifest generation:**

```pseudo
function generateManifests(bmadDir, modules):
  skills = []
  agents = []
  
  for each module in modules:
    walk module directory:
      for each SKILL.md found:
        parse frontmatter
        validate: name matches dir, has description
        skills.push({canonicalId: dirName, name, description, module, path})
    
    parse module.yaml:
      for each agent:
        agents.push(agent)
  
  write manifest.yaml
  write skill-manifest.csv
  write files-manifest.csv (with SHA-256 hashes)
```

### Error handling

```pseudo
try:
  install phases 1-8
catch error:
  cleanup temp backup dirs
  re-throw error

finally:
  # Always cleanup temp
  remove /tmp/bmad-backup-*
  remove /tmp/bmad-modified-*
```

---

## 5. Phase 3: Validator

### 14 deterministic rules implementation

**Hand-rolled YAML frontmatter parser** (avoid YAML library dependency):

```pseudo
function parseFrontmatterMultiline(content):
  trimmed = content.trimStart()
  if not starts with "---": return null
  
  find end "\n---\n" after position 3
  if not found and ends with "\n---": endIndex = length - 4
  else if not found: return null
  
  fmBlock = trimmed[3..endIndex].trim()
  if fmBlock is empty: return {}
  
  result = {}
  currentKey = null
  currentValue = ""
  
  for line in fmBlock.split("\n"):
    colonIndex = line.indexOf(":")
    
    # New key: colon > 0, line starts at column 0
    if colonIndex > 0 and line[0] not in (" ", "\t"):
      if currentKey:
        result[currentKey] = stripQuotes(currentValue.trim())
      currentKey = line[0..colonIndex].trim()
      currentValue = line[colonIndex+1..]
    elif currentKey:
      if line.trimStart().startsWith("#"): continue
      currentValue += "\n" + line
  
  if currentKey:
    result[currentKey] = stripQuotes(currentValue.trim())
  
  return result
```

### Rule implementations (pseudo-code)

See [08-installer-code-level-spec.md § 5.3](08-installer-code-level-spec.md) for full implementations. Summary:

- **SKILL-01:** `fs.exists(path + '/SKILL.md')`
- **SKILL-02:** `'name' in frontmatter`
- **SKILL-03:** `'description' in frontmatter`
- **SKILL-04:** `regex_match(name, /^bmad-[a-z0-9]+(-[a-z0-9]+)*$/)`
- **SKILL-05:** `name === path.basename(skillDir)`
- **SKILL-06:** `description.length <= 1024 && /use\s+when/i.test(description)`
- **SKILL-07:** `body_after_frontmatter.trim() !== ''`
- **WF-01:** Non-SKILL.md frontmatter: `!('name' in fm)`
- **WF-02:** Non-SKILL.md frontmatter: `!('description' in fm)`
- **PATH-02:** No `installed_path` substring in files
- **STEP-01:** `regex_match(filename, /^step-\d{2}[a-z]?-[a-z0-9-]+\.md$/)`
- **STEP-06:** Step frontmatter: `!('name' in fm) && !('description' in fm)`
- **STEP-07:** Step count in [2, 10]
- **SEQ-02:** No time estimate patterns (`~\d+ min`, `takes N min`, etc.)

### CLI interface

```bash
validate-skills                              # All skills
validate-skills PATH                         # Single skill
validate-skills --strict                     # Exit 1 if HIGH+
validate-skills --json                       # JSON output
validate-skills PATH --strict --json         # Combined
```

---

## 6. Phase 4: Customization resolver

### Merge algorithm

```pseudo
function deepMerge(base, override):
  if isDict(base) and isDict(override):
    result = copy(base)
    for key, val in override.items():
      result[key] = deepMerge(result.get(key), val)
    return result
  
  if isList(base) and isList(override):
    keyedField = detectKeyedField(base + override)
    if keyedField:
      return mergeByKey(base, override, keyedField)
    else:
      return base + override  # Append
  
  # Scalar
  return override if override is defined else base


function detectKeyedField(items):
  if not all items are dicts: return null
  
  for candidate in ['code', 'id']:
    if all items have non-null item[candidate]:
      return candidate
  
  return null


function mergeByKey(base, override, keyField):
  result = []
  byKey = {}
  
  # Build from base
  for item in base:
    key = item[keyField]
    byKey[key] = item
    result.append(key)
  
  # Merge override
  for item in override:
    key = item[keyField]
    if key in byKey:
      byKey[key] = deepMerge(byKey[key], item)  # Replace
    else:
      byKey[key] = item
      result.append(key)  # Append
  
  return [byKey[k] for k in result]
```

### CLI interface

```bash
resolve_customization --skill /path/to/skill --key agent
resolve_customization --skill /path/to/skill --key workflow
resolve_customization --skill /path/to/skill --key agent.menu[0]
```

Output: JSON of merged config.

### 3-layer merge sequence

```pseudo
function resolveCustomization(skillRoot, projectRoot, key=null):
  # 1. Load defaults (required)
  defaults = parseToml(skillRoot + "/customize.toml")
  
  # 2. Find project root if not provided
  if not projectRoot:
    projectRoot = findProjectRoot(skillRoot)
  
  # 3. Load overrides (optional)
  team = {}
  user = {}
  if projectRoot:
    teamPath = projectRoot + "/_bmad/custom/" + skillName(skillRoot) + ".toml"
    userPath = projectRoot + "/_bmad/custom/" + skillName(skillRoot) + ".user.toml"
    if exists(teamPath): team = parseToml(teamPath)
    if exists(userPath): user = parseToml(userPath)
  
  # 4. 3-layer merge
  merged = deepMerge(defaults, team)
  merged = deepMerge(merged, user)
  
  # 5. Extract key if requested
  if key:
    return extractDottedKey(merged, key)
  
  return merged
```

---

## 7. Phase 5: CLI + UI

### Command structure

```bash
bmad [--version] [--help]
bmad install [OPTIONS]
bmad uninstall [OPTIONS]
bmad update [OPTIONS]
bmad status [OPTIONS]
bmad validate [PATH] [OPTIONS]
bmad resolve [OPTIONS]
```

### Install command

```typescript
interface InstallOptions {
  directory?: string;           // Default: cwd
  modules?: string[];           // Comma-separated
  tools?: string[];             // IDEs
  action?: 'install' | 'update' | 'quick-update';
  userName?: string;            // Skip prompt
  communicationLanguage?: string;
  documentOutputLanguage?: string;
  outputFolder?: string;
  customSource?: string;        // Git URL
  yes?: boolean;                // Skip prompts
  verbose?: boolean;
}

async function install(options: InstallOptions): Promise<void> {
  const config = await buildConfigFromPromptsOrOptions(options);
  const installer = new Installer();
  const result = await installer.install(config);
  renderSummary(result);
}
```

### Interactive prompts

```pseudo
async function promptInstall(options):
  displayLogo()
  displayStartMessage()
  
  directory = options.directory ?? await prompt.text("Where install?")
  validateDirectory(directory)
  
  existingInstall = await detectExisting(directory)
  
  actionType = existingInstall
    ? await prompt.select("How proceed?", ['Quick Update', 'Modify'])
    : 'install'
  
  modules = options.modules
    ?? (options.yes ? getDefaults() : await promptModules(existingInstall))
  
  if 'core' not in modules: modules.prepend('core')
  
  ides = await promptIdeSelection(options, existingInstall)
  
  moduleConfigs = {}
  for module in modules:
    moduleYaml = loadModuleYaml(module)
    for var, def in moduleYaml.configVars:
      answer = options[var]
        ?? (options.yes ? def.default : await prompt.text(def.prompt))
      moduleConfigs[module][var] = applyResultTemplate(answer, def.result)
  
  return Config.build({
    directory,
    modules,
    ides,
    actionType,
    moduleConfigs,
    skipPrompts: options.yes
  })
```

---

## 8. Phase 6: IDE integration

### Generic IDE setup

```typescript
class ConfigDrivenIdeSetup {
  constructor(
    readonly platformCode: string,
    readonly platformConfig: PlatformConfig
  ) {}
  
  async setup(projectDir: string, bmadDir: string, options: SetupOptions): Promise<SetupResult> {
    // 1. Ancestor conflict check
    if (this.platformConfig.ancestor_conflict_check) {
      const conflict = await this.findAncestorConflict(projectDir);
      if (conflict) return { success: false, reason: 'ancestor-conflict', conflictDir: conflict };
    }
    
    // 2. Cleanup legacy targets
    await this.cleanup(projectDir, options, bmadDir);
    
    // 3. Install verbatim skills
    if (this.platformConfig.target_dir) {
      return this.installToTarget(projectDir, bmadDir, this.platformConfig, options);
    }
    
    return { success: false, reason: 'no-config' };
  }
  
  async installVerbatimSkills(projectDir: string, bmadDir: string, targetPath: string): Promise<number> {
    const csvPath = path.join(bmadDir, '_config', 'skill-manifest.csv');
    const records = parseCsv(await readFile(csvPath));
    
    let count = 0;
    for (const record of records) {
      const sourceDir = path.dirname(path.join(bmadDir, record.path.replace(bmadPrefix, '')));
      if (!await exists(sourceDir)) continue;
      
      const skillDir = path.join(targetPath, record.canonicalId);
      await rm(skillDir, { recursive: true });
      await mkdir(skillDir, { recursive: true });
      
      await copyDir(sourceDir, skillDir, {
        filter: (src) => !isOsArtifact(src) && !isHidden(src)
      });
      
      count++;
    }
    
    return count;
  }
}
```

### platform-codes.yaml support

```yaml
platforms:
  claude-code:
    name: "Claude Code"
    preferred: true
    installer:
      target_dir: ".claude/skills"
      legacy_targets: []
      ancestor_conflict_check: true
```

Load at startup, instantiate `ConfigDrivenIdeSetup` for each platform.

---

## 9. Phase 7: External modules

### Registry client

```typescript
class RegistryClient {
  async fetchOfficialRegistry(): Promise<Registry> {
    try {
      const url = 'https://raw.githubusercontent.com/bmad-code-org/bmad-plugins-marketplace/main/registry/official.yaml';
      const response = await http.get(url);
      return parseYaml(response.body);
    } catch (error) {
      // Fallback to bundled
      return parseYaml(readFile(BUNDLED_REGISTRY_PATH));
    }
  }
}
```

### Git operations (subprocess)

```pseudo
function cloneExternalModule(moduleCode, moduleInfo):
  cacheDir = os.home + "/.bmad/cache/external-modules/" + moduleCode
  
  if exists(cacheDir):
    # Update existing
    try:
      currentRef = exec("git rev-parse HEAD", cwd=cacheDir)
      exec("git fetch origin --depth 1", cwd=cacheDir)
      exec("git reset --hard origin/HEAD", cwd=cacheDir)
      newRef = exec("git rev-parse HEAD", cwd=cacheDir)
      needsDependencyInstall = currentRef != newRef
    catch:
      rm(cacheDir, recursive=True)
      wasNewClone = True
  else:
    wasNewClone = True
  
  if wasNewClone:
    exec(`git clone --depth 1 "${moduleInfo.url}" "${cacheDir}"`)
  
  # npm install if needed
  if exists(cacheDir + "/package.json"):
    if needsDependencyInstall or wasNewClone or not exists(cacheDir + "/node_modules"):
      exec("npm install --omit=dev --no-audit --legacy-peer-deps", cwd=cacheDir)
  
  return cacheDir
```

### module.yaml resolution

```pseudo
function findExternalModuleSource(cacheDir, configuredPath):
  # Priority:
  # 1. Configured path (moduleDefinition field)
  # 2. skills/module.yaml
  # 3. src/module.yaml
  # 4. skills/SUBDIR/module.yaml (one level)
  # 5. src/SUBDIR/module.yaml (one level)
  # 6. module.yaml at root
  
  candidates = [
    path.join(cacheDir, configuredPath),
    path.join(cacheDir, "skills/module.yaml"),
    path.join(cacheDir, "src/module.yaml"),
    # ... SUBDIR variants
    path.join(cacheDir, "module.yaml")
  ]
  
  for candidate in candidates:
    if exists(candidate):
      return path.dirname(candidate)
  
  return null
```

---

## 10. Testing strategy

### Unit tests (priority 1)

**Parser:** frontmatter YAML (hand-rolled)
```
test-frontmatter-parser.{js,go,rs,py}
  - testParseEmpty
  - testParseValid
  - testParseMultilineValue
  - testParseInvalid
  - testParseWithComments
```

**Validator:** 14 rules
```
test-validator-rules.{lang}
  - testSKILL01ThroughSKILL07
  - testWF01_WF02
  - testPATH02
  - testSTEP01_STEP06_STEP07
  - testSEQ02
```

**Resolver:** merge algorithm
```
test-resolver.{lang}
  - testScalarOverride
  - testDictDeepMerge
  - testArrayAppend
  - testKeyedMergeByCode
  - testKeyedMergeById
  - testMixedArrayFallbackToAppend
  - test3LayerMerge
  - test4LayerCentralMerge
```

**File ops:** syncDirectory
```
test-sync-directory.{lang}
  - testNewFile
  - testIdenticalFileCopy
  - testUserModifiedPreserved
  - testSourceNewerCopied
  - testDeletedFileRemoved
```

### Integration tests (priority 2)

```
test-integration-install.{lang}
  - Fresh install
  - Update install
  - Uninstall
  - Customization preservation
```

### Fixture-based tests

```
test/fixtures/
├── skills/                   # Sample SKILL.md files (valid + invalid)
├── manifests/                # Sample manifest CSVs
├── customizations/           # Sample customize.toml files
└── module-yamls/             # Sample module.yaml files
```

### Target coverage

- Parser: 100%
- Validator: 90%+
- Resolver: 95%+
- File ops: 80%+
- Integration: Key flows covered manually

---

## 11. Per-language recipe: Go

### Dependencies

```go
// go.mod
require (
    github.com/spf13/cobra v1.8.0          // CLI framework
    github.com/charmbracelet/bubbletea v0.25.0  // TUI
    github.com/charmbracelet/lipgloss v0.9.0     // Styling
    gopkg.in/yaml.v3 v3.0.1                 // YAML parsing
    github.com/BurntSushi/toml v1.3.0      // TOML parsing
    github.com/go-git/go-git/v5 v5.11.0    // Git operations
)
```

### Project structure

```
bmad-go/
├── cmd/
│   └── bmad/main.go              # Entry point
├── internal/
│   ├── installer/                # Core installer
│   │   ├── installer.go
│   │   ├── config.go
│   │   ├── paths.go
│   │   └── manifest.go
│   ├── validator/
│   │   ├── validator.go
│   │   ├── rules.go
│   │   └── frontmatter.go
│   ├── resolver/
│   │   └── resolver.go
│   ├── modules/
│   │   └── external.go
│   └── ide/
│       ├── manager.go
│       └── config_driven.go
├── pkg/
│   └── types/                    # Public types
├── test/
│   └── fixtures/
└── go.mod
```

### Key pattern: Interfaces

```go
// Installer interface
type Installer interface {
    Install(ctx context.Context, cfg *Config) (*InstallResult, error)
    Uninstall(ctx context.Context, cfg *UninstallConfig) error
}

// File operations interface (for testing)
type FileOps interface {
    SyncDirectory(source, dest string) error
    CopyDirectory(source, dest string, filter FileFilter) error
    GetFileHash(path string) (string, error)
}

// Concurrent file copy with semaphore
func (f *FileOpsImpl) CopyDirectory(source, dest string, filter FileFilter) error {
    sem := make(chan struct{}, 10)  // Max 10 concurrent
    g, ctx := errgroup.WithContext(context.Background())
    
    filepath.Walk(source, func(srcPath string, info os.FileInfo, err error) error {
        if !filter(srcPath) { return nil }
        
        sem <- struct{}{}
        g.Go(func() error {
            defer func() { <-sem }()
            return f.copyFile(srcPath, dest)
        })
        
        return nil
    })
    
    return g.Wait()
}
```

### CLI with Cobra

```go
func NewRootCmd() *cobra.Command {
    rootCmd := &cobra.Command{
        Use:   "bmad",
        Short: "BMad Method CLI",
    }
    
    rootCmd.AddCommand(NewInstallCmd())
    rootCmd.AddCommand(NewUninstallCmd())
    rootCmd.AddCommand(NewValidateCmd())
    
    return rootCmd
}

func NewInstallCmd() *cobra.Command {
    cmd := &cobra.Command{
        Use:   "install",
        Short: "Install BMad into project",
        RunE:  runInstall,
    }
    
    cmd.Flags().String("directory", "", "Install directory")
    cmd.Flags().StringSlice("modules", nil, "Modules to install")
    cmd.Flags().Bool("yes", false, "Skip prompts")
    
    return cmd
}
```

---

## 12. Per-language recipe: Rust

### Dependencies

```toml
# Cargo.toml
[dependencies]
clap = { version = "4.4", features = ["derive"] }
dialoguer = "0.11"
indicatif = "0.17"
serde = { version = "1.0", features = ["derive"] }
serde_yaml = "0.9"
toml = "0.8"
tokio = { version = "1.35", features = ["full"] }
sha2 = "0.10"
git2 = "0.18"
anyhow = "1.0"
thiserror = "1.0"
```

### Project structure

```
bmad-rs/
├── src/
│   ├── main.rs                 # Entry point
│   ├── lib.rs                  # Public API
│   ├── installer/
│   │   ├── mod.rs
│   │   ├── config.rs
│   │   ├── paths.rs
│   │   └── manifest.rs
│   ├── validator/
│   ├── resolver/
│   ├── modules/
│   └── ide/
├── tests/
│   └── integration/
└── Cargo.toml
```

### Key pattern: Strong types + traits

```rust
#[derive(Debug, Clone)]
pub struct Config {
    pub directory: PathBuf,
    pub modules: Vec<ModuleName>,  // Newtype
    pub ides: Vec<IdeName>,
    pub skip_prompts: bool,
    pub action_type: ActionType,
    pub core_config: HashMap<String, serde_yaml::Value>,
    pub module_configs: HashMap<ModuleName, HashMap<String, serde_yaml::Value>>,
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct ModuleName(String);

impl ModuleName {
    pub fn new(s: impl Into<String>) -> Result<Self, ValidationError> {
        let s = s.into();
        if Self::is_valid(&s) {
            Ok(Self(s))
        } else {
            Err(ValidationError::InvalidModuleName(s))
        }
    }
    
    fn is_valid(s: &str) -> bool {
        // validate: kebab-case, alphanumeric
        s.chars().all(|c| c.is_ascii_lowercase() || c.is_ascii_digit() || c == '-')
    }
}

#[derive(Debug, Clone, Copy)]
pub enum ActionType {
    Install,
    Update,
    QuickUpdate,
}

// Trait for file ops
#[async_trait]
pub trait FileOps: Send + Sync {
    async fn sync_directory(&self, source: &Path, dest: &Path) -> Result<()>;
    async fn copy_directory(&self, source: &Path, dest: &Path, filter: impl Fn(&Path) -> bool) -> Result<()>;
    async fn get_file_hash(&self, path: &Path) -> Result<String>;
}
```

### Error handling

```rust
#[derive(Debug, thiserror::Error)]
pub enum InstallError {
    #[error("Invalid directory: {0}")]
    InvalidDirectory(String),
    
    #[error("Module not found: {0}")]
    ModuleNotFound(ModuleName),
    
    #[error("Validation failed: {0}")]
    ValidationFailed(String),
    
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
}

pub type InstallResult<T> = Result<T, InstallError>;
```

### CLI with clap

```rust
use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(name = "bmad", version, about = "BMad Method CLI")]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    Install {
        #[arg(short, long)]
        directory: Option<PathBuf>,
        
        #[arg(short, long, value_delimiter = ',')]
        modules: Vec<String>,
        
        #[arg(long)]
        yes: bool,
    },
    Uninstall { /* ... */ },
    Validate { /* ... */ },
}

#[tokio::main]
async fn main() -> Result<()> {
    let cli = Cli::parse();
    
    match cli.command {
        Commands::Install { directory, modules, yes } => {
            install_command(directory, modules, yes).await?;
        }
        Commands::Uninstall { .. } => { /* ... */ }
        Commands::Validate { .. } => { /* ... */ }
    }
    
    Ok(())
}
```

---

## 13. Per-language recipe: Python

### Dependencies

```toml
# pyproject.toml
[project]
dependencies = [
    "click>=8.1",                  # CLI
    "questionary>=2.0",            # Prompts
    "rich>=13.7",                  # TUI
    "pyyaml>=6.0",                 # YAML
    "tomli>=2.0; python_version<'3.11'",  # TOML (builtin in 3.11+)
    "GitPython>=3.1",              # Git
    "httpx>=0.25",                 # HTTP
]

[project.optional-dependencies]
dev = [
    "pytest>=7.4",
    "pytest-asyncio>=0.23",
    "mypy>=1.7",
    "ruff>=0.1",
]
```

### Project structure

```
bmad-py/
├── src/
│   └── bmad/
│       ├── __init__.py
│       ├── __main__.py           # Entry point
│       ├── cli.py                # Click commands
│       ├── installer/
│       │   ├── __init__.py
│       │   ├── core.py
│       │   ├── config.py
│       │   ├── paths.py
│       │   └── manifest.py
│       ├── validator/
│       ├── resolver/
│       ├── modules/
│       └── ide/
├── tests/
└── pyproject.toml
```

### Key pattern: Dataclasses + type hints

```python
from dataclasses import dataclass, field
from pathlib import Path
from typing import Literal
from enum import Enum

class ActionType(str, Enum):
    INSTALL = 'install'
    UPDATE = 'update'
    QUICK_UPDATE = 'quick-update'


@dataclass(frozen=True)
class Config:
    directory: Path
    modules: tuple[str, ...]        # Immutable
    ides: tuple[str, ...]
    skip_prompts: bool = False
    action_type: ActionType = ActionType.INSTALL
    core_config: dict = field(default_factory=dict)
    module_configs: dict = field(default_factory=dict)
    
    def __post_init__(self):
        # Validation
        if not self.directory.is_absolute():
            object.__setattr__(self, 'directory', self.directory.resolve())


@dataclass
class InstallPaths:
    project_root: Path
    bmad_dir: Path
    config_dir: Path
    scripts_dir: Path
    custom_dir: Path
    
    @classmethod
    async def create(cls, config: Config) -> 'InstallPaths':
        bmad_dir = config.directory / '_bmad'
        return cls(
            project_root=config.directory,
            bmad_dir=bmad_dir,
            config_dir=bmad_dir / '_config',
            scripts_dir=bmad_dir / 'scripts',
            custom_dir=bmad_dir / 'custom'
        )
    
    def module_dir(self, name: str) -> Path:
        return self.bmad_dir / name
    
    def module_config(self, name: str) -> Path:
        return self.module_dir(name) / 'config.yaml'
```

### CLI with Click

```python
import click
from pathlib import Path

@click.group()
@click.version_option()
def cli():
    """BMad Method CLI."""
    pass


@cli.command()
@click.option('--directory', '-d', type=click.Path(), help='Install directory')
@click.option('--modules', '-m', multiple=True, help='Modules')
@click.option('--yes', '-y', is_flag=True, help='Skip prompts')
async def install(directory, modules, yes):
    """Install BMad into project."""
    from bmad.installer.core import Installer
    from bmad.installer.config import build_config
    
    config = await build_config(directory, modules, yes)
    installer = Installer()
    result = await installer.install(config)
    
    click.echo(f"✅ Installed at {result.path}")
    click.echo(f"  Modules: {', '.join(result.modules)}")
    click.echo(f"  IDEs: {', '.join(result.ides)}")


@cli.command()
@click.argument('path', required=False, type=click.Path())
@click.option('--strict', is_flag=True, help='Exit 1 on HIGH+ findings')
@click.option('--json', 'json_output', is_flag=True, help='JSON output')
def validate(path, strict, json_output):
    """Validate skills."""
    from bmad.validator import validate_skills
    
    findings = validate_skills(path or Path.cwd())
    
    if json_output:
        import json as json_lib
        click.echo(json_lib.dumps(findings, default=lambda o: o.__dict__, indent=2))
    else:
        render_table(findings)
    
    if strict and any(f.severity in ('CRITICAL', 'HIGH') for f in findings):
        exit(1)
```

### Async file ops

```python
import asyncio
import aiofiles
import hashlib
from pathlib import Path

async def sync_directory(source: Path, dest: Path):
    source_files = list(source.rglob('*'))
    
    # Parallel with semaphore
    sem = asyncio.Semaphore(10)
    
    async def process_file(src_file: Path):
        async with sem:
            rel = src_file.relative_to(source)
            dest_file = dest / rel
            
            if not src_file.is_file():
                return
            
            if not dest_file.exists():
                dest_file.parent.mkdir(parents=True, exist_ok=True)
                await copy_file(src_file, dest_file)
                return
            
            src_hash = await get_file_hash(src_file)
            dst_hash = await get_file_hash(dest_file)
            
            if src_hash == dst_hash:
                await copy_file(src_file, dest_file)  # Safe update
            elif src_file.stat().st_mtime > dest_file.stat().st_mtime:
                await copy_file(src_file, dest_file)
            # Else: preserve user mods
    
    await asyncio.gather(*[process_file(f) for f in source_files])


async def get_file_hash(path: Path) -> str:
    hash_obj = hashlib.sha256()
    async with aiofiles.open(path, 'rb') as f:
        while chunk := await f.read(65536):
            hash_obj.update(chunk)
    return hash_obj.hexdigest()
```

---

## 14. Migration plan

Gradual migration from the JS installer to the new language.

### Strategy: Parallel implementations

**Phase 1 (Month 1-2):** Build validator-only

- Port `validate-skills.js` → new language
- Verify 100% identical findings vs JS version
- Publish as a standalone binary

Benefit: Users get a fast validator, the BMad team verifies port quality.

### Phase 2 (Month 3-4): Build resolver-only

- Port `resolve_customization.py` → new language
- Verify identical merged output
- Publish as a standalone binary

### Phase 3 (Month 5-6): Build installer core

- Port the `installer.js` state machine
- Dual-install mode: users can choose JS or the new installer
- Extensive compatibility testing

### Phase 4 (Month 7-8): Build external module support

- Git clone logic
- Registry client
- Cache management

### Phase 5 (Month 9-10): Build IDE integration

- platform-codes.yaml support
- ConfigDrivenIdeSetup equivalent
- Manual testing of each IDE

### Phase 6 (Month 11-12): Deprecation + cutover

- Mark JS installer as deprecated
- Migration guide for users
- Final cutover in next major version

---

## Quick start: Minimum working installer (Python)

Example 50-line minimum installer:

```python
#!/usr/bin/env python3
"""Minimum BMad-compatible installer (Python)."""

import click
import yaml
import shutil
from pathlib import Path

@click.command()
@click.option('--directory', '-d', default='.', type=click.Path())
@click.option('--modules', '-m', multiple=True, default=['core', 'bmm'])
def install(directory, modules):
    """Install BMad skills into project."""
    project_root = Path(directory).resolve()
    bmad_dir = project_root / '_bmad'
    config_dir = bmad_dir / '_config'
    
    # Find BMAD source
    bmad_source = Path(__file__).parent.parent / 'src'
    
    # Create _bmad/
    bmad_dir.mkdir(exist_ok=True)
    config_dir.mkdir(exist_ok=True)
    
    # Copy modules
    for module in modules:
        src = bmad_source / f'{module}-skills'
        if not src.exists():
            click.echo(f"⚠️  Module not found: {module}")
            continue
        
        dst = bmad_dir / module
        if dst.exists():
            shutil.rmtree(dst)
        shutil.copytree(src, dst)
        click.echo(f"✅ Installed: {module}")
    
    # Generate basic manifest
    manifest = {
        'installation': {'version': '1.0.0-minimum', 'modules': list(modules)},
    }
    with open(config_dir / 'manifest.yaml', 'w') as f:
        yaml.dump(manifest, f)
    
    click.echo(f"\n✅ BMad installed at: {bmad_dir}")


if __name__ == '__main__':
    install()
```

Not full-featured, but demonstrates the core concepts.

---

## Summary

### What you get from this blueprint

1. **Complete data structures** — can implement in any typed language
2. **Core algorithms pseudo-code** — syncDirectory, detectCustomFiles, deepMerge
3. **14 validation rules with implementation hints**
4. **Per-language recipes** (Go, Rust, Python) with dependencies and patterns
5. **Migration plan** for gradual JS → new language transition

### Effort estimates (single engineer)

| Language | Minimum (MVF v1.0) | Full parity |
|----------|---------------------|-------------|
| **Go** | 3-4 weeks | 6-8 weeks |
| **Rust** | 4-6 weeks | 8-12 weeks |
| **Python** | 2-3 weeks | 4-6 weeks |

### Success criteria

Your rewrite is "BMad-compatible" if:
- [ ] Installs a compatible `_bmad/` structure
- [ ] Reads existing skills unchanged
- [ ] Generates valid manifests
- [ ] Customization TOML format compatible
- [ ] Validator output matches JS version (14 rules)
- [ ] External modules work
- [ ] IDE integration produces correct `.claude/skills/` etc.

### Getting started

1. Read [08-installer-code-level-spec.md](08-installer-code-level-spec.md) for the actual JS code
2. Pick a target language, follow the recipe above
3. Start with the **validator only** (self-contained, easy to verify)
4. Build incrementally, testing against the JS reference

---

**End of file 14.** The full developer deep dive is now complete.

Return to [README.md](README.md) to view the index.
