#!/bin/bash -ex

for t in $(./image-tags); do
  docker push registry.tld/conjurinc/debify:$t
done

