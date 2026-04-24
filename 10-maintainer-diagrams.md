# 10. Maintainer Diagrams - 10 Mermaid Diagrams

> ⚠️ **UNOFFICIAL THIRD-PARTY DOCUMENTATION**
> NOT official BMad docs. See [DISCLAIMER.md](DISCLAIMER.md) | Licensed MIT — see [LICENSE](LICENSE) and [NOTICE](NOTICE)
> Official BMAD-METHOD: <https://github.com/bmad-code-org/BMAD-METHOD>

---

> Diagrams for maintainers diving deep into the installer, validator, and build pipeline architecture. Use when debugging or rewriting.

---

## Table of Contents

1. [Installer state machine (detect → prepare → install → restore)](#1-installer-state-machine)
2. [File-level data flow in the installer](#2-file-level-data-flow-in-the-installer)
3. [Resolver algorithm flowchart (keyed merge vs append)](#3-resolver-algorithm-flowchart)
4. [Validator execution flow](#4-validator-execution-flow)
5. [IDE handler class hierarchy + sequence](#5-ide-handler-class-hierarchy--sequence)
6. [External module lifecycle](#6-external-module-lifecycle)
7. [Skill invocation sequence (agent ↔ skill ↔ sub-skill ↔ Agent tool)](#7-skill-invocation-sequence)
8. [Backup-restore flow during update](#8-backup-restore-flow-during-update)
9. [Customization merge visualization](#9-customization-merge-visualization)
10. [package.json scripts dependency graph](#10-packagejson-scripts-dependency-graph)

---

## 1. Installer state machine

Detailed 8-phase install with error paths.

```mermaid
stateDiagram-v2
    [*] --> Start
    
    Start: bmad install command
    BuildConfig: Build Config<br/>(immutable, frozen)
    BuildPaths: Create InstallPaths<br/>(bmadDir, configDir, customDir)
    DetectExisting: Detect existing<br/>ExistingInstall.detect()
    
    Start --> BuildConfig
    BuildConfig --> BuildPaths
    BuildPaths --> DetectExisting
    
    DetectExisting --> FreshInstall: No existing
    DetectExisting --> UpdateCheck: Existing found
    
    state UpdateCheck {
        [*] --> RemoveDeselected
        RemoveDeselected: Remove deselected modules<br/>fs.remove(moduleDir)
        PrepareState: Prepare update state<br/>detectCustomFiles + backup
        RemoveIDEs: Remove deselected IDEs<br/>cleanup handler
        
        [*] --> RemoveDeselected
        RemoveDeselected --> PrepareState
        PrepareState --> RemoveIDEs
        RemoveIDEs --> [*]
    }
    
    FreshInstall: Fresh install path
    ValidateIDE: Validate IDE selection<br/>(fail fast)
    
    UpdateCheck --> ValidateIDE
    FreshInstall --> ValidateIDE
    
    ValidateIDE --> ValidateFail: Unknown IDE
    ValidateIDE --> InstallModules: Valid
    ValidateFail: ❌ Error<br/>Unknown IDE
    
    state InstallModules {
        [*] --> InstallShared
        InstallShared: Install shared scripts<br/>src/scripts → _bmad/scripts
        LoopModules: For each module
        ResolveVersion: Resolve version<br/>(cache > yaml > git)
        CopyFiles: Copy src → _bmad/{module}
        GenConfigs: Generate config.yaml
        
        [*] --> InstallShared
        InstallShared --> LoopModules
        LoopModules --> ResolveVersion
        ResolveVersion --> CopyFiles
        CopyFiles --> GenConfigs
        GenConfigs --> LoopModules: More modules
        LoopModules --> [*]: Done
    }
    
    state SetupIDEs {
        [*] --> LoadPlatforms
        LoadPlatforms: Load platform-codes.yaml
        LoopIDEs: For each IDE
        AncestorCheck: Ancestor conflict check
        CleanupOld: Cleanup old legacy targets
        InstallSkills: installVerbatimSkills<br/>(from skill-manifest.csv)
        UpdateSettings: Update IDE settings
        
        [*] --> LoadPlatforms
        LoadPlatforms --> LoopIDEs
        LoopIDEs --> AncestorCheck
        AncestorCheck --> CleanupOld
        CleanupOld --> InstallSkills
        InstallSkills --> UpdateSettings
        UpdateSettings --> LoopIDEs: More IDEs
        LoopIDEs --> [*]: Done
    }
    
    InstallModules --> SetupIDEs
    SetupIDEs --> CleanupSkillDirs
    
    CleanupSkillDirs: Cleanup _bmad/skills/<br/>(moved to IDE dirs)
    RestoreFiles: Restore user files<br/>(merge custom + modified)
    
    CleanupSkillDirs --> RestoreFiles
    RestoreFiles --> GenManifests
    
    GenManifests: Generate manifests<br/>manifest.yaml, skill-manifest.csv,<br/>files-manifest.csv
    Summary: Render summary<br/>(results, customFiles, modifiedFiles)
    
    GenManifests --> Summary
    Summary --> Success
    
    Success: ✅ Success<br/>Return { path, modules, ides }
    
    Success --> [*]
    ValidateFail --> [*]
    
    note right of UpdateCheck
        If any error here:
        - Remove tempBackupDir
        - Remove tempModifiedBackupDir
        - Re-throw error
    end note
```

---

## 2. File-level data flow in the installer

Data flows between source, temp backups, and target dirs with checksum diff logic.

```mermaid
flowchart TB
    subgraph Source["Source (read-only)"]
        SrcCore[src/core-skills/]
        SrcBMM[src/bmm-skills/]
        SrcScripts[src/scripts/]
        SrcCustom[src/modules/*]
    end
    
    subgraph Cache["Cache (~/.bmad/cache/)"]
        ExtCache[external-modules/*]
    end
    
    subgraph Temp["Temp (OS tmp dir)"]
        TempBackup[tempBackupDir<br/>custom files]
        TempMod[tempModifiedBackupDir<br/>modified installed files]
    end
    
    subgraph Target["Target (project-root/)"]
        BmadDir[_bmad/]
        BmadCore[_bmad/core/]
        BmadBMM[_bmad/bmm/]
        BmadCustom[_bmad/custom/]
        BmadConfig[_bmad/_config/]
        
        subgraph Manifests["Manifests"]
            ManifestYaml[manifest.yaml]
            SkillManifest[skill-manifest.csv]
            FilesManifest[files-manifest.csv]
        end
        
        subgraph IDEConfigs["IDE configs"]
            ClaudeDir[.claude/skills/]
            CursorDir[.cursor/rules/]
            WindsurfDir[.windsurf/skills/]
        end
    end
    
    SrcCore -->|copyDirectory| BmadCore
    SrcBMM -->|copyDirectory| BmadBMM
    SrcScripts -->|copy| BmadDir
    SrcCustom -->|resolve module| BmadDir
    
    ExtCache -->|git clone/fetch| BmadDir
    
    BmadCore -.->|syncDirectory<br/>SHA-256 check| TempBackup
    BmadBMM -.->|syncDirectory<br/>mtime check| TempBackup
    BmadCustom -.->|always preserve| TempBackup
    
    TempBackup -.->|restore after install| BmadCustom
    TempMod -.->|diff check| BmadDir
    
    BmadDir -->|scan SKILL.md<br/>parse frontmatter| SkillManifest
    BmadDir -->|parse module.yaml<br/>agents: array| ManifestYaml
    BmadDir -->|sha256 every file| FilesManifest
    
    SkillManifest -->|installVerbatimSkills<br/>csv.parse| ClaudeDir
    SkillManifest --> CursorDir
    SkillManifest --> WindsurfDir
    
    classDef source fill:#e3f2fd,stroke:#1976d2
    classDef cache fill:#fff3e0,stroke:#f57c00
    classDef temp fill:#ffebee,stroke:#c62828
    classDef target fill:#e8f5e9,stroke:#388e3c
    classDef manifest fill:#f3e5f5,stroke:#7b1fa2
    classDef ide fill:#fce4ec,stroke:#c2185b
    
    class SrcCore,SrcBMM,SrcScripts,SrcCustom source
    class ExtCache cache
    class TempBackup,TempMod temp
    class BmadDir,BmadCore,BmadBMM,BmadCustom,BmadConfig target
    class ManifestYaml,SkillManifest,FilesManifest manifest
    class ClaudeDir,CursorDir,WindsurfDir ide
```

### Key flows

1. **Install:** Source → Target (direct copy)
2. **Update:** Target → Temp (backup) → Source → Target (install) → Temp → Target (restore)
3. **Manifest:** Target scan → Manifests (JSON/YAML/CSV)
4. **IDE:** Manifest → IDE target dirs (verbatim skill copy)

---

## 3. Resolver algorithm flowchart

Shape-based merge with keyed detection.

```mermaid
flowchart TD
    Start([deep_merge&#40;base, override&#41;])
    
    CheckShape{What type is<br/>base + override?}
    
    Start --> CheckShape
    
    CheckShape -->|Both dicts| DictMerge[Deep recursive merge<br/>for each key]
    CheckShape -->|Both arrays| ArrayCheck{Array element<br/>type?}
    CheckShape -->|Scalars or mixed| ScalarMerge[override wins<br/>return override ?? base]
    
    DictMerge --> CopyBase[result = &#123;...base&#125;]
    CopyBase --> IterKeys[For each key in override]
    IterKeys --> RecurseKey["result[key] = deep_merge&#40;base[key], override[key]&#41;"]
    RecurseKey --> NextKey{More keys?}
    NextKey -->|Yes| IterKeys
    NextKey -->|No| ReturnDict[Return result]
    
    ArrayCheck -->|Items are dicts| KeyedCheck{All items have<br/>same key field?}
    ArrayCheck -->|Items are scalars| AppendArray[Return base + override<br/>&#40;append&#41;]
    ArrayCheck -->|Mixed types| AppendArray
    
    KeyedCheck -->|Check 'code'| CheckCode{ALL have 'code'<br/>field?}
    CheckCode -->|Yes| KeyedMerge[Merge by 'code'<br/>replace matches<br/>append new]
    CheckCode -->|No| CheckId{ALL have 'id'<br/>field?}
    CheckId -->|Yes| KeyedMergeId[Merge by 'id'<br/>replace matches<br/>append new]
    CheckId -->|No| AppendArray
    
    KeyedMerge --> IterBase[For each item in base:<br/>register by code]
    IterBase --> IterOverride[For each item in override:<br/>if match found → replace<br/>else → append]
    IterOverride --> ReturnKeyed[Return merged array]
    
    KeyedMergeId --> SameAsCode[&#40;same logic as code&#41;]
    SameAsCode --> ReturnKeyed
    
    AppendArray --> ReturnAppend[Return combined array]
    
    ScalarMerge --> ReturnScalar[Return]
    ReturnDict --> Done([Return merged])
    ReturnKeyed --> Done
    ReturnAppend --> Done
    ReturnScalar --> Done
    
    classDef decision fill:#fff3e0
    classDef process fill:#e3f2fd
    classDef result fill:#c8e6c9
    
    class CheckShape,ArrayCheck,KeyedCheck,CheckCode,CheckId,NextKey decision
    class DictMerge,CopyBase,IterKeys,RecurseKey,AppendArray,KeyedMerge,KeyedMergeId,IterBase,IterOverride,SameAsCode,ScalarMerge process
    class ReturnDict,ReturnKeyed,ReturnAppend,ReturnScalar,Done result
```

### Key insight

**Keyed detection is STRICT:** All items must have same identifier field. Mixed → append fallback. This prevents subtle bugs where user thinks they're replacing but actually appending.

---

## 4. Validator execution flow

`validate-skills.js` execution with 14 deterministic rules.

```mermaid
flowchart TB
    Start([node validate-skills.js])
    
    ParseArgs[Parse CLI args<br/>--strict --json --path]
    
    CollectSkills[Collect skill dirs<br/>recursive walk src/]
    
    Start --> ParseArgs
    ParseArgs --> CollectSkills
    
    CollectSkills --> LoopSkills[For each skill dir]
    LoopSkills --> CheckSKILL01[SKILL-01:<br/>SKILL.md exists?]
    
    CheckSKILL01 -->|No| AddCritical1[Add finding CRITICAL<br/>SKILL.md missing]
    AddCritical1 --> NextSkill
    CheckSKILL01 -->|Yes| ParseFM[parseFrontmatterMultiline&#40;&#41;<br/>hand-rolled YAML]
    
    ParseFM --> CheckSKILL02[SKILL-02:<br/>has name?]
    CheckSKILL02 -->|No| AddCritical2[Add finding CRITICAL]
    CheckSKILL02 -->|Yes| CheckSKILL03[SKILL-03:<br/>has description?]
    AddCritical2 --> CheckSKILL03
    
    CheckSKILL03 -->|No| AddCritical3[Add finding CRITICAL]
    CheckSKILL03 -->|Yes| CheckSKILL04[SKILL-04:<br/>name matches regex?]
    AddCritical3 --> CheckSKILL04
    
    CheckSKILL04 -->|No| AddHigh1[Add finding HIGH]
    CheckSKILL04 -->|Yes| CheckSKILL05[SKILL-05:<br/>name matches dir?]
    AddHigh1 --> CheckSKILL05
    
    CheckSKILL05 -->|No| AddHigh2[Add HIGH]
    CheckSKILL05 -->|Yes| CheckSKILL06[SKILL-06:<br/>description quality]
    AddHigh2 --> CheckSKILL06
    
    CheckSKILL06 --> CheckSKILL07[SKILL-07:<br/>body non-empty?]
    CheckSKILL07 --> CheckOtherMDFiles[For each other .md file]
    
    CheckOtherMDFiles --> CheckWF01[WF-01:<br/>no name in frontmatter]
    CheckWF01 --> CheckWF02[WF-02:<br/>no description]
    CheckWF02 --> CheckPATH02[PATH-02:<br/>no installed_path]
    CheckPATH02 --> CheckSEQ02[SEQ-02:<br/>no time estimates]
    
    CheckSEQ02 --> CheckStepsDir{Steps dir<br/>exists?}
    CheckStepsDir -->|Yes| CheckSTEP01[STEP-01:<br/>filename format]
    CheckStepsDir -->|No| NextSkill
    
    CheckSTEP01 --> CheckSTEP06[STEP-06:<br/>no name/description]
    CheckSTEP06 --> CheckSTEP07[STEP-07:<br/>2-10 steps]
    CheckSTEP07 --> NextSkill
    
    NextSkill{More skills?}
    NextSkill -->|Yes| LoopSkills
    NextSkill -->|No| Format{Output<br/>format?}
    
    Format -->|--json| JSONOutput[Write JSON to stdout]
    Format -->|Table| TableOutput[Render table to stdout]
    
    JSONOutput --> CheckStrict{--strict flag?}
    TableOutput --> CheckStrict
    
    CheckStrict -->|Yes + HIGH+ findings| Exit1[exit&#40;1&#41;]
    CheckStrict -->|No or no HIGH+| Exit0[exit&#40;0&#41;]
    
    classDef decision fill:#fff3e0
    classDef process fill:#e3f2fd
    classDef finding fill:#ffebee
    classDef result fill:#c8e6c9
    
    class CheckSKILL01,CheckSKILL02,CheckSKILL03,CheckSKILL04,CheckSKILL05,CheckStepsDir,NextSkill,Format,CheckStrict decision
    class ParseFM,CheckSKILL06,CheckSKILL07,CheckWF01,CheckWF02,CheckPATH02,CheckSEQ02,CheckSTEP01,CheckSTEP06,CheckSTEP07 process
    class AddCritical1,AddCritical2,AddCritical3,AddHigh1,AddHigh2 finding
    class Exit0,Exit1,JSONOutput,TableOutput result
```

### Sample finding output

```json
{
  "rule": "SKILL-04",
  "title": "name Format",
  "severity": "HIGH",
  "file": "src/bmm-skills/my-skill/SKILL.md",
  "detail": "name \"my-skill\" does not match pattern: /^bmad-[a-z0-9]+(-[a-z0-9]+)*$/",
  "fix": "Rename to comply with lowercase letters, numbers, and hyphens only (max 64 chars)."
}
```

---

## 5. IDE handler class hierarchy + sequence

```mermaid
classDiagram
    class IdeManager {
        -handlers: Map~string, ConfigDrivenIdeSetup~
        -platformConfig: Object
        +loadHandlers(): Promise~void~
        +setup(ideName, projectDir, bmadDir, options): Promise~Object~
        +cleanup(ideName, projectDir, options): Promise~void~
        +getAvailableIdes(): string[]
        +getPreferredIdes(): string[]
        +getOtherIdes(): string[]
    }
    
    class ConfigDrivenIdeSetup {
        +name: string
        +displayName: string
        +preferred: boolean
        +platformConfig: Object
        +installerConfig: Object
        +bmadFolderName: string
        +configDir: string
        +constructor(platformCode, platformConfig)
        +setup(projectDir, bmadDir, options): Promise~Object~
        +cleanup(projectDir, options, bmadDir): Promise~void~
        #installToTarget(projectDir, bmadDir, config, options): Promise~Object~
        #installVerbatimSkills(projectDir, bmadDir, targetPath, config): Promise~number~
        #findAncestorConflict(projectDir): Promise~string|null~
        #generateIdeConfig(configPath, modules): Promise~void~
    }
    
    class PlatformCodesYaml {
        <<config file>>
        +platforms: Map
        <<each entry has>>
        +name: string
        +preferred: boolean
        +installer.target_dir: string
        +installer.legacy_targets: string[]
        +installer.ancestor_conflict_check: boolean
    }
    
    class SkillManifestCSV {
        <<data source>>
        +canonicalId: string
        +name: string
        +description: string
        +module: string
        +path: string
    }
    
    IdeManager "1" *-- "many" ConfigDrivenIdeSetup : creates
    IdeManager ..> PlatformCodesYaml : reads
    ConfigDrivenIdeSetup ..> SkillManifestCSV : reads
    ConfigDrivenIdeSetup ..> PlatformCodesYaml : uses config
```

### Sequence: setup Claude Code

```mermaid
sequenceDiagram
    participant Installer
    participant Manager as IdeManager
    participant Handler as ConfigDrivenIdeSetup(claude-code)
    participant FS as Filesystem
    participant CSV as skill-manifest.csv
    
    Installer->>Manager: setup('claude-code', projectDir, bmadDir)
    Manager->>Manager: getHandlers().get('claude-code')
    Manager->>Handler: setup(projectDir, bmadDir, options)
    
    alt ancestor_conflict_check enabled
        Handler->>Handler: findAncestorConflict(projectDir)
        Handler->>FS: Walk up from projectDir
        FS-->>Handler: Any BMAD install found?
        
        alt Conflict found
            Handler-->>Manager: {success: false, reason: 'ancestor-conflict'}
            Manager-->>Installer: Error
        end
    end
    
    Handler->>Handler: cleanup(projectDir, options, bmadDir)
    Handler->>FS: Remove legacy_targets (.windsurf/workflows, etc.)
    
    Handler->>Handler: installToTarget()
    
    alt target_dir has verbatim skills
        Handler->>CSV: Read skill-manifest.csv
        CSV-->>Handler: Parsed records
        
        loop for each skill record
            Handler->>FS: sourceDir = dirname(bmadDir + record.path)
            
            alt sourceDir exists
                Handler->>FS: fs.remove(targetPath/canonicalId)
                Handler->>FS: fs.ensureDir(targetPath/canonicalId)
                Handler->>FS: fs.copy(sourceDir, targetPath/canonicalId, {filter})
                Note right of Handler: filter: skip .DS_Store,<br/>*.swp, .hidden
            end
        end
    end
    
    Handler->>FS: generateIdeConfig(configPath, modules)
    Handler->>FS: Update .claude/skills.json
    
    Handler-->>Manager: {success: true, skillsInstalled: N}
    Manager-->>Installer: Result
```

---

## 6. External module lifecycle

Git clone → cache → version resolve → install.

```mermaid
sequenceDiagram
    participant Installer
    participant EMM as ExternalModuleManager
    participant Registry as GitHub<br/>bmad-plugins-marketplace
    participant Fallback as Bundled<br/>registry-fallback.yaml
    participant Git as Git CLI
    participant NPM as npm CLI
    participant Cache as ~/.bmad/cache/external-modules/
    participant Installer2 as Installer
    
    Installer->>EMM: Need module "tea"
    EMM->>EMM: cachedModules?
    
    alt No cache
        EMM->>Registry: Fetch registry/official.yaml
        alt Success
            Registry-->>EMM: { modules: [...] }
        else Network error
            EMM->>Fallback: Read bundled
            Fallback-->>EMM: { modules: [...] }
            EMM->>EMM: Log warn "Using bundled list"
        end
        EMM->>EMM: Cache modules
    end
    
    EMM->>EMM: getModuleByCode('tea')
    EMM-->>Installer: moduleInfo {url, moduleDefinition, ...}
    
    Installer->>EMM: cloneExternalModule('tea')
    EMM->>Cache: Check ~/.bmad/cache/external-modules/tea/
    
    alt Cache exists
        EMM->>Git: git rev-parse HEAD (in cache dir)
        Git-->>EMM: currentRef
        EMM->>Git: git fetch origin --depth 1
        EMM->>Git: git reset --hard origin/HEAD
        Git-->>EMM: newRef
        
        alt currentRef != newRef
            EMM->>EMM: needsDependencyInstall = true
        end
    else Cache doesn't exist
        EMM->>Git: git clone --depth 1 {url} {cacheDir}
        Git-->>EMM: Cloned
        EMM->>EMM: wasNewClone = true
    end
    
    alt package.json in cache
        alt needsDependencyInstall || wasNewClone || nodeModulesMissing
            EMM->>NPM: npm install --omit=dev --no-audit --legacy-peer-deps
            NPM-->>EMM: Installed
        end
    end
    
    EMM-->>Installer: cacheDir path
    
    Installer->>EMM: findExternalModuleSource('tea')
    EMM->>EMM: Check configured path (skills/module.yaml)
    
    alt Configured path exists
        EMM-->>Installer: path.dirname(configured)
    else Search skills/, src/
        EMM->>Cache: Check skills/module.yaml
        EMM->>Cache: Check src/module.yaml
        EMM->>Cache: Check one-level-deep
        EMM->>Cache: Check root module.yaml
        EMM-->>Installer: Found dir OR preserve configured path
    end
    
    Installer->>Installer2: Install module from resolved path
```

### Layout variants (4)

```mermaid
graph LR
    Cache[~/.bmad/cache/external-modules/tea/]
    
    V1[V1: skills/module.yaml]
    V2[V2: src/module.yaml]
    V3[V3: src/SUBDIR/module.yaml]
    V4[V4: module.yaml &#40;root&#41;]
    
    Cache --> V1
    Cache --> V2
    Cache --> V3
    Cache --> V4
    
    classDef variant fill:#e3f2fd
    class V1,V2,V3,V4 variant
```

---

## 7. Skill invocation sequence

Agent ↔ Skill ↔ Sub-skill ↔ Agent tool (party mode).

```mermaid
sequenceDiagram
    actor User
    participant Agent as bmad-agent-pm<br/>(John)
    participant Skill as bmad-create-prd
    participant Steps as steps-c/step-02.md
    participant SubSkill as bmad-advanced-elicitation
    participant Party as bmad-party-mode
    participant SubAgent as Mary/Amelia<br/>(via Agent tool)
    
    User->>Agent: /bmad-agent-pm "create a PRD"
    Agent->>Agent: Load customize.toml<br/>3-level merge
    Agent->>Agent: Adopt John persona
    Agent->>Agent: Load persistent_facts
    
    Agent->>User: 📋 Hi! I'm John, your PM.
    User->>Agent: "let's create a PRD"
    
    Note over Agent: Intent clear → direct invoke
    
    Agent->>Skill: Invoke `bmad-create-prd` skill
    Skill->>Skill: Load workflow.md
    Skill->>Steps: Read fully and follow step-01-init.md
    Steps->>Steps: Initialize prd.md
    Steps->>User: [C] Continue to discovery
    User->>Steps: C
    Steps->>Steps: Load step-02-discovery.md
    Steps->>User: Present discovery menu [A/P/C]
    
    alt User selects [A] Advanced Elicitation
        User->>Steps: A
        Steps->>SubSkill: Invoke `bmad-advanced-elicitation` skill
        SubSkill->>User: Present 5 methods + [r/a/x]
        User->>SubSkill: 3
        SubSkill->>SubSkill: Execute pre-mortem method
        SubSkill->>User: Enhanced content + apply?
        User->>SubSkill: Yes
        SubSkill-->>Steps: Return enhanced content
        Steps->>User: Re-present menu
    end
    
    alt User selects [P] Party Mode
        User->>Steps: P
        Steps->>Party: Invoke `bmad-party-mode` skill
        Party->>Party: Resolve agent roster
        Party->>User: Welcome + roster
        
        User->>Party: "discuss requirements"
        Party->>Party: Pick 3 agents (Mary, John, Winston)
        
        par Parallel spawn
            Party->>SubAgent: Agent tool: Mary
        and
            Party->>SubAgent: Agent tool: Winston
        end
        
        par Parallel responses
            SubAgent-->>Party: Mary's response
        and
            SubAgent-->>Party: Winston's response
        end
        
        Party->>User: Present both responses (unabridged)
        User->>Party: "enough, back to PRD"
        Party-->>Steps: Return
    end
    
    alt User selects [C] Continue
        User->>Steps: C
        Steps->>Steps: Load step-03-success.md
    end
    
    Note over Skill,Steps: Continue through remaining steps...
    
    Steps->>Skill: step-12-complete
    Skill->>User: PRD ready at {planning_artifacts}/prd.md
    Skill-->>Agent: Return control
    Agent->>User: What's next, John menu?
```

### Invocation patterns summary

| Pattern | Syntax | Context |
|---------|--------|---------|
| **Intra-skill step** | "Read fully and follow `./steps/step-02.md`" | Within skill, load next step |
| **Cross-skill invoke** | "Invoke the `bmad-xxx` skill" | Delegate to another skill |
| **Sub-agent spawn** | Agent tool with prompt | Party mode, distillator |
| **External CLI** | `npx @kayvan/markdown-tree-parser`, `python3 resolve_*.py` | Deterministic logic |

---

## 8. Backup-restore flow during update

Preserve user modifications across framework updates.

```mermaid
sequenceDiagram
    participant Installer
    participant FS as Filesystem
    participant Hash as SHA-256
    participant Manifest as files-manifest.csv
    participant TempBackup as tmp/bmad-backup-{ts}
    participant TempMod as tmp/bmad-modified-{ts}
    
    Note over Installer: Phase: _prepareUpdateState
    
    Installer->>Manifest: readFilesManifest(bmadDir)
    Manifest-->>Installer: existingFilesManifest[]
    
    Installer->>Installer: detectCustomFiles(bmadDir, manifest)
    
    loop Scan bmadDir
        Installer->>FS: readdir recursive
        FS-->>Installer: files
        
        loop Each file
            Installer->>Installer: Skip _config/, _memory/, config.yaml
            
            Installer->>Manifest: lookup file in manifest
            Manifest-->>Installer: fileInfo or null
            
            alt File not in manifest
                Note over Installer: CUSTOM FILE (user added)
                Installer->>Installer: customFiles.push(fullPath)
            else File in manifest with hash
                Installer->>Hash: calculateFileHash(fullPath)
                Hash-->>Installer: currentHash
                
                alt currentHash != originalHash
                    Note over Installer: MODIFIED FILE (user edited)
                    Installer->>Installer: modifiedFiles.push({path, relativePath})
                end
            end
        end
    end
    
    Installer->>Installer: _backupUserFiles(paths, customFiles, modifiedFiles)
    
    Installer->>FS: fs.ensureDir(tmp/bmad-backup-{ts})
    Installer->>FS: fs.ensureDir(tmp/bmad-modified-{ts})
    
    loop Each custom file
        Installer->>FS: Copy custom file → TempBackup
        TempBackup->>TempBackup: Preserved
    end
    
    loop Each modified file
        Installer->>FS: Copy modified file → TempMod
        TempMod->>TempMod: Preserved
    end
    
    Note over Installer: Install phase (overwrites files)
    Installer->>FS: Install new modules (overwrites)
    
    Note over Installer: Phase: _restoreUserFiles
    
    Installer->>TempBackup: Read custom files
    loop Each custom file
        Installer->>FS: Copy custom file back to bmadDir
        Note over FS: User's added files preserved
    end
    
    Installer->>TempMod: Read modified files
    loop Each modified file
        Installer->>FS: Check if new default differs from old default
        
        alt New default != old default (framework updated file)
            Installer->>Installer: Merge: prefer user mod if hash matches,<br/>else use new default
            Note over Installer: Logs "conflict" for manual resolution
        else Same defaults (user just modified)
            Installer->>FS: Restore user modification
        end
    end
    
    Installer->>FS: fs.remove(TempBackup)
    Installer->>FS: fs.remove(TempMod)
    
    Installer-->>Installer: { customFiles, modifiedFiles }
    
    Note over Installer: Show summary with preserved files list
```

### Decision table for restoration

| Situation | Action |
|-----------|--------|
| Custom file (not in manifest) | Always restore |
| Modified file, new default == old default | Restore user modification |
| Modified file, new default != old default (framework changed) | Restore user modification, log conflict |
| Modified file, user's content matches new default | Use new default (no conflict) |

---

## 9. Customization merge visualization

3-level skill customization + 4-level central config visualization.

```mermaid
flowchart TB
    subgraph Level1["🔒 Level 1: DEFAULT"]
        direction TB
        L1Shipped[shipped customize.toml]
        L1Content["""
        [agent]
        name = John
        title = PM
        icon = 📋
        role = base role
        principles = [P1, P2, P3]
        
        [[agent.menu]]
        code = CP
        skill = bmad-create-prd
        """]
    end
    
    subgraph Level2["👥 Level 2: TEAM"]
        direction TB
        L2File["_bmad/custom/bmad-agent-pm.toml<br/>(committed to git)"]
        L2Content["""
        [agent]
        icon = 🏥
        principles = [Healthcare-P1]
        
        [[agent.menu]]
        code = CP
        skill = bmad-create-prd-healthcare
        """]
    end
    
    subgraph Level3["👤 Level 3: USER"]
        direction TB
        L3File["_bmad/custom/bmad-agent-pm.user.toml<br/>(gitignored)"]
        L3Content["""
        [agent]
        communication_style = Vietnamese
        
        [[agent.menu]]
        code = NEW
        description = Personal shortcut
        skill = my-custom-skill
        """]
    end
    
    subgraph Merger["🔀 Resolver"]
        Step1[Load L1 → base]
        Step2[Deep merge L2 → merged1]
        Step3[Deep merge L3 → merged2]
        
        Step1 --> Step2
        Step2 --> Step3
    end
    
    subgraph Result["✅ Final Config"]
        direction TB
        FinalContent["""
        [agent]
        name = John                ← L1 (read-only)
        title = PM                  ← L1 (read-only)
        icon = 🏥                    ← L2 overrides
        role = base role            ← L1
        communication_style = Vietnamese  ← L3 overrides
        principles = [
          P1, P2, P3,                ← L1 (appended)
          Healthcare-P1              ← L2 (appended)
        ]
        
        [[agent.menu]]
        code = CP
        skill = bmad-create-prd-healthcare  ← L2 replaced by code
        
        [[agent.menu]]
        code = NEW
        description = Personal shortcut    ← L3 appended
        skill = my-custom-skill
        """]
    end
    
    Level1 --> Merger
    Level2 --> Merger
    Level3 --> Merger
    Merger --> Result
    
    classDef level1 fill:#e8f5e9,stroke:#2e7d32
    classDef level2 fill:#fff3e0,stroke:#ef6c00
    classDef level3 fill:#fce4ec,stroke:#c2185b
    classDef merger fill:#e1f5ff,stroke:#0277bd
    classDef result fill:#f3e5f5,stroke:#6a1b9a
    
    class Level1,L1Shipped,L1Content level1
    class Level2,L2File,L2Content level2
    class Level3,L3File,L3Content level3
    class Merger,Step1,Step2,Step3 merger
    class Result,FinalContent result
```

### Merge rules summary

| Input type | Rule |
|-----------|------|
| Scalars (icon, role) | Override replaces |
| Read-only (name, title) | Silent ignore override |
| Arrays (principles, persistent_facts) | Append |
| Arrays of tables with `code` field | Merge by code (replace or append) |
| Arrays of tables with `id` field | Merge by id |
| Mixed arrays | Append (fallback) |

---

## 10. package.json scripts dependency graph

Chain dependencies between npm scripts.

```mermaid
graph LR
    Quality[npm run quality]
    Test[npm run test]
    
    FormatCheck[format:check<br/>prettier]
    Lint[lint<br/>eslint]
    LintMD[lint:md<br/>markdownlint-cli2]
    DocsBuild[docs:build<br/>build-docs.mjs]
    TestInstall[test:install<br/>test-installation-components.js]
    TestRefs[test:refs<br/>test-file-refs-csv.js]
    ValidateRefs[validate:refs<br/>validate-file-refs.js]
    ValidateSkills[validate:skills<br/>validate-skills.js]
    
    Quality --> FormatCheck
    Quality --> Lint
    Quality --> LintMD
    Quality --> DocsBuild
    Quality --> TestInstall
    Quality --> ValidateRefs
    Quality --> ValidateSkills
    
    Test --> TestRefs
    Test --> TestInstall
    Test --> Lint
    Test --> LintMD
    Test --> FormatCheck
    
    BmadInstall[bmad:install<br/>bmad-cli.js install]
    BmadUninstall[bmad:uninstall<br/>bmad-cli.js uninstall]
    
    FormatFix[format:fix<br/>prettier --write]
    LintFix[lint:fix<br/>eslint --fix]
    
    DocsDev[docs:dev<br/>astro dev]
    DocsPreview[docs:preview<br/>astro preview]
    DocsFixLinks[docs:fix-links<br/>fix-doc-links.js]
    DocsValidateLinks[docs:validate-links<br/>validate-doc-links.js]
    
    DocsBuild -.-> DocsValidateLinks
    
    Rebundle[rebundle<br/>bundle-web.js rebundle]
    Prepare[prepare<br/>husky]
    
    FormatFixStaged[format:fix:staged<br/>prettier --write]
    
    classDef aggregate fill:#ffccbc,stroke:#d84315,font-weight:bold
    classDef check fill:#e3f2fd,stroke:#1976d2
    classDef fix fill:#c8e6c9,stroke:#388e3c
    classDef docs fill:#f3e5f5,stroke:#6a1b9a
    classDef install fill:#fff3e0,stroke:#f57c00
    classDef utility fill:#f5f5f5,stroke:#616161
    
    class Quality,Test aggregate
    class FormatCheck,Lint,LintMD,ValidateRefs,ValidateSkills,TestRefs,TestInstall check
    class FormatFix,LintFix,FormatFixStaged fix
    class DocsBuild,DocsDev,DocsPreview,DocsFixLinks,DocsValidateLinks docs
    class BmadInstall,BmadUninstall install
    class Rebundle,Prepare utility
```

### CI workflow

```mermaid
flowchart LR
    PR[Pull Request]
    Check[.github/workflows/quality.yaml]
    
    NpmCi[npm ci]
    NpmQuality[npm run quality]
    
    PR --> Check
    Check --> NpmCi
    NpmCi --> NpmQuality
    
    NpmQuality --> Pass{All pass?}
    
    Pass -->|Yes| MergeReady[✅ Ready to merge]
    Pass -->|No| RequestFix[❌ Request fixes]
    
    classDef trigger fill:#fff3e0
    classDef action fill:#e3f2fd
    classDef result fill:#c8e6c9
    classDef fail fill:#ffcdd2
    
    class PR trigger
    class NpmCi,NpmQuality,Check action
    class MergeReady result
    class RequestFix fail
```

---

## Summary

10 maintainer-focused diagrams sufficient to:
- Debug install/update failures (diagrams 1, 2, 8)
- Implement resolver (diagram 3)
- Debug/extend validator (diagram 4)
- Add new IDE support (diagram 5)
- Handle external module issues (diagram 6)
- Understand skill invocation (diagram 7)
- Extend customization system (diagram 9)
- CI/CD pipeline (diagram 10)

**In total, the project has:**
- 16 user-facing diagrams (file 05)
- 10 maintainer diagrams (this file)
- Type variety: state, sequence, class, flowchart, graph

---

**Read next:** [11-testing-and-quality.md](11-testing-and-quality.md) — Testing infrastructure + quality metrics.
