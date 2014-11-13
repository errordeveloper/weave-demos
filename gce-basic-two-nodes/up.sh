#!/bin/bash -x -e

args="--zone $DC $VM"

gcloud compute instances create $args

sleep 30

gcloud compute ssh $args \
  --command 'curl https://get.docker.io/ | sudo bash'

gcloud compute ssh $args
