#!/bin/bash -ex

ruby -rrspec -e 'puts RSpec::Version::STRING'
echo Test succeeded
