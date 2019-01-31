#!/bin/bash -ex

TAG=$(< VERSION)
for t in $(./image-tags); do
  docker tag debify:$TAG registry.tld/conjurinc/debify:$t
done
