#!/bin/bash -ex

TAG=$(< VERSION)

docker tag debify registry.tld/conjurinc/debify:$TAG
docker tag debify registry.tld/conjurinc/debify:latest
docker push registry.tld/conjurinc/debify:$TAG
docker push registry.tld/conjurinc/debify:latest
