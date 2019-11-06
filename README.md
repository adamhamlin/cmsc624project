# cmsc624project
Advanced Database Design - Final Project (Fall 2019)

# Development
To spin up the networked containers for the coordinator and multiple contractors, run the following:
```bash
make run CONTRACTORS=3
```
The coordinator will have read access to any tables on contractor_X under schema `contractor_X`.

To spin down:
```bash
make stop
```

Check out the Makefile for other commands/shortcuts.