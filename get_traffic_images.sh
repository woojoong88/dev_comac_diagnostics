#! /usr/bin/env bash
docker login
docker pull woojoong/kone-traffic-gen:latest

docker run -t -d --name traffic --cap-add NET_ADMIN woojoong/omec-traffic-gen:v1-debug bash
docker network connect brs11 traffic
docker network connect brs1u traffic
docker network connect brsgi traffic

