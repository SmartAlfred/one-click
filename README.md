# smartalfred one-click deploys

Ready-made stacks you can put into a [smartalfred](https://smartalfred.com) project with one click:
an app together with its database and settings. Browse them at
[smartalfred.com/one-click](https://smartalfred.com/one-click).

This repository **is** the catalog. smartalfred reads it as it is (about once a minute), so a
folder merged here shows up on the page by itself.

## How it's laid out

One folder per deploy. The folder's name is its address (`umami` → `smartalfred.com/one-click/umami`),
and it holds one `smartalfred.toml`, and a `README.md` saying what the app is:

```
umami/
  smartalfred.toml
  README.md
```

The `README.md` is the longer text on the deploy's page (the catalog's card shows only the
`description`): what the app is, what people use it for, and what's good to know about this setup.
Its `# Title` line is left out there; `###` headings, lists, **bold**, `code` and links are shown.

It's the same file a project keeps beside its code ([its docs](https://smartalfred.com/docs/smartalfred-toml)):
services, databases and buckets, wired together with references, secrets generated. What the
catalog shows for it lives in the same file, under `[template]`.

```toml
[template]
name = "Umami"                    # required
description = "Privacy-friendly web analytics you host yourself."
category = "Analytics"
website = "https://umami.is"
logo = "logo.svg"                 # optional: a file in the folder, or a URL
after = """
Open ${{umami.URL}} and log in with `admin` / `umami`, then change the password.
"""

[template.inputs.ADMIN_EMAIL]     # asked for in the form
label = "Admin email"
description = "Where password resets go."
required = true

[services.umami]
image = "ghcr.io/umami-software/umami:latest"
port = 3000
always_on = true
health_path = "/api/heartbeat"

[services.umami.env]
DATABASE_URL = "${{umami-db.DATABASE_URL}}"
ADMIN_EMAIL = "${ADMIN_EMAIL}"

[services.umami.secrets]
APP_SECRET = "generate"

[databases.umami-db]
engine = "postgres"
```

## What the file means

Everything outside `[template]` is an ordinary smartalfred.toml, and deploying the folder makes
what it says, the way a deploy of a project's own file makes it. In short:

| In the file | On smartalfred |
| --- | --- |
| `[services.<name>]` with `image` | a service running that image. Public (an HTTPS address) unless `public = false` |
| `port` | where it listens (`$PORT` is set to it) |
| `[services.<name>.env]` | its variables |
| `[services.<name>.secrets]` | its secrets: `"generate"` makes one when deploying (`"generate:32"` for a length; `{ generate = 64, hex = true }` for hex digits; `{ generate = 32, prefix = "sk-" }` for keys that start a certain way) |
| `[[services.<name>.volumes]]` | volumes that keep their data across deploys (`name`, `path`) |
| `command`, `entrypoint` | instead of the image's |
| `always_on`, `health_path`, `memory` | never asleep; a path that answers once it's ready; its size |
| `[databases.<name>]` | a Postgres, MySQL or Redis made the way the dashboard makes one: private, always on, a snapshot every day |
| `[buckets.<name>]` | a bucket (files over S3) |

Services reach each other by name (`http://meilisearch:7700`), and read each other's values with
**references**: `${{umami-db.DATABASE_URL}}`, `${{langfuse.SALT}}`, `${{n8n.URL}}`. smartalfred fills
them in for the containers and keeps them up to date. What a reference can read:

| Of | |
| --- | --- |
| any service | `URL` (its HTTPS address when it's public), `HOST` (its name inside the project), `PORT`, `NAME`; a service reads only these of itself |
| a service of the file | its variables and secrets: a password generated once and shared by several services lives on one, and the others refer to it |
| a Postgres database | `DATABASE_URL`, `POSTGRES_USER`, `POSTGRES_DB`, `POSTGRES_PASSWORD` |
| a MySQL database | `DATABASE_URL`, `MYSQL_USER`, `MYSQL_DATABASE`, `MYSQL_PASSWORD` |
| a Redis database | `REDIS_URL`, `REDIS_PASSWORD` |
| a bucket | `S3_ENDPOINT`, `S3_BUCKET`, `S3_REGION`, `S3_ACCESS_KEY_ID`, `S3_SECRET_ACCESS_KEY` |

A reference goes one level: point at the value itself, not at another service's reference to it.
And a one-click deploy may go into an empty project, so its references point only at what its own
file makes.

### What the form asks for

Declare each value under `[template.inputs.NAME]` and write `${NAME}` where it goes, in `env`
values and in `after` (`$$` is a `$` of its own):

| Key | Meaning |
| --- | --- |
| `label`, `description` | how the form asks for it |
| `default` | used when the form is left empty |
| `required = true` | the form insists |

A secret the person deploying has to give (an API key) is `"ask"` under the service's `secrets`, as
in any smartalfred.toml: the form asks for it as a secret, and every service that asks for it by
that name gets it. Give it a label with an input of the same name (no default, and not written as
`${NAME}`: the services that need it ask for it, or refer to it).

### After deploying

`after` (Markdown) is shown once, to the person who deployed, together with the generated secrets.
`${{name.URL}}` (and `HOST`, `PORT`, `NAME`) of what the file makes are filled in there, and the
inputs too. Other references stay as written, so `${{postgres.DATABASE_URL}}` in `after` tells
people what to put in their own app.

### Building an image

A service can have `dockerfile = "Dockerfile"` instead of `image`, with a `Dockerfile` in the folder.
It's then built on the server it runs on, from this repository (see `pocketbase/`). Prefer a
published image where the project offers one.

### What a one-click deploy can't say

`project` and `organization` (it goes into the project it's deployed to), `[computers]`, and
`domains` (a domain is someone's own).

## Good practice

- **Name things after the app** (`umami`, `umami-db`, not `app`, `db`): a project can hold several
  deploys, and two things can't share a name.
- **Use smartalfred's databases** (`[databases.x]`) for Postgres, MySQL and Redis: they come with
  daily snapshots, and apps get their URL by reference. Run another image only for what they aren't.
- **Pin what matters**: a major version for images whose data format changes (`getmeili/meilisearch:v1.54`).
- **Generate every password**: nobody should have to think of one, and none should be in the file.
- **Say what to do first** under `after`: the default login, what to change.
- **Say what it's for** in the folder's `README.md`: what it is, what people use it for, what's good to know.
- **Keep it small**: the fewer services, the more servers it fits on. Say so in the description when it needs real memory.
- **Mind the licence**: say so in the description when something isn't open source in the usual sense.
- **Slow starters** (more than half a minute to open their port) should be `always_on` and have a `health_path`, and say in `after` that the first start takes a while.

## Adding one

1. Fork, add a folder with a `smartalfred.toml`, open a pull request.
2. Try it before: put the file (without `[template]`, with values for any `${…}`) in an empty
   directory and run `smartalfred deploy` into a test project.
3. A folder that can't be read is left out of the catalog; `https://api.smartalfred.com/api/v1/templates`
   lists such folders under `problems`, with the reason.
