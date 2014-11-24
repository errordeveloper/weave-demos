FROM errordeveloper/oracle-jdk

RUN opkg-install bash

ENV SPARK_BINARY_RELEASE 1.1.0-bin-cdh4

RUN curl \
  --silent \
  --location \
  --retry 3 \
  --insecure \
  https://d3kbcqa49mib13.cloudfront.net/spark-$SPARK_BINARY_RELEASE.tgz \
    | gunzip \
    | tar x -C /usr/

ENV SPARK_HOME /usr/spark-$SPARK_BINARY_RELEASE
ENV PATH $PATH:$SPARK_HOME/bin

WORKDIR $SPARK_HOME

ENTRYPOINT [ "/bin/bash" ]