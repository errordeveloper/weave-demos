FROM errordeveloper/oracle-jdk

ENV SBT_BINARY_RELEASE 0.13.7

RUN curl \
  --silent \
  --location \
  --retry 3 \
  --insecure \
  https://repo.typesafe.com/typesafe/ivy-releases/org.scala-sbt/sbt-launch/$SBT_BINARY_RELEASE/sbt-launch.jar \
  --output /usr/lib/sbt-launch.jar \
    && java -Xms512M -Xmx1536M -Xss1M -XX:+CMSClassUnloadingEnabled -jar /usr/lib/sbt-launch.jar

VOLUME [ "/io" ]

WORKDIR /io

ENTRYPOINT [ \
  "java", "-Xms512M", "-Xmx1536M", "-Xss1M", "-XX:+CMSClassUnloadingEnabled", \
  "-jar", "/usr/lib/sbt-launch.jar" \
]
