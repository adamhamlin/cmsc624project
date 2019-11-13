#!/bin/bash

DIR=/opt/app-root/src/postgresql-start # this is lame but these scripts are not sourced in place
CONTRACTOR_PREFIX=cmsc624project_contractor_

create_foreign_server() {
    local container_num=$1
    local foreign_host=${CONTRACTOR_PREFIX}${container_num}
    until pg_isready -h ${foreign_host}
    do
        echo "Waiting for ${foreign_host} postgres to start..."
        sleep 1.5
    done
    echo "Creating foreign server for ${foreign_host}..."
    PGPASSWORD=pw psql -U postgres -v foreign_host="'${foreign_host}'" -v container_num=${container_num} -f ${DIR}/init.sql
}

################################################################################################################

echo "Creating extensions..."
PGPASSWORD=pw psql -U postgres -d main -f ${DIR}/superuser.sql

echo "Creating foreign servers..."
# Populate new search_path as we go
search_path="public"

k=1
while ping -c 1 ${CONTRACTOR_PREFIX}${k} > /dev/null 2>&1 ; do
    create_foreign_server ${k}
    search_path="contractor_${k},${search_path}"
    ((k++))
done

echo "Setting search_path to ${search_path}"
# This can't be done with -c option, needs separate file :(
PGPASSWORD=pw psql -U postgres -v new_search_path=${search_path} -f ${DIR}/set_search_path.sql

echo "Coordinator initialization complete!"
