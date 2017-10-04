#!/bin/bash -e

# Make sure we don't echo commands as executed, otherwise the user's
# Conjur API key will show up in the logs.
set +x
bundle

creds=( $(bundle exec ruby ci/conjur_creds.rb) )
echo -n "${creds[1]}" | docker login registry.tld -u ${creds[0]} --password-stdin

cucumber --format pretty --format junit --out features/reports "$@"
