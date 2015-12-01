FROM errordeveloper/oracle-jre

ENV ELASTICSEARCH_BINARY_RELEASE 2.1.0

RUN curl \
  --silent \
  --location \
  --retry 3 \
  --cacert /etc/ssl/certs/Go_Daddy_Class_2_CA.crt \
  https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-$ELASTICSEARCH_BINARY_RELEASE.tar.gz \
    | gunzip \
    | tar x -C /usr/ \
  && ln -s /usr/elasticsearch-$ELASTICSEARCH_BINARY_RELEASE /usr/elasticsearch \
  && mkdir /data && chown nobody /data \
  && mkdir /usr/elasticsearch/logs && chown nobody /usr/elasticsearch/logs \
  && mkdir /usr/elasticsearch/plugins && chown nobody /usr/elasticsearch/plugins \
  && mkdir /usr/elasticsearch/config/scripts && chown nobody /usr/elasticsearch/config/scripts

VOLUME [ "/data" ]

RUN [ "java", "-Xmx64m", "-Xms16m", "-Delasticsearch", "-Des.path.home=/usr/elasticsearch", \
  "-cp", "/usr/elasticsearch/lib/*", "org.elasticsearch.plugins.PluginManager", \
    "--install", "discovery-multicast" ]

USER nobody

ADD logging.yml /usr/elasticsearch/config/logging.yml

CMD [ \
  "-Xms256m", "-Xmx1g", \
  "-Djava.awt.headless=true", \
  "-Djna.nosys=true", \
  "-Dfile.encoding=UTF-8", \
  "-XX:+UseParNewGC", \
  "-XX:+UseConcMarkSweepGC", \
  "-XX:CMSInitiatingOccupancyFraction=75", \
  "-XX:+UseCMSInitiatingOccupancyOnly", \
  "-XX:+HeapDumpOnOutOfMemoryError", \
  "-XX:+DisableExplicitGC", \
  "-Delasticsearch", \
  "-Des.foreground=yes", \
  "-Des.path.home=/usr/elasticsearch", \
  "-Des.path.data=/data", \
  "-Des.network.bind_host=_ethwe:ipv4_", \
  "-Des.network.publish_host=_ethwe:ipv4_", \
  "-Des.discovery.zen.ping.multicast.address=_ethwe:ipv4_", \
  "-Des.cluster.name=elasticsearch", \
  "-Des.http.cors.enabled=true", \
  "-cp", "/usr/elasticsearch/lib/elasticsearch-2.1.0.jar:/usr/elasticsearch/lib/*", \
  "org.elasticsearch.bootstrap.Elasticsearch", \
  "start" \
]
