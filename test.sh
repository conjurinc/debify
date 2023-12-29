#!/bin/bash -ex

VERSION=$(< VERSION)

ARCH="$1"
if [ -z "$ARCH" ]; then
  ARCH="amd64"
fi

docker run --rm "debify:$VERSION-$ARCH" config script > docker-debify
chmod +x docker-debify
DEBIFY_IMAGE=debify:$VERSION-$ARCH DEBIFY_ENTRYPOINT=ci/test.sh ./docker-debify
