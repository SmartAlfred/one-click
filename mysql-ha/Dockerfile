# One node of the cluster: MySQL with Group Replication (in the image already), the script that
# keeps it in the group, and ncat for the answers HAProxy asks for.

# MySQL's version is its data's: nodes are rebuilt from here when redeployed. A new LTS is a new
# folder, not a change here.
FROM mysql:8.4

RUN microdnf --assumeyes install nmap-ncat && microdnf clean all

COPY --chmod=755 node.sh health.sh /usr/local/bin/
# Run once by the image's own entrypoint, when the node's data directory is first made.
COPY init.sh /docker-entrypoint-initdb.d/

ENTRYPOINT ["node.sh"]
