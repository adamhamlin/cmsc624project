# **Shuk**
*A pay-per-query data marketplace*

Advanced Database Design - Final Project (Fall 2019)

# Dependencies
Of note, you will need `docker`, `docker-compose`, and some postgres client tools like `psql` and `pg_isready`.

# Running the demo
To spin up networked containers for the coordinator and multiple contractors, run the following:
```bash
make run CONTRACTORS=3
```
The coordinator will have read access to any tables on contractor_X under schema `contractor_X`. You can connect a client to the coordinator by running:
```bash
make psql-coordinator
```
To execute a query that will compute query cost and payouts, use the following dummy example:
```sql
select * from pay_per_query('select a.id, b.id, add_sources(a.source, b.source) as source
from contractor_1.bleep a join contractor_2.bloop b on true')
as t(id1 int, id2 int, source jsonb);
```
...where `bleep` and `bloop` are valid table names. As done above, the `source` column must be selected and concatenated (using `add_sources`) or aggregated (using `agg_source`) as applicable in every query/subquery.

To spin down:
```bash
make stop
```

# Development
If you make changes to the Dockerfiles or initialization files, you'll need to rebuild before running again
```bash
make build
```
For convenience, you quickly spin down any existing containers, re-build, and re-run using the following:
```bash
make retry  # or alternatively `make retry CONTRACTORS=4`
```

Check out the Makefile for other commands/shortcuts.

# Resources
- [PostgreSQL Hooks](https://github.com/AmatanHead/psql-hooks/blob/master/Detailed.md)
- [Info about our postgres docker image](https://hub.docker.com/r/centos/postgresql-10-centos7). See `./src/contractor/init` for an example of how to extend it
- [User-friendly PostreSQL Source Code and Documentation](https://doxygen.postgresql.org/annotated.html)