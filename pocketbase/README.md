# PocketBase

PocketBase is a whole backend in one small program: a database (SQLite) with a REST and realtime API, user accounts with email, password and social logins, file uploads, and an admin dashboard to manage it all. You define collections in the dashboard, and your frontend talks to it directly with its JavaScript or Dart SDK.

### What people use it for

- MVPs and prototypes, where a separate API, database and auth service would be too much.
- Small apps and internal tools: a booking form, an inventory, a club's members.
- Mobile and single-page apps that need accounts and data without writing a server.

### Good to know

- Everything (the database, uploaded files and settings) lives on its volume. The dashboard is at `/_/` on its address.
- It's built here from its official release, in a small image.
- It runs as one service on one server; for heavy traffic or several regions, a full database is the better fit.
