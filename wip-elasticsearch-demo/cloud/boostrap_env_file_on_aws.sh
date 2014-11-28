#!/bin/sh
cat << ENVIRON | sudo tee /etc/`hostname -s`.env
WEAVE_LAUNCH_ARGS="$@"
WEAVE_LAUNCH_DNS_ARGS="10.10.2.2$1/16"
SPARK_NODE_ADDR="10.10.1.3$1/24"
SPARK_NODE_NAME="spark-worker-aws-$1.weave.local"
SPARK_CONTAINER="errordeveloper/weave-spark-worker-minimal:latest"
SPARK_CONTAINER_ARGS="spark://spark-master-gce.weave.local:7077"
ELASTICSEARCH_NODE_ADDR="10.10.1.4$1/24"
ELASTICSEARCH_NODE_NAME="elasticsearch-aws-$1.weave.local"
ELASTICSEARCH_CONTAINER="errordeveloper/weave-elasticsearch-minimal:latest"
ENVIRON
