#!/usr/bin/env bash
set -e

docker run -i --rm -v $PWD:/src -w /src --entrypoint /bin/sh alpine/git \
  -c "git config --global --add safe.directory /src && \
      git clean -fdx \
        -e VERSION \
        -e bom-assets/ \
        -e release-assets"

summon --yaml "RUBYGEMS_API_KEY: !var rubygems/api-key" \
  publish-rubygem debify
