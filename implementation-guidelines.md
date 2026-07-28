# Implementation Guidelines

## Overview

This project provides a production-inspired local Kafka platform running on a Kubernetes cluster using Kind.

It demonstrates an end-to-end Change Data Capture (CDC) pipeline from PostgreSQL to an S3-compatible object store (MinIO).

```
PostgreSQL
      │
      ▼
Debezium PostgreSQL Connector
      │
      ▼
Apache Kafka
      │
      ├── Schema Registry
      ▼
S3 Sink Connector
      │
      ▼
MinIO
```

The infrastructure is deployed using Helm and managed by the Strimzi Kafka Operator.

---

# Scalability

Although intended for local development, the architecture follows production deployment patterns.

## Kafka

- Three Kafka brokers
- Topic replication factor of three
- Three topic partitions
- Operator-managed cluster using Strimzi

Production scaling can be achieved by:

- Adding Kafka brokers
- Increasing topic partitions
- Distributing producers and consumers across brokers

## Kafka Connect

Kafka Connect can be scaled horizontally by increasing the number of worker replicas. Connector task parallelism can also be increased by raising the connector's `tasks.max` configuration.

## Storage

MinIO is used only for local development.

For production deployments it should be replaced with cloud object storage such as AWS S3.

Similarly, Kubernetes `emptyDir` volumes should be replaced with Persistent Volumes to provide durable storage across pod restarts.

---

# Security

Although designed for local development, several production security practices have been implemented.

## TLS Encryption

Kafka communication is encrypted using TLS certificates automatically managed by Strimzi.

## Authentication

Kafka clients authenticate using Strimzi-managed TLS users.

Implemented users:

### connect-user

Used exclusively by Kafka Connect.

Permissions include:

- Read source topics
- Write destination topics
- Read and write Kafka Connect internal topics
- Consumer group access required by Kafka Connect

### schema-registry-user

Used exclusively by Schema Registry.

Permissions include:

- Read Kafka topics
- Write schema metadata
- Access required for schema registration and compatibility validation

## Authorization

Kafka ACLs enforce least-privilege access.

Each application receives only the permissions required to perform its specific responsibilities.

## Secrets Management

Sensitive information is stored using Kubernetes Secrets, including:

- PostgreSQL credentials
- MinIO credentials
- Kafka client certificates

Secrets are never embedded inside container images or committed to source control.

---

# Serialization and Schema Management

Apache Avro was selected as the event serialization format.

Advantages include:

- Compact binary representation
- Smaller payloads than JSON
- Strong schema enforcement
- Built-in schema evolution
- Native integration with Confluent Schema Registry
- Widely adopted within Kafka ecosystems

Compared with JSON, Avro reduces message size while ensuring producers and consumers remain schema-compatible over time.

Schema Registry provides:

- Centralised schema storage
- Schema versioning
- Compatibility validation
- Producer and consumer decoupling
- Safe schema evolution

---

# Destination Storage Format

The S3 Sink Connector stores CDC events as JSON objects.

JSON was intentionally selected because it is:

- Human-readable
- Easy to inspect during development
- Simple to debug
- Convenient for validating CDC behaviour

For analytical workloads, Parquet would generally be the preferred storage format because it offers:

- Columnar storage
- Better compression
- Lower storage costs
- Faster analytical queries
- Predicate pushdown support

The choice of JSON prioritises development simplicity over analytical performance.

---

# System Performance

The project is configured for local development rather than maximum throughput.

Production recommendations include:

- Increase Kafka broker resources
- Increase Kafka Connect JVM heap
- Increase connector task parallelism
- Use SSD-backed Persistent Volumes
- Tune PostgreSQL WAL parameters
- Monitor consumer lag
- Collect JVM and Kafka metrics with Prometheus

---

# Maintainability

The platform is managed declaratively using Helm.

Benefits include:

- Parameterised configuration
- Version-controlled infrastructure
- Reproducible deployments
- Simplified upgrades
- Easy environment customisation

Deployment is automated using Make:

```bash
make cluster
make deploy
make test
make clean
make delete
```

An automated smoke test validates the complete CDC pipeline after deployment.

---

# Troubleshooting

## Kafka

```bash
kubectl get kafka -n kafka
kubectl get pods -n kafka
kubectl logs <broker-pod> -n kafka
```

---

## Kafka Connect

```bash
kubectl get kafkaconnect -n kafka
kubectl get kafkaconnector -n kafka
kubectl logs kafka-connect-connect-0 -n kafka
```

---

## PostgreSQL

```bash
kubectl exec -it deployment/postgres -n kafka -- \
psql -U postgres -d inventory
```

---

## Schema Registry

```bash
kubectl exec deployment/schema-registry -n kafka -- \
curl http://localhost:8081/subjects
```

---

## MinIO

```bash
kubectl exec deployment/minio -n kafka -- \
mc ls local/cdc-data --recursive
```

---

## Verify Kubernetes Resources

```bash
kubectl get kafka,kafkaconnect,kafkaconnector,kafkatopic,kafkauser -n kafka
```

---

# Future Improvements

Potential production enhancements include:

- Prometheus metrics
- Grafana dashboards
- Alertmanager
- GitOps using Argo CD
- Persistent Volumes
- External Secrets Operator
- OAuth/OIDC authentication
- Multi-node Kubernetes cluster
- Dead Letter Queue (DLQ)
- Kafka MirrorMaker 2 for disaster recovery
- Automatic connector scaling

---

# Conclusion

This implementation provides a production-inspired local Kafka development environment that is fully reproducible using Helm.

The solution demonstrates an end-to-end CDC pipeline from PostgreSQL to an S3-compatible object store while incorporating production-oriented practices such as:

- Declarative Helm-managed Kubernetes deployments
- TLS-encrypted Kafka communication
- Kafka ACL-based authorization
- Schema Registry with Avro serialization
- Kubernetes Secrets for credential management
- Automated end-to-end smoke testing

The design prioritises reproducibility, maintainability and ease of local development while remaining closely aligned with production deployment patterns.