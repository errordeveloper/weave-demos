FROM errordeveloper/oracle-jdk

ENV MVN_BINARY_RELEASE 3.2.3

RUN curl \
  --silent \
  --location \
  --retry 3 \
  http://mirror.vorboss.net/apache/maven/maven-3/$MVN_BINARY_RELEASE/binaries/apache-maven-$MVN_BINARY_RELEASE-bin.tar.gz \
    | gunzip \
    | tar x -C /usr/ \
  && ln -s /usr/apache-maven-$MVN_BINARY_RELEASE /usr/maven

ADD settings.xml /usr/maven/conf/

ENV PATH $PATH:$SPARK_HOME/bin:/usr/maven/bin/

VOLUME [ "/io" ]

WORKDIR /io


ENTRYPOINT [ "mvn" ]
