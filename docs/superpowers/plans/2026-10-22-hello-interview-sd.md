# hello-interview-sd Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Claude Code plugin, `/hello-interview`, that runs system design practice (mock, learn, postmortem, generate) following the Hello Interview method exactly.

**Architecture:** A local marketplace repo wrapping one plugin with one skill. `SKILL.md` routes on the first argument and loads one mode file from `reference/`. Shared method files (`framework.md`, `rubric.md`, `patterns.md`, `topics.md`, `diagrams.md`) are loaded on demand. Progress is kept in `~/.hello-interview/`. The plugin is all Markdown plus JSON manifests. Correctness is checked by a structural check script (`scripts/check.sh`) and then by running each mode.

**Tech Stack:** Claude Code plugin format (marketplace.json, plugin.json, SKILL.md), Markdown, bash + jq for checks.

**Spec:** `docs/superpowers/specs/2026-10-22-hello-interview-sd-design.md`

**Rules for every task:**
- Write all prose fresh. Never copy text from `~/.claude/plugins/marketplaces/system-design/` (no license) or from hellointerview.com (copyrighted). Problem *names* are fine.
- Work in `/Users/raphaelkwek/GitHub/hello-interview-sd`. All paths below are relative to it.
- Commit messages end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

---

## File map

| File | Responsibility |
|---|---|
| `.claude-plugin/marketplace.json` | Local marketplace listing the one plugin |
| `plugin/.claude-plugin/plugin.json` | Plugin manifest |
| `plugin/skills/hello-interview/SKILL.md` | Router, setup, state format, flags, shared don'ts |
| `plugin/skills/hello-interview/reference/framework.md` | HI phases, rules per phase, anti-patterns AP1–AP8 |
| `plugin/skills/hello-interview/reference/rubric.md` | 4 themes, score anchors, level calibration, verdict rule |
| `plugin/skills/hello-interview/reference/patterns.md` | Recurring patterns as Bad/Good/Great ladders + key technologies |
| `plugin/skills/hello-interview/reference/topics.md` | Problem catalog with slugs, levels, patterns |
| `plugin/skills/hello-interview/reference/diagrams.md` | ASCII templates |
| `plugin/skills/hello-interview/reference/mock.md` | Mock mode |
| `plugin/skills/hello-interview/reference/learn.md` | Learn mode + `--auto` |
| `plugin/skills/hello-interview/reference/postmortem.md` | Postmortem mode |
| `plugin/skills/hello-interview/reference/generate.md` | Generate mode + breakdown template |
| `scripts/check.sh` | Structural checks (the "test suite") |
| `README.md` | Install and usage |

---

### Task 1: Check script and manifests

**Files:**
- Create: `scripts/check.sh`
- Create: `.claude-plugin/marketplace.json`
- Create: `plugin/.claude-plugin/plugin.json`

- [ ] **Step 1: Write the check script (the failing test)**

Create `scripts/check.sh`:

```bash
#!/usr/bin/env bash
# Structural checks for the hello-interview-sd plugin. Exits 1 if any check fails.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SK="$ROOT/plugin/skills/hello-interview"
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

# Manifests
check "marketplace.json lists ./plugin" jq -e '.plugins[0].source == "./plugin" and .plugins[0].name == "hello-interview-sd"' "$ROOT/.claude-plugin/marketplace.json"
check "plugin.json name + skills dir" jq -e '.name == "hello-interview-sd" and .skills == "./skills/"' "$ROOT/plugin/.claude-plugin/plugin.json"

# Router
check "SKILL.md name" grep -q '^name: hello-interview$' "$SK/SKILL.md"
check "SKILL.md user-invocable" grep -q '^user-invocable: true$' "$SK/SKILL.md"
check "SKILL.md runs.md row format" has "$SK/SKILL.md" '<nav>,<design>,<tech>,<comms> | <verdict> | <next>'
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

# patterns.md / topics.md / diagrams.md
check "patterns has 8 patterns" test "$(grep -c '^## Pattern: ' "$REF/patterns.md")" -eq 8
check "patterns ladders" has "$REF/patterns.md" "**Great:**"
check "topics has >=24 rows" min_rows "$REF/topics.md" 24
check "diagrams has HLD template" has "$REF/diagrams.md" "## High-level design"

# Modes
check "mock: debrief parts" in_order "$REF/mock.md" "## Debrief" "Theme scores" "Verdict" "Deep dives" "Phase timing" "Next"
check "mock: writes runs.md" has "$REF/mock.md" "<nav>,<design>,<tech>,<comms>"
check "mock: pause escape" has "$REF/mock.md" '`pause`'
check "mock: cites APs" has "$REF/mock.md" "AP1"
check "learn: HI answer order" in_order "$REF/learn.md" "Requirements" "Core Entities" "API" "High-Level Design" "Deep Dives"
check "learn: --auto loop" has "$REF/learn.md" "ENDING:"
check "learn: no state writes" has "$REF/learn.md" "Never write to"
check "postmortem: one or two questions" has "$REF/postmortem.md" "one or two"
check "postmortem: writes runs.md" has "$REF/postmortem.md" "<nav>,<design>,<tech>,<comms>"
check "generate: breakdown order" in_order "$REF/generate.md" "## Understanding the Problem" "## The Set Up" "## High-Level Design" "## Potential Deep Dives" "## Final Design" "## What is Expected at Each Level?"
check "generate: Bad/Good/Great" in_order "$REF/generate.md" "Bad Solution" "Good Solution" "Great Solution"
check "generate: no overwrite" has "$REF/generate.md" "-2"

# Hygiene
check "no placeholders" lacks "$SK" 'TODO|TBD|FIXME'
check "no dropped flags" lacks "$SK" '--say|--direction'
check "no old command name" lacks "$SK" '/system-design|\$system-design'

echo
if [ "$fails" -gt 0 ]; then echo "$fails check(s) failed"; exit 1; fi
echo "All checks passed"
```

Then: `chmod +x scripts/check.sh`

- [ ] **Step 2: Run it to verify it fails**

