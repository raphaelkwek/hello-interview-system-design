# postmortem: diagnose a real interview

1. **Level.** If `--level` wasn't given, the level is the one the real interview was for: get it first (from the notes, or ask), and use it for the preamble, the scores and `runs.md`.
2. Show the preamble from SKILL.md, if it applies.
3. **Gather.** With `--file=<path>`, read the notes and ask only about gaps. Without it, ask one or two questions at a time, in this order, and stop once you have enough:
   - Company, problem, and how long the interview was.
   - What requirements did you state? Did you write NFRs with numbers? Anything out of scope?
   - Did you list entities and an API before drawing?
   - What did the high-level design look like, and did every requirement get a path?
   - Which deep dives happened, who picked them, and what did you propose?
   - Where did the interviewer push, and how did you respond? Did you run out of time?
4. **Timeline.** Rebuild a table of phase, target time, rough actual time, and what happened.
5. **Diagnosis.** Load `rubric.md`, and `patterns.md` if any deep dive happened. List each anti-pattern (AP1–AP8) that occurred with the evidence. Score the four themes with justifications and give the verdict at the level. Be honest; the user wants the real read, not reassurance.
6. **What stronger looked like.** For each phase that went wrong, show what a strong answer at this level would have said, briefly. Use `patterns.md` for deep dives and `diagrams.md` if a diagram makes the fix clearer.
7. **Next.** Two themes to drill and one or two practice commands.

## Save state

Append to `~/.hello-interview/runs.md` (slug per Slugs in SKILL.md):

```
YYYY-MM-DD | <slug> | postmortem | <level> | <nav>,<design>,<tech>,<comms> | <verdict> | <next>
```

Append one line to `~/.hello-interview/weaknesses.md` per theme scored 3 or lower.
