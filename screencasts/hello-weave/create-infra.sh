#!/bin/sh -ex
p="--project weave-testing-1"
z="--zone europe-west1-c"

gcloud compute networks create $p \
  'test-net-1'
gcloud compute instances create $p $z \
  --image 'centos-7' \
  --preemptible \
  --network 'test-net-1' \
  'weave-01' 'weave-02'
