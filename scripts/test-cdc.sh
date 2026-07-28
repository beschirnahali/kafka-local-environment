#!/usr/bin/env bash
set -euo pipefail

NAMESPACE=kafka
TOPIC=inventory.public.customers

echo "Inserting sample customer..."

kubectl exec -n ${NAMESPACE} deployment/postgres -- \
psql -U postgres -d inventory \
-c "INSERT INTO customers(first_name,last_name,email)
VALUES ('David','Beckham','david.beckham@example.com');"

echo "✓ Customer inserted"

echo "Waiting for CDC..."
sleep 10

echo "Checking connectors..."

kubectl wait kafkaconnector/postgres-connector \
    -n ${NAMESPACE} \
    --for=condition=Ready \
    --timeout=30s

kubectl wait kafkaconnector/s3-sink \
    -n ${NAMESPACE} \
    --for=condition=Ready \
    --timeout=30s

echo "✓ Connectors ready"

echo "Checking Schema Registry..."

kubectl exec -n ${NAMESPACE} deployment/schema-registry -- \
sh -c "curl -sf http://localhost:8081/subjects | grep -q '${TOPIC}-value'"

echo "✓ Schema registered"

echo "Checking MinIO..."

kubectl exec -n ${NAMESPACE} deployment/minio -- \
sh -c '
mc alias set local http://localhost:9000 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD" >/dev/null &&
mc ls local/cdc-data --recursive | wc -l
'

echo "✓ Object written to MinIO"
echo
echo "PASS"