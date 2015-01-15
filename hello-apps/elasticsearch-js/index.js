var elasticsearch = require('elasticsearch');
var es = new elasticsearch.Client({
    hosts: [ 'es-1.weave.local:9200', 'es-2.weave.local:9200', 'es-3.weave.local:9200', ],
      log: 'trace'
});

var restify = require('restify');

var server = restify.createServer({
  name: 'Hello, ElasticSearch on Weave!',
});

server.use(restify.bodyParser({ mapParams: false }));

server.listen(80);

es.ping({
  requestTimeout: 1000,
  // undocumented params are appended to the query string
  hello: "elasticsearch!"
}, function (error) {
  if (error) {
    console.error('elasticsearch cluster is down!');
  } else {
    console.log('All is well');
  }
});

es.indices.create({
  index: "hello",
}, function (error) {
  if (error) {
   console.error(error.message);
  } else {
   console.log('Created an index for our app.');
  }
});

server.get('/', function (req, res, next) {
  es.nodes.info({
    human: true,
    metrics: [ 'host', 'ip' ],
  }, function (error, es_res) {
    if (error) {
      res.send(500, { msg: error.message });
    } else {
    //res.send(200, { msg: "ElasticSearch cluster has _ nodes and all are well!" });
      res.send(200, es_res);
    }
  });
  return next();
});

server.post('/hello/:name', function (req, res, next) {
  es.create({
    index: 'hello',
    type: 'json',
    //id: 'h1',
    body: {
      title: req.params.name,
      published: true,
      text: req.body,
    },
  }, function (error, es_res) {
    if (error) {
      res.send(500, { msg: error.message });
    } else {
      res.send(201, { msg: es_res });
    }
  });
  return next();
});

server.get('/hello/:name', function (req, res, next) {
  es.search({
    index: 'hello',
    type: 'json',
    //id: 'h1',
    q: "title:"+req.params.name,
  }, function (error, es_res) {
    if (error) {
      res.send(500, { msg: error.message });
    } else {
      if (es_res.hits.total === 1) {
        res.send(200, { msg: es_res.hits.hits[0]._source.text });
      } else if (es_res.hits.total === 0) {
        res.send(404, { msg: "There're none of those, I'm afraid!" });
      } else if (es_re.hits.total > 1) {
        res.send(500, { msg: "There're too many of those, I'm sorry!" });
      }
    }
  });
  return next();
});
