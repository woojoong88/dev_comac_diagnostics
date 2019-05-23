#! /usr/bin/env bash

echo "remove ps"
docker rm -f traffic
docker rm -f cp
docker rm -f dp

echo "remove all networks"
docker network rm brs1u
docker network rm brs11
docker network rm brsgi
docker network rm brspgw

echo "Remaining docker ps"
docker ps -a
echo

echo "Remaining docker networks"
docker network ls
echo

