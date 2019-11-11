CONTRACTORS ?= 1 # Specify how many contractors to spin up
CPORT ?= 4445 # Contractor port; if you want to connect a postgres client direct to contractor

.PHONY: build run shell-coordinator shell-contractor psql-coordinator psql-contractor stop retry

build: # should only be needed when making changes to Dockerfiles, etc
	docker-compose build

run:
	docker-compose up -d --scale contractor=$(CONTRACTORS)
	./src/contractor/init.sh
	./src/coordinator/init.sh

shell-coordinator:
	docker exec -u 0 -it cmsc624project_coordinator_1 /bin/bash

shell-contractor: # Note this can only be used for contractor 1
	docker exec -u 0 -it cmsc624project_contractor_1 /bin/bash

psql-coordinator:
	psql postgresql://buddy:pw@localhost:4444/main

psql-contractor:
	psql postgresql://buddy:pw@localhost:$(CPORT)/main

stop:
	docker-compose down

retry:
	make stop && make build && make run