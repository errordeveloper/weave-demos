#!/bin/sh
## This script takes count of the instance and the name of the cloud.
## It only generates and writes /etc/weave.env, and doesn't run anything.
cloud=$1
count=$2
crypt=$3
shift 3

case "weave-${cloud}-${count}" in
  (weave-gce-0)
    ## first machine in GCE doesn't yet know of any other peers
    known_weave_nodes=''
    ## it also happes to run Spark master JVM
    spark_node_role='master'
    spark_container_args=''
    spark_node_name="spark-${spark_node_role}-gce.weave.local"
    break
    ;;
  (weave-gce-*)
    ## any other node in GCE connects to the first one by native DNS name
    known_weave_nodes='weave-gce-0'
    ## these nodes run Spark worker JVM's and connect to master using weave DNS
    spark_node_role='worker'
    spark_container_args='spark://spark-master-gce.weave.local:7077'
    spark_node_name="spark-${spark_node_role}-${cloud}-${count}.weave.local"
    break
    ;;
  (weave-aws-*)
    ## every node in AWS connects to all GCE nodes by IP address
    known_weave_nodes="$@"
    ## same as in GCE
    spark_node_role='worker'
    spark_container_args='spark://spark-master-gce.weave.local:7077'
    spark_node_name="spark-${spark_node_role}-${cloud}-${count}.weave.local"
    break
    ;;
esac

case "${cloud}" in
  (gce)
    weavedns_addr="10.10.2.1${count}/16"
    spark_node_addr="10.10.1.1${count}/24"
    elasticsearch_node_addr="10.10.1.2${count}/24"
    break
    ;;
  (aws)
    weavedns_addr="10.10.2.2${count}/16"
    spark_node_addr="10.10.1.3${count}/24"
    elasticsearch_node_addr="10.10.1.4${count}/24"
    break
    ;;
esac

cat << ENVIRON | sudo tee /etc/weave.env
WEAVE_PEERS="${known_weave_nodes}"
WEAVE_PASSWORD="${crypt}"
WEAVEDNS_ADDR="${weavedns_addr}"
SPARK_NODE_ADDR="${spark_node_addr}"
SPARK_NODE_NAME="${spark_node_name}"
SPARK_CONTAINER="errordeveloper/weave-spark-${spark_node_role}-minimal:latest"
SPARK_CONTAINER_ARGS="${spark_container_args}"
ELASTICSEARCH_NODE_ADDR="${elasticsearch_node_addr}"
ELASTICSEARCH_NODE_NAME="elasticsearch-${cloud}-${count}.weave.local"
ELASTICSEARCH_CONTAINER="errordeveloper/weave-twitter-river-minimal:latest"
ENVIRON
