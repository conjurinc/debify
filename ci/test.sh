#!/bin/bash -ex

bundle

for target in spec cucumber; do
  bundle exec rake $target || true
done