Run: `scripts/check.sh | tail -3`
Expected: many FAIL lines, last line `N check(s) failed`, exit code 1.

- [ ] **Step 3: Write the manifests**

`.claude-plugin/marketplace.json`:

```json
{
  "$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
  "name": "hello-interview-sd",
  "metadata": {
    "description": "System design interview practice in the Hello Interview style."
  },
  "owner": { "name": "Raphael Kwek" },
  "plugins": [
    {
      "name": "hello-interview-sd",
      "description": "Mock, learn, postmortem and generate modes that follow the Hello Interview delivery framework and rubric.",
      "version": "0.1.0",
      "source": "./plugin",
      "category": "productivity",
      "tags": ["system-design", "interview", "hello-interview"]
    }
  ]
}
```

`plugin/.claude-plugin/plugin.json`:

```json
{
  "name": "hello-interview-sd",
  "description": "System design interview practice in the Hello Interview style: mock, learn, postmortem, generate.",
  "version": "0.1.0",
  "author": { "name": "Raphael Kwek" },
  "skills": "./skills/"
}
```

- [ ] **Step 4: Run checks**

Run: `scripts/check.sh | head -2`
Expected: both manifest lines `PASS`.

- [ ] **Step 5: Commit**

```bash
git add scripts/check.sh .claude-plugin plugin/.claude-plugin
git commit -m "Add structural check script and plugin manifests"
```

---

### Task 2: SKILL.md router

**Files:**
- Create: `plugin/skills/hello-interview/SKILL.md`

- [ ] **Step 1: Confirm router checks fail**

Run: `scripts/check.sh | grep SKILL`
Expected: all `SKILL.md ...` lines `FAIL`.

- [ ] **Step 2: Write SKILL.md**

````markdown
---
name: hello-interview
description: "Practise system design interviews the Hello Interview way: Requirements, Core Entities, API, (Data Flow), High-Level Design, Deep Dives; graded on Problem Navigation, Solution Design, Technical Excellence, and Communication & Collaboration at mid, senior or staff level. Modes: `mock` (Claude interviews you, ends with scores and a hire verdict), `learn` (Claude answers as the candidate; `--auto` runs interviewer and candidate subagents while you watch), `postmortem` (diagnose a real interview), `generate` (write a practice question plus an HI-style breakdown). Use when the user runs /hello-interview or asks for Hello Interview–style system design practice."
argument-hint: "<mock|learn|postmortem|generate> [problem] [--level=mid|senior|staff] [--auto] [--exchanges=N] [--file=path]"
user-invocable: true
---

# Hello Interview system design practice

Every mode follows one method: [reference/framework.md](reference/framework.md). Read it at the start of every invocation, before the mode file.

## Modes

| `$1` | What happens | Mode file |
|---|---|---|
| `mock [problem]` | Claude interviews you, enforces the phases, then debriefs with scores and a verdict. | [reference/mock.md](reference/mock.md) |
| `learn [problem] [--auto]` | You interview Claude, who answers as a candidate at your level. `--auto` runs both sides as subagents. | [reference/learn.md](reference/learn.md) |
| `postmortem [--file=path]` | Diagnose a real interview you already did. | [reference/postmortem.md](reference/postmortem.md) |
| `generate [topic]` | Write a practice question and its breakdown to `./hello-interview-questions/<slug>/`. | [reference/generate.md](reference/generate.md) |

## Routing

1. No argument: show the table above and ask which mode and problem. Don't guess.
2. First word is a mode: run Setup, read `framework.md`, then follow the mode file. Everything after `$1` is the problem text and flags.
3. First word is anything else: ask. Don't guess.

## Setup (every invocation)

1. **Level.** `--level=<mid|senior|staff>` wins. Otherwise read `~/.hello-interview/level.md` (one token). Otherwise `senior`. Any other value: ask which level they meant.
2. **State.** Read `~/.hello-interview/runs.md` and `~/.hello-interview/weaknesses.md`. A missing file is empty, not an error.
3. **Flags.**

| Flag | Modes | Default |
|---|---|---|
| `--level=<mid\|senior\|staff>` | all | `level.md`, else `senior` |
| `--auto` | `learn` | off |
| `--exchanges=<N>` | `learn --auto` | `30` |
| `--file=<path>` | `postmortem` | none |

## State

Directory: `~/.hello-interview/`. Create it on first write. Only `mock` and `postmortem` write state.

`runs.md`: one line per scored session:

```
YYYY-MM-DD | <slug> | <mode> | <level> | <nav>,<design>,<tech>,<comms> | <verdict> | <next>
```

- Scores are integers 1–5 in theme order: Problem Navigation, Solution Design, Technical Excellence, Communication & Collaboration.
- `<verdict>` is one of `hire`, `lean hire`, `lean no hire`, `no hire`.
- `<next>` is one concrete drill of at most 80 characters (e.g. "quantify every NFR; name the call and the number"), or empty. Keep the trailing `|` either way.

`weaknesses.md`: one line per theme scored 3 or lower:

```
YYYY-MM-DD | <slug> | <theme> | <one-line context quoting the candidate>
```

`level.md`: a single token the user writes. The skill only reads it.

### Preamble (`mock` and `postmortem`)

If `runs.md` has at least 2 rows at the resolved level, show before starting:

1. Sessions at this level: count.
2. Recurring weak themes: any theme scored 3 or lower in at least half of the last 4 sessions at this level. If none: "No recurring weak themes. Pick something new."
3. Last 3 slugs at this level, newest first.
4. `Last drill: <next>` from the newest row at this level, if non-empty.

Fewer than 2 rows: skip silently.

## Reference files (load on demand)

| File | Load when |
|---|---|
| [reference/framework.md](reference/framework.md) | Every invocation. |
| [reference/rubric.md](reference/rubric.md) | `mock` debrief, `postmortem`, the `learn --auto` observer, `generate`. |
| [reference/patterns.md](reference/patterns.md) | Debrief or postmortem when Technical Excellence is 3 or lower; any deep dive in `learn` or `generate`. |
| [reference/topics.md](reference/topics.md) | `mock`, `learn` or `generate` with no problem given. |
| [reference/diagrams.md](reference/diagrams.md) | Claude is the candidate (`learn`), writing a breakdown (`generate`), or illustrating a fix (`postmortem`). Never in `mock`. |

