#!/bin/bash -ex

if [ ! -f "VERSION" ]; then
  echo -n "0.0.1.dev" > VERSION
fi

VERSION=$(< VERSION)
docker build --build-arg VERSION=$VERSION -t debify:$VERSION .
