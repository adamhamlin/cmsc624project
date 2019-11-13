#!/bin/bash

DIR=/opt/app-root/src/postgresql-start # this is lame but these scripts are not sourced in place...

echo "Creating extensions..."
PGPASSWORD=pw psql -U postgres -d main -f ${DIR}/superuser.sql
echo "Populating contractor data..."
PGPASSWORD=pw psql -U buddy -d main -v suffix=${HOSTNAME} -f ${DIR}/init.sql
