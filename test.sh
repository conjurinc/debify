#!/bin/bash -ex
docker pull registry.tld/cyberark/phusion-ruby-fips:0.11-d243f6c
VERSION=$(< VERSION)
docker run --rm debify:$VERSION config script > docker-debify
chmod +x docker-debify
DEBIFY_IMAGE=debify:$VERSION DEBIFY_ENTRYPOINT=ci/test.sh ./docker-debify
