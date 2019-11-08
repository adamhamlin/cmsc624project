CONTRACTORS ?= 1 # Specify how many contractors to spin up
CPORT ?= 4445 # Contractor port; if you want to connect a postgres client direct to contractor

.PHONY: run psql-coordinator psql-contractor stop

run:
	docker-compose up -d --scale contractor=$(CONTRACTORS)
	./src/contractor/init.sh
	./src/coordinator/init.sh

psql-coordinator:
	psql postgresql://buddy:pw@localhost:4444/main

psql-contractor:
	psql postgresql://buddy:pw@localhost:$(CPORT)/main

stop:
	docker-compose down