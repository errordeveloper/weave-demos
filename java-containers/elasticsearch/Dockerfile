FROM errordeveloper/oracle-jdk

RUN curl \
  --silent \
  --location \
  --retry 3 \
  --cacert /etc/ssl/certs/Go_Daddy_Class_2_CA.crt \
  https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.4.0.tar.gz \
    | gunzip \
    | tar x -C /usr/

CMD [ \
  "-Xms256m", "-Xmx1g", "-Xss256k", \
  "-Djava.awt.headless=true", \
  "-XX:+UseParNewGC", \
  "-XX:+UseConcMarkSweepGC", \
  "-XX:CMSInitiatingOccupancyFraction=75", \
  "-XX:+UseCMSInitiatingOccupancyOnly", \
  "-XX:+HeapDumpOnOutOfMemoryError", \
  "-XX:+DisableExplicitGC", \
  "-Delasticsearch", \
  "-Des.foreground=yes", \
  "-Des.path.home=/usr/elasticsearch-1.4.0", \
  "-Des.network.bind_host=_ethwe:ipv4_", \
  "-Des.network.publish_host=_ethwe:ipv4_", \
  "-Des.cluster.name=elasticsearch", \
  "-cp", ":/usr/elasticsearch-1.4.0/lib/elasticsearch-1.4.0.jar:/usr/elasticsearch-1.4.0/lib/*:/usr/elasticsearch-1.4.0/lib/sigar/*", \
  "org.elasticsearch.bootstrap.Elasticsearch" \
]
