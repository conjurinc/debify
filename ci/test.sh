#!/bin/bash -ex

bundle

for target in spec cucumber; do
  bundle exec env TAGS=@only rake $target || true
done

