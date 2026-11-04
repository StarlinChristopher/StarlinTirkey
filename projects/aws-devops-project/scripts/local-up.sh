#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
ENVIRONMENT="${1:-dev}"
case "$ENVIRONMENT" in dev|staging|prod) ;; *) echo 'Usage: local-up.sh {dev|staging|prod}' >&2; exit 2 ;; esac
CLUSTER="aws-devops-${ENVIRONMENT}"
command -v k3d >/dev/null || { echo 'Install k3d to create a local cluster.' >&2; exit 127; }
if ! k3d cluster list -o json | grep -q "\"name\":\"${CLUSTER}\""; then
  k3d cluster create "$CLUSTER" --agents 1 --servers 1 --wait
fi
kubectl config use-context "k3d-${CLUSTER}"
echo "Local cluster ready: k3d-${CLUSTER}"
echo "Build the local image with: docker build -f app/Dockerfile -t aws-devops-backend:local app"
echo "Apply the environment manifests with: kubectl apply -f ${ROOT_DIR}/k8s/${ENVIRONMENT}/"
