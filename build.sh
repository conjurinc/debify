#!/bin/bash -ex

if [ ! -f "VERSION" ]; then
  echo -n "0.0.1.dev" > VERSION
fi

VERSION=$(< VERSION)

ARCH="$1"
if [ -z "$ARCH" ]; then
  ARCH="amd64"
fi

docker build --platform "linux/$ARCH" --build-arg VERSION=$VERSION -t debify:$VERSION-$ARCH .
