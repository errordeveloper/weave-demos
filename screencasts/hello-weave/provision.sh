#!/bin/sh

gpasswd -a ilya docker

for i in \
  weaveworks/weave:1.0.1 \
  weaveworks/weaveexec:1.0.1 \
  weaveworks/weavedns:1.0.1 \
  centos:7 ;
do docker pull $i
done
