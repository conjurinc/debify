#!/bin/bash -ex

gem install -N bundler
bundle
rake features
