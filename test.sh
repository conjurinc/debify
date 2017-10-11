#!/bin/bash -ex

VERSION=$(< VERSION)
docker run --rm debify:$VERSION config script > docker-debify
chmod +x docker-debify
DEBIFY_IMAGE=debify:$VERSION DEBIFY_ENTRYPOINT=ci/test.sh ./docker-debify
