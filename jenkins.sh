#!/bin/bash -ex

readonly IMAGENAME='debify'

docker build -t $IMAGENAME .

docker run --rm \
  -v $PWD/features/reports:/src/features/reports \
  -v '/var/run/docker.sock:/var/run/docker.sock' \
  --entrypoint '' \
  $IMAGENAME \
  bash -c "bundle exec cucumber --format pretty --format junit --out features/reports"
