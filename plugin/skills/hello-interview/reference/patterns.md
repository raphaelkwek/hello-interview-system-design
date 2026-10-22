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
