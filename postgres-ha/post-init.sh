#!/bin/bash
# Run by Patroni once, on the first primary, right after the database cluster is made: the app's
# user and its database. Replicated to the other nodes from there. $1 is how to connect.
set -euo pipefail

psql "$1" -v ON_ERROR_STOP=1 -v user="$POSTGRES_USER" -v db="$POSTGRES_DB" -v password="$POSTGRES_PASSWORD" <<'SQL'
CREATE ROLE :"user" LOGIN PASSWORD :'password';
CREATE DATABASE :"db" OWNER :"user";
SQL
