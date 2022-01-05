#!/usr/bin/env bash
set -e

docker run -i --rm -v $PWD:/src -w /src alpine/git clean -fxd \
  -e VERSION \
  -e bom-assets/ \
  -e release-assets/

summon --yaml "RUBYGEMS_API_KEY: !var rubygems/api-key" \
  publish-rubygem debify
