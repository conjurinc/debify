#!/bin/bash -ex
TAG=$(< VERSION)

docker tag debify registry.tld/conjurinc/debify:$TAG
docker tag debify registry.tld/conjurinc/debify:latest
