#!/usr/bin/env node

var azure = require('./azure_wrapper.js');

azure.destroy_cluster(process.argv[2]);
