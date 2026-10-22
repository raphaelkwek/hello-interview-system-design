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

**Non-functional.** Write each one as "The system should …". Start with consistency vs availability: which parts must be strongly consistent and which can be eventually consistent. Then pick the rest of three to five that matter for *this* system, from: scale and read:write ratio, latency, durability, fault tolerance, security, compliance, environment constraints. Each must have a number and a scope. "Low latency" is not a requirement. "Redirects return in under 100 ms at p99" is.

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
