#!/usr/bin/env node

var cloudAxe = require('./util.js');

var conf = {
  nodes: {
    'etcd': 3,
    'main': 4,
  },
  resources: cloudAxe.generate_azure_resource_strings('kubernetes'),
};

cloudAxe.run_task_queue([
  cloudAxe.queue_default_network(conf.resources),
  cloudAxe.queue_x_machines('etcd', conf.nodes.etcd, conf.resources, 'stable',
    cloudAxe.create_kube_etcd_cloud_config(conf.nodes.etcd)),
  cloudAxe.queue_x_machines('kube', conf.nodes.main, conf.resources, 'stable',
    cloudAxe.create_kube_node_cloud_config(conf.nodes.main)),
]);

cloudAxe.create_ssh_conf('kubernetes_deployment_ssh_conf', conf.resources);
cloudAxe.save_state('kubernetes-deployment.yml', conf);
