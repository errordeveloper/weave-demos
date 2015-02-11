#!/usr/bin/env node

var azure = require('./azure_wrapper.js');

azure.create_config('kubernetes', { 'core': 3 });

azure.run_task_queue([
  azure.queue_default_network(),
  azure.queue_machines('core', 'stable',
    azure.create_basic_weave_cluster_cloud_config),
});
