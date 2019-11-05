#!/bin/bash

DIR=`dirname "$0"`

until pg_isready -h localhost -p 4444
do
    echo "Waiting for coordinator postgres to start..."
    sleep 1
done
echo "Creating foreign server..."
PGPASSWORD=pw psql -h localhost -p 4444 -U postgres -f ${DIR}/init.sql