#!/bin/bash
# Starts one node: MySQL with Group Replication (single primary); a loop that keeps the node in the
# group (joins it, or starts it again when all three were down); and health.sh on port 8008, which
# HAProxy asks which node is the primary.
#
# NODE is this node's name and PEERS all three (the services' names, which is how they reach each
# other). If MySQL or the answers on 8008 end, so does the container, and smartalfred starts it
# again.
set -euo pipefail

: "${NODE:?NODE is the name of this node}" "${PEERS:?PEERS are the names of all three nodes}"
: "${GROUP_NAME:?}" "${MYSQL_ROOT_PASSWORD:?}" "${REPLICATION_PASSWORD:?}"

id=0 n=0 seeds=""
for peer in $PEERS; do
  n=$((n + 1))
  [ "$peer" = "$NODE" ] && id=$n
  seeds+="${seeds:+,}$peer:3306"
done
[ "$id" -gt 0 ] || { echo "node.sh: $NODE isn't one of PEERS ($PEERS)" >&2; exit 1; }

# Root's password for the mysql client, here and in a shell on the node.
umask 077
printf '[client]\nuser=root\npassword=%s\n' "$MYSQL_ROOT_PASSWORD" >/root/.my.cnf
umask 022

# The group talks over MySQL's own port, signed in as replicator, encrypted. A node that loses the
# majority leaves the group after 30 seconds and turns read-only; the loop below takes it back.
docker-entrypoint.sh mysqld \
  --datadir=/var/lib/mysql/data \
  --server-id="$id" --report-host="$NODE" \
  --gtid-mode=ON --enforce-gtid-consistency=ON \
  --disabled-storage-engines=MyISAM,BLACKHOLE,FEDERATED,ARCHIVE,MEMORY \
  --plugin-load-add=group_replication.so --plugin-load-add=mysql_clone.so \
  --loose-group-replication-group-name="$GROUP_NAME" \
  --loose-group-replication-communication-stack=MYSQL \
  --loose-group-replication-local-address="$NODE:3306" \
  --loose-group-replication-group-seeds="$seeds" \
  --loose-group-replication-start-on-boot=OFF \
  --loose-group-replication-recovery-use-ssl=ON \
  --loose-group-replication-ssl-mode=REQUIRED \
  --loose-group-replication-exit-state-action=READ_ONLY \
  --loose-group-replication-autorejoin-tries=0 \
  --loose-group-replication-unreachable-majority-timeout=30 \
  --loose-group-replication-message-cache-size=134217728 &
mysqld=$!

ncat --listen --keep-open 8008 --exec /usr/local/bin/health.sh &
health=$!

here() { mysql -h127.0.0.1 -NB -e "$1"; }
there() { mysql -h"$1" --connect-timeout=2 -NB -e "$2" 2>/dev/null; }
STATE="SELECT MEMBER_STATE FROM performance_schema.replication_group_members WHERE MEMBER_ID = @@server_uuid"

# Joins a group another node is in. With none anywhere and all three up (a first start, or all
# three were down), the node with the most transactions starts it again: with equal ones, the
# first in PEERS. All three nodes see the same, so only one starts it. With a node missing, nobody
# does: it may have the newest transactions (README says how to start it by hand).
join_or_start() {
  local peer theirs cmp seen_me=0
  for peer in $PEERS; do
    if [ "$peer" != "$NODE" ] && [ "$(there "$peer" "$STATE")" = ONLINE ]; then
      echo "node.sh: joining the group ($peer is in it)" >&2
      here "START GROUP_REPLICATION" || true
      return
    fi
  done
  for peer in $PEERS; do
    if [ "$peer" = "$NODE" ]; then seen_me=1; continue; fi
    theirs=$(there "$peer" "SELECT @@GLOBAL.gtid_executed") || return 0 # not up (yet)
    cmp=$(here "SELECT CONCAT(GTID_SUBSET('$theirs', @@GLOBAL.gtid_executed), GTID_SUBSET(@@GLOBAL.gtid_executed, '$theirs'))") || return 0
    case "$cmp" in
      10) ;;                                 # this node has more
      11) [ "$seen_me" = 1 ] || return 0 ;;  # the same: the first in PEERS starts it
      01) return 0 ;;                        # the other has more
      *) echo "node.sh: $NODE and $peer each have transactions the other hasn't; start the group by hand on the right one" >&2; return 0 ;;
    esac
  done
  echo "node.sh: no node is in a group; starting it" >&2
  here "SET GLOBAL group_replication_bootstrap_group = ON; START GROUP_REPLICATION; SET GLOBAL group_replication_bootstrap_group = OFF" ||
    here "SET GLOBAL group_replication_bootstrap_group = OFF" || true
}

keep() {
  set +e
  # The real server: the one setting up a new data directory takes no connections over the network.
  until here "SELECT 1" >/dev/null 2>&1; do sleep 2; done
  here "CHANGE REPLICATION SOURCE TO SOURCE_USER = 'replicator', SOURCE_PASSWORD = '$REPLICATION_PASSWORD' FOR CHANNEL 'group_replication_recovery'"
  while true; do
    case "$(here "$STATE" 2>/dev/null)" in
      ONLINE | RECOVERING) ;;
      ERROR) here "STOP GROUP_REPLICATION" ;;
      *) join_or_start ;;
    esac
    sleep 5
  done
}
keep &
keeper=$!

stop() {
  kill "$keeper" "$health" 2>/dev/null || true
  kill -TERM "$mysqld" 2>/dev/null || true
  wait "$mysqld" || true
  exit 0
}
trap stop TERM INT

set +e
wait -n "$mysqld" "$health" "$keeper"
code=$?
echo "node.sh: $(kill -0 "$mysqld" 2>/dev/null && echo 'a helper' || echo MySQL) ended ($code); stopping the node" >&2
kill "$keeper" "$health" 2>/dev/null
kill -TERM "$mysqld" 2>/dev/null
wait
exit $((code ? code : 1))
