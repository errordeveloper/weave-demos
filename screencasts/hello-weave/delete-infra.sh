#!/bin/sh -ex
p="--project weave-testing-1"
z="--zone europe-west1-c"

gcloud compute instances delete -q $p $z \
  'weave-01' 'weave-02'
gcloud compute networks delete -q $p \
  'test-net-1'
