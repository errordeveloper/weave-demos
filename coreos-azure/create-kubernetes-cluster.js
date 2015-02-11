#!/usr/bin/env node

var azure = require('./azure_wrapper.js');

azure.create_config('kubernetes', { 'etcd': 3, 'kube': 4 });

azure.run_task_queue([
  azure.queue_default_network(),
  azure.queue_machines('etcd', 'stable',
    azure.create_kube_etcd_cloud_config),
  azure.queue_machines('kube', 'stable',
    azure.create_kube_node_cloud_config),
]);