## Don'ts (all modes)

- Don't volunteer architecture during `mock`. Coaching belongs in the debrief.
- Don't write transcripts to state files.
- Don't write state from `learn` or `generate`.
- Don't overwrite an existing `generate` folder.
- Don't ask more than two postmortem questions at once.
- Don't copy Hello Interview's text. The method is theirs; the words are ours.
````

- [ ] **Step 3: Run checks**

Run: `scripts/check.sh | grep 'SKILL.md'`
Expected: all `SKILL.md ...` lines `PASS` (the `reference/*.md exists` lines still FAIL).

- [ ] **Step 4: Commit**

```bash
git add plugin/skills/hello-interview/SKILL.md
git commit -m "Add hello-interview router skill"
```

---

### Task 3: framework.md

**Files:**
- Create: `plugin/skills/hello-interview/reference/framework.md`

- [ ] **Step 1: Write framework.md**

````markdown
# The method

Six phases, in this order, in about 45 minutes. The goal of the first 30 minutes is a **working** system that meets the functional requirements. The last 15 make it meet the non-functional ones. Running out of time before having a working design is the most common way to fail.

| Phase | Target |
|---|---|
| 1. Requirements | ~5 min |
| 2. Core Entities | ~2 min |
| 3. API | ~5 min |
| 4. Data Flow (optional) | ~5 min |
| 5. High-Level Design | ~10–15 min |
| 6. Deep Dives | ~10 min |

## 1. Requirements

**Functional.** Write each one as "Users should be able to …". Ask product questions to find the core, then commit to about three. A long list signals poor prioritisation.

**Below the line.** List what is explicitly out of scope ("Below the line: analytics, admin tools, …") in one line each. This shows you saw them and chose not to build them.

**Non-functional.** Write each one as "The system should …". Pick three to five that matter for *this* system, from: consistency vs availability (and where), scale and read:write ratio, latency, durability, fault tolerance, security, compliance, environment constraints. Each must have a number and a scope. "Low latency" is not a requirement. "Redirects return in under 100 ms at p99" is.

**Capacity estimates.** Skip them up front. Say so: "I'll skip estimates for now and do the math where it changes a decision." Do the math later, at the point where a number picks between two designs (e.g. whether a counter fits on one node).

## 2. Core Entities

A short bulleted list of the nouns the functional requirements touch, plus the actors. Good names, one line each. No columns or types yet. Fields get added as the design needs them.

## 3. API

- One endpoint (or small group) per functional requirement.
- REST by default. GraphQL only if clients need very different shapes of data; gRPC only for internal, latency-sensitive service-to-service calls. State the reason if you leave REST.
- Plural resource names: `POST /events/{id}/bookings`, not `POST /bookEvent`.
- The current user comes from the auth token in a header. Never put `userId` in the body or path for the caller's own identity.
- Real-time channels (WebSocket, SSE) come after the core endpoints, and only if a requirement needs push.

## 4. Data Flow

Only for systems that are a pipeline (crawlers, ETL, ad-click aggregation). A numbered list of steps from input to output. It becomes the spine of the high-level design. Skip it otherwise and say so.

## 5. High-Level Design

- Go one functional requirement (or one endpoint) at a time. For each: draw the boxes it needs, then walk a request through them from client to storage and back, saying what state changes.
- Start simple: client, API gateway or load balancer, a service, a database. Add a component only when the current requirement needs it.
- When you see where a cache, queue or shard will be needed, say so in one sentence and keep going: "This read path will want a cache. I'll come back to it in the deep dives."
- Next to each database, write only the fields that matter to the design (keys, indexes, status columns). Skip obvious fields like `name` and `email`.
- By the end of this phase every functional requirement has a path through the diagram.

## 6. Deep Dives

- Each deep dive exists to meet a non-functional requirement, remove a bottleneck, or handle a failure. Say which one: "To hit 100 ms redirects at 10k RPS, let's look at the read path."
- Present answers as a ladder: the naive approach and why it fails, then a better one, then the best one and its costs. `patterns.md` has ladders for the common problems.
- Do math here, when a number decides between options.
- Leave space for the interviewer. They often probe for a specific signal; answering their question beats finishing your own monologue.
- How much the candidate drives depends on level. See `rubric.md`.

## Anti-patterns

Each has an ID that `mock` and `postmortem` cite.

**AP1 Too many functional requirements.** More than four, or no stated priority. Fix: commit to the top three and move the rest below the line.

**AP2 Vague non-functional requirements.** "Scalable", "low latency", "highly available" with no number or scope. Fix: a number, a percentile where relevant, and which part of the system it applies to.

**AP3 Math that changes nothing.** Minutes of DAU, QPS and storage arithmetic up front that no later decision uses. Fix: skip it and estimate only at the decision point.

**AP4 Boxes before entities and API.** Drawing architecture before naming entities and endpoints. Fix: go back and do phases 2 and 3; the design hangs off them.

**AP5 Scale in the first pass.** Sharding, caches, queues or replicas in the high-level design before a requirement forces them. Fix: name them verbally and defer to deep dives.

**AP6 Caller identity in the request.** `userId` in the body or path for the person making the call. Fix: derive it from the auth token.

**AP7 Deep dive with no reason.** Diving into a component without tying it to a non-functional requirement or a failure. Fix: state which requirement the dive serves.

**AP8 No room for the interviewer.** Long monologues, ignoring or talking over a probe. Fix: pause at decision points and answer the question asked.
````

- [ ] **Step 2: Run checks**

Run: `scripts/check.sh | grep framework`
Expected: all framework lines `PASS`, including AP1–AP8.

- [ ] **Step 3: Commit**

