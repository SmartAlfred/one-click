# One node of the replica set: MongoDB, and the script that starts it and, once, sets up the set
# and its users.

# MongoDB's version is its data's: members are rebuilt from here when redeployed, and an upgrade
# goes one version at a time. A new version is a new folder, not a change here.
FROM mongo:8.0

COPY --chmod=755 node.sh /usr/local/bin/

ENTRYPOINT ["node.sh"]
