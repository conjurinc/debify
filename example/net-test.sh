#!/bin/bash -ex

cid=$1

docker exec $cid ping -c1 other_host

echo Test succeeded