```bash
git add plugin/skills/hello-interview/reference/framework.md
git commit -m "Add HI delivery framework reference"
```

---

### Task 4: rubric.md

**Files:**
- Create: `plugin/skills/hello-interview/reference/rubric.md`

- [ ] **Step 1: Write rubric.md**

````markdown
# Rubric

Four themes, each scored 1–5. Every score gets one line of justification that quotes or closely paraphrases something the candidate said or did.

## Themes

**Problem Navigation**: breaking an open problem into parts, choosing the important ones, and spending time where it matters. Evidence: prioritised functional requirements, a below-the-line list, quantified NFRs, keeping to phase times, picking the right deep dives.

**Solution Design**: a design that works end to end for every functional requirement, then holds up against the NFRs. Evidence: each requirement has a path through the diagram, components are justified, the design changes sensibly under pushback.

**Technical Excellence**: correct, specific use of technology and depth when pushed. Evidence: deep-dive answers at Good or Great on the ladder, real numbers at decision points, knowing failure modes, choosing the right pattern from `patterns.md`.

**Communication & Collaboration**: clear structure, thinking aloud at the right density, answering what was asked, taking hints. Evidence: signposting phases, pausing at decision points, adapting after a probe (see AP8).

## Score anchors

| Score | Meaning |
|---|---|
| 5 | Above the bar for this level; would stand out. |
| 4 | Solidly at the bar for this level. |
| 3 | Mixed: some signal at the bar, some gaps. |
| 2 | Below the bar; clear gaps the interviewer had to work around. |
| 1 | Little or no signal. |

Scores are relative to the resolved level. The same answer can be a 4 at mid and a 2 at staff.

## Levels

Breadth matters most at mid. Depth and how much the candidate drives rise with level.

### mid

- Covers every phase and finishes with a working high-level design.
- Knows what each named component does and why it's there; expect "what does that gateway do?"
- Depth can be conceptual. Deep-dive answers at Good are enough.
- The interviewer drives the deep dives and may redirect.

### senior

- Fundamentals are assumed; time goes to depth.
- Goes deep in about two areas with specifics (key design, index choice, consistency setting, failure handling), ideally from experience.
- Spots what makes this problem hard early and names weaknesses in their own design before being asked.
- Proposes the deep dives; the interviewer steers only if a critical one is missed. Deep-dive answers should reach Great on at least one.

### staff

- Runs nearly the whole session as a peer.
- Depth across several areas and can teach the interviewer something; may bring in less common tools with a clear reason.
- Anticipates problems, second-order effects and operational costs before they are raised.
- Deep-dive answers at Great by default, with tradeoffs stated.

## Verdict

One of: hire, lean hire, lean no hire, no hire, judged at the resolved level.

1. Any theme at 2 or lower: at most **lean no hire**. Any theme at 1: **no hire**.
2. All four themes at 4 or higher: **hire**.
3. Otherwise: **lean hire** if Problem Navigation and Solution Design are both at least 4, else **lean no hire**.

State the rule that decided it in one line.
````

- [ ] **Step 2: Run checks**

Run: `scripts/check.sh | grep rubric`
Expected: all rubric lines `PASS`.

- [ ] **Step 3: Commit**

```bash
git add plugin/skills/hello-interview/reference/rubric.md
git commit -m "Add HI rubric with level calibration and verdict rule"
```

---

### Task 5: patterns.md and diagrams.md

**Files:**
- Create: `plugin/skills/hello-interview/reference/patterns.md`
- Create: `plugin/skills/hello-interview/reference/diagrams.md`

- [ ] **Step 1: Write patterns.md**

````markdown
# Patterns

Problems that recur across questions, each as a Bad / Good / Great ladder. Cite them by section name in debriefs ("see patterns.md, Pattern: Dealing with Contention"). Ladders are starting points; the right rung depends on the stated NFRs.

## Pattern: Real-time Updates

When: clients must see changes within seconds (chat, live scores, ride location).
- **Bad:** clients poll every second. Wasteful at scale, latency equals the poll interval.
- **Good:** long polling or SSE for server-to-client push; WebSockets when both directions are frequent.
- **Great:** persistent connections on a connection tier, plus pub/sub (Redis pub/sub, Kafka) so whichever server holds the recipient's connection gets the event. Covers reconnects and fan-out.

## Pattern: Dealing with Contention

When: many users compete for one resource (last ticket, seat, inventory, auction).
- **Bad:** read, check, write with no locking. Double-booking.
- **Good:** a database transaction with row locks (`SELECT … FOR UPDATE`) or optimistic concurrency with a version column.
- **Great:** a short-lived reservation (distributed lock in Redis with TTL, or a `reserved_until` status) so holding a seat doesn't hold a DB lock; plus a virtual waiting queue for extreme spikes.

## Pattern: Multi-step Processes

When: a request spans several services or steps that must all complete or be compensated (payments, order fulfilment, ride matching).
- **Bad:** one service calls the others synchronously in sequence; a crash midway leaves partial state.
- **Good:** event-driven steps over a durable queue with idempotent consumers and a saga with compensating actions.
- **Great:** a durable workflow engine (Temporal, AWS Step Functions) that persists progress, retries and timeouts per step.

## Pattern: Scaling Reads

When: reads far outnumber writes (feeds, profiles, URL redirects).
- **Bad:** every read hits the primary database.
- **Good:** indexes, then read replicas, then a cache-aside layer (Redis) for hot keys.
- **Great:** cache plus CDN for public content, precomputed views (e.g. fan-out-on-write feeds) for expensive reads, and a plan for hot keys (replicating hot entries, request coalescing).

## Pattern: Scaling Writes

When: write volume exceeds one node (likes, metrics, location pings, click events).
- **Bad:** a single database taking every write.
- **Good:** shard by a key that spreads load evenly (user ID, hash), and choose a write-friendly store (Cassandra, DynamoDB).
- **Great:** buffer writes through a queue, batch or pre-aggregate them (in memory or in Flink), and split hot keys (counter sharding with periodic merge).

## Pattern: Handling Large Blobs

