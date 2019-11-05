# cmsc624project
Advanced Database Design - Final Project (Fall 2019)

# Development
To spin up the networked containers for the coordinator and contractors, run the following:
```bash
make run
```
The coordinator will have read access to any tables on contractor under schema `contractor`.

To spin down:
```bash
make stop
```

Check out the Makefile for other commands/shortcuts.