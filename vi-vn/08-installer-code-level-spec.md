# 08. Installer Code-Level Spec - Ready to Rewrite

> ⚠️ **UNOFFICIAL THIRD-PARTY DOCUMENTATION**
> Không phải official BMad docs. Xem [DISCLAIMER.md](DISCLAIMER.md) | Licensed MIT — xem [LICENSE](LICENSE) và [NOTICE](NOTICE)
> Official BMAD-METHOD: <https://github.com/bmad-code-org/BMAD-METHOD>

---

> **Mục đích:** Đặc tả chi tiết đủ để rewrite installer BMad sang Go/Rust/Python. Spec-level, code-ready, với actual algorithms + data shapes + function signatures.

> **Đối tượng:** Framework maintainer muốn hack installer hoặc engineer đang port BMad sang ngôn ngữ khác.

---

## Mục lục

1. [Architecture overview](#1-architecture-overview)
2. [File-by-file specifications](#2-file-by-file-specifications)
3. [Data structures](#3-data-structures)
4. [Core algorithms](#4-core-algorithms)
5. [Validator - 14 deterministic rules (full)](#5-validator---14-deterministic-rules-full)
6. [External module management](#6-external-module-management)
7. [IDE integration](#7-ide-integration)
8. [Build pipeline](#8-build-pipeline)
9. [Interface specs cho rewrite](#9-interface-specs-cho-rewrite)

---

## 1. Architecture overview

```
┌──────────────────────────────────────────────────────────────┐
│ bmad-cli.js (entry point)                                    │
│ - Commander.js CLI                                           │
│ - Update checker (async non-blocking)                        │
│ - Windows stdin fix (MaxListeners=50)                        │
│ - Dynamic command loading from commands/                     │
└──────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────┐
│ ui.js — Installation UI Orchestration (1569 lines)           │
│ - promptInstall(): main entry, returns Config                │
│ - Module selection (official + community + custom)           │
│ - IDE selection (preferred + others)                         │
│ - Config collection (core + per-module)                      │
└──────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────┐
│ core/installer.js — State machine (1507 lines)               │
│ Install flow (8 phases):                                     │
│ 1. Build Config + Paths + ExistingInstall                    │
│ 2. Remove deselected modules                                 │
│ 3. Prepare update state (backup user files)                  │
│ 4. Remove deselected IDEs                                    │
│ 5. Install & configure modules                               │
│ 6. Setup IDEs                                                │
│ 7. Cleanup + restore user files                              │
│ 8. Render summary                                            │
└──────────────────────────────────────────────────────────────┘
        │                                           │
        ▼                                           ▼
┌──────────────────────┐              ┌──────────────────────┐
│ modules/             │              │ ide/                 │
│ - external-manager   │              │ - manager            │
│ - version-resolver   │              │ - _config-driven     │
│ - custom-module-mgr  │              │ (per-IDE setup)      │
└──────────────────────┘              └──────────────────────┘
        │                                           │
        ▼                                           ▼
┌──────────────────────────────────────────────────────────────┐
│ file-ops.js + fs-native.js — File I/O                        │
│ - syncDirectory(): SHA-256 hash + mtime based                │
│ - copyDirectory(): filtered recursive copy                   │
│ - Replace fs-extra (avoid graceful-fs issues on macOS)       │
└──────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────┐
│ core/manifest-generator.js                                   │
│ - Scan installed skills (SKILL.md parse)                     │
│ - Collect agents from module.yaml                            │
│ - Write: manifest.yaml, skill-manifest.csv, files-manifest.csv│
└──────────────────────────────────────────────────────────────┘
```

---

## 2. File-by-file specifications

### 2.1 bmad-cli.js (109 lines)

**Responsibilities:**
- Entry point (`#!/usr/bin/env node`)
- Dynamic command loading
- Update checker

**Initialization sequence:**

```javascript
// 1. Check for update (async, non-blocking)
checkForUpdate().catch(() => {});

// 2. Raise stdin listener limit (Windows/WSL fix for libuv #852)
const currentLimit = process.stdin.getMaxListeners();
process.stdin.setMaxListeners(Math.max(currentLimit, 50));

// 3. Dynamic command loading
const commandsPath = path.join(__dirname, 'commands');
const commands = {};
for (const file of fs.readdirSync(commandsPath).filter(f => f.endsWith('.js'))) {
  const command = require(path.join(commandsPath, file));
  commands[command.command] = command;
}

// 4. Register with commander
program.version(packageJson.version);
for (const [name, cmd] of Object.entries(commands)) {
  const cli = program.command(name).description(cmd.description);
  for (const option of cmd.options || []) cli.option(...option);
  cli.action(cmd.action);
}

program.parse(process.argv);
```

**Key insight:** Không hardcode commands — add file vào `commands/` là đủ.

**Port considerations:**
- Go: use `cobra` cho CLI
- Rust: use `clap`
- Python: use `click` hoặc `typer`

---

### 2.2 prompts.js (704 lines)

**Purpose:** @clack/prompts wrapper với custom enhancements.

**Key patterns:**

**Lazy ESM loading** (để avoid expensive imports):
```javascript
let _clack = null;
async function getClack() {
  if (!_clack) _clack = await import('@clack/prompts');
  return _clack;
}
```

**Custom autocompleteMultiselect:** Fix cho @clack/prompts quirk — SPACE không toggle.

```javascript
prompt.on('key', (char, key) => {
  if (key?.name === 'space' && !prompt.isNavigating) {
    const focused = prompt.filteredOptions[prompt.cursor];
    if (focused) prompt.toggleSelected(focused.value);
  }
});
```

**Exports:**
```javascript
{
  getClack, getColor, handleCancel,
  intro, outro, cancel, note, box, spinner,
  select, multiselect, autocompleteMultiselect, autocomplete,
  confirm, text, password, tasks,
  log, prompt
}
```

**Port considerations:**
- Go: `charmbracelet/bubbletea` hoặc `AlecAivazis/survey`
- Rust: `dialoguer` + `indicatif`
- Python: `questionary` hoặc `rich.prompt`

---

### 2.3 fs-native.js (117 lines)

**Purpose:** Drop-in replacement cho fs-extra, dùng native `node:fs/promises`.

**Why not fs-extra?** fs-extra dùng `graceful-fs` monkey-patching, gây non-deterministic file loss trên macOS (issue #1779).

**API shape:**

```javascript
module.exports = {
  // Native async
  readFile: fsp.readFile,
  writeFile: fsp.writeFile,
  stat: fsp.stat,
  readdir: fsp.readdir,
  access: fsp.access,
  rename: fsp.rename,
  unlink: fsp.unlink,
  mkdir: fsp.mkdir,
  rm: fsp.rm,
  copyFile: fsp.copyFile,
  
  // fs-extra compatible helpers (custom impls)
  pathExists(p),          // try access, return bool
  ensureDir(dir),         // mkdir recursive: true
  remove(p),              // rm recursive: true, force: true
  copy(src, dest, opts?), // recursive copy with filter
  move(src, dest),        // rename with EXDEV fallback
  readJsonSync(p),
  writeJson(p, data),
  
  // Sync from core node:fs
  existsSync, readFileSync, writeFileSync,
  statSync, accessSync, readdirSync,
  createReadStream,
  
  constants: fs.constants
};
```

**Port considerations:** Trong Go/Rust/Python native file API đủ, không cần wrapper này.

---

### 2.4 project-root.js (132 lines)

**Purpose:** Locate BMAD project root + module paths.

**Algorithm:**

```javascript
function findProjectRoot(startPath = __dirname) {
  let currentPath = path.resolve(startPath);
  
  while (currentPath !== path.dirname(currentPath)) {
    const packagePath = path.join(currentPath, 'package.json');
    
    if (fs.existsSync(packagePath)) {
      try {
        const pkg = fs.readJsonSync(packagePath);
        if (pkg.name === 'bmad-method' ||
            fs.existsSync(path.join(currentPath, 'src', 'core-skills'))) {
          return currentPath;
        }
      } catch {}
    }
    
    if (fs.existsSync(path.join(currentPath, 'src', 'core-skills', 'agents'))) {
      return currentPath;
    }
    
    currentPath = path.dirname(currentPath);
  }
  
  return process.cwd();  // Fallback
}
```

**Module paths:**
- `core` → `<project-root>/src/core-skills/`
- `bmm` → `<project-root>/src/bmm-skills/`
- others → `<project-root>/src/modules/<name>/`
- external → `~/.bmad/cache/external-modules/<name>/`

**External module layouts (4 variants):**
```
~/.bmad/cache/external-modules/MODULE/
├── skills/module.yaml                    # Variant 1
├── src/module.yaml                       # Variant 2
├── src/SUBDIR/module.yaml                # Variant 3
└── module.yaml                           # Variant 4 (root)
```

---

### 2.5 core/installer.js (1507 lines)

**Responsibilities:** Main installation state machine.

**8-phase install flow:**

```javascript
async install(originalConfig) {
  let updateState = null;
  
  try {
    // Phase 1: Build config + paths + detect existing
    const config = Config.build(originalConfig);
    const paths = await InstallPaths.create(config);
    const officialModules = await OfficialModules.build(config, paths);
    const existingInstall = await ExistingInstall.detect(paths.bmadDir);
    
    // Phase 2: Remove deselected (if update)
    if (existingInstall.installed) {
      await this._removeDeselectedModules(existingInstall, config, paths);
      updateState = await this._prepareUpdateState(paths, config, existingInstall, officialModules);
      await this._removeDeselectedIdes(existingInstall, config, paths);
    }
    
    // Phase 3: Validate IDE selection (fail fast)
    await this._validateIdeSelection(config);
    
    // Phase 4: Install modules
    const results = [];
    const addResult = (step, status, detail, meta) => results.push({step, status, detail, ...meta});
    
    const previousSkillIds = await this._readPreviousSkillIds(paths);
    
    await this._installAndConfigure(config, originalConfig, paths,
      config.modules, config.modules, addResult, officialModules);
    
    // Phase 5: Setup IDEs
    await this._setupIdes(config, config.modules, paths, addResult, previousSkillIds);
    
    // Phase 6: Cleanup old skill dirs
    await this._cleanupSkillDirs(paths.bmadDir);
    
    // Phase 7: Restore user files
    const restoreResult = await this._restoreUserFiles(paths, updateState);
    
    // Phase 8: Summary
    await this.renderInstallSummary(results, {
      bmadDir: paths.bmadDir,
      modules: config.modules,
      ides: config.ides,
      customFiles: restoreResult.customFiles,
      modifiedFiles: restoreResult.modifiedFiles
    });
    
    return {
      success: true,
      path: paths.bmadDir,
      modules: config.modules,
      ides: config.ides,
      projectDir: paths.projectRoot
    };
    
  } catch (error) {
    // Cleanup temp backups on error
    try {
      if (updateState?.tempBackupDir) await fs.remove(updateState.tempBackupDir);
      if (updateState?.tempModifiedBackupDir) await fs.remove(updateState.tempModifiedBackupDir);
    } catch {}
    throw error;
  }
}
```

**Sub-methods:**

**_installAndConfigure():** 4 tasks
1. Install shared scripts (`src/scripts/*` → `_bmad/scripts/`, seed `.gitignore`)
2. Install modules (for each: resolve version, copy, configure)
3. Create module directories (from module.yaml `directories:` field)
4. Generate configs + manifests + help catalog

**_installOfficialModules():**
```javascript
for (const moduleName of officialModuleIds) {
  const moduleConfig = officialModules.moduleConfigs[moduleName] || {};
  
  const installResult = await officialModules.install(
    moduleName,
    paths.bmadDir,
    (filePath) => { this.installedFiles.add(filePath); },  // Track for manifest
    {
      skipModuleInstaller: true,
      moduleConfig,
      installer: this,
      silent: true
    }
  );
  
  const versionInfo = await resolveModuleVersion(moduleName, {
    moduleSourcePath: sourcePath,
    fallbackVersion: cachedResolution?.version
  });
  
  addResult(displayName, 'ok', '', { moduleCode: moduleName, newVersion: versionInfo.version });
}
```

**_prepareUpdateState():** Backup user files
```javascript
async _prepareUpdateState(paths, config, existingInstall, officialModules) {
  const existingFilesManifest = await this.readFilesManifest(paths.bmadDir);
  const { customFiles, modifiedFiles } = await this.detectCustomFiles(paths.bmadDir, existingFilesManifest);
  
  // Preserve existing core config during updates
  const coreConfigPath = paths.moduleConfig('core');
  if (await fs.pathExists(coreConfigPath) && !config.coreConfig) {
    const coreConfigContent = await fs.readFile(coreConfigPath, 'utf8');
    config.coreConfig = yaml.parse(coreConfigContent);
    officialModules.moduleConfigs.core = config.coreConfig;
  }
  
  const backupDirs = await this._backupUserFiles(paths, customFiles, modifiedFiles);
  
  return {
    customFiles,
    modifiedFiles,
    tempBackupDir: backupDirs.tempBackupDir,
    tempModifiedBackupDir: backupDirs.tempModifiedBackupDir
  };
}
```

**detectCustomFiles():** File preservation scanning
```javascript
async detectCustomFiles(bmadDir, existingFilesManifest) {
  const customFiles = [];
  const modifiedFiles = [];
  const bmadMemoryPaths = ['_memory', 'memory'];  // Excluded
  
  // Build hash map of installed files
  const installedFilesMap = new Map();
  for (const fileEntry of existingFilesManifest) {
    if (fileEntry.path) {
      const absolutePath = path.join(bmadDir, fileEntry.path);
      installedFilesMap.set(path.normalize(absolutePath), {
        hash: fileEntry.hash,
        relativePath: fileEntry.path
      });
    }
  }
  
  // Scan bmadDir
  const scanDirectory = async (dir) => {
    const entries = await fs.readdir(dir, { withFileTypes: true });
    
    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);
      const relativePath = path.relative(bmadDir, fullPath);
      
      if (entry.isDirectory()) {
        if (entry.name === 'node_modules' || entry.name === '.git') continue;
        await scanDirectory(fullPath);
      } else if (entry.isFile()) {
        // Skip special folders
        if (relativePath.startsWith('_config/')) continue;
        if (bmadMemoryPaths.some(mp => relativePath.startsWith(mp))) continue;
        if (entry.name === 'config.yaml') continue;
        
        const fileInfo = installedFilesMap.get(path.normalize(fullPath));
        
        if (!fileInfo) {
          // File not in manifest = custom
          if (!(entry.name.endsWith('.md') && relativePath.includes('/agents/'))) {
            customFiles.push(fullPath);
          }
        } else if (fileInfo.hash) {
          const currentHash = await this.manifest.calculateFileHash(fullPath);
          if (currentHash && currentHash !== fileInfo.hash) {
            modifiedFiles.push({ path: fullPath, relativePath: fileInfo.relativePath });
          }
        }
      }
    }
  };
  
  await scanDirectory(bmadDir);
  return { customFiles, modifiedFiles };
}
```

---

## 3. Data structures

### 3.1 Config object

```typescript
interface Config {
  directory: string;                    // Installation target
  modules: readonly string[];           // Frozen array ['core', 'bmm', 'cis', ...]
  ides: readonly string[];              // Frozen array ['claude-code', 'windsurf', ...]
  skipPrompts: boolean;                 // --yes flag
  verbose: boolean;
  actionType: 'install' | 'update' | 'quick-update';
  coreConfig: {
    user_name: string;
    communication_language: string;
    document_output_language: string;
    output_folder: string;
  };
  moduleConfigs: {
    [moduleName: string]: Record<string, any>;  // Per-module config
  };
  _quickUpdate?: boolean;
  _existingModules?: string[];          // For quick-update
  _preserveModules?: string[];          // For update
}
```

Config là **immutable** — `Object.freeze()` áp dụng cho `modules`, `ides`, và toàn bộ object.

### 3.2 InstallPaths

```typescript
interface InstallPaths {
  // Readonly fields
  projectRoot: string;
  bmadDir: string;         // <projectRoot>/_bmad
  configDir: string;       // <bmadDir>/_config
  scriptsDir: string;      // <bmadDir>/scripts
  customDir: string;       // <bmadDir>/custom
  
  // Methods
  moduleDir(name: string): string;        // <bmadDir>/<name>
  moduleConfig(name: string): string;     // <moduleDir>/config.yaml
  manifestFile(): string;                 // <configDir>/manifest.yaml
  filesManifest(): string;                // <configDir>/files-manifest.csv
  skillManifest(): string;                // <configDir>/skill-manifest.csv
  teamConfig(): string;                   // <configDir>/.team-config.toml
  userConfig(): string;                   // <configDir>/.user-config.toml
}
```

### 3.3 ExistingInstall

```typescript
interface ExistingInstall {
  installed: boolean;
  version?: string;
  modules: Array<{ name: string; version: string; source: string }>;
  ides: string[];
  installDate?: string;
  lastUpdated?: string;
}
```

### 3.4 Manifest files

**`_bmad/_config/manifest.yaml`:**
```yaml
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

ides:
  - claude-code
  - cursor

agentCustomizations:
  _config/.team-config.toml: "sha256-hash"
  _config/.user-config.toml: "sha256-hash"
```

**`_bmad/_config/skill-manifest.csv`:**
```csv
canonicalId,name,description,module,path
"bmad-brainstorming","bmad-brainstorming","Facilitate...","core","_bmad/core/bmad-brainstorming/SKILL.md"
```

**`_bmad/_config/files-manifest.csv`:**
```csv
type,name,module,path,hash
skill,"bmad-brainstorming",core,"_bmad/core/bmad-brainstorming/SKILL.md",abc123...
```

### 3.5 Finding (validator output)

```typescript
interface Finding {
  rule: string;          // e.g., 'SKILL-04'
  title: string;         // Human-readable name
  severity: 'CRITICAL' | 'HIGH' | 'MEDIUM' | 'LOW';
  file: string;          // Relative path
  line?: number;         // Optional line number
  detail: string;        // Explanation
  fix: string;           // How to fix
}
```

---

## 4. Core algorithms

### 4.1 syncDirectory (file-ops.js)

Preserve user modifications while updating. Uses SHA-256 + mtime comparison.

**Algorithm:**

```
For each file in source:
  If dest doesn't exist:
    → copy (new file)
  Else:
    source_hash = sha256(source_file)
    dest_hash = sha256(dest_file)
    
    If source_hash == dest_hash:
      → copy (identical, safe update)
    Else:
      source_mtime = stat(source_file).mtime
      dest_mtime = stat(dest_file).mtime
      
      If source_mtime > dest_mtime:
        → copy (source newer, likely framework update)
      Else:
        → preserve (user modified, don't overwrite)

For each file in dest:
  If source file doesn't exist:
    → remove (file deleted in source)
```

**Implementation:**

```javascript
async syncDirectory(source, dest) {
  const sourceFiles = await this.getFileList(source);
  
  for (const file of sourceFiles) {
    const sourceFile = path.join(source, file);
    const destFile = path.join(dest, file);
    
    if (await fs.pathExists(destFile)) {
      const sourceHash = await this.getFileHash(sourceFile);
      const destHash = await this.getFileHash(destFile);
      
      if (sourceHash === destHash) {
        await fs.copy(sourceFile, destFile, { overwrite: true });
      } else {
        const sourceStats = await fs.stat(sourceFile);
        const destStats = await fs.stat(destFile);
        
        if (sourceStats.mtime > destStats.mtime) {
          await fs.copy(sourceFile, destFile, { overwrite: true });
        }
        // Else: preserve user mods (no-op)
      }
    } else {
      await fs.ensureDir(path.dirname(destFile));
      await fs.copy(sourceFile, destFile);
    }
  }
  
  // Remove deleted files
  const destFiles = await this.getFileList(dest);
  for (const file of destFiles) {
    if (!(await fs.pathExists(path.join(source, file)))) {
      await fs.remove(path.join(dest, file));
    }
  }
}

async getFileHash(filePath) {
  const hash = crypto.createHash('sha256');
  const stream = fs.createReadStream(filePath);
  return new Promise((resolve, reject) => {
    stream.on('data', (data) => hash.update(data));
    stream.on('end', () => resolve(hash.digest('hex')));
    stream.on('error', reject);
  });
}
```

**Ignore patterns:**
```javascript
const IGNORED = ['.git', '.DS_Store', 'node_modules',
  '*.swp', '*.tmp', '.idea', '.vscode', '__pycache__', '*.pyc'];
```

### 4.2 Manifest generation

**Scan installed skills algorithm:**

```javascript
async collectSkills() {
  this.skills = [];
  this.skillClaimedDirs = new Set();
  
  for (const moduleName of this.updatedModules) {
    const modulePath = path.join(this.bmadDir, moduleName);
    if (!(await fs.pathExists(modulePath))) continue;
    
    const walk = async (dir) => {
      const entries = await fs.readdir(dir, { withFileTypes: true });
      
      const skillMdPath = path.join(dir, 'SKILL.md');
      const dirName = path.basename(dir);
      const skillMeta = await this.parseSkillMd(skillMdPath, dir, dirName);
      
      if (skillMeta) {
        const relativePath = path.relative(modulePath, dir)
          .split(path.sep).join('/');
        const installPath = relativePath
          ? `${this.bmadFolderName}/${moduleName}/${relativePath}/SKILL.md`
          : `${this.bmadFolderName}/${moduleName}/SKILL.md`;
        
        this.skills.push({
          name: skillMeta.name,
          description: this.cleanForCSV(skillMeta.description),
          module: moduleName,
          path: installPath,
          canonicalId: dirName
        });
        
        this.skillClaimedDirs.add(dir);
      } else {
        // Recurse if no skill here
        for (const entry of entries) {
          if (!entry.isDirectory()) continue;
          if (entry.name.startsWith('.') || entry.name.startsWith('_')) continue;
          await walk(path.join(dir, entry.name));
        }
      }
    };
    
    await walk(modulePath);
  }
}

async parseSkillMd(skillMdPath, dir, dirName) {
  if (!(await fs.pathExists(skillMdPath))) return null;
  
  const rawContent = await fs.readFile(skillMdPath, 'utf8');
  const content = rawContent.replaceAll('\r\n', '\n');
  
  const frontmatterMatch = content.match(/^---\n([\s\S]*?)\n---/);
  if (!frontmatterMatch) return null;
  
  const skillMeta = yaml.parse(frontmatterMatch[1]);
  
  if (!skillMeta ||
      typeof skillMeta.name !== 'string' ||
      typeof skillMeta.description !== 'string') {
    return null;
  }
  
  if (skillMeta.name !== dirName) {
    console.error(`Error: SKILL.md name "${skillMeta.name}" != dir "${dirName}"`);
    return null;
  }
  
  return skillMeta;
}
```

### 4.3 Config merge (YAML deep merge)

```javascript
function deepMerge(base, override) {
  if (typeof base === 'object' && typeof override === 'object' &&
      base !== null && override !== null &&
      !Array.isArray(base) && !Array.isArray(override)) {
    const result = { ...base };
    for (const [key, val] of Object.entries(override)) {
      result[key] = deepMerge(result[key], val);
    }
    return result;
  }
  return override !== undefined ? override : base;
}
```

---

## 5. Validator - 14 deterministic rules (full)

### 5.1 Constants

```javascript
const NAME_REGEX = /^bmad-[a-z0-9]+(-[a-z0-9]+)*$/;
const STEP_FILENAME_REGEX = /^step-\d{2}[a-z]?-[a-z0-9-]+\.md$/;
const TIME_ESTIMATE_PATTERNS = [
  /takes?\s+\d+\s*min/i,
  /~\s*\d+\s*min/i,
  /estimated\s+time/i,
  /\bETA\b/
];

const WF_SKIP_SKILLS = new Set(['bmad-agent-tech-writer']);
```

### 5.2 Hand-rolled frontmatter parser

Validator không dùng `yaml` library — hand-rolled để avoid dependency:

```javascript
function parseFrontmatterMultiline(content) {
  const trimmed = content.trimStart();
  if (!trimmed.startsWith('---')) return null;
  
  let endIndex = trimmed.indexOf('\n---\n', 3);
  if (endIndex === -1) {
    if (trimmed.endsWith('\n---')) endIndex = trimmed.length - 4;
    else return null;
  }
  
  const fmBlock = trimmed.slice(3, endIndex).trim();
  if (fmBlock === '') return {};
  
  const result = {};
  let currentKey = null;
  let currentValue = '';
  
  for (const line of fmBlock.split('\n')) {
    const colonIndex = line.indexOf(':');
    
    // New key: colon > 0 and starts at column 0
    if (colonIndex > 0 && line[0] !== ' ' && line[0] !== '\t') {
      if (currentKey !== null) {
        result[currentKey] = stripQuotes(currentValue.trim());
      }
      currentKey = line.slice(0, colonIndex).trim();
      currentValue = line.slice(colonIndex + 1);
    } else if (currentKey !== null) {
      if (line.trimStart().startsWith('#')) continue;  // Skip comments
      currentValue += '\n' + line;  // Multi-line continuation
    }
  }
  
  if (currentKey !== null) {
    result[currentKey] = stripQuotes(currentValue.trim());
  }
  
  return result;
}
```

### 5.3 14 rule implementations (pseudo-code)

**SKILL-01: SKILL.md must exist**
```javascript
if (!fs.existsSync(skillMdPath)) {
  findings.push({
    rule: 'SKILL-01',
    severity: 'CRITICAL',
    file: 'SKILL.md',
    detail: 'SKILL.md not found in skill directory.',
    fix: 'Create SKILL.md as the skill entrypoint.'
  });
  return findings;  // Cannot check further
}
```

**SKILL-02: frontmatter has `name`**
```javascript
if (!skillFm || !('name' in skillFm)) {
  findings.push({
    rule: 'SKILL-02',
    severity: 'CRITICAL',
    file: 'SKILL.md',
    detail: 'Frontmatter is missing the `name` field.',
    fix: 'Add `name: <skill-name>` to the frontmatter.'
  });
}
```

**SKILL-03: frontmatter has `description`** (analogous)

**SKILL-04: name format**
```javascript
if (name && !NAME_REGEX.test(name)) {
  findings.push({
    rule: 'SKILL-04',
    severity: 'HIGH',
    file: 'SKILL.md',
    detail: `name "${name}" does not match pattern: ${NAME_REGEX}`,
    fix: 'Rename to comply with lowercase letters, numbers, and hyphens only.'
  });
}
```

**SKILL-05: name matches directory**
```javascript
if (name && name !== dirName) {
  findings.push({
    rule: 'SKILL-05',
    severity: 'HIGH',
    file: 'SKILL.md',
    detail: `name "${name}" does not match directory name "${dirName}".`,
    fix: `Change name to "${dirName}" or rename the directory.`
  });
}
```

**SKILL-06: description quality**
```javascript
if (description) {
  if (description.length > 1024) {
    findings.push({ rule: 'SKILL-06', severity: 'MEDIUM',
      detail: `description is ${description.length} chars (max 1024).`,
      fix: 'Shorten description.' });
  }
  if (!/use\s+when\b/i.test(description) && !/use\s+if\b/i.test(description)) {
    findings.push({ rule: 'SKILL-06', severity: 'MEDIUM',
      detail: 'description missing "Use when" or "Use if" trigger.',
      fix: 'Append a "Use when..." clause.' });
  }
}
```

**SKILL-07: body non-empty**
```javascript
const body = extractBodyAfterFrontmatter(skillContent).trim();
if (body === '') {
  findings.push({ rule: 'SKILL-07', severity: 'HIGH',
    detail: 'SKILL.md has no content after frontmatter.',
    fix: 'Add markdown body with skill instructions.' });
}
```

**WF-01 / WF-02: non-SKILL.md files must NOT have name/description**
```javascript
for (const filePath of allFiles) {
  if (path.basename(filePath) === 'SKILL.md') continue;
  if (WF_SKIP_SKILLS.has(dirName)) continue;
  if (path.extname(filePath) !== '.md') continue;
  
  const fm = parseFrontmatter(readFile(filePath));
  if (!fm) continue;
  
  if ('name' in fm) {
    findings.push({ rule: 'WF-01', severity: 'HIGH', file: relFile,
      detail: `${relFile} frontmatter contains \`name\`.`,
      fix: "Remove `name:` from this file's frontmatter." });
  }
  if ('description' in fm) {
    findings.push({ rule: 'WF-02', ... });
  }
}
```

**PATH-02: no `installed_path` variable**
```javascript
for (const filePath of allFiles) {
  if (!['.md', '.yaml', '.yml'].includes(path.extname(filePath))) continue;
  
  const fm = parseFrontmatter(content);
  if (fm && 'installed_path' in fm) {
    findings.push({ rule: 'PATH-02', severity: 'HIGH',
      detail: 'Frontmatter contains `installed_path:` key.',
      fix: 'Remove. Use relative paths instead.' });
  }
  
  const stripped = stripCodeBlocks(content);
  const lines = stripped.split('\n');
  for (const [i, line] of lines.entries()) {
    if (/installed_path/i.test(line)) {
      findings.push({ rule: 'PATH-02', severity: 'HIGH',
        file: relFile, line: i + 1,
        detail: '`installed_path` reference found.',
        fix: 'Remove. Use relative paths (`./path` or `../path`).' });
    }
  }
}
```

**STEP-01: step filename format**
```javascript
if (fs.existsSync(stepsDir)) {
  const stepFiles = fs.readdirSync(stepsDir).filter(f => f.endsWith('.md'));
  
  for (const stepFile of stepFiles) {
    if (!STEP_FILENAME_REGEX.test(stepFile)) {
      findings.push({ rule: 'STEP-01', severity: 'MEDIUM',
        file: `steps/${stepFile}`,
        detail: `Filename doesn't match pattern: ${STEP_FILENAME_REGEX}`,
        fix: 'Rename to step-NN-description.md.' });
    }
  }
}
```

**STEP-06: step frontmatter must NOT have name/description** (analogous to WF-01)

**STEP-07: step count 2-10**
```javascript
if (stepFiles.length < 2 || stepFiles.length > 10) {
  findings.push({ rule: 'STEP-07', severity: 'MEDIUM', file: 'steps/',
    detail: `Found ${stepFiles.length} steps (expected 2-10).`,
    fix: 'Organize workflow into 2-10 discrete steps.' });
}
```

**SEQ-02: no time estimates**
```javascript
for (const filePath of mdFiles) {
  const stripped = stripCodeBlocks(readFile(filePath));
  for (const [i, line] of stripped.split('\n').entries()) {
    for (const pattern of TIME_ESTIMATE_PATTERNS) {
      if (pattern.test(line)) {
        findings.push({ rule: 'SEQ-02', severity: 'LOW',
          file: relFile, line: i + 1,
          detail: `Time estimate found: "${line.trim()}"`,
          fix: 'Remove time estimates.' });
        break;
      }
    }
  }
}
```

### 5.4 Output modes

```javascript
// Human-readable table (default)
// --json: JSON array of findings
// --strict: exit(1) if any HIGH+ finding

if (options.json) {
  console.log(JSON.stringify(allFindings, null, 2));
} else {
  renderTable(allFindings);
}

if (options.strict && allFindings.some(f => ['CRITICAL', 'HIGH'].includes(f.severity))) {
  process.exit(1);
}
```

---

## 6. External module management

### 6.1 Registry structure

**Fetched từ:** `github.com/bmad-code-org/bmad-plugins-marketplace/registry/official.yaml`

**Fallback:** `tools/installer/modules/registry-fallback.yaml` (bundled).

**Format:**
```yaml
modules:
  - name: tea
    code: tea
    display_name: "Test Experience Automation"
    description: "Playwright test generation"
    url: "https://github.com/bmad-code-org/tea-module.git"
    module_definition: "skills/module.yaml"
    default_selected: false
    type: "bmad-org"
```

### 6.2 Clone algorithm

**Cache directory:** `~/.bmad/cache/external-modules/<code>/`

**Algorithm:**

```javascript
async cloneExternalModule(moduleCode, options = {}) {
  const moduleInfo = await this.getModuleByCode(moduleCode);
  const cacheDir = this.getExternalCacheDir();
  const moduleCacheDir = path.join(cacheDir, moduleCode);
  
  await fs.ensureDir(cacheDir);
  
  let needsDependencyInstall = false;
  let wasNewClone = false;
  
  if (await fs.pathExists(moduleCacheDir)) {
    // Update existing: git fetch + reset
    try {
      const currentRef = execSync('git rev-parse HEAD', { cwd: moduleCacheDir })
        .toString().trim();
      execSync('git fetch origin --depth 1', { cwd: moduleCacheDir });
      execSync('git reset --hard origin/HEAD', { cwd: moduleCacheDir });
      const newRef = execSync('git rev-parse HEAD', { cwd: moduleCacheDir })
        .toString().trim();
      if (currentRef !== newRef) needsDependencyInstall = true;
    } catch {
      // Fetch failed, re-download
      await fs.remove(moduleCacheDir);
      wasNewClone = true;
    }
  } else {
    wasNewClone = true;
  }
  
  if (wasNewClone) {
    execSync(`git clone --depth 1 "${moduleInfo.url}" "${moduleCacheDir}"`, {
      env: { ...process.env, GIT_TERMINAL_PROMPT: '0' }
    });
  }
  
  // Install npm dependencies if package.json exists
  const packageJsonPath = path.join(moduleCacheDir, 'package.json');
  if (await fs.pathExists(packageJsonPath)) {
    const nodeModulesPath = path.join(moduleCacheDir, 'node_modules');
    const nodeModulesMissing = !(await fs.pathExists(nodeModulesPath));
    
    if (needsDependencyInstall || wasNewClone || nodeModulesMissing) {
      execSync('npm install --omit=dev --no-audit --no-fund --no-progress --legacy-peer-deps', {
        cwd: moduleCacheDir,
        timeout: 120_000
      });
    }
  }
  
  return moduleCacheDir;
}
```

### 6.3 module.yaml resolution

4 variants supported (search in order):
1. `<cache>/skills/module.yaml`
2. `<cache>/src/module.yaml`
3. `<cache>/skills/<SUBDIR>/module.yaml` or `<cache>/src/<SUBDIR>/module.yaml`
4. `<cache>/module.yaml`

---

## 7. IDE integration

### 7.1 platform-codes.yaml

```yaml
platforms:
  claude-code:
    name: "Claude Code"
    preferred: true
    installer:
      target_dir: ".claude/skills"
      legacy_targets: []
      ancestor_conflict_check: true
  
  cursor:
    name: "Cursor"
    preferred: true
    installer:
      target_dir: ".cursor/rules"
      legacy_targets: []
  
  windsurf:
    name: "Windsurf"
    preferred: true
    installer:
      target_dir: ".windsurf/skills"
      legacy_targets: [".windsurf/workflows"]
```

### 7.2 Setup algorithm

```javascript
async setup(projectDir, bmadDir, options = {}) {
  // Fail fast: ancestor conflict check (for IDEs with inheritance)
  if (this.installerConfig?.ancestor_conflict_check) {
    const conflict = await this.findAncestorConflict(projectDir);
    if (conflict) {
      return { success: false, reason: 'ancestor-conflict',
        conflictDir: conflict };
    }
  }
  
  await this.cleanup(projectDir, options, bmadDir);
  
  if (this.installerConfig.target_dir) {
    return this.installToTarget(projectDir, bmadDir, this.installerConfig, options);
  }
}

async installVerbatimSkills(projectDir, bmadDir, targetPath, config) {
  const csvPath = path.join(bmadDir, '_config', 'skill-manifest.csv');
  if (!(await fs.pathExists(csvPath))) return 0;
  
  const records = csv.parse(await fs.readFile(csvPath, 'utf8'), {
    columns: true,
    skip_empty_lines: true
  });
  
  let count = 0;
  
  for (const record of records) {
    const canonicalId = record.canonicalId;
    if (!canonicalId) continue;
    
    // Strip bmadFolderName prefix, get source directory
    const relativePath = record.path.startsWith(bmadPrefix)
      ? record.path.slice(bmadPrefix.length)
      : record.path;
    const sourceFile = path.join(bmadDir, relativePath);
    const sourceDir = path.dirname(sourceFile);
    
    if (!(await fs.pathExists(sourceDir))) continue;
    
    // Clean target, copy verbatim
    const skillDir = path.join(targetPath, canonicalId);
    await fs.remove(skillDir);
    await fs.ensureDir(skillDir);
    
    // Filter OS/editor artifacts
    const skipPatterns = new Set(['.DS_Store', 'Thumbs.db', 'desktop.ini']);
    const skipSuffixes = ['~', '.swp', '.swo', '.bak'];
    
    const filter = (src) => {
      const name = path.basename(src);
      if (src === sourceDir) return true;
      if (skipPatterns.has(name)) return false;
      if (name.startsWith('.') && name !== '.gitkeep') return false;
      if (skipSuffixes.some(s => name.endsWith(s))) return false;
      return true;
    };
    
    await fs.copy(sourceDir, skillDir, { filter });
    count++;
  }
  
  return count;
}
```

---

## 8. Build pipeline

### 8.1 build-docs.mjs flow

```
npm run docs:build
    │
    ▼
[build-docs.mjs]
    │
    ├─ checkDocLinks()       ← validate-doc-links.js
    │
    ├─ cleanBuildDirectory()
    │
    ├─ generateArtifacts()
    │    ├─ generateLlmsTxt()        ← llms.txt
    │    └─ generateLlmsFullTxt()    ← llms-full.txt (≤600k chars)
    │
    ├─ buildAstroSite()       ← npm run build --root website
    │    └─ Astro + Starlight → build/site/
    │
    └─ copyArtifactsToSite()   ← copy llms.*.txt to site
```

### 8.2 llms-full.txt generation

**Constants:**
```javascript
const LLM_MAX_CHARS = 600_000;   // ~150k tokens
const LLM_WARN_CHARS = 500_000;

const LLM_EXCLUDE_PATTERNS = [
  'changelog', 'ide-info/', 'v4-to-v6-upgrade', 'faq',
  'reference/glossary/', 'explanation/game-dev/', 'bmgd/'
];
```

**Algorithm:**

```javascript
function generateLlmsFullTxt(docsDir, outputDir) {
  const files = getAllMarkdownFiles(docsDir).sort(compareLlmDocs);
  const output = [
    '# BMAD Method Documentation (Full)',
    `> Complete documentation for AI consumption`,
    `> Generated: ${date}`,
    ''
  ];
  
  for (const mdPath of files) {
    if (shouldExcludeFromLlm(mdPath)) continue;
    
    const content = readMarkdownContent(path.join(docsDir, mdPath));
    output.push(`<document path="${mdPath}">`, content, '</document>', '');
  }
  
  const result = output.join('\n');
  validateLlmSize(result);  // Exit if > MAX, warn if > WARN
  
  fs.writeFileSync(path.join(outputDir, 'llms-full.txt'), result);
}

function shouldExcludeFromLlm(filePath) {
  // Underscore prefix (any level) = private/internal
  if (filePath.split(path.sep).some(p => p.startsWith('_'))) return true;
  
  // Non-root locales (translations duplicate English)
  if (translatedLocales.some(l => filePath.startsWith(`${l}/`))) return true;
  
  return LLM_EXCLUDE_PATTERNS.some(p => filePath.includes(p));
}
```

---

## 9. Interface specs cho rewrite

### 9.1 CLI interface (reference)

```bash
# install
bmad install
  [--directory <path>]         # Target directory (default: cwd)
  [--modules <list>]           # Comma-separated (e.g., 'bmm,cis')
  [--tools <list>]             # IDEs (e.g., 'claude-code,cursor')
  [--action <type>]            # install | update | quick-update
  [--user-name <name>]         # Skip prompt for user_name
  [--communication-language <lang>]
  [--document-output-language <lang>]
  [--output-folder <path>]
  [--custom-source <url>]      # Git URL for custom module
  [--yes, -y]                  # Skip all prompts
  [--verbose, -v]

# uninstall
bmad uninstall
  [--directory <path>]
  [--modules <list>]           # Specific modules (or all)

# upgrade
bmad upgrade
  [--directory <path>]

# status
bmad status
  [--directory <path>]
```

### 9.2 Module API (for module authors)

```typescript
// module.yaml schema
interface ModuleYaml {
  code: string;                // e.g., 'bmm', 'security'
  name: string;                // Display name
  description: string;
  default_selected?: boolean;
  header?: string;             // Installer UI header
  subheader?: string;
  
  // Config variables (prompted during install)
  [varName: string]: ConfigVar | any;
  
  // Directories created during install
  directories?: string[];      // Paths with variable expansion
  
  // Agent roster
  agents?: Agent[];
  
  // Post-install hooks
  'post-install-notes'?: string | {
    [configKey: string]: { [value: string]: string }
  };
}

interface ConfigVar {
  prompt: string | string[];
  scope?: 'user';              // Or absent (team)
  default?: string;
  result?: string;             // Template for final value
  'single-select'?: Array<{ value: string; label: string }>;
}

interface Agent {
  code: string;                // e.g., 'bmad-agent-pm'
  name: string;                // e.g., 'John'
  title: string;               // e.g., 'Product Manager'
  icon: string;                // Single emoji
  team?: string;
  description: string;
}
```

### 9.3 Skill API (for skill authors)

```
<skill-dir>/
├── SKILL.md               # Required
│   ---
│   name: bmad-<name>      # Must match dir, regex ^bmad-[a-z0-9]+(-[a-z0-9]+)*$
│   description: "..."      # Must include "Use when" or "Use if", max 1024 chars
│   ---
│   [body with L2 instructions]
│
├── workflow.md            # Optional, referenced from SKILL.md
├── customize.toml         # Optional, agent/workflow persona
├── template.md            # Optional, output template
├── checklist.md           # Optional, validation checklist
├── steps/                 # Optional, micro-file workflow
│   ├── step-01-<desc>.md   # Pattern: ^step-\d{2}[a-z]?-[a-z0-9-]+\.md$
│   └── ...                 # 2-10 steps total
├── resources/             # Optional, reference docs
├── agents/                # Optional, sub-agent prompts
└── scripts/               # Optional, Python/JS helpers
```

### 9.4 Rewrite priorities (Go/Rust/Python)

**Phase 1 (Week 1): Core data structures**
- Config, InstallPaths, ExistingInstall
- Manifest files parsers/writers (YAML, CSV)
- File ops với SHA-256

**Phase 2 (Week 2): Installer state machine**
- Install flow 8 phases
- Update detection + user file preservation
- Module directory creation

**Phase 3 (Week 3): External module management**
- Registry client (HTTP + YAML)
- Git clone + npm install (subprocess)
- module.yaml resolution (4 variants)
- Fallback to bundled registry

**Phase 4 (Week 4): IDE integration**
- Config-driven IDE setup
- Verbatim skill copy
- Ancestor conflict check

**Phase 5 (Week 5): CLI + UI**
- Interactive prompts (use TUI library)
- Command dispatch
- Status/uninstall/upgrade commands

**Phase 6 (Week 6): Validator**
- 14 deterministic rules
- Hand-rolled frontmatter parser (language-native)
- JSON + strict output modes

**Phase 7 (Week 7): Build pipeline** (optional, nếu rewrite luôn build tools)
- llms.txt / llms-full.txt generation
- Docs link validation

### 9.5 Port-specific notes

**Go:**
```go
// Recommended libs:
// - cobra (CLI)
// - bubbletea or survey (prompts)
// - go-yaml v3
// - github.com/go-git/go-git (Git operations)
// - crypto/sha256 (hashing)

type Config struct {
    Directory    string
    Modules      []string
    IDEs         []string
    SkipPrompts  bool
    ActionType   string
    CoreConfig   map[string]interface{}
    ModuleConfigs map[string]map[string]interface{}
}
```

**Rust:**
```rust
// Recommended crates:
// - clap (CLI)
// - dialoguer + indicatif (prompts)
// - serde_yaml, serde_json
// - git2 (Git operations)
// - sha2 (SHA-256)

#[derive(Debug, Clone)]
pub struct Config {
    pub directory: PathBuf,
    pub modules: Vec<String>,
    pub ides: Vec<String>,
    pub skip_prompts: bool,
    pub action_type: ActionType,
    pub core_config: HashMap<String, serde_json::Value>,
    pub module_configs: HashMap<String, HashMap<String, serde_json::Value>>,
}
```

**Python:**
```python
# Recommended libs:
# - click or typer (CLI)
# - questionary (prompts)
# - PyYAML
# - GitPython
# - hashlib (SHA-256)

from dataclasses import dataclass, field
from pathlib import Path

@dataclass
class Config:
    directory: Path
    modules: list[str]
    ides: list[str]
    skip_prompts: bool = False
    action_type: str = 'install'
    core_config: dict = field(default_factory=dict)
    module_configs: dict = field(default_factory=dict)
```

---

## Tóm lược

Installer BMad có 3 layers:

1. **CLI/UI layer** (~2300 dòng JS): bmad-cli, prompts, ui
2. **Install logic layer** (~2000 dòng JS): installer, config, paths, manifest-generator
3. **Integration layer** (~1500 dòng JS): modules/*, ide/*, file-ops, fs-native

Core algorithms:
- **syncDirectory**: SHA-256 + mtime cho file preservation
- **detectCustomFiles**: Scan + compare với manifest hashes
- **collectSkills**: Recursive walk, parse SKILL.md frontmatter
- **cloneExternalModule**: Git clone/fetch, npm install nếu có deps

Validator 14 rules: hand-rolled YAML parser, regex-based detection.

IDE setup: config-driven từ `platform-codes.yaml`, verbatim skill copy.

Rewrite effort ước tính: **6-7 tuần** cho 1 maintainer có kinh nghiệm với target language.

---

**Đọc tiếp:** [09a-skills-core-deep.md](09a-skills-core-deep.md) — 12 core skills chi tiết.
