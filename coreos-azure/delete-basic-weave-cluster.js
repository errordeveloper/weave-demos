#!/usr/bin/env node

var _ = require('underscore');

var util = require('./util.js');

var conf = util.load_state('weave-cluster-deployment.yml');

if (conf === undefined) {
  console.log('Nothing to delete.');
  process.abort();
}

var delete_vms = _(conf.node_count).times(function (n) {
  return ['vm', 'delete', '--quiet', '--blob-delete', util.hostname(n)];
});

var delete_vnet = [
  ['network', 'vnet', 'delete', '--quiet', conf.resources['vnet']],
];

util.run_task_queue(delete_vms.concat(delete_vnet));
