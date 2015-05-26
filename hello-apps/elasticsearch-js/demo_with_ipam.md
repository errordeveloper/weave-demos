# Setup

```
git clone https://github.com/errordeveloper/weave-demos
cd weave-demos/felix 
vagrant up
```

# Deploy Elasticsearch Cluster

```
> ../hello-apps/elasticsearch-js/scripts/run_elasticsearch_with_ipam.sh
Starting ElasticSearch on core-01...
  - done
Starting ElasticSearch on core-02...
  - done
Starting ElasticSearch on core-03...
  - done
```

```
> vagrant ssh core-01
```

## Deploy Node.js App

```
>> git clone https://github.com/errordeveloper/weave-demos
>> cd weave-demos/hello-apps/elasticsearch-js
>> ./scripts/build.sh
>> weave run --with-dns --name hello-es-app-instance -h hello-es-app.weave.local hello-es-app
```

## Test Deployment

```
>> weave run --with-dns --name='es-admin' --tty --interactive errordeveloper/curl:latest
>> docker attach es-admin

/ # curl es-1.weave.local:9200 | jq '.'
{
  "status" : 200,
  "name" : "Hydro-Man",
  "cluster_name" : "elasticsearch",
  "version" : {
    "number" : "1.5.2",
    "build_hash" : "62ff9868b4c8a0c45860bebb259e21980778ab1c",
    "build_timestamp" : "2015-04-27T09:21:06Z",
    "build_snapshot" : false,
    "lucene_version" : "4.10.4"
  },
  "tagline" : "You Know, for Search"
}
/ # curl es-1.weave.local:9200/_cat/nodes
es-3.weave.local 10.2.3.65  4 17 0.00 d m Prototype 
es-2.weave.local 10.2.3.128 4 17 0.00 d * Shatter   
es-1.weave.local 10.2.3.1   4 18 0.09 d m Hydro-Man 
/ # 
/ # curl -s \
  --request POST \
  --data '{"a": 1}' \
  --header 'Content-type: application/json' \
  http://hello-es-app.weave.local/hello/sample1 | jq '.'
{
  "msg": {
    "_index": "hello",
    "_type": "json",
    "_id": "AUsB9l_6iEcqWz_eIw5X",
    "_version": 1,
    "created": true
  }
}
/ # curl -s \
  --request GET \
  http://hello-es-app.weave.local/hello/sample1 | jq '.'
{
  "msg": {
    "a": 1
  }
}
```
