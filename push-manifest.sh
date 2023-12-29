#!/bin/bash -ex

for t in $(./image-tags); do
  docker pull "registry.tld/conjurinc/debify:$t-amd64"
  docker pull "registry.tld/conjurinc/debify:$t-arm64"

  docker manifest create \
    --insecure \
    "registry.tld/conjurinc/debify:$t" \
    --amend "registry.tld/conjurinc/debify:$t-amd64" \
    --amend "registry.tld/conjurinc/debify:$t-arm64"

  docker manifest push --insecure "registry.tld/conjurinc/debify:$t"
done
