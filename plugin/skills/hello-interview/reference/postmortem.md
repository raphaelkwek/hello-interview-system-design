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
