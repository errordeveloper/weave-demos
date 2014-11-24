FROM errordeveloper/weave-spark-base-minimal

ENV SPARK_MASTER_IP 0.0.0.0
ENV SPARK_MASTER_PORT 7077
ENV SPARK_MASTER_WEBUI_PORT 8080

CMD [ \
  "org.apache.spark.deploy.master.Master", \
  "--ip", "$SPARK_MASTER_IP", \
  "--port", "$SPARK_MASTER_PORT", \
  "--webui-port", "$SPARK_MASTER_WEBUI_PORT" \
]
