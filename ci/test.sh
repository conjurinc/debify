#!/bin/bash -ex

bundle

# Some tests need to be logged in to the registry, to pull a base
# image if it's not already available. Have entrypoint.sh do something
# simple, and log in as a side effect.
/debify/distrib/entrypoint.sh detect-version

# for target in spec cucumber; do
#   bundle exec rake $target
# done

# bundle exec rake cucumber

apt-get install -yqq strace

whoami

strace -f -o ./trace.out docker pull registry.tld/conjur-appliance:5.0-stable

grep docker < ./trace.out 
