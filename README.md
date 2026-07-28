# Kafka Local Development Environment

A production-inspired Apache Kafka development environment running on a local Kubernetes cluster.

The project demonstrates an end-to-end Change Data Capture (CDC) pipeline from PostgreSQL to an S3-compatible object store using Debezium, Apache Kafka, Kafka Connect, Schema Registry and MinIO.

## Architecture

```
                    +----------------------+
                    |     PostgreSQL       |
                    +----------+-----------+
                               |
                               | CDC
                               ▼
                 +----------------------------+
                 | Debezium PostgreSQL        |
                 | Kafka Connect Source       |
                 +-------------+--------------+
                               |
                               ▼
                      +----------------+
                      | Apache Kafka   |
                      | (Strimzi)      |
                      +-------+--------+
                              |
              +---------------+----------------+
              |                                |
              ▼                                ▼
    Schema Registry                 S3 Sink Connector
              |                                |
              +---------------+----------------+
                              |
                              ▼
                      +----------------+
                      | MinIO          |
                      | (Local S3)     |
                      +----------------+
```

---

# Features

- Local Kubernetes cluster using Kind
- Strimzi Kafka Operator
- Three-node Apache Kafka cluster
- Kafka Connect
- Debezium PostgreSQL Connector
- Confluent Schema Registry
- Confluent S3 Sink Connector
- MinIO (local S3-compatible object storage)
- Avro serialization
- TLS authentication
- Kafka ACL authorization
- Helm-based deployment
- Automated end-to-end smoke test

---

# Technology Stack

| Component | Technology |
|------------|------------|
| Kubernetes | Kind |
| Kafka | Apache Kafka |
| Kafka Operator | Strimzi |
| Database | PostgreSQL |
| CDC | Debezium |
| Serialization | Apache Avro |
| Schema Management | Confluent Schema Registry |
| Object Storage | MinIO (S3-compatible) |
| Deployment | Helm |

---

# Implementation Choices

## Why Kind?

Kind provides a lightweight local Kubernetes cluster that runs consistently on macOS and Linux while closely matching production Kubernetes behaviour.

## Why Strimzi?

Strimzi simplifies Kafka operations by managing Kafka clusters, users, topics, connectors and certificates through Kubernetes Custom Resources.

## Why Helm?

Helm provides declarative, version-controlled Kubernetes deployments with reusable templates and parameterised configuration, making deployments reproducible and easy to maintain.

## Why PostgreSQL?

PostgreSQL supports logical replication, making it fully compatible with Debezium's Change Data Capture capabilities.

## Why Debezium?

Debezium captures database changes directly from PostgreSQL WAL logs without modifying application code.

## Why Schema Registry?

Schema Registry centralises schema management and enables schema evolution while maintaining compatibility between producers and consumers.

## Why MinIO?

MinIO is an open-source **S3-compatible object storage** used as a local replacement for AWS S3. This enables local development without requiring cloud infrastructure while keeping the same S3 API.

---

# Prerequisites

- Docker — https://www.docker.com/
- Kind — https://kind.sigs.k8s.io/
- kubectl — https://kubernetes.io/docs/tasks/tools/
- Helm — https://helm.sh/
- Make — https://www.gnu.org/software/make/

---

# Quick Start

Create the Kafka Connect image

```bash
docker build -t kafka-connect:0.1 docker/
```

Create the local Kubernetes cluster:

```bash
make cluster
```

Deploy the complete platform:

```bash
make deploy
```

Run the smoke test:

```bash
make test
```

---

# Make Targets

```bash
make cluster     # Create Kind cluster
make deploy      # Deploy Kafka platform
make test        # Run end-to-end smoke test
make status      # Show running pods
make clean       # Remove Helm release
make delete      # Delete Kind cluster
```

---

# Smoke Test

The smoke test validates the complete CDC pipeline.

It performs the following checks:

1. Inserts a customer into PostgreSQL
2. Verifies Debezium processed the change
3. Verifies Kafka Connect connectors are healthy
4. Verifies Schema Registry contains the Avro schema
5. Verifies the S3 Sink Connector wrote an object to MinIO

Successful execution confirms the complete pipeline:

```
PostgreSQL
    ↓
Debezium
    ↓
Kafka
    ↓
Schema Registry
    ↓
S3 Sink Connector
    ↓
MinIO
```

---

# Investigating the Pipeline

## Verify PostgreSQL

```bash
kubectl exec -it deployment/postgres -n kafka -- \
psql -U postgres -d inventory
```

List customers:

```sql
SELECT * FROM customers;
```

---

## Verify Kafka Connect

```bash
kubectl get kafkaconnector -n kafka
```

---

## Verify Schema Registry

```bash
kubectl exec deployment/schema-registry -n kafka -- \
curl http://localhost:8081/subjects
```

---

## Verify MinIO

```bash
kubectl exec deployment/minio -n kafka -- \
mc ls local/cdc-data --recursive
```

---

## View Kafka Resources

```bash
kubectl get kafka,kafkaconnect,kafkaconnector,kafkatopic,kafkauser -n kafka
```

---

## View Pods

```bash
kubectl get pods -n kafka
```

---

# Project Structure

```
charts/
docker/
scripts/
Makefile
README.md
implementation-guidelines.md
kind.yaml
```

---

# Documentation

- Apache Kafka — https://kafka.apache.org/documentation/
- Strimzi — https://strimzi.io/documentation/
- Debezium — https://debezium.io/documentation/
- Kafka Connect — https://docs.confluent.io/platform/current/connect/
- Schema Registry — https://docs.confluent.io/platform/current/schema-registry/
- Apache Avro — https://avro.apache.org/docs/
- MinIO — https://min.io/docs/
- Helm — https://helm.sh/docs/
- Kind — https://kind.sigs.k8s.io/docs/

---

# Next Steps

The accompanying `implementation-guidelines.md` document explains the design decisions, scalability considerations, security model, schema management strategy, troubleshooting approach and production recommendations.