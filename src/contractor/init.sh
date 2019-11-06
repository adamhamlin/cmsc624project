#!/bin/bash

DIR=`dirname "$0"`

# Get space-delimited <container_name, host_port> pairs for each contractor container
container_port_mappings=$(docker ps --format "{{.Names}} {{.Ports}}" | grep cmsc624project_contractor_ | sed -n 's/\(.*\) 0\.0\.0\.0:\([0-9]\{4\}\)->.*$/\1 \2/p')

while read -r line; do
    container=$(echo "$line" | cut -d' ' -f 1)
    container_num=$(echo -n $container | tail -c 1) # assumes we won't have double-digit number of contractors
    port=$(echo "$line" | cut -d' ' -f 2)
    until pg_isready -h localhost -p ${port}
    do
        echo "Waiting for ${container} postgres to start..."
        sleep 1
    done
    echo "Populating contractor data for ${container}..."
    PGPASSWORD=pw psql -h localhost -p ${port} -U buddy -d main -v container_num=${container_num} -f ${DIR}/init.sql
done <<< "$container_port_mappings"
