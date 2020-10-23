#!/bin/bash -ex

docker pull registry.tld/cyberark/phusion-ruby-fips:0.11-6228320

VERSION=$(< VERSION)
docker run --rm debify:$VERSION config script > docker-debify
chmod +x docker-debify
DEBIFY_IMAGE=debify:$VERSION DEBIFY_ENTRYPOINT=ci/test.sh ./docker-debify
