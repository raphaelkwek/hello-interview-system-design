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
