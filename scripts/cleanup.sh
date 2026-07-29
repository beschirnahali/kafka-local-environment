#!/bin/bash
set -e

NAMESPACE=kafka
RELEASE_NAME=kafka-local

echo "Removing Helm release..."
helm uninstall "${RELEASE_NAME}" -n "${NAMESPACE}" || true

echo "Removing namespace..."
kubectl delete namespace "${NAMESPACE}" --ignore-not-found=true

echo "Waiting for namespace deletion..."
kubectl wait \
    --for=delete namespace/"${NAMESPACE}" \
    --timeout=300s || true

echo "Cleanup complete."
