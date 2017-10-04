#!/bin/bash -ex

docker build --build-arg VERSION=$(< VERSION) -t debify .
