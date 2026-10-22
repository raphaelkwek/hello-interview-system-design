# hello-interview-sd — design

**Date:** 2026-10-22
**Status:** Draft, awaiting review

## Goal

A Claude Code plugin for practising system design interviews that follows the Hello Interview (HI) method exactly: its delivery framework, its write-up structure, and its level-based expectations.

It borrows the *structure* of the installed `ftvision/system-design-skill` plugin (router skill + per-mode reference files, durable progress state, pre-session preamble, scored debrief, two-agent auto mode). It does **not** copy that plugin's files: the repo has no license, so all text here is written fresh. HI material is paraphrased, never copied.

## Non-goals (v1)

- Text-to-speech (`--say`) and domain biasing (`--direction`). See "Later improvements".
- Reproducing HI's premium breakdowns. `topics.md` lists problem names only; the plugin writes its own answers.

## Layout

> Changed after build: the plugin now lives at the repo root (`source: "./"`, `skills/` and `.claude-plugin/plugin.json` at top level) to match the layout claude.ai accepted for interview-prep, and `dist/hello-interview-system-design.plugin` is the zip for uploading to claude.ai.

```
hello-interview-sd/
  .claude-plugin/marketplace.json     # local marketplace, source: ./plugin
  plugin/
    .claude-plugin/plugin.json
    skills/hello-interview/
      SKILL.md                        # router, setup, shared rules
      reference/
        framework.md                  # HI delivery framework, phase rules, anti-patterns
        rubric.md                     # 4 themes × 3 levels, hire verdict rules
        patterns.md                   # recurring patterns + key technologies
        topics.md                     # problem catalog with slugs and level tags
        diagrams.md                   # ASCII templates
        mock.md
        learn.md
        postmortem.md
        generate.md
  docs/superpowers/specs/             # this file
  README.md
```

Invocation: `/hello-interview <mock|learn|postmortem|generate> [problem] [--flags]`. No argument or an unknown mode: show the mode table and ask. Never guess.

## Core method (`framework.md`)

Phases and targets for a 45-minute session:

| Phase | Target | Rules |
|---|---|---|
| Requirements | ~5 min | ~3 functional reqs as "Users should be able to…". 3–5 non-functional reqs as "The system should…", quantified and tied to a specific part of the system. Explicit "below the line" (out-of-scope) list. No upfront capacity math: estimate only when a number changes a design decision. |
| Core Entities | ~2 min | Bulleted list of nouns/actors. No full schema yet. |
| API | ~5 min | REST by default (GraphQL/gRPC only with a stated reason). Plural resources. Current user from the auth token, never body/path. Real-time (WebSocket/SSE) added only after the core API. |
| Data Flow | ~5 min, optional | Numbered steps, only for pipeline-shaped systems. |
| High-Level Design | ~10–15 min | One functional requirement (or endpoint) at a time. Simple first. Caches/queues are named verbally and deferred. Only relevant DB fields noted. |
| Deep Dives | ~10 min | Each dive exists to satisfy a non-functional requirement (or fix a bottleneck/failure point). Solutions graded Bad / Good / Great. |

Anti-patterns that `mock` pushes back on, and that `postmortem`/debrief flag:

1. More than ~4 functional requirements, or none prioritised.
2. Non-functional requirements without numbers ("low latency").
3. Upfront back-of-envelope math that changes nothing.
4. Jumping to boxes before entities and API.
5. Scale machinery (sharding, caches, queues) inside the first high-level pass.
6. User identity in the request body or path.
7. A deep dive not traceable to a non-functional requirement.
8. Talking over the interviewer / not leaving room for probes.

## Grading (`rubric.md`)

Four HI themes, each scored 1–5 with a one-line justification quoting the candidate:

1. **Problem Navigation**: scoping, prioritisation, spending time on what matters.
2. **Solution Design**: a working design that meets the functional requirements, then hardened for the non-functional ones.
3. **Technical Excellence**: depth, correct use of technologies, Bad/Good/Great quality of deep dives.
4. **Communication & Collaboration**: clarity, responding to probes, leaving room.

Level calibration (breadth falls, depth and proactiveness rise):

| Level | Expectation |
|---|---|
| mid | Broad coverage, conceptual depth, a working design. Interviewer drives the deep dives. |
| senior | Real depth in ~2 areas. Spots the hard parts and own design's weaknesses unprompted. |
| staff | Drives nearly the whole session as a peer. Depth across domains, anticipates issues before being asked. |

Verdict: `hire / lean hire / lean no hire / no hire` at the resolved level, by ordered rules where the first match decides: any theme at 1, or two or more at 2 → no hire; exactly one at 2 → lean no hire; all ≥4 → hire; otherwise lean hire if Problem Navigation and Solution Design are both ≥4, else lean no hire.

## Setup (every invocation)

- **Level:** `--level=<mid|senior|staff>`, else `~/.hello-interview/level.md`, else `senior`. An invalid value means ask.
- **State dir:** `~/.hello-interview/`. Missing files are treated as empty. Create on first write.
  - `runs.md`: one row per scored session: `YYYY-MM-DD | slug | mode | level | nav,design,tech,comms | verdict | next`
  - `weaknesses.md`: one row per theme scored ≤3: `YYYY-MM-DD | slug | theme | one-line context`
  - `level.md`: single token. Written by the user; the skill only reads it.
