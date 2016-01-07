#!/bin/bash -ex

gem install -N bundler
bundle
rm -rf features/reports
cucumber --format pretty --format junit --report-dir features/reports || true
