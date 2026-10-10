# smartalfred one-click deploys

Ready-made stacks you can put into a [smartalfred](https://smartalfred.com) project with one click:
an app together with its database and settings. Browse them at
[smartalfred.com/one-click](https://smartalfred.com/one-click).

This repository **is** the catalog. smartalfred reads it as it is (about once a minute), so a
folder merged here shows up on the page by itself.

## How it's laid out

One folder per deploy. The folder's name is its address (`umami` → `smartalfred.com/one-click/umami`),
and it holds one `docker-compose.yml`:

```
umami/
  docker-compose.yml
```

The compose file is an ordinary one. What smartalfred shows for it lives in the same file, under
`x-smartalfred` (compose ignores keys that start with `x-`, so the file still works with
`docker compose up`).

```yaml
x-smartalfred:
  name: Umami                     # required
  description: Privacy-friendly web analytics you host yourself.
  category: Analytics
  website: https://umami.is
  logo: logo.svg                  # optional: a file in the folder, or a URL
  variables:
    POSTGRES_PASSWORD:
      generate: password          # made up at deploy time, stored as a secret
    APP_SECRET:
      generate: hex
    ADMIN_EMAIL:                  # asked for in the form
      label: Admin email
      description: Where password resets go.
      required: true
  after: |                        # shown after deploying (Markdown)
    Log in with `admin` / `umami` and change the password.

services:
  umami:
    image: ghcr.io/umami-software/umami:latest
    ports: ["3000:3000"]
    environment:
      DATABASE_URL: postgresql://umami:${POSTGRES_PASSWORD}@umami-db:5432/umami
  umami-db:
    image: postgres:15-alpine
    volumes: ["umami-db-data:/var/lib/postgresql/data"]
```

## What the compose file means on smartalfred

| In the file | On smartalfred |
| --- | --- |
| a service with `ports:` | public: it gets an HTTPS address (the first port is the one served) |
| a service without `ports:` | private: reachable only by the other services, as `name:port` |
| `environment:` | variables; a value built from a generated or secret variable is stored as a secret |
| named `volumes:` | volumes that keep their data across deploys |
| `command:`, `entrypoint:` | taken over |
| `depends_on:`, `restart:`, `networks:` | not needed: services of a project share a private network, and private ones start first |
| bind mounts (`./file:/path`) | skipped: there's no machine to take the file from |

Labels for what compose can't say:

| Label | Meaning |
| --- | --- |
| `smartalfred.public: "true"` / `"false"` | public or private, whatever `ports:` says |
| `smartalfred.always_on: "true"` | never sleeps (by default a public service sleeps when idle and wakes on the next request) |
| `smartalfred.health_path: /health` | a path that answers once the app is ready; a new version takes over only then |

### Variables

Write `${NAME}` in the compose file and declare `NAME` under `x-smartalfred.variables`:

| Key | Meaning |
| --- | --- |
| `generate: password` | 32 letters and digits, made up when deploying (safe inside a connection URL) |
| `generate: hex` | a 64-character hex key |
| `length: 48` | another length for a generated value (8 to 128) |
| `label`, `description` | how the form asks for it |
| `default` | used when the form is left empty |
| `required: true` | the form insists |
| `secret: true` / `false` | whether values built from it are stored as secrets (default: yes for generated ones) |

## Good practice

- **Name services after the app** (`umami`, `umami-db`, not `app`, `db`): a project can hold several
  deploys, and two services can't share a name.
- **Pin what matters**: a major version for databases (`postgres:15-alpine`), so an upgrade is a decision.
- **Generate every password**: nobody should have to think of one, and none should be in the file.
- **Say what to do first** under `after`: the default login, what to change.

## Adding one

1. Fork, add a folder with a `docker-compose.yml`, open a pull request.
2. Try it before: `docker compose up` locally with the variables set.
3. A folder that can't be read is left out of the catalog; `https://api.smartalfred.com/api/v1/templates`
   lists such folders under `problems`, with the reason.
