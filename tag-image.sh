#!/bin/bash -ex

IFS=. read MAJOR MINOR PATCH <VERSION
TAG=$MAJOR.$MINOR.$PATCH

for t in latest $TAG $MAJOR.$MINOR; do
  docker tag debify:$TAG registry.tld/conjurinc/debify:$t
done
