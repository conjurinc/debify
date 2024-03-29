#!/bin/bash -e

# Make sure we don't echo commands as executed, otherwise the user's
# Conjur API key will show up in the logs.
set +x

creds=( $(ruby /debify/distrib/conjur_creds.rb) )

# If there are creds, use them to log in to the registry.
#
# If there are no creds, any commands that do
# Docker stuff will fail, but the non-Docker commands (e.g. the config
# subcommands) will work fine.
if [[ ${#creds[*]} > 0 ]]; then
  echo -n "${creds[1]}" | docker login registry.tld -u ${creds[0]} --password-stdin >/dev/null 2>&1
fi

# Ensure the current working directory is considered safe by git in the debify
# container.
git config --global --add safe.directory "$PWD"

exec debify "$@"

