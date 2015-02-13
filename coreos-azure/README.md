---
published: false
title: Weaving Kubernetes on Azure
---

In this tutorial we will demonstrate how to deploy a Kubernetes cluster to Azure cloud.

To get started, you need to checkout the code:

```
git clone <repo>
cd <dir>
```

You will need to have [Node.js installed](http://nodejs.org/download/) on you machine. If you have previously used Azure CLI, you should have it already.

```
npm install
```

Now, all you need to do is:

```
./azure-login.js
./create-kubernetes-cluster.js
```

With a much being output from the creator, after a while you will have a cluster suitable for production use, where there are 3 dedicated etcd nodes and 3 Kubernetes nodes. The `kube-00` node only acts as a master, and doesn't run any other work loads.

![enter image description here](https://www.dropbox.com/s/v12rr2hzinjwr1a/Screenshot%202015-02-13%2008.00.10.png?dl=1)

Once the creation of Azure VMs has finished, you should see the following:

```
azure_wrapper/info: Saved SSH config, you can use it like so: `ssh -F  ./output/kubernetes_1c1496016083b4_ssh_conf <hostname>`
azure_wrapper/info: The hosts in this deployment are:
 [ 'etcd-00', 'etcd-01', 'etcd-02', 'kube-00', 'kube-01', 'kube-02' ]
azure_wrapper/info: Saved state into `./output/kubernetes_1c1496016083b4_deployment.yml`
```

Let's login to the master node like so:
```
ssh -F  ./output/kubernetes_1c1496016083b4_ssh_conf kube-00
```
> Note: config file name will be different, make sure to use the one you see.

Check there are 3 minions in the cluster:
```
core@kube-00 ~ $ kubectl get minions
NAME                LABELS                   STATUS
kube-01             environment=production   Ready
kube-02             environment=production   Ready
```

Let's follow the guestbook example now:
```
cd guestbook-example
kubectl create -f redis-master.json
kubectl create -f redis-master-service.json
kubectl create -f redis-slave-controller.json
kubectl create -f redis-slave-service.json
kubectl create -f frontend-controller.json
kubectl create -f frontend-service.json
```

Now we need to wait for the pods to get deployed, run the following and wait for `STATUS` to change from `Unknown`, through `Pending` to `Runnig`. 
```
kubectl get pods --watch
```
> Note: the most time is spent to download Docker container images on each of the hosts.

Eventually you should see:
```
POD                                    IP                  CONTAINER(S)        IMAGE(S)                                 HOST                LABELS                                       STATUS
3c66b758-b3a0-11e4-9d5d-000d3a2028a3   10.2.1.3            php-redis           kubernetes/example-guestbook-php-redis   kube-01/            name=frontend,uses=redisslave,redis-master   Running
3c67c923-b3a0-11e4-9d5d-000d3a2028a3   10.2.2.6            php-redis           kubernetes/example-guestbook-php-redis   kube-02/            name=frontend,uses=redisslave,redis-master   Running
redis-master                           10.2.2.4            master              dockerfile/redis                         kube-02/            name=redis-master                            Running
3b2baab4-b3a0-11e4-9d5d-000d3a2028a3   10.2.2.5            slave               brendanburns/redis-slave                 kube-02/            name=redisslave,uses=redis-master            Running
3b2c9221-b3a0-11e4-9d5d-000d3a2028a3   10.2.1.2            slave               brendanburns/redis-slave                 kube-01/            name=redisslave,uses=redis-master            Running
3c6976c7-b3a0-11e4-9d5d-000d3a2028a3                       php-redis           kubernetes/example-guestbook-php-redis   <unassigned>        name=frontend,uses=redisslave,redis-master   Pending
```

Two single-core minions is certainly not enough for a production system of today, and, as you can see we have one _unassigned_ pod. Let's resize the cluster, adding a couple of bigger nodes.

From an another shell on your machine, you want to run:
```
#TODO: make sure there is enough cores in the trial plan
env AZ_VM_SIZE=Large ./resize-kubernetes-cluster.js ./output/kubernetes_f5eaa9f06b2fdb_deployment.yml
```
> Note: this will create new files in `./output`.

Back on `kube-00`:
```
core@kube-00 ~ $ kubectl get minions
NAME                LABELS                   STATUS
kube-01             environment=production   Ready
kube-02             environment=production   Ready
kube-03             environment=production   Ready
kube-04             environment=production   Ready
```

We can see that two more minions joined happily. Let's resize the number of guestbook instances we have:

```
core@kube-00 ~ $ kubectl get rc
CONTROLLER             CONTAINER(S)        IMAGE(S)                                 SELECTOR            REPLICAS
redisSlaveController   slave               brendanburns/redis-slave                 name=redisslave     2
frontendController     php-redis           kubernetes/example-guestbook-php-redis   name=frontend       3
core@kube-00 ~ $ kubectl resize --replicas=4 rc redisSlaveController
resized
kubectl get rc
CONTROLLER             CONTAINER(S)        IMAGE(S)                                 SELECTOR            REPLICAS
redisSlaveController   slave               brendanburns/redis-slave                 name=redisslave     4
frontendController     php-redis           kubernetes/example-guestbook-php-redis   name=frontend       4

```

You now will have more front-end server and Redis slave.

```
##TODO: make-up the running pods, I cannot wait to do it all over on monday!!!

core@kube-00 ~ $ kubectl get pods
POD                                    IP                  CONTAINER(S)        IMAGE(S)                                 HOST                LABELS                                       STATUS
3c66b758-b3a0-11e4-9d5d-000d3a2028a3   10.2.1.3            php-redis           kubernetes/example-guestbook-php-redis   kube-01/            name=frontend,uses=redisslave,redis-master   Running
d79a7e44-b3a9-11e4-9d5d-000d3a2028a3                       slave               brendanburns/redis-slave                 kube-04/            name=redisslave,uses=redis-master            Unknown
d79d5849-b3a9-11e4-9d5d-000d3a2028a3                       slave               brendanburns/redis-slave                 kube-03/            name=redisslave,uses=redis-master            Unknown
2522f63a-b3aa-11e4-9d5d-000d3a2028a3                       php-redis           kubernetes/example-guestbook-php-redis   kube-04/            name=frontend,uses=redisslave,redis-master   Unknown
redis-master                           10.2.2.4            master              dockerfile/redis                         kube-02/            name=redis-master                            Running
3b2baab4-b3a0-11e4-9d5d-000d3a2028a3   10.2.2.5            slave               brendanburns/redis-slave                 kube-02/            name=redisslave,uses=redis-master            Running
3b2c9221-b3a0-11e4-9d5d-000d3a2028a3   10.2.1.2            slave               brendanburns/redis-slave                 kube-01/            name=redisslave,uses=redis-master            Running
3c67c923-b3a0-11e4-9d5d-000d3a2028a3   10.2.2.6            php-redis           kubernetes/example-guestbook-php-redis   kube-02/            name=frontend,uses=redisslave,redis-master   Running
3c6976c7-b3a0-11e4-9d5d-000d3a2028a3                       php-redis           kubernetes/example-guestbook-php-redis   kube-03/            name=frontend,uses=redisslave,redis-master   Unknown
```


ooops:
```
0 %> ssh -F ./output/kubernetes_b36527b1c0d8eb_ssh_conf kube-04
CoreOS stable (557.2.0)
Failed Units: 4
  docker.service
  install-weave.service
  sshd.service
  docker.socket
core@kube-04 ~ $ systemctl status install-weave.service
● install-weave.service - Install Weave
   Loaded: loaded (/etc/systemd/system/install-weave.service; enabled; vendor preset: disabled)
   Active: failed (Result: exit-code) since Fri 2015-02-13 17:53:12 UTC; 9min ago
     Docs: http://zettio.github.io/weave/
  Process: 752 ExecStartPre=/usr/bin/curl --silent --location --retry 99 --retry-delay 2 https://github.com/zettio/weave/releases/download/latest_release/weave --output /opt/bin/weave (code=exited, status=6)
  Process: 749 ExecStartPre=/bin/mkdir -p /opt/bin/ (code=exited, status=0/SUCCESS)

Feb 13 17:53:12 kube-04 systemd[1]: install-weave.service: control process exited, code=exited status=6
Feb 13 17:53:12 kube-04 systemd[1]: Failed to start Install Weave.
Feb 13 17:53:12 kube-04 systemd[1]: Unit install-weave.service entered failed state.
Feb 13 17:53:12 kube-04 systemd[1]: install-weave.service failed.
core@kube-04 ~ $ logout
```

