#!/bin/sh
## This script takes count of the instance and the name of the cloud.
## It only generates and writes /etc/weave.env, and doesn't run anything.
cloud=$1
count=$2
shift 2

case "weave-${cloud}-${count}" in
  (weave-gce-0)
    ## first machine in GCE doesn't yet know of any other peers
    known_weave_nodes=''
    ## it also happes to run Spark master JVM
    spark_role='master'
    spark_args=''
    spark_node="spark-${role}-gce.weave.local"
    break
    ;;
  (weave-gce-*)
    ## any other node in GCE connects to the first one by native DNS name
    known_weave_nodes='weave-gce-0'
    ## these nodes run Spark worker JVM's and connect to master using weave DNS
    spark_role='worker'
    spark_args='spark://spark-master-gce.weave.local:7077'
    spark_node="spark-${spark_role}-${cloud}-${count}.weave.local"
    break
    ;;
  (weave-aws-*)
    ## every node in AWS connects to all GCE nodes by IP address
    known_weave_nodes="$@"
    ## same as in GCE
    spark_role='worker'
    spark_args='spark://spark-master-gce.weave.local:7077'
    spark_node="spark-${spark_role}-${cloud}-${count}.weave.local"
    break
    ;;
esac

case "weave-${cloud}-${count}" in
  (weave-gce-0)
    break
    ;;
  (*)
    spark_role='worker'
    spark_args='spark://spark-master-gce.weave.local:7077'
    spark_node="spark-${spark_role}-${cloud}-${count}.weave.local"
    break
    ;;
esac

cat << ENVIRON | sudo tee /etc/weave.env
WEAVE_LAUNCH_ARGS="${known_weave_nodes}"
WEAVE_LAUNCH_DNS_ARGS="10.10.2.2${count}/16"
SPARK_NODE_ADDR="10.10.1.3${count}/24"
SPARK_NODE_NAME="${spark_node}"
SPARK_CONTAINER="errordeveloper/weave-spark-${spark_role}-minimal:latest"
SPARK_CONTAINER_ARGS="${spark_args}"
ELASTICSEARCH_NODE_ADDR="10.10.1.4${count}/24"
ELASTICSEARCH_NODE_NAME="elasticsearch-${cloud}-${count}.weave.local"
ELASTICSEARCH_CONTAINER="errordeveloper/weave-twitter-river-minimal:latest"
ENVIRON
