SCALE ?= 1 # NOTE specifying SCALE higher than 1 doesn't really work yet

.PHONY: run init-contractor stop

run:
	docker-compose up -d --scale contractor=$(SCALE)
	./src/contractor/init.sh
	./src/coordinator/init.sh

psql-coordinator:
	psql postgresql://buddy:pw@localhost:4444/main

psql-contractor:
	psql postgresql://buddy:pw@localhost:4445/main

stop:
	docker-compose down