# BunkerWeb

BunkerWeb is a web application firewall: it sits in front of an app, checks each request against the OWASP Core Rule Set (SQL injection, cross-site scripting and the like), adds security headers and bans visitors who behave badly. Alf's own [traffic rules](https://runalf.com/docs/access#traffic-rules) look at who a request is from; this looks at what's in it.

### What people use it for

- Protecting an app whose code they can't fully vouch for, like a CMS or an older app.
- Seeing what attacks an app actually gets, before deciding what to block.

### Good to know

- **Make your app private after deploying**, or attackers can go straight to it.
- It starts in detection-only mode, because these rules can block real traffic. Read its logs, then turn blocking on.
- It runs at 2 GB, billed while awake, on top of your app. It's always on.
- It protects your app, not Alf's capacity: requests it turns away have already reached your service, and count as your traffic.
