# Read by the image's entrypoint once, when the node's data directory is first made, after it set
# up root and the app's user and database.
#
# The replicator user is each node's own (not replicated): it's what the others copy with. Then the
# node forgets the history of what was written so far (time zones, the app's user), which every
# node did the same: so all three start with an empty one, and the group can form.
docker_process_sql --database=mysql <<-EOSQL
	SET SQL_LOG_BIN = 0;
	CREATE USER 'replicator'@'%' IDENTIFIED BY '${REPLICATION_PASSWORD}';
	GRANT REPLICATION SLAVE, CONNECTION_ADMIN, BACKUP_ADMIN, CLONE_ADMIN, GROUP_REPLICATION_STREAM ON *.* TO 'replicator'@'%';
	SET SQL_LOG_BIN = 1;
	RESET BINARY LOGS AND GTIDS;
EOSQL
