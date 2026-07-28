FROM quay.io/strimzi/kafka:0.51.0-kafka-4.2.0

USER root

RUN microdnf install -y unzip tar gzip && \
    microdnf clean all

# Debezium PostgreSQL Connector
ADD https://repo1.maven.org/maven2/io/debezium/debezium-connector-postgres/3.3.0.Final/debezium-connector-postgres-3.3.0.Final-plugin.zip /tmp/debezium.zip

RUN mkdir -p /opt/kafka/plugins/debezium-postgres && \
    unzip /tmp/debezium.zip -d /opt/kafka/plugins/debezium-postgres && \
    rm /tmp/debezium.zip

# S3 Sink Connector
COPY plugins/confluentinc-kafka-connect-s3-12.1.8.zip /tmp/s3.zip

RUN mkdir -p /opt/kafka/plugins/s3-sink && \
    unzip /tmp/s3.zip -d /opt/kafka/plugins/s3-sink && \
    rm /tmp/s3.zip

# Avro Converter
COPY plugins/confluentinc-kafka-connect-avro-converter-8.3.0.zip /tmp/avro.zip

RUN mkdir -p /opt/kafka/plugins/avro-converter && \
    unzip /tmp/avro.zip -d /opt/kafka/plugins/avro-converter && \
    rm /tmp/avro.zip

USER 1001