#!/bin/bash

DIR=`dirname "$0"`

until pg_isready -h localhost -p 4445
do
    echo "Waiting for contractor postgres to start..."
    sleep 1
done
echo "Populating contractor data..."
PGPASSWORD=pw psql -h localhost -p 4445 -U buddy -d main -f ${DIR}/init.sql

# TODO - for scaling need to repat the above actions for other contractor instances on other ports