When: files, images or video (Dropbox, YouTube).
- **Bad:** upload through the app servers into the database.
- **Good:** store blobs in object storage (S3), metadata in the database, serve through a CDN.
- **Great:** presigned URLs so clients upload and download directly; chunked, resumable multipart uploads; storage events update metadata status.

## Pattern: Managing Long-Running Tasks

When: work takes seconds to minutes (video transcoding, report generation, code execution).
- **Bad:** do the work inside the HTTP request.
- **Good:** accept the request, put a job on a queue, return a job ID; workers process it and the client polls status.
- **Great:** autoscaled worker pools per job type, retries with dead-letter queues, idempotent jobs, and push notification on completion.

## Pattern: Proximity-Based Services

When: "find things near me" (Uber, Yelp, Tinder).
- **Bad:** scan all rows and compute distance.
- **Good:** a geospatial index: PostGIS, geohash prefix queries, or quadtrees.
- **Great:** Redis geo commands or in-memory geohash buckets for fast-moving entities (drivers), updated from a location stream; a durable store only for slower-changing places.

## Key technologies

| Tech | Reach for it when | Know |
|---|---|---|
| PostgreSQL | Default relational store; transactions, constraints | Indexes, row locks, replicas, partitioning |
| DynamoDB | Key-value at scale with predictable access patterns | Partition key and sort key design, GSIs, conditional writes |
| Cassandra | Very high write throughput, wide rows | Partition key, clustering columns, tunable consistency |
| Redis | Cache, counters, locks, rate limits, geo, pub/sub | TTLs, eviction, single-threaded ops, persistence options |
| Elasticsearch | Full-text and faceted search | Inverted index, sync from source of truth via CDC |
| Kafka | Durable ordered event streams, replay | Partitions and keys for ordering, consumer groups, retention |
| Flink | Stateful stream processing, windowed aggregation | Windows, checkpoints, exactly-once with Kafka |
| ZooKeeper / etcd | Coordination, leader election, config | Consensus, small data only |
| API Gateway | Auth, routing, rate limiting at the edge | It routes; it doesn't hold business logic |
| CDN | Static and cacheable content close to users | Cache keys, TTLs, invalidation |
````

- [ ] **Step 2: Write diagrams.md**

````markdown
# Diagrams (ASCII)

Use ASCII in code fences so diagrams render everywhere. Label every arrow with what flows along it. Don't repeat the diagram in prose.

## High-level design

```
 [Client] --HTTPS--> [API Gateway] --> [Booking Service] --> (Postgres: events, bookings)
                          |                    |
                          |                    +--reserve--> (Redis: seat locks, TTL 10m)
                          +--> [Search Service] --> (Elasticsearch: events)
```

Boxes `[ ]` are services, parentheses `( )` are stores, and `{ }` are queues or streams.

## Building the design one requirement at a time

Show the diagram after each functional requirement, adding only what that requirement needs. Mark new parts with `*`:

```
FR2: Users should be able to book a ticket
 [Client] --> [API Gateway] --> [Booking Service]* --> (Postgres: bookings*)
```

## Sequence (deep dives)

```
Client          Booking Svc         Redis            Postgres
  |--POST /bookings-->|                |                 |
  |                   |--SET NX seat-->|                 |
  |                   |<----OK---------|                 |
  |                   |--INSERT booking (status=reserved)-->|
  |<--202 reserved----|                |                 |
```

## Entity sketch

```
Event(id, venue_id, date)  1---*  Ticket(id, event_id, seat, status, reserved_until)
User(id)                   1---*  Booking(id, user_id, ticket_ids, status)
```

## Final design

One consolidated diagram after deep dives, with every deep-dive change included.
````

- [ ] **Step 3: Run checks**

Run: `scripts/check.sh | grep -E 'patterns|diagrams'`
Expected: all `PASS`.

- [ ] **Step 4: Commit**

```bash
git add plugin/skills/hello-interview/reference/patterns.md plugin/skills/hello-interview/reference/diagrams.md
git commit -m "Add pattern ladders and ASCII diagram templates"
```

---

### Task 6: topics.md

**Files:**
- Create: `plugin/skills/hello-interview/reference/topics.md`

- [ ] **Step 1: Write topics.md**

````markdown
# Topics

Problems for `mock`, `learn` and `generate` when no problem is given. Pick one whose `Levels` includes the resolved level and whose slug is not already in `runs.md`. Prefer problems that stress patterns tied to recurring weak themes.

| Problem | Slug | Levels | Patterns stressed |
|---|---|---|---|
| URL shortener (Bitly) | `bitly` | mid, senior | Scaling Reads |
| File storage and sync (Dropbox) | `dropbox` | mid, senior, staff | Handling Large Blobs, Real-time Updates |
| Ticket booking (Ticketmaster) | `ticketmaster` | mid, senior, staff | Dealing with Contention, Scaling Reads |
| News feed (Facebook) | `news-feed` | senior, staff | Scaling Reads, Scaling Writes |
| Chat (WhatsApp) | `whatsapp` | senior, staff | Real-time Updates, Scaling Writes |
| Ride hailing (Uber) | `uber` | senior, staff | Proximity-Based Services, Dealing with Contention |
| Dating swipes (Tinder) | `tinder` | senior, staff | Proximity-Based Services, Scaling Writes |
| Coding judge (LeetCode) | `leetcode` | mid, senior | Managing Long-Running Tasks |
| Video streaming (YouTube) | `youtube` | senior, staff | Handling Large Blobs, Managing Long-Running Tasks |
| Web crawler | `web-crawler` | senior, staff | Multi-step Processes, Scaling Writes |
| Ad click aggregator | `ad-click-aggregator` | senior, staff | Scaling Writes |
| Top-K (trending items) | `top-k` | senior, staff | Scaling Writes, Scaling Reads |
| Distributed rate limiter | `rate-limiter` | mid, senior | Scaling Reads, Dealing with Contention |
| Live comments (Facebook Live) | `live-comments` | senior, staff | Real-time Updates |
| Post search (Facebook) | `post-search` | senior, staff | Scaling Reads, Scaling Writes |
| Price tracker (CamelCamelCamel) | `price-tracker` | mid, senior | Managing Long-Running Tasks, Scaling Writes |
| Local business search (Yelp) | `yelp` | mid, senior | Proximity-Based Services, Scaling Reads |
| Online auction | `online-auction` | senior, staff | Dealing with Contention, Real-time Updates |
| Collaborative editor (Google Docs) | `google-docs` | senior, staff | Real-time Updates, Dealing with Contention |
| Job scheduler | `job-scheduler` | senior, staff | Managing Long-Running Tasks, Multi-step Processes |
| Payment system | `payment-system` | senior, staff | Multi-step Processes, Dealing with Contention |
| Metrics monitoring | `metrics-monitoring` | senior, staff | Scaling Writes, Scaling Reads |
| Photo sharing (Instagram) | `instagram` | mid, senior | Handling Large Blobs, Scaling Reads |
| Food delivery (DoorDash) | `doordash` | senior, staff | Proximity-Based Services, Multi-step Processes |
| Strava-style activity tracker | `strava` | mid, senior | Scaling Writes |
| Distributed cache | `distributed-cache` | senior, staff | Scaling Reads |
````

