#!/bin/bash -ex

cd $(dirname $0)

install -o root -g root -m 0755 weave /usr/local/bin/
install -o root -g root -m 0644 weave.target weave.service weavedns.service weaveproxy.service /etc/systemd/system/

## Pull container images
/usr/local/bin/weave setup
