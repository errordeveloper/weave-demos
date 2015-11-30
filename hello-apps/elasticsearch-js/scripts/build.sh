#!/bin/bash -x

docker run -v `pwd`:/app \
    node \
    sh -c 'cd /app ; npm install'

docker build -t hello-es-app ./
