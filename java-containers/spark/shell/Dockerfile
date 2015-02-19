FROM errordeveloper/oracle-jdk

RUN opkg-install bash libstdcpp zlib

ENV SPARK_BINARY_RELEASE 1.2.1-bin-cdh4

RUN curl \
  --silent \
  --location \
  --retry 3 \
  --insecure \
  https://d3kbcqa49mib13.cloudfront.net/spark-$SPARK_BINARY_RELEASE.tgz \
    | gunzip \
    | tar x -C /usr/ \
  && ln -s /usr/spark-$SPARK_BINARY_RELEASE /usr/spark

RUN curl \
  --silent \
  --location \
  --retry 3 \
  --insecure \
  https://github.com/errordeveloper/weave-demos/releases/download/sparkles-demo-1/python-2.7.6-gce-x86_64.txz \
    | xzcat \
    | tar x -C /usr/

RUN curl \
  --silent \
  --location \
  --retry 3 \
  http://central.maven.org/maven2/org/elasticsearch/elasticsearch-spark_2.10/2.1.0.Beta3/elasticsearch-spark_2.10-2.1.0.Beta3.jar \
  --output /usr/spark/lib/elasticsearch-spark_2.10-2.1.0.Beta3.jar

## Currently we need to tweak nsswitch.conf(5), mainly due to zettio/weave#68
RUN sed 's/^\(hosts:[\ ]*\)\(files\)\ \(dns\)$/\1\3 \2/' -i /etc/nsswitch.conf

ENV SPARK_HOME /usr/spark-$SPARK_BINARY_RELEASE
ENV PATH $PATH:$SPARK_HOME/bin:/usr/python/bin/

ENTRYPOINT [ "spark-shell" ]
