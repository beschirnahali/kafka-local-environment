#!/bin/bash
set -e

NAMESPACE=kafka
RELEASE_NAME=kafka-local
CHART_PATH=charts/kafka-local
KIND_CLUSTER=kafka
CONNECT_IMAGE=kafka-connect:0.1

echo "Checking Kind cluster..."
kind get clusters | grep -qx "${KIND_CLUSTER}" || {
    echo "Kind cluster '${KIND_CLUSTER}' not found."
    exit 1
}

echo "Creating namespace..."
kubectl create namespace "${NAMESPACE}" \
    --dry-run=client -o yaml | kubectl apply -f -

echo "Installing Strimzi..."
if ! kubectl get deployment strimzi-cluster-operator -n "${NAMESPACE}" >/dev/null 2>&1; then
    kubectl apply -f "https://strimzi.io/install/latest?namespace=${NAMESPACE}"

    kubectl wait deployment/strimzi-cluster-operator \
        -n "${NAMESPACE}" \
        --for=condition=Available \
        --timeout=300s
fi

echo "Checking Kafka Connect image..."
docker image inspect "${CONNECT_IMAGE}" >/dev/null 2>&1 || {
    echo "Docker image '${CONNECT_IMAGE}' not found."
    exit 1
}

echo "Loading Kafka Connect image into Kind..."
kind load docker-image "${CONNECT_IMAGE}" --name "${KIND_CLUSTER}"

echo "Installing/Upgrading Helm chart..."
helm upgrade --install "${RELEASE_NAME}" \
    "${CHART_PATH}" \
    --namespace "${NAMESPACE}" \
    --create-namespace

echo "Waiting for Kafka..."
kubectl wait kafka/local-cluster \
    -n "${NAMESPACE}" \
    --for=condition=Ready \
    --timeout=600s

echo "Creating Schema Registry truststore..."

rm -f ca.crt truststore.p12

kubectl get secret local-cluster-cluster-ca-cert \
    -n "${NAMESPACE}" \
    -o jsonpath='{.data.ca\.crt}' | base64 -d > ca.crt

keytool \
    -importcert \
    -alias cluster-ca \
    -file ca.crt \
    -keystore truststore.p12 \
    -storetype PKCS12 \
    -storepass changeit \
    -noprompt

kubectl create secret generic schema-registry-truststore \
    --from-file=truststore.p12 \
    -n "${NAMESPACE}" \
    --dry-run=client -o yaml | kubectl apply -f -

rm -f ca.crt truststore.p12

echo "Waiting for Kafka Connect..."
kubectl wait kafkaconnect/kafka-connect \
    -n "${NAMESPACE}" \
    --for=condition=Ready \
    --timeout=300s

echo
echo "Deployment completed successfully."
echo

kubectl get kafka,kafkaconnect,kafkaconnector,kafkatopic,kafkauser -n "${NAMESPACE}"
echo
kubectl get pods -n "${NAMESPACE}"
