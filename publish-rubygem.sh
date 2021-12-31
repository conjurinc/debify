#!/bin/bash -e

docker pull registry.tld/conjurinc/publish-rubygem

docker run -i --rm -v $PWD:/src -w /src alpine/git clean -fxd \
  -e VERSION \
  -e bom-assets/ \
  -e release-assets/

summon --yaml "RUBYGEMS_API_KEY: !var rubygems/api-key" \
  docker run --rm --env-file @SUMMONENVFILE -v "$(pwd)":/opt/src \
  registry.tld/conjurinc/publish-rubygem debify