- [ ] **Step 2: Run checks**

Run: `scripts/check.sh | grep topics`
Expected: `PASS  topics has >=24 rows`.

- [ ] **Step 3: Commit**

```bash
git add plugin/skills/hello-interview/reference/topics.md
git commit -m "Add topic catalog"
```

---

### Task 7: mock.md

**Files:**
- Create: `plugin/skills/hello-interview/reference/mock.md`

- [ ] **Step 1: Write mock.md**

````markdown
# mock: Claude interviews you

You are the interviewer. Your job is to assess, not teach. Follow `framework.md` for the phases and cite its anti-pattern IDs (AP1–AP8) when pushing back.

## Before starting

1. Show the preamble from SKILL.md, if it applies.
2. Pick the problem: the user's text verbatim, else from `topics.md` (level match, slug not in `runs.md`, biased toward recurring weak themes).
3. Open with: the problem in one or two sentences, the level, and "45 minutes. Start whenever you're ready." Nothing else.

## During the interview

Track rough elapsed time by phase from the conversation.

- **Requirements.** Let the candidate lead. If they list more than four functional requirements, ask which three matter most (AP1). If an NFR has no number, ask "how fast, and for which call?" (AP2). If they start long arithmetic, ask "which decision does that number change?" (AP3). If they skip the below-the-line list, ask what they are leaving out.
- **Core Entities and API.** If they draw boxes first, ask for entities and endpoints before continuing (AP4). If `userId` appears in a body or path for the caller, ask where the caller's identity comes from (AP6).
- **High-Level Design.** Ask them to walk one request end to end per functional requirement. If they add sharding, caches or queues before a requirement needs them, ask what requirement forces it (AP5). Ask "what does that component do?" for anything named without reason.
- **Deep Dives.** Behaviour depends on level:
  - mid: you pick each dive, aimed at the NFR most at risk.
  - senior: ask "where do you think this design breaks?" and let them choose. Steer only if they miss a critical one.
  - staff: let them run it; respond as a peer, raise second-order effects.
  If they dive without naming the requirement it serves, ask which one (AP7). Push past vague answers: "which store, which key, what happens when that node dies?"
- **Time.** When a phase runs well over target, move them on: "We're about 8 minutes into requirements. Let's go to entities."
- If they monologue through a probe, repeat the probe (AP8).

Rules:
- Never volunteer architecture or finish their sentence.
- Keep each turn short: one question or one pushback.
- `pause` from the user: drop out of role, answer their real question, then resume where you were.
- The user saying "done" or the deep dives running out ends the interview.

## Debrief

Always run it, even if the session was cut short. Load `rubric.md`. Load `patterns.md` if Technical Excellence is 3 or lower.

1. **Theme scores**: four lines, `Theme: N/5 — justification quoting the candidate`.
2. **Verdict**: hire / lean hire / lean no hire / no hire at the level, plus the rule from `rubric.md` that decided it.
3. **Deep dives**: for each dive, its rung (Bad, Good or Great) and what the Great answer adds, citing a `patterns.md` section by name when one fits.
4. **Anti-patterns hit**: each AP ID observed, with the moment it happened.
5. **Phase timing**: a table of phase, target, rough actual.
6. **Next**: the two weakest themes to drill and one or two next problems as commands, e.g. `/hello-interview mock ticketmaster`.

## Save state

Append to `~/.hello-interview/runs.md`:

```
YYYY-MM-DD | <slug> | mock | <level> | <nav>,<design>,<tech>,<comms> | <verdict> | <next>
```

`<next>` is the single most specific drill from the debrief, at most 80 characters, or empty.

Append one line to `~/.hello-interview/weaknesses.md` per theme scored 3 or lower:

```
YYYY-MM-DD | <slug> | <theme> | <one-line context quoting the candidate>
```
````

- [ ] **Step 2: Run checks**

Run: `scripts/check.sh | grep mock`
Expected: all `mock:` lines `PASS`.

- [ ] **Step 3: Commit**

```bash
git add plugin/skills/hello-interview/reference/mock.md
git commit -m "Add mock mode"
```

---

### Task 8: learn.md

**Files:**
- Create: `plugin/skills/hello-interview/reference/learn.md`

- [ ] **Step 1: Write learn.md**

````markdown
# learn: you interview Claude

The user is the interviewer. You are the candidate at the resolved level. If no problem was given, ask which one they want to ask, and wait.

Never write to `runs.md` or `weaknesses.md` in this mode.

## Default (no `--auto`)

Answer the way a strong candidate at this level would, following `framework.md`, in this order, pausing for the interviewer between phases:

