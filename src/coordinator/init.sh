#!/bin/bash

DIR=`dirname "$0"`
COORDINATOR_PORT=4444

until pg_isready -h localhost -p ${COORDINATOR_PORT}
do
    echo "Waiting for coordinator postgres to start..."
    sleep 1
done
echo "Enabling postgres fdw extension..."
PGPASSWORD=pw psql -h localhost -p ${COORDINATOR_PORT} -U postgres -d main -c 'CREATE EXTENSION postgres_fdw'

# Get list of contractor container names
container_names=$(docker ps --format "{{.Names}}" | grep cmsc624project_contractor_ )
# Populate new search_path as we go
search_path="public"

while read -r container; do
    echo "Creating foreign server for ${container}..."
    container_num=$(echo -n $container | tail -c 1) # assumes we won't have double-digit number of contractors
    PGPASSWORD=pw psql -h localhost -p ${COORDINATOR_PORT} -U postgres -v foreign_host="'${container}'" -v container_num=${container_num} -f ${DIR}/init.sql
    search_path="contractor_${container_num},${search_path}"
done <<< "$container_names"

echo "Setting search_path..."
# This can't be done with -c option, needs separate file :(
PGPASSWORD=pw psql -h localhost -p ${COORDINATOR_PORT} -U postgres -v new_search_path=${search_path} -f ${DIR}/set_search_path.sql

echo "Coordinator initialization complete!"
