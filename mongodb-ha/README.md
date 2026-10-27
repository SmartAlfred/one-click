# MongoDB HA cluster

A MongoDB 8.0 [replica set](https://www.mongodb.com/docs/manual/replication/) of three members that hold the same data. One is the primary, which takes the writes; the other two are secondaries that copy every change. When the primary goes, the other two elect a new one themselves, and a write counts once most of the set has it. [HAProxy](https://www.haproxy.org) sits in front for clients that want one address and always reaches the primary.

### What people use it for

- A database that stays up when a node crashes, its server restarts or a node is redeployed: a new primary is elected within about 10 seconds, or at once when a node is stopped on purpose.
- Spreading reads over the secondaries: reports, exports and other heavy queries.
- Apps that can't lose a write: what was acknowledged is on most of the set, so a failover loses nothing.

### How it fits together

- `mongodb-ha-1`, `mongodb-ha-2` and `mongodb-ha-3` are the members, each with a volume of its own. On the first start they form the set `rs0` and make the users `root` (database `admin`) and `app` (database `app`).
- MongoDB's drivers are best given all three (`mongodb://…@mongodb-ha-1:27017,mongodb-ha-2:27017,mongodb-ha-3:27017/app?replicaSet=rs0`): they find the primary themselves and follow it when it changes, with retried writes.
- `mongodb-ha` is HAProxy, for clients that take one address (`directConnection=true`): port 27017 reaches the primary, 27018 the secondaries, and 8404 is its status page (inside the project). The cluster's passwords live on it.
- In a shell on a member, `mongosh -u root -p "$MONGO_ROOT_PASSWORD"` and `rs.status()` show the set.

### Good to know

- **Size:** each member is an m (1 GB), HAProxy an xs (256 MB): 3.25 GB in all, and 5 GB of disk per member that grows by itself up to 50 GB. Each member's cache is 256 MB.
- **One server or several:** smartalfred places each member on a server with room for it, but doesn't yet promise three different servers. Where they share one, the set gets through a member failing, restarts and redeploys, but not that server going down.
- **Two of three:** the set needs two members to elect a primary. With one left it takes no writes, until a second is back.
- **HAProxy is one service:** if it stops, smartalfred starts it again within seconds; apps with the replica set's address don't go through it at all.
- **Replication isn't a backup:** a dropped collection is gone on all three at once. Take dumps (`mongodump` from another service), or give a member's volume a snapshot schedule: the member stands still while it's copied, so if it's the primary, another is elected.
- **The passwords are set once:** they're written into the cluster when it's made. Changing one later in `mongodb-ha`'s variables doesn't change it there, and the nodes can no longer sign in to each other.
