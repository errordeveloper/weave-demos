#!/bin/sh -ex
p="--project weave-testing-1"
z="--zone europe-west1-c"

gcloud compute networks create $p \
  'test-net-1'
gcloud compute firewall-rules create $p \
  --network 'test-net-1' \
  'allow-ssh-access' \
  --allow 'tcp:22'
gcloud compute instances create $p $z \
  --image 'centos-7' \
  --preemptible \
  --network 'test-net-1' \
  'weave-01' 'weave-02'
