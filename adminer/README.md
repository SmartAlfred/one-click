# Adminer

Adminer is a database client that runs in the browser: one small PHP app that logs in to a database and lets you look around. Browse tables and their rows, edit a value, run a query, change a column, import a `.sql` file or export one. It speaks PostgreSQL, MySQL and MariaDB, SQLite, and more.

### What people use it for

- Looking at what an app actually wrote, without installing a client on every laptop.
- Fixing a row by hand, or running a one-off query, on a database that's private to the project.
- Importing a dump to start a project with data, or exporting tables to share.

### Good to know

- It reaches the project's databases by their names (`postgres`, `mysql`), so they stay private: Adminer is the only thing with an address.
- Anyone who has a database's password can use it through Adminer. Keep the address to yourself, or switch Adminer off when you're done.
- It sleeps when nobody uses it, so it costs next to nothing between visits.
