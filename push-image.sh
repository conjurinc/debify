#!/bin/bash -ex

IFS=. read MAJOR MINOR PATCH <VERSION

TAGS="latest $(docker images --filter reference="registry.tld/conjurinc/debify:$MAJOR.$MINOR*" --format '{{.Tag}}')"
for t in $TAGS; do
  docker push registry.tld/conjurinc/debify:$t
done

