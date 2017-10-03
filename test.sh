#!/bin/bash -ex

# If we're running in jenkins, there will be a conjur.identity file
# with Conjur creds in it. Otherwise, assume the user's netrc has
# them.
if [[ -f /etc/conjur.identity ]]; then
  netrc=/etc/conjur.identity
else
  netrc=$HOME/.netrc
fi

: ${CONJUR_APPLIANCE_URL=https://conjur-master-v2.itp.conjur.net/api}
export CONJUR_APPLIANCE_URL

# mounting docker socket is required because tests launch containers
# And, we need Conjur creds because we need to pull a cuke-master
# image
docker run --rm -i \
  -e CONJUR_APPLIANCE_URL \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $PWD:$PWD \
  -v $netrc:/root/.netrc:ro \
  -w $PWD \
  --entrypoint ci/test.sh debify

