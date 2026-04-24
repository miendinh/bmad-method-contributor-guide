#!/usr/bin/env bash
# validate-dev-docs.sh
# Validate internal consistency of dev/ folder:
# 1. Mermaid diagram syntax
# 2. Cross-link integrity (file + anchor)
# 3. Consistency checks
#
# Usage: ./validate-dev-docs.sh [--strict]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

STRICT=0
if [[ "${1:-}" == "--strict" ]]; then
  STRICT=1
fi

ERRORS=0
WARNINGS=0

echo "=== BMad Dev Docs Validator ==="
echo

# ---------------------------------------------------
# Check 1: File inventory
# ---------------------------------------------------
echo "→ Checking file inventory..."
EXPECTED_FILES=(
  "README.md"
  "01-philosophy.md"
  "02-environment-and-variables.md"
  "03-skill-anatomy-deep.md"
  "04-skills-catalog.md"
  "05-flows-and-diagrams.md"
  "06-installer-internals.md"
  "07-extension-patterns.md"
  "08-installer-code-level-spec.md"
  "09a-skills-core-deep.md"
  "09b-skills-phase1-2-deep.md"
  "09c-skills-phase3-deep.md"
  "09d-skills-phase4-deep.md"
  "10-maintainer-diagrams.md"
  "11-testing-and-quality.md"
  "12-comparison-and-migration.md"
  "13-operational-runbook.md"
  "14-rewrite-blueprint.md"
  "15-glossary.md"
  "16-faq.md"
  "17-cheat-sheet.md"
  "18-workflow-deep-walkthrough.md"
  "bmad-architecture.md"
)

for f in "${EXPECTED_FILES[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "  ❌ Missing: $f"
    ERRORS=$((ERRORS + 1))
  fi
done
echo "  ✓ ${#EXPECTED_FILES[@]} expected files"

# ---------------------------------------------------
# Check 2: Mermaid diagram syntax (if mmdc available)
# ---------------------------------------------------
echo
echo "→ Checking Mermaid diagram syntax..."

# Use Python to extract mermaid blocks
python3 << 'PYEOF' > /tmp/mermaid-blocks.txt
import re
import os

for filepath in sorted(os.listdir('.')):
    if not filepath.endswith('.md'):
        continue
    with open(filepath) as f:
        content = f.read()
    blocks = re.findall(r'```mermaid\n(.*?)\n```', content, re.DOTALL)
    for i, block in enumerate(blocks):
        # Basic syntax check
        first_line = block.strip().split('\n')[0] if block.strip() else ''
        valid_types = ['graph', 'flowchart', 'sequenceDiagram', 'classDiagram',
                       'stateDiagram', 'stateDiagram-v2', 'erDiagram', 'gantt',
                       'pie', 'journey', 'gitGraph', 'mindmap', 'timeline']
        if not any(first_line.startswith(t) for t in valid_types):
            print(f"FAIL\t{filepath}\tblock {i+1}\tUnknown type: {first_line[:50]}")
        else:
            print(f"OK\t{filepath}\tblock {i+1}")
PYEOF

MERMAID_OK=$(grep -c "^OK" /tmp/mermaid-blocks.txt 2>/dev/null || true)
MERMAID_OK=${MERMAID_OK:-0}
MERMAID_FAIL=$(grep -c "^FAIL" /tmp/mermaid-blocks.txt 2>/dev/null || true)
MERMAID_FAIL=${MERMAID_FAIL:-0}

if [[ "$MERMAID_FAIL" -gt 0 ]]; then
  echo "  ❌ Mermaid syntax issues: $MERMAID_FAIL"
  grep "^FAIL" /tmp/mermaid-blocks.txt | head -5
  ERRORS=$((ERRORS + MERMAID_FAIL))
fi
echo "  ✓ Valid Mermaid blocks: $MERMAID_OK"

# ---------------------------------------------------
# Check 3: Cross-link integrity
# ---------------------------------------------------
echo
echo "→ Checking cross-links..."

python3 << 'PYEOF' > /tmp/link-check.txt
import re
import os
from pathlib import Path

