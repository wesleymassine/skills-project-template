# Context

Written on {{date}}, before the first grilling session. It separates what is **verified** from what is still a **question**, and it is the input for `/grill-with-docs`.

## Problem

{{What hurts today, for whom, and what changes once this project exists.}}

## Verified facts

{{Only what has been checked: documentation read, existing code, infrastructure limits. Cite the source of each fact.}}

## Open questions

1. {{A question whose answer changes the design.}}

## Engineering questions

The grill settles every question below that applies to this feature before the spec is written, and records each non-obvious answer as an ADR. Delete the sections that don't apply; skip a question only on purpose.

**Every feature**
- Who uses it, how often, and what does failure cost them?
- Which data does it create, change or delete, and who owns that data?
- What happens on bad input, a timeout, or a dependency being down?
- Authentication, authorization, secrets: who may do what, and where do credentials live?
- How will we know it works in production: logs, metrics, alerts?
- How is it rolled out and rolled back (feature flag, migration order)?

**Architecture and system design**
- Which module or service owns this behavior, and where is its seam?
- Synchronous or asynchronous? What needs to be idempotent, retried or queued?
- Expected volume and latency, and which of them is the real constraint?
- Which decision would be expensive to reverse (a one-way door)?

**Backend and APIs**
- The contract: endpoints or events, error format, versioning, pagination.
- Persistence: schema change, migration and backfill, transactions, consistency.
- Limits: rate limiting, quotas, payload size.

**Frontend**
- States of each screen: loading, empty, error, partial, success.
- Accessibility, responsive layout, internationalization.
- Where state lives (server, URL, client) and how it is cached.

**Mobile**
- Offline behavior and sync conflicts.
- Supported OS versions, permissions, push notifications.
- App store release, and a minimum-version policy for old clients.

**Tests (the pyramid)**
- Which behavior is proven by unit tests, which by integration tests, and which by a few end-to-end tests?
- Which seams do the tests use (the `tdd` skill asks again before the first test)?
- What can't be tested automatically, and how is it checked instead?
