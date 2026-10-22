# n8n

n8n is workflow automation with a visual editor: you draw a workflow as boxes joined by lines, and it runs whenever something happens, on a schedule, or when a webhook is called. It has hundreds of ready-made connections (Slack, Google Sheets, GitHub, Stripe, databases, any HTTP API) and lets you drop into JavaScript or Python where a box isn't enough.

### What people use it for

- Gluing services together: a new signup goes into the CRM, a Slack channel and a welcome email.
- Scheduled jobs: a nightly report, cleaning up old records, syncing two systems.
- AI workflows and agents that call language models and act on what they answer.

### Good to know

- It's always on, so schedules and webhooks run at any hour, and its data lives on a volume.
- Keep the encryption key it's given: credentials saved in n8n are encrypted with it.
- n8n is source-available under the Sustainable Use License: fine for you and your company's own use. Read it before offering n8n to others.
