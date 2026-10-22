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
3. **Every subagent prompt** includes the resolved level, the problem, and the absolute paths of the reference files it must read before answering (see the end of SKILL.md). The files are named per role below.
4. **Phase hint** for exchange k of N: requirements up to 15% of N, entities and API up to 30%, high-level design up to 60%, deep dives up to 95%, then close. For pipeline problems, the data flow goes at the start of the high-level design.
5. **Loop** until the interviewer's turn starts with `ENDING:` or N exchanges are done:
   - **Interviewer turn.** Spawn a `general-purpose` agent with: the role (strict interviewer at the resolved level, pushing back on AP1–AP8), `framework.md` and `rubric.md` to read, the current phase hint, and the full transcript. Ask for the next interviewer turn only, at most 150 words, no answers given away, prefixed `ENDING:` to close. Show it as `INTERVIEWER:`.
   - **Candidate turn.** Spawn a `general-purpose` agent with: the role (candidate at the resolved level), `framework.md`, `rubric.md`, `patterns.md` and `diagrams.md` to read, and the full transcript including the new interviewer turn. Ask for the next candidate turn only, at most 300 words. Show it as `CANDIDATE:`.
   - Append both turns to the transcript.
6. **Review.** Spawn one more agent as an observer with `rubric.md` and `framework.md` to read, the level, and the transcript. Ask for: the four theme scores and verdict for the candidate at that level, two or three things done well, two or three things to flag (with AP IDs), and one or two probes the interviewer missed. Show it.

If the user stops the run (Esc cancels the current subagent call), don't restart the loop. Offer the review on the transcript so far.
