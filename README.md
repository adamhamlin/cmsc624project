# cmsc624project
Advanced Database Design - Final Project (Fall 2019)

# Dependencies
Of note, you will need `docker`, `docker-compose`, and some postgres client tools like `psql` and `pg_isready`.

# Development
To spin up the networked containers for the coordinator and multiple contractors, run the following:
```bash
make run CONTRACTORS=3
```
The coordinator will have read access to any tables on contractor_X under schema `contractor_X`. You can connect a client to the coordinator by running:
```bash
make psql-coordinator
```
To spin down:
```bash
make stop
```

Check out the Makefile for other commands/shortcuts.