#!/bin/sh
## This script takes count of the instance and the name of the cloud.
## It only generates and writes /etc/weave.env, and doesn't run anything.
count=$1
crypt=$2
shift 2

cat << ENVIRON | sudo tee /etc/weave.env
WEAVE_PEERS="${@}"
WEAVE_PASSWORD="${crypt}"
WEAVEDNS_ADDR="10.10.2.1${count}/16"
ENVIRON
