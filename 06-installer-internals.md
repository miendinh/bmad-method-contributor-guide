# 06. Installer Internals - tools/installer, Validators, Build

> ⚠️ **UNOFFICIAL THIRD-PARTY DOCUMENTATION**
> NOT official BMad docs. See [DISCLAIMER.md](DISCLAIMER.md) | Licensed MIT — see [LICENSE](LICENSE) and [NOTICE](NOTICE)
> Official BMAD-METHOD: <https://github.com/bmad-code-org/BMAD-METHOD>

---

> Specification for the **framework maintainer**: internals of the installer CLI, skill validator, reference validator, and docs build pipeline. Detailed enough to modify or rewrite.

---

## Table of Contents

1. [Overview of tools/](#1-overview-of-tools)
2. [bmad-cli.js - Entry point](#2-bmad-clijs---entry-point)
3. [Command layer](#3-command-layer)
4. [Core installer logic](#4-core-installer-logic)
5. [Config system](#5-config-system)
6. [Prompt engine & UI orchestration](#6-prompt-engine--ui-orchestration)
7. [File operations](#7-file-operations)
8. [Module management](#8-module-management)
9. [IDE integration](#9-ide-integration)
10. [Manifest system](#10-manifest-system)
11. [validate-skills.js](#11-validate-skillsjs)
12. [validate-file-refs.js](#12-validate-file-refsjs)
13. [build-docs.mjs](#13-build-docsmjs)
14. [Utility scripts](#14-utility-scripts)
15. [Testing infrastructure](#15-testing-infrastructure)
16. [Design patterns used](#16-design-patterns-used)
17. [Extension points (for maintainers)](#17-extension-points-for-maintainers)

---

## 1. Overview of tools/

```
tools/
├── installer/                    # CLI `bmad` + installer logic
│   ├── bmad-cli.js               # ENTRY POINT
│   ├── cli-utils.js
│   ├── commands/                 # install, uninstall, upgrade, status
│   ├── core/                     # Installer logic
│   │   ├── installer.js          # Main install flow
│   │   ├── config.js             # Config builder (immutable)
│   │   ├── install-paths.js      # Path management
│   │   ├── manifest.js           # Manifest CRUD
│   │   └── manifest-generator.js # Scan + generate manifests
│   ├── ide/                      # IDE handlers
│   │   ├── manager.js            # Load handlers from platform-codes.yaml
│   │   └── _config-driven.js     # Generic IDE setup
│   ├── modules/                  # Module management
│   │   ├── external-manager.js   # Official registry
│   │   ├── version-resolver.js   # Resolve module versions
│   │   └── custom-module-manager.js # --custom-source
│   ├── bundlers/                 # Web bundle generation
│   │   └── bundle-web.js
│   ├── prompts.js                # @clack/prompts wrapper
│   ├── ui.js                     # Installation flow orchestration
│   ├── file-ops.js               # File copy/sync
│   ├── fs-native.js              # fs abstraction (avoid fs-extra)
│   ├── project-root.js           # Project root detection
│   ├── yaml-format.js            # YAML parsing/writing
│   ├── message-loader.js
│   ├── install-messages.yaml
│   └── README.md
│
├── validate-skills.js            # Deterministic skill validator
├── skill-validator.md            # Rule catalog (30+ rules)
├── validate-file-refs.js         # Reference validator
├── validate-doc-links.js         # Doc links validator
├── build-docs.mjs                # Astro/Starlight builder
├── fix-doc-links.js              # Fix broken doc links
├── format-workflow-md.js         # Format workflow files
├── migrate-custom-module-paths.js # Migration script
├── validate-svg-changes.sh
├── javascript-conventions.md     # JS style rules
├── platform-codes.yaml           # IDE platform definitions
└── docs/                         # Tools docs
```

**Separation of concerns:**
- `tools/installer/` — logic executed when a user runs `npx bmad-method install`
- `tools/*.{js,mjs}` — maintainer tools (validate, build, format) that run in CI
- `tools/skill-validator.md` — rule specification (read by both the validator and the LLM)

---

## 2. bmad-cli.js - Entry point

### 2.1 Responsibilities

```js
#!/usr/bin/env node

// 1. Check for update (async, non-blocking)
checkForUpdate().catch(() => {});

// 2. Fix stdin listener limit (Windows/WSL fix)
process.stdin.setMaxListeners(Math.max(process.stdin.getMaxListeners(), 50));

// 3. Dynamic command loading
const commandsPath = path.join(__dirname, 'commands');
const commandFiles = fs.readdirSync(commandsPath).filter(f => f.endsWith('.js'));
for (const file of commandFiles) {
  const command = require(path.join(commandsPath, file));
  commands[command.command] = command;
}

// 4. Register with commander.js
for (const [name, cmd] of Object.entries(commands)) {
  const cli = program.command(name).description(cmd.description);
  for (const option of cmd.options || []) {
    cli.option(...option);
  }
  cli.action(cmd.action);
}

program.parse(process.argv);
```

### 2.2 Why @clack/prompts instead of Inquirer.js?

- Inquirer.js has a bug on Windows with arrow keys (libuv #852)
- @clack/prompts does not depend on libuv event loop processing
- Cleaner API (intro/outro/select/multiselect/confirm)

### 2.3 Command pattern

Each command is a single file under `commands/`:

```js
// commands/install.js
module.exports = {
  command: 'install',
  description: 'Install BMad into a project',
  options: [
    ['-d, --directory <path>', 'Target directory'],
    ['-m, --modules <list>', 'Comma-separated modules'],
    ['-t, --tools <list>', 'Comma-separated IDEs'],
    ['-a, --action <type>', 'install | update | quick-update'],
    ['-y, --yes', 'Skip all prompts']
  ],
  action: async (options) => {
    const ui = require('../ui');
    const installer = require('../core/installer');
    
    const config = await ui.promptInstall(options);
    const result = await installer.install(config);
    
    // Handle quick-update, update, new install separately
  }
};
```

Adding a new command simply means adding a file under `commands/`; no changes to `bmad-cli.js` are required.

---

## 3. Command layer

### 3.1 install.js - Install flow

```js
action: async (options) => {
  // Step 1: Gather config (interactive or non-interactive with --yes)
  const config = await ui.promptInstall(options);
  
  // Step 2: Execute install
  const result = await installer.install(config);
  
  // Step 3: Handle result
  if (config.actionType === 'quick-update') {
    // Quick update: only refresh module files
  } else if (config.actionType === 'update') {
    // Update: selective module reconfigure
  } else {
    // New install: full setup
  }
}
```

### 3.2 Options

| Option | Description | Example |
|--------|-------------|---------|
| `--directory <path>` | Target directory | `--directory /path/to/project` |
| `--modules <list>` | Modules to install | `--modules bmm,bmb` |
| `--tools <list>` | IDEs to configure | `--tools claude-code,cursor` |
| `--action <type>` | Action type | `--action update` |
| `--yes` | Skip all prompts | `--yes` |
| `--custom-source <url>` | Custom module source | `--custom-source <https://github.com/x/y>` |

### 3.3 uninstall.js

```js
action: async (options) => {
  // Load existing installation
  const installPath = await findBmadInstall(options.directory);
  
  // Ask which modules (or all)
  // Remove _bmad/ + IDE configs
  // Keep user files (custom, output folders)
}
```

### 3.4 status.js

Shows the current install state:
- Installed modules + versions
- Configured IDEs
- Last update time
- Customizations applied

---

## 4. Core installer logic

### 4.1 installer.js - Main flow

```
install(originalConfig)
│
├─ 1. Build Config + InstallPaths
├─ 2. Detect existing installation
├─ 3. Remove deselected modules (if update)
├─ 4. Prepare update state (backup files)
├─ 5. Remove deselected IDEs
├─ 6. Install & configure modules
│   └─ For each module:
│       ├─ Resolve version
│       ├─ Clone (if external)
│       ├─ Copy src/ → _bmad/{module}
│       └─ Generate module configs
├─ 7. Setup IDEs
│   └─ For each IDE:
│       └─ ConfigDrivenIdeSetup.setup()
├─ 8. Cleanup old skill directories
├─ 9. Restore user customizations
├─ 10. Generate manifests
└─ 11. Render install summary
```

### 4.2 Update state management

```js
// Backup user files before overwrite
async _prepareUpdateState(paths, config) {
  const updateState = {
    tempBackupDir: path.join(os.tmpdir(), `bmad-backup-${Date.now()}`),
    tempModifiedBackupDir: path.join(os.tmpdir(), `bmad-modified-${Date.now()}`),
    modifiedFiles: [],
    customFiles: []
  };
  
  // Copy user-modified files to tempBackupDir
  // Copy original files to tempModifiedBackupDir (for diff comparison)
  
  return updateState;
}

// After install completes, restore user files
async _restoreUserFiles(paths, updateState) {
  // For each backup file:
  //   - Compare with new default via checksum
  //   - If user modified: preserve modification
  //   - If identical to old default: use new default (updated)
  //   - Merge configs (YAML deep merge for config.yaml)
}
```

### 4.3 Module removal

```js
async _removeDeselectedModules(existingInstall, config, paths) {
  const previouslyInstalled = new Set(existingInstall.modules.map(m => m.name));
  const newlySelected = new Set(config.modules);
  const toRemove = [...previouslyInstalled].filter(m => !newlySelected.has(m));
  
  for (const moduleId of toRemove) {
    await fs.remove(paths.moduleDir(moduleId));
  }
}
```

### 4.4 Manifest generation after install

```js
await this.manifest.create(bmadDir, {
  modules: config.modules,
  ides: config.ides,
  version: packageVersion,
  installDate: new Date().toISOString()
});
// Output: _bmad/_config/manifest.yaml
```

---

## 5. Config system

### 5.1 Config class (immutable)

```js
class Config {
  constructor({
    directory,         // Target directory
    modules,          // ['core', 'bmm', ...]
    ides,             // ['claude-code', 'cursor', ...]
    skipPrompts,      // Boolean
    actionType,       // 'install' | 'update' | 'quick-update'
    coreConfig,       // {} - core-specific customization
    moduleConfigs     // {} - per-module customizations
  }) {
    this.directory = directory;
    this.modules = modules;
    // ...
    
    // Immutable
    Object.freeze(this.modules);
    Object.freeze(this.ides);
    Object.freeze(this);
  }
  
  static async build(userInput) {
    // Normalize + validate
    return new Config(userInput);
  }
}
```

### 5.2 Why immutable?

- Config flows through many layers (UI → installer → module setup → IDE setup)
- Immutability prevents mid-flight mutations
- Single source of truth for install parameters
- Easier to debug (snapshot at start vs. end)

---

## 6. Prompt engine & UI orchestration

### 6.1 prompts.js wrapper

```js
// Lazy-load ESM @clack/prompts
let _clack = null;
async function getClack() {
  if (!_clack) {
    _clack = await import('@clack/prompts');
  }
  return _clack;
}

// Wrapper API
async function select(options) {
  const clack = await getClack();
  return clack.select(options);
}

async function multiselect(options) { /* ... */ }
async function confirm(options) { /* ... */ }
async function text(options) { /* ... */ }

// UI primitives
async function intro(msg) { /* ... */ }
async function outro(msg) { /* ... */ }
async function note(msg, title) { /* ... */ }
function spinner() { /* ... */ }

// Logging
const log = {
  info: async (msg) => { /* ... */ },
  warn: async (msg) => { /* ... */ },
  error: async (msg) => { /* ... */ }
};
```

### 6.2 ui.js orchestration

```js
async function promptInstall(options) {
  // 1. Display logo
  await prompts.intro('BMad-Method v' + version);
  
  // 2. Get directory
  const directory = options.directory || await prompts.text({
    message: 'Where should BMad be installed?',
    defaultValue: process.cwd()
  });
  
  // 3. Check existing
  const existing = await detectExistingInstall(directory);
  let actionType;
  if (existing) {
    actionType = await promptActionMenu(existing);
  } else {
    actionType = 'install';
  }
  
  // 4. Module selection
  const modules = await promptModules(options, existing);
  
  // 5. IDE selection
  const ides = await promptIdes(options);
  
  // 6. Collect module-specific configs
  const moduleConfigs = await collectModuleConfigs(modules);
  
  // 7. Build unified config
  return Config.build({
    directory, modules, ides,
    actionType, moduleConfigs,
    skipPrompts: options.yes
  });
}

async function collectModuleConfigs(modules) {
  const configs = {};
  
  for (const moduleId of modules) {
    // Load module.yaml
    const moduleYaml = await loadModuleYaml(moduleId);
    
    // Iterate config_variables
    const answers = {};
    for (const [varName, varDef] of Object.entries(moduleYaml.configVars)) {
      const answer = await promptForVariable(varName, varDef);
      answers[varName] = applyResultTemplate(answer, varDef.result);
    }
    
    configs[moduleId] = answers;
  }
  
  return configs;
}
```

### 6.3 Non-interactive mode

```js
if (options.yes) {
  // Skip ALL prompts
  selectedModules = await getDefaultModules(); // from module.yaml default_selected
  actionType = 'quick-update';
  moduleConfigs = {}; // use defaults
}
```

---

## 7. File operations

### 7.1 file-ops.js

```js
class FileOps {
  async copyDirectory(source, dest) {
    // Recursive copy with filter (skip .git, node_modules, etc.)
  }
  
  async syncDirectory(source, dest) {
    // Sync mode: preserve user modifications
    // 1. For each file in source:
    //    - If exists in dest:
    //      - Compare SHA-256 hashes
    //      - If hashes match: update (files identical, safe)
    //      - If hashes differ:
    //        - If source.mtime > dest.mtime: update (source newer)
    //        - Else: preserve (user modified)
    //    - Else: copy (new file)
    // 2. For each file in dest (not in source):
    //    - Remove (deleted in source)
  }
  
  async getFileHash(filePath) {
    const crypto = require('crypto');
    const content = await fs.readFile(filePath);
    return crypto.createHash('sha256').update(content).digest('hex');
  }
  
  shouldIgnore(filePath) {
    return /\.(git|DS_Store|swp)|node_modules/.test(filePath);
  }
}
```

### 7.2 fs-native.js

**Why not use fs-extra?**

> fs-extra relies on graceful-fs monkey-patching, which causes non-deterministic file loss on macOS (issue #1779).

Solution: a drop-in replacement using native `node:fs/promises`:

```js
const fsp = require('node:fs/promises');

module.exports = {
  // Re-export native
  readFile: fsp.readFile,
  writeFile: fsp.writeFile,
  stat: fsp.stat,
  readdir: fsp.readdir,
  unlink: fsp.unlink,
  
  // Helper layer for compat with fs-extra API
  pathExists: async (p) => {
    try {
      await fsp.access(p);
      return true;
    } catch {
      return false;
    }
  },
  
  ensureDir: async (p) => fsp.mkdir(p, { recursive: true }),
  
  remove: async (p) => {
    try {
      await fsp.rm(p, { recursive: true, force: true });
    } catch (err) {
      if (err.code !== 'ENOENT') throw err;
    }
  },
  
  copy: async (src, dest) => {
    // Custom recursive implementation
  },
  
  move: async (src, dest) => {
    try {
      await fsp.rename(src, dest);
    } catch (err) {
      if (err.code === 'EXDEV') {
        // Cross-device: copy + remove
        await this.copy(src, dest);
        await this.remove(src);
      } else {
        throw err;
      }
    }
  }
};
```

### 7.3 InstallPaths

```js
class InstallPaths {
  static async create(config) {
    return new InstallPaths({
      srcDir: path.join(__dirname, '..', '..', 'src'),
      projectRoot: config.directory,
      bmadDir: path.join(config.directory, '_bmad'),
      configDir: path.join(config.directory, '_bmad', '_config'),
      coreDir: path.join(config.directory, '_bmad', 'core'),
      scriptsDir: path.join(config.directory, '_bmad', 'scripts'),
      customDir: path.join(config.directory, '_bmad', 'custom'),
      isUpdate: config.actionType !== 'install'
    });
  }
  
  manifestFile() { return path.join(this.configDir, 'manifest.yaml'); }
  centralConfig() { return path.join(this.bmadDir, 'config.toml'); }
  filesManifest() { return path.join(this.configDir, 'files-manifest.csv'); }
  moduleDir(name) { return path.join(this.bmadDir, name); }
  moduleConfig(name) { return path.join(this.bmadDir, name, 'config.yaml'); }
}
```

---

## 8. Module management

### 8.1 Module sources

There are 3 kinds of modules:
1. **Built-in** — `core`, `bmm` (shipped with the package)
2. **Official** — from the `bmad-plugins-marketplace` registry
3. **Custom** — user-specified via `--custom-source <git-url>`

### 8.2 external-manager.js

```js
class ExternalModuleManager {
  async loadExternalModulesConfig() {
    try {
      // Fetch from GitHub
      const config = await RegistryClient.fetchGitHubYaml(
        'bmad-code-org',
        'bmad-plugins-marketplace',
        'registry/official.yaml'
      );
      return config;
    } catch (err) {
      // Fallback: bundled registry
      const bundledPath = path.join(__dirname, 'registry-fallback.yaml');
      return yaml.parse(await fs.readFile(bundledPath, 'utf-8'));
    }
  }
  
  async cloneExternalModule(moduleCode) {
    const cacheDir = path.join(os.homedir(), '.bmad', 'cache', 'external-modules', moduleCode);
    
    // Git sparse-checkout for performance
    await git.clone({
      dir: cacheDir,
      url: moduleDef.repository,
      singleBranch: true,
      noCheckout: true
    });
    await git.sparseCheckout(cacheDir, ['src/']);
    
    return cacheDir;
  }
  
  getExternalCacheDir() {
    return path.join(os.homedir(), '.bmad', 'cache', 'external-modules');
  }
}
```

### 8.3 Registry format

```yaml
# registry/official.yaml
modules:
  - name: bmb
    code: bmb
    display_name: "BMad Builder"
    description: "Create custom BMad skills and agents"
    repository: "https://github.com/bmad-code-org/bmad-builder-module"
    module_definition: "src/module.yaml"
    default_selected: false
    type: "bmad-org"
  
  - name: tea
    code: tea
    display_name: "Test Experience Automation"
    description: "Playwright test generation"
    repository: "https://github.com/bmad-code-org/tea-module"
    module_definition: "src/module.yaml"
    default_selected: false
    type: "bmad-org"
```

### 8.4 Version resolver

```js
async resolveModuleVersion(moduleCode) {
  // Priority:
  // 1. package.json in module cache (if exists)
  // 2. module.yaml metadata (version field)
  // 3. git tag (latest)
  // 4. Return 'unknown'
  
  const pkgPath = path.join(cacheDir, 'package.json');
  if (await fs.pathExists(pkgPath)) {
    const pkg = JSON.parse(await fs.readFile(pkgPath, 'utf-8'));
    return pkg.version;
  }
  
  // Fallback to yaml
  const yamlPath = path.join(cacheDir, 'src', 'module.yaml');
  const yaml = yamlParse(await fs.readFile(yamlPath, 'utf-8'));
  return yaml.version || 'unknown';
}
```

---

## 9. IDE integration

### 9.1 platform-codes.yaml

```yaml
platforms:
  claude-code:
    displayName: "Claude Code"
    preferred: true
    installer:
      configFile: ".claude/skills.json"
      skillsDir: ".claude/skills"
      allowUrlFetch: true
  
  cursor:
    displayName: "Cursor"
    preferred: true
    installer:
      configFile: ".cursor/skills.json"
      skillsDir: ".cursor/skills"
  
  jetbrains:
    displayName: "JetBrains IDEs"
    preferred: false
    installer:
      configFile: ".idea/bmad-skills.json"
      skillsDir: ".idea/bmad-skills"
  
  vscode:
    displayName: "VS Code"
    preferred: false
    installer:
      configFile: ".vscode/settings.json"
      skillsDir: ".vscode/bmad-skills"
```

### 9.2 IdeManager

```js
class IdeManager {
  async loadHandlers() {
    const platformConfig = await loadPlatformCodes();
    
    for (const [code, info] of Object.entries(platformConfig.platforms)) {
      if (!info.installer) continue; // Skip IDEs without installer config
      
      const handler = new ConfigDrivenIdeSetup(code, info);
      this.handlers.set(code, handler);
    }
  }
  
  async setup(ideName, projectDir, bmadDir, options) {
    const handler = this.handlers.get(ideName);
    if (!handler) {
      throw new Error(`Unknown IDE: ${ideName}`);
    }
    
    return handler.setup(projectDir, bmadDir, options);
  }
  
  getAvailableIdes() {
    return [...this.handlers.keys()];
  }
  
  getPreferredIdes() {
    // Claude Code, Cursor first
    return [...this.handlers.entries()]
      .filter(([_, info]) => info.preferred)
      .map(([code]) => code);
  }
}
```

### 9.3 ConfigDrivenIdeSetup

```js
class ConfigDrivenIdeSetup {
  constructor(code, info) {
    this.code = code;
    this.info = info;
  }
  
  async setup(projectDir, bmadDir, options) {
    const { configFile, skillsDir } = this.info.installer;
    
    // 1. Read platform config
    const platformConfigPath = path.join(projectDir, configFile);
    
    // 2. Copy skills from _bmad/{module}/skills to IDE skills dir
    const ideSkillsPath = path.join(projectDir, skillsDir);
    await fs.ensureDir(ideSkillsPath);
    
    // Walk all modules
    const modules = await this.getInstalledModules(bmadDir);
    for (const moduleId of modules) {
      await this.copyModuleSkills(bmadDir, moduleId, ideSkillsPath);
    }
    
    // 3. Generate/update IDE config file (JSON or YAML)
    await this.generateIdeConfig(platformConfigPath, modules);
  }
  
  async cleanup(projectDir, options) {
    // Remove IDE-specific skill directory and configs
    const { configFile, skillsDir } = this.info.installer;
    await fs.remove(path.join(projectDir, skillsDir));
    
    // Clear IDE config file (or restore default)
    if (await fs.pathExists(path.join(projectDir, configFile))) {
      await this.cleanConfigFile(path.join(projectDir, configFile));
    }
  }
}
```

---

## 10. Manifest system

### 10.1 manifest.yaml structure

```yaml
# _bmad/_config/manifest.yaml
installation:
  version: "6.3.0"
  installDate: "2026-04-24T10:30:00Z"
  lastUpdated: "2026-04-24T10:35:00Z"

modules:
  - name: core
    version: "6.3.0"
    source: "built-in"
    installDate: "2026-04-24T10:30:00Z"
  - name: bmm
    version: "6.3.0"
    source: "built-in"
  - name: bmb
    version: "2.1.0"
    source: "official"

ides:
  - claude-code
  - cursor
```

### 10.2 skill-manifest.csv

CSV of all installed skills:

```csv
canonical_id,name,description,module,path,install_date
bmad-brainstorming,bmad-brainstorming,"Facilitate interactive brainstorming...",core,_bmad/core/bmad-brainstorming,2026-04-24T10:30:00Z
bmad-create-prd,bmad-create-prd,"Create comprehensive PRDs...",bmm,_bmad/bmm/bmad-create-prd,2026-04-24T10:30:00Z
```

Used by the `bmad-help` skill for routing.

### 10.3 files-manifest.csv

CSV of every installed file (for update/uninstall tracking):

```csv
path,source_module,checksum,install_date
_bmad/core/bmad-brainstorming/SKILL.md,core,abc123...,2026-04-24T10:30:00Z
_bmad/core/bmad-brainstorming/workflow.md,core,def456...,2026-04-24T10:30:00Z
```

### 10.4 ManifestGenerator

```js
class ManifestGenerator {
  async generateManifests(bmadDir, selectedModules, installedFiles) {
    // 1. Scan installed modules
    const installedModules = await this.scanInstalledModules(bmadDir);
    
    // 2. Collect skills (walk each module, find SKILL.md)
    const skills = [];
    for (const mod of installedModules) {
      const modSkills = await this.findSkillsInModule(mod.path);
      skills.push(...modSkills);
    }
    
    // 3. Collect agents (from module.yaml `agents:` array)
    const agents = [];
    for (const mod of installedModules) {
      const yamlPath = path.join(mod.path, 'module.yaml');
      if (await fs.pathExists(yamlPath)) {
        const yaml = yamlParse(await fs.readFile(yamlPath, 'utf-8'));
        agents.push(...(yaml.agents || []));
      }
    }
    
    // 4. Write manifests
    await this.writeMainManifest(bmadDir, installedModules);
    await this.writeSkillManifest(bmadDir, skills);
    await this.writeFilesManifest(bmadDir, installedFiles);
    await this.writeCentralConfig(bmadDir, agents);
  }
}
```

---

## 11. validate-skills.js

### 11.1 Overview

A deterministic validator — checks 14 rules that can be verified with regex/AST without invoking an LLM.

```bash
node tools/validate-skills.js                  # All skills
node tools/validate-skills.js path/to/skill    # Single skill
node tools/validate-skills.js --strict         # Exit 1 if HIGH+ severity
node tools/validate-skills.js --json           # JSON output
```

### 11.2 14 Deterministic rules

| Rule | Applies to | Check |
|------|-----------|-------|
| SKILL-01 | Skill directory | `SKILL.md` exists |
| SKILL-02 | SKILL.md | Frontmatter has `name` |
| SKILL-03 | SKILL.md | Frontmatter has `description` |
| SKILL-04 | SKILL.md | `name` matches regex `^bmad-[a-z0-9]+(-[a-z0-9]+)*$` |
| SKILL-05 | SKILL.md | `name` matches directory basename |
| SKILL-06 | SKILL.md | `description` length, contains "Use when/if" |
| SKILL-07 | SKILL.md | Body non-empty after frontmatter |
| WF-01 | Non-SKILL.md files | Frontmatter must NOT contain `name:` |
| WF-02 | Non-SKILL.md files | Frontmatter must NOT contain `description:` |
| PATH-02 | All files | Must NOT use the `installed_path` variable |
| STEP-01 | Step files | Filename format `step-NN[-variant]-desc.md` |
| STEP-06 | Step files | Frontmatter must NOT contain name/description |
| STEP-07 | steps/ folder | Contains 2-10 steps |
| SEQ-02 | All files | Must NOT include time estimates (such as "~5 minutes") |

### 11.3 Frontmatter parser (hand-rolled)

The validator does not use a `yaml` library — it uses a hand-rolled parser to avoid the dependency:

```js
function parseFrontmatterMultiline(content) {
  const lines = content.split('\n');
  if (lines[0].trim() !== '---') return { frontmatter: {}, body: content };
  
  const result = {};
  let i = 1;
  let currentKey = null;
  let currentValue = '';
  
  while (i < lines.length && lines[i].trim() !== '---') {
    const line = lines[i];
    
    // New key: value
    const keyMatch = line.match(/^([a-zA-Z_][a-zA-Z0-9_]*):\s*(.*)$/);
    if (keyMatch) {
      if (currentKey) result[currentKey] = currentValue.trim();
      currentKey = keyMatch[1];
      currentValue = keyMatch[2];
    } else if (currentKey) {
      // Multi-line value continuation
      currentValue += '\n' + line;
    }
    
    i++;
  }
  if (currentKey) result[currentKey] = currentValue.trim();
  
  const body = lines.slice(i + 1).join('\n');
  return { frontmatter: result, body };
}
```

### 11.4 Output

```json
[
  {
    "rule": "SKILL-04",
    "severity": "HIGH",
    "file": "src/bmm-skills/4-implementation/my-skill/SKILL.md",
    "message": "name 'my-skill' does not start with 'bmad-' prefix",
    "suggestion": "Rename to 'bmad-my-skill'"
  }
]
```

### 11.5 Exit codes

- `0` — No HIGH+ findings (or no `--strict`)
- `1` — HIGH+ findings and `--strict` flag set
- `2` — Validator error (invalid path, etc.)

---

## 12. validate-file-refs.js

### 12.1 Overview

Validates that every file reference in YAML/MD/XML/CSV files resolves correctly.

### 12.2 Patterns extracted

```js
const PROJECT_ROOT_REF = /\{project-root\}\/[\w\-.\/]+/g;
const INSTALLED_SHORTHAND = /\{_bmad\}\/[\w\-.\/]+/g;
const EXEC_ATTR = /exec="([^"]+)"/g;
const INVOKE_TASK = /<invoke-task>([^<]+)<\/invoke-task>/g;
const RELATIVE_PATH = /\.\.?\/[\w\-.\/]+\.(md|csv|yaml|yml|json)/g;

// Skipped (runtime):
// {installed_path}/...
// {{mustache}}
// {config_source}:key
```

### 12.3 Resolution logic

```js
function validateRef(ref, sourceFile) {
  // Map installed path to source path
  const sourcePath = mapInstalledToSource(ref);
  
  if (!fs.existsSync(sourcePath)) {
    return {
      rule: 'REF-BROKEN',
      severity: 'HIGH',
      file: sourceFile,
      ref: ref,
      message: `File not found: ${sourcePath}`
    };
  }
  return null;
}

function mapInstalledToSource(ref) {
  // Replace {project-root}/_bmad/core/... → src/core-skills/...
  // Replace {project-root}/_bmad/bmm/... → src/bmm-skills/...
  // Replace {_bmad}/core/... → src/core-skills/...
}
```

### 12.4 Strict mode

```bash
node tools/validate-file-refs.js --strict
```

Exits with 1 if any reference is broken. Used in CI.

---

## 13. build-docs.mjs

### 13.1 Pipeline

```
docs/                    (source content)
  ├─ index.md
  ├─ tutorials/
  ├─ how-to/
  ├─ explanation/
  └─ reference/
        ↓
   [build-docs.mjs]
        ↓
build/
  ├─ artifacts/
  │  ├─ llms.txt          (concise summary)
  │  └─ llms-full.txt     (full docs)
  └─ site/                 (Astro static site)
     └─ *.html
```

### 13.2 Main flow

```js
async function main() {
  // 1. Validate internal links
  checkDocLinks();
  
  // 2. Clean build/
  cleanBuildDirectory();
  
  // 3. Generate artifacts (llms.txt, llms-full.txt)
  const artifactsDir = await generateArtifacts(docsDir);
  
  // 4. Build Astro site (Starlight theme)
  const siteDir = buildAstroSite();
  
  // 5. Copy artifacts into site
  copyArtifactsToSite(artifactsDir, siteDir);
}
```

### 13.3 LLM-friendly artifacts

```js
async function generateLlmsTxt(docsDir) {
  // Concise summary: project metadata, quick nav
  const content = [
    '# BMad-Method',
    'Agent skills framework for AI-driven development',
    '',
    '## Quick navigation',
    '- Tutorials: /tutorials/',
    '- How-to guides: /how-to/',
    '- Explanations: /explanation/',
    '- Reference: /reference/',
  ].join('\n');
  return content;
}

async function generateLlmsFullTxt(docsDir) {
  const MAX_CHARS = 600_000; // ~150k tokens
  const EXCLUSIONS = ['changelog', 'faq', 'game-dev'];
  
  // Walk docs/, collect content, concatenate
  // Respect exclusions, truncate to MAX_CHARS
}
```

### 13.4 Astro/Starlight config

```js
// website/astro.config.mjs
export default defineConfig({
  integrations: [
    starlight({
      title: 'BMad-Method Documentation',
      social: {
        github: 'https://github.com/bmad-code-org/BMAD-METHOD',
        discord: 'https://discord.gg/...'
      },
      sidebar: [ /* auto-generated from docs/ */ ],
      locales: {
        root: { label: 'English', lang: 'en' },
        'vi-vn': { label: 'Tiếng Việt', lang: 'vi' },
        'zh-cn': { label: '中文', lang: 'zh' },
        // ...
      }
    })
  ]
});
```

---

## 14. Utility scripts

### 14.1 format-workflow-md.js

Formats workflow files with a consistent style:
- 2-space XML indentation
- Preserves markdown content
- Checks tag nesting

```bash
node tools/format-workflow-md.js src/core-skills/bmad-brainstorming/workflow.md
```

### 14.2 fix-doc-links.js

Auto-fixes broken doc links:
- Scans every `.md` file
- Finds broken `[text](path)` references
- Attempts to locate the intended target (fuzzy match)
- Offers a fix

### 14.3 migrate-custom-module-paths.js

Migration script for v4→v5 upgrades — converts old custom module paths to the new structure.

### 14.4 validate-svg-changes.sh

Bash script that validates SVG changes (for icon updates).

---

## 15. Testing infrastructure

### 15.1 Test structure

```
test/
├── README.md
├── test-installation-components.js    # Installer component tests
├── test-file-refs-csv.js              # Reference validator tests
├── test-workflow-path-regex.js        # Path regex tests
├── test-rehype-plugins.mjs            # Docs plugin tests
├── adversarial-review-tests/
│   ├── README.md
│   └── sample-content.md
└── fixtures/
    └── file-refs-csv/                 # Fixtures for ref tests
```

### 15.2 Assertion pattern

```js
// Pure Node test, no framework dependency
const assert = require('node:assert');

function testName() {
  const result = doSomething();
  assert.strictEqual(result, expected);
}

testName();
console.log('✅ All tests passed');
```

### 15.3 Running tests

```bash
npm test                    # Run all test suites
npm run test:install        # Installation components
npm run test:refs           # File references
node test/test-X.js         # Run specific file
```

---

## 16. Design patterns used

### 16.1 Lazy-load ESM

```js
let _module = null;
async function getModule() {
  if (!_module) {
    _module = await import('@clack/prompts');
  }
  return _module;
}
```

Delays expensive imports and enables ESM interop with CommonJS.

### 16.2 Immutable Config

```js
Object.freeze(this.modules);
Object.freeze(this);
```

Provides a single source of truth for install parameters.

### 16.3 Result aggregation

```js
const results = [];
for (const step of installSteps) {
  try {
    await step();
    results.push({ step: step.name, status: 'success' });
  } catch (err) {
    results.push({ step: step.name, status: 'error', error: err });
  }
}
renderSummary(results);
```

A single summary output instead of scattered log messages.

### 16.4 Config-driven IDE setup

```yaml
# platform-codes.yaml
claude-code:
  installer:
    configFile: ".claude/skills.json"
    skillsDir: ".claude/skills"
```

The generic `ConfigDrivenIdeSetup` reads the config and applies the logic. Adding a new IDE simply means adding a YAML entry — no code changes required.

### 16.5 Version resolution chain

```js
// 1. package.json in module cache
// 2. module.yaml version field
// 3. git tag (latest)
// 4. Return 'unknown'
```

A fallback chain for robustness.

### 16.6 Graceful degradation

```js
checkForUpdate().catch(() => {}); // Ignore failures, non-blocking

try {
  await handler.setup(...);
} catch (error) {
  await prompts.log.warn(`Failed to setup ${ide}: ${error}`);
  // Continue with other IDEs
}
```

### 16.7 State cleanup on failure

```js
try {
  await install();
} catch (err) {
  // Remove temp backup dirs
  await fs.remove(updateState.tempBackupDir);
  await fs.remove(updateState.tempModifiedBackupDir);
  throw err;
}
```

---

## 17. Extension points (for maintainers)

### 17.1 Adding a new IDE

1. Edit `tools/platform-codes.yaml`:
   ```yaml
   platforms:
     my-ide:
       displayName: "My New IDE"
       preferred: false
       installer:
         configFile: ".myide/skills.json"
         skillsDir: ".myide/skills"
   ```
2. Test with `npx bmad-method install --tools my-ide`
3. `ConfigDrivenIdeSetup` handles the rest automatically

### 17.2 Adding a validation rule

**Option A: Deterministic rule in validate-skills.js**

```js
// tools/validate-skills.js
function checkMyRule(skillDir) {
  const findings = [];
  // ... check logic
  if (violation) {
    findings.push({
      rule: 'MY-RULE-01',
      severity: 'MEDIUM',
      file: filePath,
      message: 'My violation message'
    });
  }
  return findings;
}

// Add to main() function
findings.push(...checkMyRule(skillDir));
```

**Option B: Inference rule in skill-validator.md**

Add a new section:
```markdown
### MY-RULE-01 - Description

- **Severity:** MEDIUM
- **Applies to:** SKILL.md
- **Rule:** [Rule description]
- **Detection:** [How the LLM detects it]
- **Fix:** [How to fix]
```

The LLM will apply the rule via inference.

### 17.3 Adding a CLI command

1. Create `tools/installer/commands/my-command.js`:
   ```js
   module.exports = {
     command: 'my-command',
     description: 'Description',
     options: [
       ['-x, --xxx <value>', 'Description of --xxx']
     ],
     action: async (options) => {
       // Implementation
     }
   };
   ```
2. Auto-loaded by `bmad-cli.js`
3. Test: `npx bmad-method my-command --xxx value`

### 17.4 Adding a module registry source

Currently: GitHub `bmad-plugins-marketplace`.

To add another source:
1. Edit `tools/installer/modules/external-manager.js`
2. Add a `fetchFromXXX()` method
3. Update `loadExternalModulesConfig` to try sources in priority order

### 17.5 Overriding the manifest format

The manifest CSV/YAML currently uses a fixed schema. To change it:
1. Edit `tools/installer/core/manifest-generator.js`
2. Update `writeSkillManifest()` and `writeFilesManifest()`
3. Provide a migration script for existing manifests

---

## Summary

The installer is a **modular framework** featuring:
- Config-driven IDE setup (add a YAML entry, not code)
- Immutable Config object (single source of truth)
- Graceful degradation (ignore failures, preserve user files)
- Detailed manifest logging (auditing)
- Clear state machine (detect → prepare → install → restore)

The validator is a **deterministic + inference hybrid**:
- 14 deterministic rules (regex/AST, no LLM)
- 13+ inference rules (LLM reads `skill-validator.md`)
- Self-documenting (the rule markdown serves as human spec + machine check + LLM prompt)

The docs build uses **Astro + Starlight** with LLM-friendly artifacts (`llms.txt`, `llms-full.txt`).

Extension points: platform-codes.yaml (IDE), skill-validator.md (rules), commands/*.js (CLI), modules/external-manager.js (registry).

---

**Continue reading:** [07-extension-patterns.md](07-extension-patterns.md) — Patterns for extending the framework.
