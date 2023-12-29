#!/bin/bash -ex

TAG=$(< VERSION)
ARCH="$1"
if [ -z "$ARCH" ]; then
  ARCH="amd64"
fi

for t in $(./image-tags); do
  docker tag "debify:$TAG-$ARCH" "registry.tld/conjurinc/debify:$t-$ARCH"
  docker push "registry.tld/conjurinc/debify:$t-$ARCH"
done
