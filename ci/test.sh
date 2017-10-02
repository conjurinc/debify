#!/bin/bash -e

bundle

creds=( $(bundle exec ruby ci/conjur_creds.rb) )
echo -n "${creds[1]}" | docker login registry.tld -u ${creds[0]} --password-stdin

cucumber --format pretty --format junit --out features/reports "$@"
