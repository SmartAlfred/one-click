# Metabase

Metabase turns a database into charts and dashboards that anyone on a team can use. Connect it to your app's database, and people can ask questions by clicking (count orders by week, filter by country) or write SQL when they want to, then save the answer as a chart and put charts together on a dashboard.

### What people use it for

- Business dashboards (signups, revenue, active users) straight from the production database.
- Answering one-off questions without asking a developer to write a query.
- Sharing a chart or a dashboard by link, or emailing it on a schedule.

### Good to know

- This is the open-source edition, with its own Postgres for its settings and saved questions. Your data stays in your database; Metabase only reads it.
- Give it a database user that can only read, rather than your app's.
- It's Java, and wants about 2 GB of memory; the first start takes a minute or two.
