#!/bin/sh -x
curl http://localhost:8080/v2/apps  \
  -X POST \
  -H Content-type: application/json \
  -d '{
    "id": "basic-3",
    "cmd": "python3 -m http.server 8080",
    "cpus": 0.5,
    "mem": 32.0,
    "container": {
      "type": "DOCKER",
      "docker": {
        "image": "python:3",
        "network": "BRIDGE",
        "portMappings": [
          { "containerPort": 8080, "hostPort": 0 }
        ]
      }
    }
  }'
