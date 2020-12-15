#!/bin/bash -ex


apt-get update && \
DEBIAN_FRONTEND=noninteractive apt-get install -y iputils-ping

ping -c1 other_host

echo Test succeeded
