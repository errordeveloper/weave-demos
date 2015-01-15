#!/bin/bash -x

docker run -v `pwd`:/app \
    errordeveloper/iojs-minimal-runtime:v1.0.1 \
    install

docker build -t hello-es-app ./