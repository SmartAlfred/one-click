# MySQL HA cluster

Three MySQL 8.4 servers that hold the same data, with one address in front of them. They form a [Group Replication](https://dev.mysql.com/doc/refman/8.4/en/group-replication.html) group, MySQL's own: one is the primary, which takes the writes, and a transaction commits only once most of the group has it. When the primary goes, the other two choose a new one themselves. [HAProxy](https://www.haproxy.org) asks each node what it is and sends connections to the primary.

### What people use it for

- A database that stays up when a node crashes, its server restarts or a node is redeployed: a new primary takes over within about 15 seconds, or within seconds when a node is stopped on purpose.
- Spreading reads over the other two (port 3307): reports, exports and other heavy queries.
- Apps that can't lose a write: what was committed is on most of the group, so a failover loses nothing.

### How it fits together

- `mysql-ha` is HAProxy, the address apps use: port 3306 reaches the primary, 3307 the other two, and 8404 is its status page (inside the project). The cluster's passwords live on it.
- `mysql-ha-1`, `mysql-ha-2` and `mysql-ha-3` are the nodes, each with a volume of its own. A small script on each keeps it in the group: it joins the group when it starts, and when all three were down, the node with the most transactions starts the group again once all three are back. On port 8008 each node says what it is (`/primary`, `/replica`, `/health`), which is what HAProxy asks.
- In a shell on a node, `mysql` signs in as root; `SELECT * FROM performance_schema.replication_group_members` shows the group.

### Good to know

- **Every table needs a primary key:** Group Replication refuses changes to a table without one. Tables are InnoDB (MyISAM and the other engines are switched off).
- **Size:** each node is an m (1 GB), HAProxy an xs (256 MB): 3.25 GB in all, and 5 GB of disk per node that grows by itself up to 50 GB.
- **One server or several:** smartalfred places each node on a server with room for it, but doesn't yet promise three different servers. Where they share one, the cluster gets through a node failing, restarts and redeploys, but not that server going down.
- **Two of three:** the group needs two nodes to take writes. A node left on its own turns read-only after 30 seconds, and rejoins when the others are back.
- **A node gone for good:** if all three were down and one can't come back, the group isn't started again by itself (the missing node might have had the newest transactions). Start it on the node with the most: `mysql -e "SET GLOBAL group_replication_bootstrap_group = ON; START GROUP_REPLICATION; SET GLOBAL group_replication_bootstrap_group = OFF"`. The other one joins by itself.
- **HAProxy is one service:** if it stops, smartalfred starts it again within seconds.
- **Replication isn't a backup:** a dropped table is gone on all three at once. Take dumps (`mysqldump --single-transaction` from another service, through port 3306), or give a node's volume a snapshot schedule: the node stands still while it's copied, so if it's the primary, another takes over.
- **The passwords are set once:** they're written into the cluster when it's made. Changing one later in `mysql-ha`'s variables doesn't change it there, and the nodes can no longer sign in to each other.
