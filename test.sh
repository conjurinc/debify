#!/bin/bash -ex

if [[ -f /etc/conjur.identity ]]; then
  netrc=/etc/conjur.identity
else
  netrc=$HOME/.netrc
fi

# mounting docker sock is required because tests launch containers
# And, we need Conjur creds because we need to pull a cuke-master
# image
docker run --rm -i \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $PWD:$PWD \
  -v $netrc:/root/.netrc:ro \
  -w $PWD \
  --entrypoint ci/test.sh debify