1. **Requirements**: ask two or three clarifying questions first. Then state about three functional requirements ("Users should be able to …"), a below-the-line line, and three to five quantified NFRs. Say you'll skip estimates until a decision needs one.
2. **Core Entities**: a short list.
3. **API**: REST endpoints in a code block, one per functional requirement, identity from the auth token.
4. **Data Flow**: only if the system is a pipeline.
5. **High-Level Design**: one functional requirement at a time, each with an ASCII diagram from `diagrams.md` and a numbered request walkthrough. Name deferred complexity in one line.
6. **Deep Dives**: offer the list, each tied to an NFR ("To keep redirects under 100 ms I'd look at caching; to handle 1B URLs, ID generation. Which first?"). For each dive: one line on the naive approach and why it fails, then the Great answer with its costs and the math that justifies it. Use `patterns.md`.

Calibrate to level using `rubric.md`: at mid answer what's asked; at senior name the hard parts and your own weaknesses unprompted; at staff run the session and raise second-order effects.

Stay in character. When the interviewer says the interview is over, offer one line: "Want me to critique my own answer against the rubric?" Do it only if they say yes.

## `--auto`

Two subagents play interviewer and candidate. The user watches.

1. **Cost check first.** Say: "This runs about 2×N subagent calls (N = `--exchanges`, default 30). Go ahead, or set a smaller N?" Wait for confirmation.
2. **Problem.** The user's text, else pick from `topics.md`. Hold it in memory; write no files.
3. **Loop** until the interviewer's turn starts with `ENDING:` or N exchanges are done:
   - **Interviewer turn.** Spawn a `general-purpose` agent with: the role (strict interviewer at the resolved level, following `framework.md` and pushing back on AP1–AP8), the problem, the current phase hint (requirements → entities → API → HLD → deep dives → close, by exchange count), and the full transcript. Ask for the next interviewer turn only, at most 150 words, no answers given away, prefixed `ENDING:` to close. Show it as `INTERVIEWER:`.
   - **Candidate turn.** Spawn a `general-purpose` agent with: the role (candidate at the resolved level following `framework.md`, using `patterns.md` ladders and ASCII diagrams from `diagrams.md`), the problem, and the full transcript including the new interviewer turn. Ask for the next candidate turn only, at most 300 words. Show it as `CANDIDATE:`.
   - Append both turns to the transcript.
4. **Review.** Spawn one more agent as an observer with `rubric.md` and the transcript. Ask for: the four theme scores and verdict for the candidate, two or three things done well, two or three things to flag (with AP IDs), and one or two probes the interviewer missed. Show it.

If the user interrupts, stop the loop and offer the review on the transcript so far.
````

- [ ] **Step 2: Run checks**

Run: `scripts/check.sh | grep learn`
Expected: all `learn:` lines `PASS`.

- [ ] **Step 3: Commit**

```bash
git add plugin/skills/hello-interview/reference/learn.md
git commit -m "Add learn mode with --auto"
```

---

### Task 9: postmortem.md

**Files:**
- Create: `plugin/skills/hello-interview/reference/postmortem.md`

- [ ] **Step 1: Write postmortem.md**

````markdown
# postmortem: diagnose a real interview

1. Show the preamble from SKILL.md, if it applies.
2. **Gather.** With `--file=<path>`, read the notes and ask only about gaps. Without it, ask one or two questions at a time, in this order, and stop once you have enough:
   - Company, level, problem, and how long the interview was.
   - What requirements did you state? Did you write NFRs with numbers? Anything out of scope?
   - Did you list entities and an API before drawing?
   - What did the high-level design look like, and did every requirement get a path?
   - Which deep dives happened, who picked them, and what did you propose?
   - Where did the interviewer push, and how did you respond? Did you run out of time?
3. **Timeline.** Rebuild a table of phase, target time, rough actual time, and what happened.
4. **Diagnosis.** Load `rubric.md`. List each anti-pattern (AP1–AP8) that occurred with the evidence. Score the four themes with justifications and give the verdict at the level. Be honest; the user wants the real read, not reassurance.
5. **What stronger looked like.** For each phase that went wrong, show what a strong answer at this level would have said, briefly. Use `patterns.md` for deep dives and `diagrams.md` if a diagram makes the fix clearer.
6. **Next.** Two themes to drill and one or two practice commands.

## Save state

