#!/bin/bash -ex

docker run --rm registry.tld/conjurinc/debify:$(< VERSION) config script > docker-debify
chmod +x docker-debify
DEBIFY_ENTRYPOINT=ci/test.sh ./docker-debify
