# Uptime Kuma

Uptime Kuma checks your websites and services every minute or so and tells you when one stops answering. It checks HTTP addresses (and what they answer), TCP ports, DNS, ping and more, keeps a history of each, and sends a notification through whichever of its many channels you choose: email, Slack, Discord, Telegram, webhooks and others.

### What people use it for

- Knowing a site is down before your users tell you.
- Public status pages that show what's up and what isn't.
- Watching certificates expire, or an API answer with the wrong content.

### Good to know

- It runs on smartalfred, so it checks from outside your apps' containers, through their public addresses. For checking smartalfred itself, a second monitor somewhere else is wise.
- Choose SQLite when it first asks for a database: everything then stays on its volume. The first person to open it creates the admin account.
- It's always on, so the checks keep running.
