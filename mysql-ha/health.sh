#!/bin/bash
# One answer on port 8008 (ncat runs this for each connection), in the manner of Patroni's:
# /primary is 200 only on the primary and /replica only on a secondary, each only while it's in a
# group that reaches a majority of its members (a node still catching up counts; one the others
# can't reach doesn't); /health on any member of such a group. HAProxy asks.
read -r -t 2 _ path _ || exit 0
while read -r -t 1 line && [ -n "${line%$'\r'}" ]; do :; done # the rest of the request

row=$(mysql -h127.0.0.1 --connect-timeout=2 -NB -e "
  SELECT MEMBER_ROLE, MEMBER_STATE,
         (SELECT COUNT(*) FROM performance_schema.replication_group_members WHERE MEMBER_STATE <> 'UNREACHABLE') * 2
           > (SELECT COUNT(*) FROM performance_schema.replication_group_members)
    FROM performance_schema.replication_group_members WHERE MEMBER_ID = @@server_uuid" 2>/dev/null)
read -r role state majority <<<"$row"

ok=
case "$path" in
  /primary) [ "$role $state $majority" = "PRIMARY ONLINE 1" ] && ok=1 ;;
  /replica) [ "$role $state $majority" = "SECONDARY ONLINE 1" ] && ok=1 ;;
  /health) [ "$state $majority" = "ONLINE 1" ] && ok=1 ;;
esac
body="${role:-NONE} ${state:-DOWN}"$'\n'
printf 'HTTP/1.0 %s\r\nContent-Type: text/plain\r\nContent-Length: %d\r\nConnection: close\r\n\r\n%s' \
  "$([ -n "$ok" ] && echo '200 OK' || echo '503 Service Unavailable')" "${#body}" "$body"
