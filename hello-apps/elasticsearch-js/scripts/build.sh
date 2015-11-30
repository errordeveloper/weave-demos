#!/bin/bash -x

docker run -v `pwd`:/app \
    node \
    npm install

docker build -t hello-es-app ./
