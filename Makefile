CONTRACTORS ?= 1 # NOTE specifying SCALE higher than 1 doesn't really work yet
CPORT ?= 4445 # Contractor port; Need to specify this when multiple contractors

.PHONY: run init-contractor stop

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