var elasticsearch = require('elasticsearch');
var es = new elasticsearch.Client({
    hosts: [ 'es-1.weave.local:9200', /* 'es-2.weave.local:9200', 'es-3.weave.local:9200', */ ],
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
  hello: "elasticsearch!"
}, function (error) {
  if (error) {
    console.error('elasticsearch cluster is down!');
  } else {
    console.log('All is well');
  }
});

server.post('/hello', function (req, res, next) {
  es.indices.create({
    index: "hello",
  }, function (error) {
    if (error) {
      res.send(500, { msg: error.message });
    } else {
      res.send(200, es_res);
    }
  });
  return next();
});

server.get('/', function (req, res, next) {
  es.nodes.info({
    human: true,
    metrics: [ 'host', 'ip' ],
  }, function (error, es_res) {
    if (error) {
      res.send(500, { msg: error.message });
    } else {
      res.send(200, es_res);
    }
  });
  return next();
});

server.get('/hello/_search/:title', function (req, res, next) {
  if (req.params.title !== "") {
    t = req.params.title;
  } else {
    t = "*";
  }
  es.search({
    index: 'hello',
    type: 'json',
    q: "title:"+t,
  }, function (error, es_res) {
    if (error) {
      res.send(500, { msg: error.message });
    } else {
      if (es_res.hits.total >= 1) {
        var hits = [];
        for (i in es_res.hits.hits) {
          hits.push({
              title: es_res.hits.hits[i]._source.title,
              text: es_res.hits.hits[i]._source.text,
              id: es_res.hits.hits[i]._id
          });
        }
        res.send(200, {
            msg: "Found " + es_res.hits.total + " matching documents...",
            hits: hits
        });
      } else if (es_res.hits.total === 0) {
        res.send(404, { msg: "There're none of those, I'm afraid!" });
      }
    }
  });
  return next();
});

server.post('/hello/:title', function (req, res, next) {
  es.create({
    index: 'hello',
    type: 'json',
    body: {
      title: req.params.title,
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

server.get('/hello/:title', function (req, res, next) {
  var redirect = function() {
    res.header('Location', '/hello/_search/'+req.params.title);
    res.send(302, { msg: "There're too many of those, I'm sorry! But you can try `GET /hello/_search/:title` ;)" });
  }

  if (req.params.title === "") {
    redirect();
    return next();
  }

  es.search({
    index: 'hello',
    type: 'json',
    q: "title:"+req.params.title,
  }, function (error, es_res) {
    if (error) {
      res.send(500, { msg: error.message });
    } else {
      if (es_res.hits.total === 1) {
        res.send(200, { msg: es_res.hits.hits[0]._source.text });
      } else if (es_res.hits.total === 0) {
        res.send(404, { msg: "There're none of those, I'm afraid!" });
      } else if (es_res.hits.total > 1) {
        redirect();
      }
    }
  });
  return next();
});
