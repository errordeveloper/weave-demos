#!/usr/bin/env node

var _ = require('underscore');

var util = require('./util.js');

var conf = util.load_state(process.argv[2]);

if (conf === undefined) {
  console.log('Nothing to delete.');
  process.abort();
}

var delete_vms = _.map(conf.hosts, function (host) {
  return ['vm', 'delete', '--quiet', '--blob-delete', host.name];
});

var delete_vnet = [
  ['network', 'vnet', 'delete', '--quiet', conf.resources['vnet']],
];

util.run_task_queue(delete_vms.concat(delete_vnet));
