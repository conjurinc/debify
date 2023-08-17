#!/bin/bash -ex

git config --global --add safe.directory "$PWD"

bundle install

for target in spec cucumber; do
  bundle exec rake $target
done
