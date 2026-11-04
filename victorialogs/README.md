# VictoriaLogs + Grafana

VictoriaLogs is a log store built to use very little memory and disk. Grafana is the page you search it from. Together they're a place of your own for what your services write.

### What people use it for

- Keeping logs longer than Alf does, without paying a logging service.
- Searching every service's logs in one place, and building dashboards on them.
- Keeping logs in your own project for privacy reasons.

### Good to know

- It takes what a [log drain](https://runalf.com/docs/log-drains) sends: add one with the command shown after deploying. Nothing arrives until you do.
- VictoriaLogs has no login, so it's team-only. Its own search page is at `/select/vmui`. Grafana is public, with its own login.
- The 10 GB volume is billed by its size. Logs go after 14 days, or sooner if the disk reaches 9 GB. Change `-retentionPeriod` in its command to keep them longer, with a bigger volume to match.
- The Grafana plugin is downloaded when it starts, so its first start takes a minute.
