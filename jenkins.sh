#!/bin/bash -ex

gem install -N bundler
bundle
rm -rf features/reports
cucumber --format pretty --format junit --out features/reports || true
