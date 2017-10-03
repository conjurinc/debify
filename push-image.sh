#!/bin/bash -ex

TAG=$(< VERSION)

docker tag debify registry.tld/debify:$TAG
docker tag debify registry.tld/debify:latest
docker push registry.tld/debify:$TAG
docker push registry.tld/debify:latest
