#!/bin/bash -ex

VERSION=$(< VERSION)
docker build --build-arg VERSION=$VERSION -t debify:$VERSION .
