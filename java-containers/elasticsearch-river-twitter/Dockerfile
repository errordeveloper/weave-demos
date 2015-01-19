FROM errordeveloper/weave-elasticsearch-minimal

RUN [ "java", "-Xmx64m", "-Xms16m", "-Delasticsearch", "-Des.path.home=/usr/elasticsearch", \
  "-cp", "/usr/elasticsearch/lib/*", "org.elasticsearch.plugins.PluginManager", \
  "--url", "https://github.com/errordeveloper/weave-demos/releases/download/sparkles-demo-1/elasticsearch-river-twitter-2.4.1.zip", \
  "--install", "elasticsearch/elasticsearch-river-twitter/2.4.1" ]
