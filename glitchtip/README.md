# GlitchTip

GlitchTip collects the errors your apps throw, groups the same one together, and tells you when something new breaks. It's an open-source alternative to Sentry and works with Sentry's own SDKs: point an app's DSN at GlitchTip and it reports there, for JavaScript, Python, Go, Ruby, PHP, Java and more.

### What people use it for

- Seeing what broke right after a deploy, with the stack trace, the request and the release it happened in.
- An email when a new kind of error shows up, rather than finding out from a user.
- Uptime checks and simple performance numbers for each project.

### Good to know

- It runs as one service with its own Postgres database, and stays light: about 512 MB.
- Emails are only written to its log until you give it an SMTP server (`EMAIL_URL` in its variables).
- Uploaded source maps and files go to a volume of its own.
