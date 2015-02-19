# Pythonic streaming  and sparkling weaving

This guide demonstrates an easy way to setup 

To keep things simple for you, I will show how to setup a cluster using Vagrant. If you would like to run it in the cloud, please refer to the [Terraform-based](http://weaveblog.com/2014/12/18/automated-provisioning-of-multi-cloud-weave-network-terraform/) setup instructions.


## Let's go!

Firstly, let's checkout the code and bring up 3 VMs on Vagrant:
```
git clone https://github.com/errordeveloper/weave-demos
cd weave-demos/sparkles
vagrant up
```

Vargant will boot and provision 3 VMs, after it exited there will a Spark cluster running with master on the head node (`core-01`) and workers on the remaining `core-02` and `core-03`. To keep this guide short, I will not explain how exactly provisioning works, as I have [done so previously](http://weaveblog.com/2014/10/28/running-a-weave-network-on-coreos/).

Now, let's login to `core-01`:
```
vagrant ssh core-01
```

A few container images should be downloading in the background. It takes a few minutes, but you can run `watch docker images` and wait for the following to appear:
```
REPOSITORY                                   TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
errordeveloper/weave-spark-master-minimal    latest              437bd4307e0e        47 hours ago        430.4 MB
errordeveloper/weave-spark-worker-minimal    latest              bdb33ca885ae        47 hours ago        430.4 MB
errordeveloper/weave-twitter-river-minimal   latest              af9f7dad1877        47 hours ago        193.8 MB
errordeveloper/weave-spark-shell-minimal     latest              8d11396e01c2        47 hours ago        574.6 MB
zettio/weavetools                            0.9.0               6c2dd751b59c        2 weeks ago         5.138 MB
zettio/weavetools                            latest              6c2dd751b59c        2 weeks ago         5.138 MB
zettio/weavedns                              0.9.0               8f3a856eda8f        2 weeks ago         9.382 MB
zettio/weavedns                              latest              8f3a856eda8f        2 weeks ago         9.382 MB
zettio/weave                                 0.9.0               efb52cb2a3b8        2 weeks ago         11.35 MB
zettio/weave                                 latest              efb52cb2a3b8        2 weeks ago         11.35 MB
```

I have prepared a set of [lean](http://weaveblog.com/2014/12/09/running-java-applications-in-docker-containers/) Spark container images for the purpose of this demo.

> Note: You can use images of your own if you'd like, just make sure to consult my [Dockerfile](https://github.com/errordeveloper/weave-demos/blob/master/java-containers/spark/base/Dockerfile#L33-L34) for the `nsswitch.conf` tweak, you will need to make sure DNS works correctly.

You may have noticed there is Elasticsearch running,  I will not be using it for the purpose of this guide, but it's there for you to experiment with, if you'd like.

Once all of the images are downloaded,  Spark cluster will get bootstrapped shortly.

You can tail the logs and see 2 workers joining the cluster,  these go by DNS names`spark-worker-1.weave.local` and `spark-worker-2.weave.local`:

```
core@core-01 ~ $ journalctl -f -u spark
...
Feb 18 16:09:34 core-01 docker[3658]: 15/02/18 16:09:34 INFO Master: I have been elected leader! New state: ALIVE
Feb 18 16:10:15 core-01 docker[3658]: 15/02/18 16:10:15 INFO Master: Registering worker spark-worker-1.weave.local:44122 with 1 cores, 982.0 MB RAM
Feb 18 16:10:17 core-01 docker[3658]: 15/02/18 16:10:17 INFO Master: Registering worker spark-worker-2.weave.local:33557 with 1 cores, 982.0 MB RAM
```

> Note: these are not very big compute nodes, if your machine has more resource, you can deploy bigger VMs by setting `$vb_memory` and `$vb_cpus` in `config-override.rb`. 

## Ready to work!

Now everything is ready to deploy a workload on the cluster. I will submit a simple job written in Python, featuring newly added stream API.

Let's start pyspark container:
```
sudo weave run \
  --with-dns \
  10.10.1.88/24 \
  --hostname=spark-shell.weave.local \
  \
  --tty --interactive \
  --name=spark-shell \
  --entrypoint=pyspark \
  errordeveloper/weave-spark-shell-minimal:latest \
  \
  --master spark://spark-master.weave.local:7077
```

As you can see, with WeaveDNS you can address Spark master node by it's name. The node running pyspark also gets a hostname - `spark-shell.weave.local`, that's simply taken care of by passing `--with-dns`  and `--hostname=...`.  The IP address I have picked for this container is `10.10.1.88`, it's part of the `10.10.1.0/24` subnet, which had been allocated for the cluster, you can. All remain arguments are not specific to Weave, these are just usual `docker run` arguments, followed by `pyspark` arguments.

For the demo to work, you will also need a data source of some sort. Naturally, it will run in a container as well, which in turns joins Weave network also.

Here is a very simple one for you:
```
sudo weave run --with-dns 10.10.1.99/24 \
  --hostname=spark-data-source.weave.local \
  busybox sh -c 'nc -ll -p 9999 -e yes Hello, Weave!'
```
So we will have a netcat server on 9999, with DNS name `spark-data-source.weave.local` and IP address `10.10.1.99`. Weave will make this server reachable from any node in the cluster.

Next, you want to attach to the Spark shell:

```
core@core-01 ~ $ docker attach spark-shell
...
Welcome to
      ____              __
     / __/__  ___ _____/ /__
    _\ \/ _ \/ _ `/ __/  '_/
   /__ / .__/\_,_/_/ /_/\_\   version 1.2.1
      /_/

Using Python version 2.7.6 (default, Nov 23 2014 14:48:23)
SparkContext available as sc.
>>> 15/02/18 17:10:37 INFO SparkDeploySchedulerBackend: Registered executor: Actor[akka.tcp://sparkExecutor@spark-worker-2.weave.local:34277/user/Executor#-2039127650] with ID 0
15/02/18 17:10:37 INFO SparkDeploySchedulerBackend: Registered executor: Actor[akka.tcp://sparkExecutor@spark-worker-1.weave.local:44723/user/Executor#-1272098548] with ID 1
15/02/18 17:10:38 INFO BlockManagerMasterActor: Registering block manager spark-worker-2.weave.local:44675 with 267.3 MB RAM, BlockManagerId(0, spark-worker-2.weave.local, 44675)
15/02/18 17:10:38 INFO BlockManagerMasterActor: Registering block manager spark-worker-1.weave.local:36614 with 267.3 MB RAM, BlockManagerId(1, spark-worker-1.weave.local, 36614)
```

The code we are going to run is based on the [`streaming/network_wordcount.py`](https://github.com/apache/spark/blob/a8eb92dcb9ab1e6d8a34eed9a8fddeda645b5094/examples/src/main/python/streaming/network_wordcount.py) example, which counts words in a text stream received from the data source server for every second.
```
>>> 
>>> from pyspark.streaming import StreamingContext
>>> 
>>> ssc = StreamingContext(sc, 1)
>>> 
>>> lines = ssc.socketTextStream('spark-data-source.weave.local', 9999)
>>> 
>>> counts = lines.flatMap(lambda line: line.split(" ")).map(lambda word: (word, 1)).reduceByKey(lambda a, b: a+b)
>>> 
>>> counts.pprint()
>>> 
>>> ssc.start(); ssc.awaitTermination();
```

Amongst much of log messages, you should see this being printed periodically:
```
-------------------------------------------
Time: 2015-02-18 18:10:56
-------------------------------------------
('Hello,', 130962)
('Weave!', 130962)
```



