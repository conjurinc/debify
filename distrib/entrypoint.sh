#!/bin/bash -e

# Make sure we don't echo commands as executed, otherwise the user's
# Conjur API key will show up in the logs.
set +x

creds=( $(ruby /debify/distrib/conjur_creds.rb) )

# If there are creds, use them to log in to the registry. Then, run
# the magic DockerInDocker wrapper script so debify can interact with
# the Docker daemon.
#
# If there are no creds, just run debify itself. Any commands that do
# Docker stuff will fail, but the non-Docker commands (e.g. the config
# subcommands) will work fine.
if [[ ${#creds[*]} > 0 ]]; then
  echo -n "${creds[1]}" | docker login registry.tld -u ${creds[0]} --password-stdin >/dev/null 2>&1
fi

exec debify "$@"