Append to `~/.hello-interview/runs.md` (slug from the problem; make one up in kebab case if it isn't in `topics.md`):

```
YYYY-MM-DD | <slug> | postmortem | <level> | <nav>,<design>,<tech>,<comms> | <verdict> | <next>
```

Append one line to `~/.hello-interview/weaknesses.md` per theme scored 3 or lower.
````

- [ ] **Step 2: Run checks**

Run: `scripts/check.sh | grep postmortem`
Expected: all `postmortem:` lines `PASS`.

- [ ] **Step 3: Commit**

```bash
git add plugin/skills/hello-interview/reference/postmortem.md
git commit -m "Add postmortem mode"
```

---

### Task 10: generate.md

**Files:**
- Create: `plugin/skills/hello-interview/reference/generate.md`

- [ ] **Step 1: Write generate.md**

`````markdown
# generate: write a practice question and its breakdown

1. **Topic.** The user's text, else pick from `topics.md` at the resolved level. Slug: the `topics.md` slug, else the topic in kebab case.
2. **Folder.** `./hello-interview-questions/<slug>/`. If it exists, use `<slug>-2`, then `-3`, and so on. Never overwrite.
3. **Write `question.md`**: the problem statement only, so the user can attempt it blind:

````markdown
# <Problem name>

<Two or three sentences describing the product, as an interviewer would say it.>

Level: <level>. Time: 45 minutes. Answer key: breakdown.md (don't open it until you've tried).
````

4. **Write `breakdown.md`**, following `framework.md`, using `patterns.md` for deep dives, `diagrams.md` for diagrams and `rubric.md` for the last section. Use exactly these headings in this order:

````markdown
# <Problem name>: breakdown

## Understanding the Problem

<One paragraph on what the product is.>

### Functional Requirements

1. Users should be able to …
2. …
3. …

Below the line (out of scope): <items>, with one sentence on why they're cut.

### Non-Functional Requirements

1. The system should … <number, scope>
2. …

Below the line: <items>.

## The Set Up

### Core Entities

- **<Entity>**: <one line>

### API

<One fenced block per endpoint, with a sentence on the verb choice.>

## High-Level Design

### 1) Users should be able to <FR1>

<Diagram, then a numbered walkthrough of the request.>

### 2) Users should be able to <FR2>

<Same shape. One subsection per functional requirement.>

## Potential Deep Dives

### 1) How do we <meet NFR X>?

#### Bad Solution: <name>
**Approach:** …
**Challenges:** …

#### Good Solution: <name>
**Approach:** …
**Challenges:** …

#### Great Solution: <name>
**Approach:** …
**Challenges:** …

<Two to four deep dives, each tied to an NFR. Include math where a number picks the solution.>

## Final Design

<One consolidated ASCII diagram including the deep-dive changes.>

## What is Expected at Each Level?

### Mid-level
<What a passing mid-level answer covers for this problem.>

### Senior
<…>

### Staff+
<…>
````

5. Tell the user both paths and suggest `/hello-interview mock <slug>` to practise it.

Write no state.
`````

- [ ] **Step 2: Run checks**

Run: `scripts/check.sh | grep generate`
Expected: all `generate:` lines `PASS`.

- [ ] **Step 3: Run full suite**

Run: `scripts/check.sh | tail -1`
Expected: `All checks passed`. If any FAIL, fix the named file and re-run.

- [ ] **Step 4: Commit**

```bash
git add plugin/skills/hello-interview/reference/generate.md
git commit -m "Add generate mode with HI breakdown template"
```

---

### Task 11: README, install, behavioural verification

**Files:**
- Create: `README.md`

- [ ] **Step 1: Write README.md**

````markdown
# hello-interview-sd

System design interview practice for Claude Code, following the Hello Interview method: Requirements → Core Entities → API → (Data Flow) → High-Level Design → Deep Dives, graded on Problem Navigation, Solution Design, Technical Excellence, and Communication & Collaboration.

Unofficial; not affiliated with Hello Interview.

## Install

```bash
claude plugin marketplace add ~/GitHub/hello-interview-sd
claude plugin install hello-interview-sd@hello-interview-sd
```

## Use

```
/hello-interview mock                      # random problem at your level
/hello-interview mock ticketmaster --level=staff
/hello-interview learn "design WhatsApp"
/hello-interview learn --auto --exchanges=10
/hello-interview postmortem --file=./notes.md
/hello-interview generate "url shortener"
```

Set a default level: `echo senior > ~/.hello-interview/level.md` (`mid`, `senior` or `staff`).

Progress lives in `~/.hello-interview/runs.md` and `weaknesses.md`.

## Develop

`scripts/check.sh` runs the structural checks.
````

- [ ] **Step 2: Validate and install**

Run: `claude plugin validate ~/GitHub/hello-interview-sd`
Expected: no errors. (If the `validate` subcommand doesn't exist in this Claude Code version, skip to the install.)

Run:
```bash
claude plugin marketplace add ~/GitHub/hello-interview-sd
claude plugin install hello-interview-sd@hello-interview-sd
```
Expected: both report success.

- [ ] **Step 3: Router smoke test**

Run: `cd "$(mktemp -d)" && claude -p "/hello-interview"`
Expected: output shows the four-mode table and asks which mode. No files written.

- [ ] **Step 4: generate end to end**

Run: `cd "$(mktemp -d)" && claude -p "/hello-interview generate url shortener" --permission-mode acceptEdits && ls hello-interview-questions/*/`
Expected: `breakdown.md  question.md`.

Then in the same directory:
```bash
f=$(ls hello-interview-questions/*/breakdown.md)
for h in "## Understanding the Problem" "## The Set Up" "## High-Level Design" "## Potential Deep Dives" "## Final Design" "## What is Expected at Each Level?"; do grep -nF "$h" "$f" | head -1; done
grep -c "Great Solution" "$f"
```
Expected: six headings with increasing line numbers; Great Solution count ≥ 2.

Re-run the generate command in the same directory and confirm a `-2` folder appears and the first is unchanged.

- [ ] **Step 5: mock (manual, by the user)**

In an interactive session run `/hello-interview mock bitly --level=senior` and deliberately:
- list six functional requirements (expect AP1 pushback),
- say "it should be low latency" (expect AP2),
- put `userId` in a POST body (expect AP6),
- type `pause`, ask a question, then continue (expect it to resume).

Say "done". Expected: the debrief has theme scores, verdict with rule, deep-dive rungs, APs hit, phase timing table, next. Then:

Run: `tail -1 ~/.hello-interview/runs.md`
Expected: a line matching `^\d{4}-\d{2}-\d{2} \| bitly \| mock \| senior \| \d,\d,\d,\d \| (hire|lean hire|lean no hire|no hire) \| .*$`.

- [ ] **Step 6: learn --auto (cheap run)**

Run `/hello-interview learn --auto --exchanges=4 "design a rate limiter"`.
Expected: the cost prompt appears first; turns are labelled `INTERVIEWER:` / `CANDIDATE:`; candidate follows the phase order; an observer review appears at the end; `runs.md` is unchanged (`wc -l` before and after).

- [ ] **Step 7: Commit**

```bash
git add README.md
git commit -m "Add README with install and usage"
```

---

## Spec coverage

| Spec item | Task |
|---|---|
| Layout, local marketplace | 1, 11 |
| Router, setup, flags, level default senior | 2 |
| State format, preamble, only mock/postmortem write | 2, 7, 9 |
| Core method, anti-patterns | 3 |
| Four themes, level calibration, verdict rule | 4 |
| Patterns, key technologies, diagrams | 5 |
| Topic catalog | 6 |
| mock behaviour by level, pause, debrief | 7 |
| learn default + `--auto` with cost check and observer | 8 |
| postmortem one-or-two questions, timeline | 9 |
| generate two files, HI order, no overwrite | 10 |
| Testing section | 1 (check.sh), 11 |
