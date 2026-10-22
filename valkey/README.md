# Valkey

Valkey is an in-memory key-value store, compatible with Redis: the same commands, the same clients, the same data types (strings, hashes, lists, sets, sorted sets, streams). It's the open-source continuation of Redis, kept by the Linux Foundation after Redis changed its licence.

### What people use it for

- A cache in front of a slower database or API.
- Job queues for background work (Sidekiq, BullMQ, Celery and others).
- Sessions, rate limits, counters and other short-lived data.

### Good to know

- Every Redis client works with it: connect with the `redis://` URL from its variables.
- It's protected by a generated password and saves to its volume, so a restart doesn't empty it.
- smartalfred's own Redis is a click away too (**+ Create → Redis**); pick Valkey if you'd rather run the open-source fork.
