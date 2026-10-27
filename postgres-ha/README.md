# PostgreSQL HA cluster

Three PostgreSQL 17 servers that hold the same data, with one address in front of them. One is the primary, which takes the writes; the other two are replicas that copy every change as it happens. [Patroni](https://patroni.readthedocs.io) runs PostgreSQL on each node and decides which one is the primary, and the three keep that agreement in [etcd](https://etcd.io), which runs beside Patroni on every node. [HAProxy](https://www.haproxy.org) asks each node's Patroni what it is and sends connections to the primary.

### What people use it for

- A database that stays up when a node crashes, its server restarts or a node is redeployed: a replica takes over within about half a minute, or within seconds when a node is stopped on purpose.
- Spreading reads over the replicas (port 5433): reports, exports and other heavy queries.
- Apps that can't lose a write: a commit waits until a replica has it too, so a failover loses nothing.

### How it fits together

- `postgres-ha` is HAProxy, the address apps use: port 5432 reaches the primary, 5433 the replicas, and 8404 is its status page (inside the project). The cluster's passwords live on it.
- `postgres-ha-1`, `postgres-ha-2` and `postgres-ha-3` are the nodes, each with a volume of its own. In a shell on any of them, `patronictl list` shows which is the primary and how far behind the replicas are; `patronictl switchover` moves the primary on purpose.

### Good to know

- **Size:** each node is an m (1 GB), HAProxy an xs (256 MB): 3.25 GB in all, and 5 GB of disk per node that grows by itself up to 50 GB.
- **One server or several:** smartalfred places each node on a server with room for it, but doesn't yet promise three different servers. Where they share one, the cluster gets through a node failing, restarts and redeploys, but not that server going down.
- **Two of three:** the nodes need two of them to agree. With only one left it stops taking writes, until a second is back.
- **HAProxy is one service:** if it stops, smartalfred starts it again within seconds.
- **Replication isn't a backup:** a dropped table is gone on all three at once. Take dumps (`pg_dump` from another service, through port 5432), or give a node's volume a snapshot schedule: the node stands still while it's copied, so if it's the primary, a replica takes over.
- With both replicas gone, the primary carries on alone rather than stop, and waits for a replica again once one is back.
- Only Patroni can change who's the primary or PostgreSQL's settings: etcd and Patroni's API take `CLUSTER_PASSWORD`.
- **The passwords are set once:** they're written into the cluster when it's made. Changing one later in `postgres-ha`'s variables doesn't change it there, and the nodes can no longer sign in to each other.
