#!/usr/bin/env bash
# Structural checks for the hello-interview-system-design plugin. Exits 1 if any check fails.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SK="$ROOT/skills/hello-interview-system-design"
REF="$SK/reference"
fails=0

pass() { printf 'PASS  %s\n' "$1"; }
fail() { printf 'FAIL  %s\n' "$1"; fails=$((fails+1)); }
check() { local name="$1"; shift; if "$@" >/dev/null 2>&1; then pass "$name"; else fail "$name"; fi; }
has() { grep -qF -- "$2" "$1"; }
lacks() { ! grep -rqE -- "$2" "$1"; }
# Each literal must appear, and first occurrences must be in the given order.
in_order() {
  local file="$1"; shift; local last=0 n
  for h in "$@"; do
    n=$(grep -nF -- "$h" "$file" | head -1 | cut -d: -f1)
    [ -n "$n" ] && [ "$n" -gt "$last" ] || return 1
    last=$n
  done
}
min_rows() { [ "$(grep -cE '^\| .* \| `[a-z0-9-]+` \|' "$1")" -ge "$2" ]; }
command -v jq >/dev/null || { echo "jq is required"; exit 2; }

# Manifests
check "marketplace.json lists ./" jq -e '.plugins[0].source == "./" and .plugins[0].name == "hello-interview-system-design"' "$ROOT/.claude-plugin/marketplace.json"
check "plugin.json name" jq -e '.name == "hello-interview-system-design"' "$ROOT/.claude-plugin/plugin.json"

# Router
check "SKILL.md name" grep -q '^name: hello-interview-system-design$' "$SK/SKILL.md"
check "SKILL.md only claude.ai frontmatter keys" bash -c "! awk '/^---$/{n++; next} n==1 && /^[a-z-]+:/' \"$SK/SKILL.md\" | cut -d: -f1 | grep -vxE 'name|description|license|allowed-tools|metadata|compatibility'"
check "SKILL.md runs.md row format" has "$SK/SKILL.md" '<nav>,<design>,<tech>,<comms> | <verdict> | <next>'
check "SKILL.md slug rule" has "$SK/SKILL.md" "### Slugs"
for f in framework rubric patterns topics diagrams mock learn postmortem generate; do
  check "reference/$f.md exists" test -s "$REF/$f.md"
  check "SKILL.md links $f.md" has "$SK/SKILL.md" "(reference/$f.md)"
done

# framework.md
check "framework phases in order" in_order "$REF/framework.md" "## 1. Requirements" "## 2. Core Entities" "## 3. API" "## 4. Data Flow" "## 5. High-Level Design" "## 6. Deep Dives" "## Anti-patterns"
for i in 1 2 3 4 5 6 7 8; do check "framework AP$i" grep -q "^\*\*AP$i " "$REF/framework.md"; done

# rubric.md
for t in "Problem Navigation" "Solution Design" "Technical Excellence" "Communication & Collaboration"; do check "rubric theme: $t" has "$REF/rubric.md" "$t"; done
check "rubric levels in order" in_order "$REF/rubric.md" "### mid" "### senior" "### staff"
for v in "**hire**" "**lean hire**" "**lean no hire**" "**no hire**"; do check "rubric verdict $v" has "$REF/rubric.md" "$v"; done
check "rubric verdict is first-match" has "$REF/rubric.md" "the first match decides"

# patterns.md / topics.md / diagrams.md
check "patterns has 8 patterns" test "$(grep -c '^## Pattern: ' "$REF/patterns.md")" -eq 8
for r in Bad Good Great; do check "patterns: 8 $r rungs" test "$(grep -c "^- \*\*$r:\*\*" "$REF/patterns.md")" -eq 8; done
check "topics has >=24 rows" min_rows "$REF/topics.md" 24
check "diagrams has HLD template" has "$REF/diagrams.md" "## High-level design"

# Modes
check "mock: debrief parts" in_order "$REF/mock.md" "## Debrief" "Theme scores" "Verdict" "Deep dives" "Anti-patterns hit" "Phase timing" "Next"
check "mock: writes runs.md" has "$REF/mock.md" "<nav>,<design>,<tech>,<comms>"
check "mock: pause escape" has "$REF/mock.md" '`pause`'
check "mock: cites APs" has "$REF/mock.md" "AP1"
check "learn: HI answer order" in_order "$REF/learn.md" "1. **Requirements**" "2. **Core Entities**" "3. **API**" "5. **High-Level Design**" "6. **Deep Dives**"
check "learn: subagents get file paths" has "$REF/learn.md" "absolute paths"
check "learn: --auto loop" has "$REF/learn.md" "ENDING:"
check "learn: no state writes" has "$REF/learn.md" "Never write to"
check "postmortem: one or two questions" has "$REF/postmortem.md" "one or two"
check "postmortem: writes runs.md" has "$REF/postmortem.md" "<nav>,<design>,<tech>,<comms>"
check "generate: breakdown order" in_order "$REF/generate.md" "## Understanding the Problem" "## The Set Up" "## High-Level Design" "## Potential Deep Dives" "## Final Design" "## What is Expected at Each Level?"
check "generate: Bad/Good/Great" in_order "$REF/generate.md" "Bad Solution" "Good Solution" "Great Solution"
check "generate: no overwrite" has "$REF/generate.md" "<slug>-2"

# Hygiene
check "no placeholders" lacks "$SK" 'TODO|TBD|FIXME'
check "no dropped flags" lacks "$SK" '--say|--direction'
check "no old command name" lacks "$SK" '/system-design|\$system-design'

echo
if [ "$fails" -gt 0 ]; then echo "$fails check(s) failed"; exit 1; fi
echo "All checks passed"
