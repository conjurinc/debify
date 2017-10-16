#!/bin/bash -ex
TAG=$(< VERSION)

docker tag debify:$TAG registry.tld/conjurinc/debify:$TAG
docker tag debify:$TAG registry.tld/conjurinc/debify:latest