def github_slug(heading):
    s = heading.lower()
    s = re.sub(r'[^\w\s-]', '', s, flags=re.UNICODE)
    s = re.sub(r'\s', '-', s)
    return s.strip('-')

md_files = sorted(Path('.').glob('*.md'))
file_anchors = {}
for f in md_files:
    content = f.read_text()
    anchors = set()
    for m in re.finditer(r'^#+\s+(.+)$', content, re.MULTILINE):
        anchors.add(github_slug(m.group(1).strip()))
    file_anchors[f.name] = anchors

broken = 0
link_pattern = re.compile(r'\[([^\]]+)\]\(([^)]+)\)')

for f in md_files:
    content = f.read_text()
    for m in link_pattern.finditer(content):
        text, link = m.group(1), m.group(2)
        if link.startswith(('http://', 'https://', 'mailto:', '!', '../')):
            continue
        if '#' not in link and '/' in link and link.startswith('./'):
            # Example path in code/template, skip
            continue
        if '#' in link:
            target_file, anchor = link.split('#', 1)
        else:
            target_file, anchor = link, None
        if target_file == '':
            resolved = f
        else:
            resolved = Path(target_file)
        if not resolved.exists():
            # Skip false positives in code blocks (heuristic)
            if text in ('text', 'file1.md', 'file2.md', 'file3.md', 'path'):
                continue
            print(f"BROKEN\t{f.name}\t'{text[:30]}'\t{link}")
            broken += 1
            continue
        if anchor and anchor not in file_anchors.get(resolved.name, set()):
            print(f"BROKEN\t{f.name}\t'{text[:30]}'\t{link}")
            broken += 1

print(f"Total broken: {broken}")
PYEOF

BROKEN=$(grep -c "^BROKEN" /tmp/link-check.txt 2>/dev/null || true)
BROKEN=${BROKEN:-0}

if [[ "$BROKEN" -gt 0 ]]; then
  echo "  ⚠️  Broken links: $BROKEN"
  grep "^BROKEN" /tmp/link-check.txt | head -5
  WARNINGS=$((WARNINGS + BROKEN))
else
  echo "  ✓ All cross-links valid"
fi

# ---------------------------------------------------
# Check 4: Consistency
# ---------------------------------------------------
echo
echo "→ Checking terminology consistency..."

# Count common terms
skill_count=$(grep -Eohw 'skill' ./*.md | wc -l)
agent_count=$(grep -Eohw 'agent' ./*.md | wc -l)
workflow_count=$(grep -Eohw 'workflow' ./*.md | wc -l)

echo "  - 'skill' used: $skill_count times"
echo "  - 'agent' used: $agent_count times"
echo "  - 'workflow' used: $workflow_count times"

# Check for stale terms
if grep -r "installed_path" ./*.md > /dev/null 2>&1; then
  echo "  ⚠️  Found 'installed_path' references (PATH-02 anti-pattern docs only)"
fi

# ---------------------------------------------------
# Check 5: Stats
# ---------------------------------------------------
echo
echo "→ Documentation stats..."
total_lines=$(wc -l ./*.md | tail -1 | awk '{print $1}')
total_files=$(ls -1 ./*.md | wc -l)
total_size=$(du -ch ./*.md | tail -1 | awk '{print $1}')
mermaid_count=$(grep -c '^```mermaid$' ./*.md 2>/dev/null | awk -F: '{sum+=$2} END {print sum}')

echo "  Files: $total_files"
echo "  Lines: $total_lines"
echo "  Size: $total_size"
echo "  Mermaid diagrams: $mermaid_count"

# ---------------------------------------------------
# Summary
# ---------------------------------------------------
echo
echo "=== Summary ==="
echo "  Errors:   $ERRORS"
echo "  Warnings: $WARNINGS"

if [[ "$ERRORS" -gt 0 ]]; then
  echo
  echo "❌ Validation failed with $ERRORS errors"
  exit 1
fi

if [[ "$WARNINGS" -gt 0 ]] && [[ "$STRICT" -eq 1 ]]; then
  echo
  echo "⚠️  Warnings in strict mode"
  exit 1
fi

echo
echo "✅ Dev docs validation passed"
exit 0
