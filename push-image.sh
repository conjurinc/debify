#!/bin/bash -ex

TAG=$(< VERSION)

docker push registry.tld/conjurinc/debify:$TAG
docker push registry.tld/conjurinc/debify:latest
