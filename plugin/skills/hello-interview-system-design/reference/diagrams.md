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
