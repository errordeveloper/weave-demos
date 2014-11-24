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

ENTRYPOINT [ \
  "java", \
  "-Dspark.akka.logLifecycleEvents=true", \
  "-Xms512m", "-Xmx512m", \
  "-cp", "::$SPARK_HOME/conf:$SPARK_HOME/lib/spark-assembly-1.1.0-hadoop2.0.0-mr1-cdh4.2.0.jar:$SPARK_HOME/lib/datanucleus-api-jdo-3.2.1.jar:$SPARK_HOME/lib/datanucleus-core-3.2.2.jar:$SPARK_HOME/lib/datanucleus-rdbms-3.2.1.jar" \
]
