var elasticsearch = require('elasticsearch');
var client = new elasticsearch.Client({
    hosts: [ 'es-1.weave.local', 'es-2.weave.local', 'es-3.weave.local', ],
      log: 'trace'
});

console.log(client.nodes);
