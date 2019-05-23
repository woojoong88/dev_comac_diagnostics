#! /usr/bin/env bash

echo "get NGIC images which are SPGW-C and SPGW-U"
docker login
docker pull woojoong/omec-spgwc:v1-debug-noconf
docker pull woojoong/omec-spgwu:v1-debug-noconf

echo "make networks"
docker network create --driver=bridge --subnet=192.168.103.0/24 --ip-range=192.168.103.0/24 --gateway=192.168.103.254 brs11
docker network create --driver=bridge --subnet=192.168.104.0/24 --ip-range=192.168.104.0/24 --gateway=192.168.104.254 brspgw
docker network create --driver=bridge --subnet=192.168.105.0/24 --ip-range=192.168.105.0/24 --gateway=192.168.105.254 brs1u
docker network create --driver=bridge --subnet=192.168.106.0/24 --ip-range=192.168.106.0/24 --gateway=192.168.106.254 brsgi

echo "run Docker images"
docker run -t -d --name cp -v $(pwd)/config/ngic_config:/opt/ngic-rtc/config woojoong/omec-spgwc:v1-debug-noconf bash
docker network connect brs11 cp
docker network connect brspgw cp

docker run -t -d --name dp --cap-add IPC_LOCK --cap-add NET_ADMIN --ulimit=memlock=-1 -v $(pwd)/config/ngic_config:/opt/ngic-rtc/config woojoong/omec-spgwu:v1-debug-noconf bash
docker network connect brs1u dp
docker network connect brsgi dp
docker network connect brspgw dp

