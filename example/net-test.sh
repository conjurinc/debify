#!/bin/bash -ex

cid=$1

docker exec $cid curl -s http://other_host > /dev/null

echo Test succeeded
