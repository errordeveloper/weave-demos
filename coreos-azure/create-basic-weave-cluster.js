#!/usr/bin/env node

var cloudAxe = require('./util.js');

var conf = {
  node_count: 3,
  resources: cloudAxe.generate_azure_resource_strings('basic-weave-example'),
};

var cloud_config_file = cloudAxe.create_basic_weave_cluster_cloud_config(conf.node_count);

cloudAxe.queue_default_network(conf.resources);

cloudAxe.queue_x_machines('core', conf.node_count, conf.resources, 'stable',
  cloudAxe.create_basic_weave_cluster_cloud_config(conf.node_count)),

cloudAxe.run_task_queue();

cloudAxe.create_ssh_conf('weave_example_deployment_ssh_conf', conf.resources);
cloudAxe.save_state('weave-cluster-deployment.yml', conf);
