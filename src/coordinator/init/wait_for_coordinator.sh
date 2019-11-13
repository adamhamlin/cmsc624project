#!/bin/bash

until pg_isready -h localhost -p 4444
do
    echo "Waiting for coordinator to start..."
    sleep 1.5
done
echo "COORDINATOR IS READY!"