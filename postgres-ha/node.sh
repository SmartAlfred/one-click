#!/bin/bash
# Starts one node: etcd, then Patroni, which runs PostgreSQL as the primary or as a replica of it.
#
# NODE is this node's name and PEERS all three (the services' names, which is how they reach each
# other). If etcd or Patroni ends, so does the container, and smartalfred starts it again. A stop
# stops Patroni first: a primary hands over to a replica while etcd is still there to say so.
set -euo pipefail

: "${NODE:?NODE is the name of this node}" "${PEERS:?PEERS are the names of all three nodes}"
: "${CLUSTER_PASSWORD:?}" "${POSTGRES_SUPERUSER_PASSWORD:?}" "${REPLICATION_PASSWORD:?}"
SCOPE=${SCOPE:-postgres-ha}

# The volume: PostgreSQL's data and etcd's, each in a directory of its own.
DATA=/var/lib/postgresql/data
install -d -o postgres -g postgres -m 700 "$DATA/pgdata" "$DATA/etcd"

cluster="" hosts=""
for peer in $PEERS; do
  cluster+="${cluster:+,}$peer=http://$peer:2380"
  hosts+="${hosts:+,}$peer:2379"
done

# On the first start the three make one etcd cluster; after that its data directory says who's in
# it and the --initial-* settings are ignored. Old revisions are compacted, or it fills up.
gosu postgres etcd \
  --name "$NODE" --data-dir "$DATA/etcd" \
  --listen-peer-urls http://0.0.0.0:2380 --initial-advertise-peer-urls "http://$NODE:2380" \
  --listen-client-urls http://0.0.0.0:2379 --advertise-client-urls "http://$NODE:2379" \
  --initial-cluster "$cluster" --initial-cluster-token "$SCOPE" --initial-cluster-state new \
  --auto-compaction-mode periodic --auto-compaction-retention 1h \
  --log-level warn &
etcd=$!

# etcd answers once two of the three are up. The first node to see that turns its passwords on, so
# only Patroni can change who's the primary (or the settings it hands PostgreSQL). The check with
# the password works before the passwords are on, and after.
local_etcd() { etcdctl --endpoints=http://127.0.0.1:2379 "$@"; }
until local_etcd --user "root:$CLUSTER_PASSWORD" endpoint health >/dev/null 2>&1; do
  kill -0 "$etcd" 2>/dev/null || exit 1
  sleep 1
done
if ! local_etcd --user "root:$CLUSTER_PASSWORD" auth status 2>/dev/null | grep -q 'Status: true'; then
  local_etcd user add root --new-user-password "$CLUSTER_PASSWORD" >/dev/null 2>&1 || true
  local_etcd auth enable >/dev/null 2>&1 || true
fi

export PATRONI_NAME="$NODE" PATRONI_SCOPE="$SCOPE"
export PATRONI_RESTAPI_CONNECT_ADDRESS="$NODE:8008" PATRONI_POSTGRESQL_CONNECT_ADDRESS="$NODE:5432"
export PATRONI_ETCD3_HOSTS="$hosts" PATRONI_ETCD3_USERNAME=root PATRONI_ETCD3_PASSWORD="$CLUSTER_PASSWORD"
export PATRONI_RESTAPI_USERNAME=patroni PATRONI_RESTAPI_PASSWORD="$CLUSTER_PASSWORD"
export PATRONI_SUPERUSER_USERNAME=postgres PATRONI_SUPERUSER_PASSWORD="$POSTGRES_SUPERUSER_PASSWORD"
export PATRONI_REPLICATION_USERNAME=replicator PATRONI_REPLICATION_PASSWORD="$REPLICATION_PASSWORD"

# For `patronictl list` (and switchover, restart, edit-config) in a shell on the node.
umask 077
cat >/etc/patroni/patronictl.yml <<EOF
scope: $SCOPE
etcd3: {hosts: "$hosts", username: root, password: "$CLUSTER_PASSWORD"}
ctl: {authentication: {username: patroni, password: "$CLUSTER_PASSWORD"}}
EOF
umask 022

gosu postgres patroni /etc/patroni/patroni.yml &
patroni=$!

stop() {
  kill -TERM "$patroni" 2>/dev/null || true
  wait "$patroni" || true
  kill -TERM "$etcd" 2>/dev/null || true
  wait "$etcd" || true
  exit 0
}
trap stop TERM INT

# Until one of them ends by itself: then the node is broken, and starting it again is the cure.
set +e
wait -n "$etcd" "$patroni"
code=$?
echo "node.sh: $( kill -0 "$etcd" 2>/dev/null && echo Patroni || echo etcd ) ended ($code); stopping the node" >&2
kill -TERM "$patroni" "$etcd" 2>/dev/null
wait
exit $(( code ? code : 1 ))
