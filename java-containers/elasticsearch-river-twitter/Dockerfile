FROM errordeveloper/weave-elasticsearch-minimal

RUN [ "java", "-Xmx64m", "-Xms16m", "-Delasticsearch", "-Des.path.home=/usr/elasticsearch", \
  "-cp", "/usr/elasticsearch/lib/*", "org.elasticsearch.plugins.PluginManager", \
  "--install", "elasticsearch/elasticsearch-river-twitter/2.4.2" ]
