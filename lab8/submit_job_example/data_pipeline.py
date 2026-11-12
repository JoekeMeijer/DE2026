import argparse

from pyspark.sql import SparkSession
from pyspark.sql.functions import explode, split, concat, col, lit, desc


# maven_packages = "com.google.guava:failureaccess:1.0.3,com.google.cloud.spark:spark-bigquery-with-dependencies_2.13:0.43.1,com.google.cloud.bigdataoss:gcs-connector:hadoop3-2.2.31,org.apache.spark:spark-streaming-kafka-0-10_2.13:4.2.0"

def run_job(project_id, temp_bucket):
    spark = SparkSession.builder \
        .appName("BigqueryExampleSubmitJob") \
        .getOrCreate()
    # Load data from BigQuery.
    df = spark.read \
        .format("bigquery") \
        .load(project_id + ".labdataset.retaildata")  # project_id.datatset.tablename. Use your project id
    df.printSchema()
    df.show(4)
    words = df.where(df.Country == "France")
    words.show(100)
    words.printSchema()
    words = df.where(df.Country == "France").select(
        explode(
            split(col("Description"), " ")
        ).alias("word")
    )
    words.show(100)

    ordered_word_count = words.groupby(words.word).count().orderBy(col("count").desc())
    ordered_word_count.printSchema()
    print(ordered_word_count.count())
    ordered_word_count.show(100)
    # Use the Cloud Storage bucket for temporary BigQuery export data used by the connector.
    spark.conf.set('temporaryGcsBucket', temp_bucket)
    # Setup hadoop fs configuration for schema gs://
    conf = spark.sparkContext._jsc.hadoopConfiguration()
    conf.set("fs.gs.impl", "com.google.cloud.hadoop.fs.gcs.GoogleHadoopFileSystem")
    conf.set("fs.AbstractFileSystem.gs.impl", "com.google.cloud.hadoop.fs.gcs.GoogleHadoopFS")
    # Saving the data to BigQuery
    ordered_word_count.write.format('bigquery') \
        .option('table', project_id + '.labdataset.wordcounts') \
        .mode("append") \
        .save()
    # Stop the app
    spark.stop()
    # sc = spark.sparkContext
    # sc._gateway.jvm.System.exit(0)


# Defining and parsing the command-line arguments
def parse_command_line_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument('--project_id', type=str, help="GCP project id")
    parser.add_argument('--temp_bucket', type=str, help="GCP data bucket")
    args = parser.parse_args()
    return vars(args)  # The vars() method returns the __dict__ (dictionary mapping) attribute of the given object.


if __name__ == '__main__':
    run_job(
        **parse_command_line_arguments())  # The *args and **kwargs is a common idiom to allow arbitrary number of