- **Preamble** (`mock`, `postmortem`): if ≥2 rows at this level, show session count, themes scoring ≤3 in at least half of the last 4 sessions, the last 3 slugs, and the last `next` item. Otherwise skip silently.
- Only `mock` and `postmortem` write state.
- **Slugs:** a generated question folder name if one matches; else the `topics.md` slug matched by name or product ("url shortener" → `bitly`); else a 1–3 word kebab-case product name.

## Modes

### `mock`: Claude = interviewer

- Problem: the argument (or a generated `question.md` matching it), else pick from `topics.md` matching the level and not already in `runs.md`.
- Elapsed time is estimated at ~1.5 min per candidate turn; there is no clock.
- Enforce phases with time callouts ("We're ~7 minutes in, let's move to core entities"). Push back on the anti-patterns. Never volunteer architecture. `pause` drops out of role and then resumes.
- Deep-dive behaviour by level: mid means the interviewer picks the dives; senior means wait for the candidate to name them and steer only if they miss a critical one; staff means react as a peer. Deep-dive targets are biased toward recurring weak themes.
- Debrief (never skipped): 4 theme scores with quotes; verdict at level; each deep dive rated Bad/Good/Great with what the Great answer adds (citing `patterns.md` by section); anti-patterns hit (AP IDs with the moment); phase-time table (target vs estimated actual, at ~1.5 min per candidate turn); top 2 themes to drill; 1–2 next problems as commands. Then append to `runs.md` and `weaknesses.md`.

### `learn`: user = interviewer, Claude = candidate

- Default: answers in HI order at the resolved level: requirements with below-the-line list, core entities, API, data flow if relevant, HLD one functional requirement at a time with ASCII diagrams, then offers deep dives mapped to each non-functional requirement. Each dive names the naive approach and why it fails in one line, then gives the Great answer.
- Asks clarifying questions first; doesn't break character to coach. At the end, offers a self-critique on request.
- `--auto [--exchanges=N]` (default 30): first states the subagent call count (≈2×N) and asks to confirm. Then an interviewer agent and a candidate agent alternate, given the transcript and a phase hint. The interviewer ends with an `ENDING:` prefix. After the loop, an observer agent grades both sides against the 4 themes. Writes no state.

### `postmortem`: diagnose a real interview

- Level: from `--level`, else the level of the real interview (asked first), used for the preamble, scores and state.
- Input: `--file=<path>`, or questions asked one or two at a time. Never all at once.
- Rebuild a phase timeline, identify where the candidate left the framework (anti-pattern list), score the 4 themes with verdict, and give "what stronger looked like" per phase. Writes state.

### `generate`: author a practice question

- Topic: the argument, else from `topics.md`.
- Writes `./hello-interview-questions/<slug>/question.md` (prompt only, to attempt blind) and `breakdown.md` in HI write-up order: Understanding the Problem (FR, NFR, below the line) → Set Up (entities, API) → High-Level Design (a section per functional requirement) → Potential Deep Dives (each with Bad / Good / Great: approach + challenges) → Final Design → What is Expected at Each Level (mid / senior / staff).
- Never overwrites an existing slug; suffixes `-2`, `-3`, and so on.

## Reference assets (load on demand)

| File | Loaded when |
|---|---|
| `framework.md` | Every mode (it is the method). |
| `rubric.md` | `mock` debrief, `postmortem`, `learn` (calibration, self-critique, `--auto` agents), `generate` (for the expectations section). |
| `patterns.md` | Any session with a deep dive: `mock` debrief, `postmortem`, `learn`, `generate`. |
| `topics.md` | No problem given in `mock`, `learn --auto` or `generate`; resolving a slug. |

`learn --auto` subagents get the resolved level and the absolute paths of the reference files they must read.
| `diagrams.md` | `learn` (candidate role only), `generate`, `postmortem` illustrations. Never `mock`. |

## Testing

There is no code to unit test. Verification is behavioural:

1. Install via `/plugin marketplace add ~/GitHub/hello-interview-sd`, then `/plugin install`. Check that `/hello-interview` with no args shows the mode table.
2. `generate "url shortener"`: check that both files exist, `breakdown.md` follows the section order, and every deep dive has Bad/Good/Great.
3. `mock` a short session that deliberately commits anti-patterns 2, 3 and 6. Check that each gets pushback, the debrief has all parts, and the `runs.md` row format is right.
4. Run `mock` twice more, then check that the preamble appears.
5. `learn --auto --exchanges=4`: check that the cost prompt appears, phase order is followed, and no state is written.

## Later improvements (parked)

- **`drill <pattern|phase>`**: 10-minute focused reps on one phase (e.g. "write NFRs for Ticketmaster") or one pattern, scored against the rubric.
- **`--say` voice**: read interviewer/candidate turns aloud.
- **Excalidraw/Mermaid diagrams**: render HLDs into a file, matching HI's whiteboard tooling.
- **Progress dashboard**: an Artifact charting theme scores over time from `runs.md`.
- **Spaced repetition**: resurface problems whose last verdict was below hire after N days.
- **Company flavours**: `--company=meta|google|amazon` to tweak pacing and probes (e.g. Meta's product vs infra split).
- **`--direction`**: bias topics toward ML infra / LLM serving.
- **Calibration check**: periodically compare a `generate`d breakdown against HI's public free breakdowns to catch drift from their style.
- **Time tracking**: real wall-clock timestamps per phase instead of estimated minutes.
