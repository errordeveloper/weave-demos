#!/bin/sh
## This script takes count of the instance and the name of the cloud.
## It only generates and writes /etc/weave.env, and doesn't run anything.
cloud=$1
count=$2
shift 2

case "weave-${cloud}-${count}" in
  (weave-gce-0)
    ## first machine in GCE doesn't yet know of any other peers
    known_weave_nodes=''
    break
    ;;
  (weave-gce-*)
    ## any other node in GCE connects to the first one by native DNS name
    known_weave_nodes='weave-gce-0'
    break
    ;;
  (weave-aws-*)
    ## every node in AWS connects to all GCE nodes by IP address
    known_weave_nodes="$@"
    break
    ;;
esac

case "${cloud}" in
  (gce)
    weavedns_addr="10.10.2.1${count}/16"
    break
    ;;
  (aws)
    weavedns_addr="10.10.2.2${count}/16"
    break
    ;;
esac

cat << ENVIRON | sudo tee /etc/weave.env
WEAVE_LAUNCH_ARGS="${known_weave_nodes}"
WEAVE_LAUNCH_DNS_ARGS="${weavedns_addr}"
ENVIRON
