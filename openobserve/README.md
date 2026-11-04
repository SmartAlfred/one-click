# OpenObserve

OpenObserve keeps logs, metrics and traces in one program, with its own search page, dashboards and alerts. It's one container, which makes it simpler to run than a stack of separate tools.

### What people use it for

- A home for your services' logs, from a [log drain](https://runalf.com/docs/log-drains).
- Searching logs with SQL, and alerting on what they say.
- Taking metrics and traces from apps that speak OpenTelemetry.

### Good to know

- Nothing arrives until you add a log drain: the command is shown after deploying.
- It's open source under the AGPL-3.0, which matters if you change it and offer it to others.
- The 20 GB volume is billed by its size. Data goes after the days you chose, but a full disk stops new data, so keep an eye on it.
