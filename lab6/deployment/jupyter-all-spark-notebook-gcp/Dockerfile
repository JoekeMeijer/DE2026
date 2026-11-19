FROM quay.io/jupyter/all-spark-notebook:spark-4.2.0
USER root

RUN mv ${SPARK_HOME}/jars/hadoop-client-api-3.5.0.jar ${SPARK_HOME}/jars/hadoop-client-api-3.5.0.jar.bk
RUN mv ${SPARK_HOME}/jars/hadoop-client-runtime-3.5.0.jar ${SPARK_HOME}/jars/hadoop-client-runtime-3.5.0.jar.bk

COPY *.jar ${SPARK_HOME}/jars/

# add bigquery, kafka, and gsc dependencies
RUN echo 'spark.jars.packages com.google.guava:failureaccess:1.0.3,com.google.cloud.spark:spark-bigquery-with-dependencies_2.13:0.43.1,com.google.cloud.bigdataoss:gcs-connector:hadoop3-2.2.31,org.apache.spark:spark-sql-kafka-0-10_2.13:4.2.0' >> "${SPARK_HOME}/conf/spark-defaults.conf"
