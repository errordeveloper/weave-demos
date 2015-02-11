#!/usr/bin/env node

var cloudAxe = require('./util.js');

cloudAxe.create_config('kubernetes', { 'etcd': 3, 'kube': 4 });

cloudAxe.run_task_queue([
  cloudAxe.queue_default_network(),
  cloudAxe.queue_machines('etcd', 'stable',
    cloudAxe.create_kube_etcd_cloud_config),
  cloudAxe.queue_machines('kube', 'stable',
    cloudAxe.create_kube_node_cloud_config),
]);

