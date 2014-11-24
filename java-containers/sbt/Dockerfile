FROM errordeveloper/oracle-jdk

RUN curl \
  --silent \
  --location \
  --retry 3 \
  --insecure \
  https://repo.typesafe.com/typesafe/ivy-releases/org.scala-sbt/sbt-launch/0.13.7/sbt-launch.jar \
  --output /usr/lib/sbt-launch.jar

VOLUME [ "/io" ]

CMD [ \
  "-Xms512M", "-Xmx1536M", "-Xss1M", \
  "-XX:+CMSClassUnloadingEnabled', \
  "-XX:MaxPermSize=256M", \
  "-jar", "/usr/lib/sbt-launch.jar" \
]
