FROM errordeveloper/weave-spark-base-minimal

ENTRYPOINT [ \
  "java", \
  "-Dspark.akka.logLifecycleEvents=true", \
  "-Xms512m", "-Xmx512m", \
  "-cp", "::/usr/spark/conf:/usr/spark/lib/*", \
  "org.apache.spark.deploy.worker.Worker" \
]
