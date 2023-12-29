#!/bin/bash -ex

TAG=$(< VERSION)
ARCH="$1"
for t in $(./image-tags); do
  docker tag "debify:$TAG" "registry.tld/conjurinc/debify:$t-$ARCH"
  docker push "registry.tld/conjurinc/debify:$t-$ARCH"
done
