#!/bin/bash

cd $(git rev-parse --show-toplevel)/felix

#creds="--build-arg nginxplus_license_cookie=${1} --build-arg nginxplus_license_secret=${2}"


for i in 1 2 3 ; do

  build_nginxplus_base_image=" \
    docker build -t nginxplus $NGINXPLUS_CREDS https://github.com/errordeveloper/dockerfile-nginxplus.git \
  "

  build_myapp_image="\
    docker build -t myapp https://github.com/errordeveloper/weave-demos.git#:hello-apps/elasticsearch-js/myapp \
  "

  run_myapp="\
    docker run -d --hostname=myapp.weave.local myapp \
  "

  run_elasticsearch="\
    docker run -d --name='es-${i}' errordeveloper/weave-elasticsearch-minimal:latest \
  "

  build_myapp_lb_image="\
    docker build -t myapp_lb https://github.com/errordeveloper/weave-demos.git#:hello-apps/elasticsearch-js/myapp_lb \
  "

  run_my_app_lb="\
    docker run --net=host myapp_lb \
  "

  cmd="weave expose \
    && eval \$(weave env) \
    && ${build_nginxplus_base_image} \
    && ${build_myapp_image} \
    && ${build_myapp_lb_image} \
    && ${run_elasticsearch} \
    && ${run_myapp} \
    && ${run_myapp} \
  "

  vm="core-0${i}"
  log="/tmp/vagrant_ssh_${vm}"
  echo "Bootstrapping ${vm}..."
  vagrant ssh $vm --command "${cmd}" &> $log && echo "  - done" || echo "  - fail (see $log)"
done

