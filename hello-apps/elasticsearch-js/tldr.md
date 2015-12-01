## Boostrap
```
git clone https://github.com/errordeveloper/weave-demos
cd weave-demos/felix
vagrant up
cd ../hello-apps/elasticsearch-js
export NGINXPLUS_CREDS=" \
  --build-arg nginxplus_license_cookie=<...> \
  --build-arg nginxplus_license_secret=<...> \
"
./scripts/bootstrap.sh
```

## Does it work?

Our app should be accessible via:

   - `172.17.8.101:80` 
   - `172.17.8.102:80` 
   - `172.17.8.103:80` 

The API defined by this app is pretty simple:

   - `GET /` will give you some basic info about the database cluster
   - `POST /hello/:title` will store body in a document with title `:title`
   - `GET /hello/:title` will retrieve contents of document with title `:title`
   - `GET /search/:title` will search by title

So let's create our first document:

```
curl -s \
  --request POST \
  --data '{"a": 1}' \
  --header 'Content-type: application/json' \
  http://172.17.8.101/hello/sample1 | jq .
{
  "msg": {
    "_index": "hello",
    "_type": "json",
    "_id": "AUsB9l_6iEcqWz_eIw5X",
    "_version": 1,
    "created": true
  }
}
```

And fetch it:
```
curl -s \
  --request GET \
  http://172.17.8.101/hello/sample1 | jq .
{
  "msg": {
    "a": 1
  }
}
```

Now, we can also post another document with the same title:
```
curl -s \
  --request POST \
  --data '{"a": 2}' \
  --header 'Content-type: application/json' \
  http://172.17.8.101/hello/sample1 | jq .
{
  "msg": {
    "_index": "hello",
    "_type": "json",
    "_id": "AUsB9quZiEcqWz_eIw5Y",
    "_version": 1,
    "created": true
  }
}
```

Try to fetch it:
```
curl -s \
  --request GET \
  http://172.17.8.101/hello/sample1 | jq .
{
  "msg": "There're too many of those, I'm sorry! But you can try `/hello/_search/:title` ;)"
}
```

So we no longer can use `GET /hello/:title`, however search comes to rescue:

```
curl -s \
  --request GET \
  http://172.17.8.101/hello/_search/sample1 | jq .
{
  "msg": "Found 2 matching documents...",
  "hits": [
    {
      "title": "sample1",
      "text": {
        "a": 1
      },
      "id": "AUsB9l_6iEcqWz_eIw5X"
    },
    {
      "title": "sample1",
      "text": {
        "a": 2
      },
      "id": "AUsB9quZiEcqWz_eIw5Y"
    }
  ]
}
```

All done, have fun weaving Nginx+, Elasticsearch and Node.js apps!
