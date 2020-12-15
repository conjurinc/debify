#!/bin/bash -ex

cid="$1"

docker exec -t "$cid" bash -c "
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y iputils-ping
"
docker exec "$cid" ping -c1 other_host

echo Test succeeded
