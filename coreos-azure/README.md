---
published: false
title: Weaving Kubernetes on Azure
---

In this tutorial we will demonstrate how to deploy a Kubernetes cluster to Azure cloud.

To get started, you need to checkout the code:

```
git clone https://github.com/errordeveloper/weave-demos
cd weave-demos/coreos-azure
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

![VMs in Azure](https://www.dropbox.com/s/logk4mot2gnlxgn/Screenshot%202015-02-15%2015.54.45.png?dl=1)

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
redis-master                           10.2.1.4            master              dockerfile/redis                         kube-01/            name=redis-master                            Running
40d8cebd-b524-11e4-b1b2-000d3a203bbc   10.2.2.4            slave               brendanburns/redis-slave                 kube-02/            name=redisslave,uses=redis-master            Running
40dbdcd0-b524-11e4-b1b2-000d3a203bbc   10.2.1.5            slave               brendanburns/redis-slave                 kube-01/            name=redisslave,uses=redis-master            Running
421473f6-b524-11e4-b1b2-000d3a203bbc   10.2.2.5            php-redis           kubernetes/example-guestbook-php-redis   kube-02/            name=frontend,uses=redisslave,redis-master   Running
4214d4fe-b524-11e4-b1b2-000d3a203bbc   10.2.1.6            php-redis           kubernetes/example-guestbook-php-redis   kube-01/            name=frontend,uses=redisslave,redis-master   Running
42153c72-b524-11e4-b1b2-000d3a203bbc                       php-redis           kubernetes/example-guestbook-php-redis   <unassigned>        name=frontend,uses=redisslave,redis-master   Pending
```

Two single-core minions is certainly not enough for a production system of today, and, as you can see we have one _unassigned_ pod. Let's resize the cluster, adding a couple of bigger nodes.

From an another shell on your machine, you want to run:
```
export AZ_VM_SIZE=Large
./resize-kubernetes-cluster.js ./output/kubernetes_f5eaa9f06b2fdb_deployment.yml
...
azure_wrapper/info: Saved SSH config, you can use it like so: `ssh -F  ./output/kubernetes_8f984af944f572_ssh_conf <hostname>`
azure_wrapper/info: The hosts in this deployment are:
 [ 'etcd-00',
  'etcd-01',
  'etcd-02',
  'kube-00',
  'kube-01',
  'kube-02',
  'kube-03',
  'kube-04' ]
azure_wrapper/info: Saved state into `./output/kubernetes_8f984af944f572_deployment.yml`
```
> Note: this step has created new files in `./output`.

Back on `kube-00`:
```
core@kube-00 ~ $ kubectl get minions
NAME                LABELS                   STATUS
kube-01             environment=production   Ready
kube-02             environment=production   Ready
kube-03             environment=production   Ready
kube-04             environment=production   Ready
```

We can see that two more minions joined happily. Let's resize the number of Guestbook instances we have:

```
core@kube-00 ~/guestbook-example $ kubectl get rc
CONTROLLER             CONTAINER(S)        IMAGE(S)                                 SELECTOR            REPLICAS
redisSlaveController   slave               brendanburns/redis-slave                 name=redisslave     2
frontendController     php-redis           kubernetes/example-guestbook-php-redis   name=frontend       3
core@kube-00 ~/guestbook-example $ kubectl resize --replicas=4 rc redisSlaveController
resized
core@kube-00 ~/guestbook-example $ kubectl resize --replicas=4 rc frontendController
resized
core@kube-00 ~/guestbook-example $ kubectl get rc
CONTROLLER             CONTAINER(S)        IMAGE(S)                                 SELECTOR            REPLICAS
redisSlaveController   slave               brendanburns/redis-slave                 name=redisslave     4
frontendController     php-redis           kubernetes/example-guestbook-php-redis   name=frontend       4
```

You now will have more instances of front-end Guestbook apps and Redis slaves. For example, if we look up all pods labled `name=frontend`, we should see one running on each node.

```
core@kube-00 ~/guestbook-example $ kubectl get pods -l name=frontend
POD                                    IP                  CONTAINER(S)        IMAGE(S)                                 HOST                LABELS                                       STATUS
4214d4fe-b524-11e4-b1b2-000d3a203bbc   10.2.1.6            php-redis           kubernetes/example-guestbook-php-redis   kube-01/            name=frontend,uses=redisslave,redis-master   Running
ae59fa80-b526-11e4-b1b2-000d3a203bbc   10.2.4.5            php-redis           kubernetes/example-guestbook-php-redis   kube-04/            name=frontend,uses=redisslave,redis-master   Running
421473f6-b524-11e4-b1b2-000d3a203bbc   10.2.2.5            php-redis           kubernetes/example-guestbook-php-redis   kube-02/            name=frontend,uses=redisslave,redis-master   Running
42153c72-b524-11e4-b1b2-000d3a203bbc   10.2.3.4            php-redis           kubernetes/example-guestbook-php-redis   kube-03/            name=frontend,uses=redisslave,redis-master   Running

```

To makes sure the app is working, we should load it in the browser. For accessing the Guesbook service from the outside world, I had to create an Azure endpoint like shown on the picture below.

![VMs in Azure](https://www.dropbox.com/s/a7gglyamb9pltqn/Screenshot%202015-02-15%2016.02.32.png?dl=1)

I was then able to access it from anywhere via the Azure virtual IP for `kube-01`, i.e. `http://104.40.211.194:8000/`.

To delete the cluster run this:
```
./destroy-cluster.js ./output/kubernetes_8f984af944f572_deployment.yml 
```

Make sure to use the latest state file, as after resizing there is a new one. By the way, with the scripts shown, you can deploy multiple clusters, if you like :)

