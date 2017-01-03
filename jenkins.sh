#!/bin/bash -ex

gem install -N bundler
bundle
rm -rf features/reports
cucumber --format pretty --format junit --out features/reports || true

if [ "$GIT_BRANCH" == "origin/master" ]; then
  TAG=$(cat lib/conjur/debify/version.rb | grep -o '".*"' | tr -d '"')

  docker build -t debify .
  docker tag -f debify registry.tld/debify:$TAG
  docker push registry.tld/debify:$TAG
fi
