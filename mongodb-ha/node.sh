#!/bin/bash
# Starts one node: mongod as a member of the replica set rs0. Once, the set is made (by the first
# node, when all three answer) and then its users (by whichever node is the primary). After that
# MongoDB itself chooses a primary, also after all three were down.
#
# NODE is this node's name and PEERS all three (the services' names, which is how they reach each
# other). If mongod ends, so does the container, and smartalfred starts it again.
set -euo pipefail

: "${NODE:?NODE is the name of this node}" "${PEERS:?PEERS are the names of all three nodes}"
: "${MONGO_KEYFILE:?}" "${MONGO_ROOT_PASSWORD:?}" "${MONGO_USER:?}" "${MONGO_PASSWORD:?}" "${MONGO_DATABASE:?}"

# The data in a directory inside the volume; the key the members prove themselves to each other
# with, readable by mongod alone.
DATA=/data/db/data
install -d -o mongodb -g mongodb -m 700 "$DATA"
install -o mongodb -g mongodb -m 400 <(printf '%s' "$MONGO_KEYFILE") /etc/mongo-keyfile

gosu mongodb mongod \
  --replSet rs0 --keyFile /etc/mongo-keyfile \
  --bind_ip_all --port 27017 --dbpath "$DATA" \
  --wiredTigerCacheSizeGB 0.25 \
  --quiet &
mongod=$!

mongo() { mongosh --quiet --host "$1" --eval "$2" 2>/dev/null; }
as_root() { mongosh --quiet "mongodb://root:$MONGO_ROOT_PASSWORD@${PEERS// /:27017,}:27017/admin?replicaSet=rs0" --eval "$1" 2>/dev/null; }

set_up() {
  set +e
  until [ "$(mongo 127.0.0.1 'db.hello().ok')" = 1 ]; do sleep 1; done
  # The set, made by the first node once all three answer and none is in a set (one that is has
  # it already, and a node that lost its data gets it back from the others).
  if [ "$NODE" = "${PEERS%% *}" ]; then
    while true; do
      local peer answered=0 in_set=0
      for peer in $PEERS; do
        case "$(mongo "$peer" 'db.hello().setName ?? "none"')" in
          none) answered=$((answered + 1)) ;;
          rs0) in_set=1 ;;
        esac
      done
      [ "$in_set" = 1 ] && break
      if [ "$answered" = 3 ]; then
        echo "node.sh: making the replica set" >&2
        mongo 127.0.0.1 'rs.initiate({ _id: "rs0", members: process.env.PEERS.split(" ").map((host, i) => ({ _id: i, host: `${host}:27017` })) })'
      fi
      sleep 2
    done
  fi
  # Root, by the primary, through the localhost exception (there until the first user exists).
  until [ "$(as_root 'db.runCommand({ ping: 1 }).ok')" = 1 ]; do
    if [ "$(mongo 127.0.0.1 'db.hello().isWritablePrimary')" = true ]; then
      mongo 127.0.0.1 'db.getSiblingDB("admin").createUser({ user: "root", pwd: process.env.MONGO_ROOT_PASSWORD, roles: ["root"] })' >/dev/null &&
        echo "node.sh: made the root user" >&2
    fi
    sleep 2
  done
  # The app's user, with rights to its own database only.
  until [ "$(as_root 'db.getSiblingDB(process.env.MONGO_DATABASE).getUser(process.env.MONGO_USER) !== null')" = true ]; do
    as_root 'db.getSiblingDB(process.env.MONGO_DATABASE).createUser({ user: process.env.MONGO_USER, pwd: process.env.MONGO_PASSWORD, roles: ["dbOwner"] })' >/dev/null &&
      echo "node.sh: made the user $MONGO_USER" >&2
    sleep 2
  done
}
set_up &

# A stop: a primary steps down first, so a secondary takes over before it goes.
trap 'kill -TERM "$mongod" 2>/dev/null; wait "$mongod"; exit 0' TERM INT
set +e
wait "$mongod"
code=$?
echo "node.sh: mongod ended ($code)" >&2
exit $((code ? code : 1))
