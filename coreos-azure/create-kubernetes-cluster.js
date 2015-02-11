#!/usr/bin/env node

var _ = require('underscore');

var util = require('./util.js');

var coreos_image_ids = {
  'stable': '2b171e93f07c4903bcad35bda10acf22__CoreOS-Stable-522.6.0',
  'alpha': '2b171e93f07c4903bcad35bda10acf22__CoreOS-Alpha-584.0.0',
};

var conf = {
  nodes: {
    'etcd': 3,
    'main': 4,
  },
  resources: util.generate_azure_resource_strings('kubernetes'),
};

var initial_tasks = [
  ['network', 'vnet', 'create',
    '--location=West Europe',
    '--address-space=172.16.0.0',
    conf.resources['vnet'],
  ],
];

var vm_create_base_args = [
  'vm', 'create',
  '--location=West Europe',
  '--connect=' + conf.resources['service'],
  '--virtual-network-name=' + conf.resources['vnet'],
  '--no-ssh-password',
  '--ssh-cert=../azure-linux/coreos/cluster/ssh-cert.pem',
];

var hosts = [];

var etcd_cloud_config_files = util.create_kube_etcd_cloud_config(conf.nodes.etcd);

var create_etcd_cluster = _(conf.nodes.etcd).times(function (n) {
  return vm_create_base_args.concat([
    '--custom-data=' + etcd_cloud_config_files[n],
    coreos_image_ids['stable'], 'core',
    util.next_host(n, 'etcd'),
  ]);
});

var kube_cloud_config_file = util.create_kube_node_cloud_config(conf.nodes.main);

var create_kube_cluster = _(conf.nodes.main).times(function (n) {
  return vm_create_base_args.concat([
    '--custom-data=' + kube_cloud_config_file,
    coreos_image_ids['stable'], 'core',
    util.next_host(n, 'kube'),
  ]);
});

util.run_task_queue(initial_tasks.concat(create_etcd_cluster, create_kube_cluster, list_vms));
util.create_ssh_conf('kubernetes_deployment_ssh_conf', conf.resources['service'], hosts);
util.save_state('kubernetes-deployment.yml', conf);
