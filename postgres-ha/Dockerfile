# One node of the cluster: PostgreSQL, Patroni (which runs it, as the primary or a replica, and
# fails over) and etcd (where the three nodes agree on which of them is the primary).
FROM quay.io/coreos/etcd:v3.6.16 AS etcd

# PostgreSQL's major version is its data's: nodes are rebuilt from here when redeployed, and 17's
# data doesn't start on 18. A new major is a new folder, not a change here.
FROM postgres:17

# Patroni from the PostgreSQL project's own packages, which the image is built from already.
RUN apt-get update \
 && apt-get install -y --no-install-recommends patroni python3-etcd \
 && rm -rf /var/lib/apt/lists/*

COPY --from=etcd /usr/local/bin/etcd /usr/local/bin/etcdctl /usr/local/bin/
COPY patroni.yml /etc/patroni/patroni.yml
COPY --chmod=755 node.sh post-init.sh /usr/local/bin/

# Written by node.sh, so `patronictl list` works in a shell on the node.
ENV PATRONICTL_CONFIG_FILE=/etc/patroni/patronictl.yml

ENTRYPOINT ["node.sh"]
