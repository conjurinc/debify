#!/bin/bash -ex

bundle

creds=( $(bundle exec ruby -rnetrc -e 'Netrc.read("/root/.netrc")["https://conjur-master-v2.itp.conjur.net/api/authn"].tap {|c| print "#{c.login} #{c.password}"}') )
echo -n "${creds[1]}" | docker login registry.tld -u ${creds[0]} --password-stdin

cucumber --format pretty --format junit --out features/reports "$@"
