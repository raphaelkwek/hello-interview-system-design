# generate: write a practice question and its breakdown

1. **Topic.** The user's text, else pick from `topics.md` at the resolved level. Slug: per Slugs in SKILL.md, rules 2 and 3 (e.g. "url shortener" → `bitly`).
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
