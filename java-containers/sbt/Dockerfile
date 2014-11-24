FROM errordeveloper/oracle-jdk

RUN curl \
  --silent \
  --location \
  --retry 3 \
  --insecure \
  https://repo.typesafe.com/typesafe/ivy-releases/org.scala-sbt/sbt-launch/0.13.7/sbt-launch.jar \
  --output /usr/lib/sbt-launch.jar

VOLUME [ "/io" ]

RUN java -Xms512M -Xmx1536M -Xss1M -XX:+CMSClassUnloadingEnabled -jar /usr/lib/sbt-launch.jar

CMD [ "-Xms512M", "-Xmx1536M", "-Xss1M", "-XX:+CMSClassUnloadingEnabled", "-jar", "/usr/lib/sbt-launch.jar" ]
