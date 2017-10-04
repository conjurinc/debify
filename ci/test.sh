#!/bin/bash -ex

bundle

cucumber --format pretty --format junit --out features/reports "$@"
