#!/usr/bin/env node

var cloudAxe = require('./util.js');

cloudAxe.create_config('kubernetes', { 'core': 3 });

cloudAxe.run_task_queue([
  cloudAxe.queue_default_network(),
  cloudAxe.queue_machines('core', 'stable',
    cloudAxe.create_basic_weave_cluster_cloud_config),
});
