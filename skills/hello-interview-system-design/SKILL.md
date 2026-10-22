---
name: hello-interview-system-design
description: "Practise system design interviews the Hello Interview way: Requirements, Core Entities, API, (Data Flow), High-Level Design, Deep Dives; graded on Problem Navigation, Solution Design, Technical Excellence, and Communication & Collaboration at mid, senior or staff level. Modes: `mock` (Claude interviews you, ends with scores and a hire verdict), `learn` (Claude answers as the candidate; `--auto` runs interviewer and candidate subagents while you watch), `postmortem` (diagnose a real interview), `generate` (write a practice question plus an HI-style breakdown). Use when the user runs /hello-interview-system-design or asks for Hello Interview–style system design practice."
metadata:
  version: "0.1.0"
---

# Hello Interview system design practice

Every mode follows one method: [reference/framework.md](reference/framework.md). Read it at the start of every invocation, before the mode file.

## Modes

| Mode | What happens | Mode file |
|---|---|---|
| `mock [problem]` | Claude interviews you, enforces the phases, then debriefs with scores and a verdict. | [reference/mock.md](reference/mock.md) |
| `learn [problem] [--auto]` | You interview Claude, who answers as a candidate at your level. `--auto` runs both sides as subagents. | [reference/learn.md](reference/learn.md) |
| `postmortem [--file=path]` | Diagnose a real interview you already did. | [reference/postmortem.md](reference/postmortem.md) |
| `generate [topic]` | Write a practice question and its breakdown to `./hello-interview-questions/<slug>/`. | [reference/generate.md](reference/generate.md) |

## Routing

1. No argument: show the table above and ask which mode and problem. Don't guess.
2. First word is a mode: run Setup, read `framework.md`, then follow the mode file. Everything after the mode word is the problem text and flags.
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
- `<next>` is one concrete drill of at most 80 characters (e.g. "quantify every NFR; name the call and the number"), or empty. With an empty `<next>` the line ends in `| `.
- Replace any `|` inside free text (`<next>`, context quotes) with `/` so the columns stay intact.

`weaknesses.md`: one line per theme scored 3 or lower:

```
YYYY-MM-DD | <slug> | <theme> | <one-line context quoting the candidate>
```

`mock` reads the context column to aim deep dives at recurring gaps.

`level.md`: a single token the user writes. The skill only reads it.

### Slugs

Every mode names a problem by slug the same way:

1. If `./hello-interview-questions/<text>/question.md` exists for the given text, the slug is that folder name (including any `-2` suffix).
2. Else if the problem matches a `topics.md` row, by name or by the product in parentheses (e.g. "url shortener" or "Bitly" → `bitly`), use that row's slug.
3. Else a 1–3 word kebab-case product name with no verbs (e.g. "design a price alert system" → `price-alerts`).

### Preamble (`mock` and `postmortem`)

If `runs.md` has at least 2 rows at the resolved level, show before starting:

1. Sessions at this level: count.
2. Recurring weak themes: any theme scored 3 or lower in at least 2 sessions and in at least half of the last 4 sessions at this level (or all of them, if fewer than 4 exist). If none: "No recurring weak themes."
3. Last 3 slugs at this level, newest first.
4. `Last drill: <next>` from the newest row at this level, if non-empty.

Fewer than 2 rows: skip silently.

## Reference files (load on demand)

| File | Load when |
|---|---|
| [reference/framework.md](reference/framework.md) | Every invocation. |
| [reference/rubric.md](reference/rubric.md) | `mock` debrief, `postmortem`, `learn` (level calibration and self-critique), `generate`. |
| [reference/patterns.md](reference/patterns.md) | Any session with a deep dive: `mock` debrief, `postmortem`, `learn`, `generate`. |
| [reference/topics.md](reference/topics.md) | `mock`, `learn --auto` or `generate` with no problem given; resolving a slug. |
| [reference/diagrams.md](reference/diagrams.md) | Claude is the candidate (`learn`), writing a breakdown (`generate`), or illustrating a fix (`postmortem`). Never in `mock`. |

The reference files live in `reference/` under this skill's base directory, which is shown when the skill loads. Subagents can't see that path on their own: when spawning one, give it the absolute paths of the files it needs and tell it to read them first.

## Don'ts (all modes)

- Don't volunteer architecture during `mock`. Coaching belongs in the debrief.
- Don't write transcripts to state files.
- Don't write state from `learn` or `generate`.
- Don't overwrite an existing `generate` folder.
- Don't ask more than two postmortem questions at once.
- Don't copy Hello Interview's text. The method is theirs; the words are ours.
