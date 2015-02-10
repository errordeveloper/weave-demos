#!/usr/bin/env node

var _ = require('underscore');

var util = require('./util.js');

var node_count = 3;

var delete_vms = _(node_count).times(function (n) {
  return ['vm', 'delete', '--quiet', '--blob-delete', util.hostname(n)];
});

var delete_vnet = [
  ['network', 'vnet', 'delete', '--quiet', 'weave-cluster-internal-vnet-1'],
];

util.run_task_queue(delete_vms.concat(delete_vnet));
