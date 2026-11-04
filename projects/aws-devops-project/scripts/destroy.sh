#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
ENVIRONMENT="${1:-dev}"
case "$ENVIRONMENT" in
  dev|staging|prod) ;;
  *) echo "Usage: $0 {dev|staging|prod}" >&2; exit 2 ;;
esac
TF_DIR="$ROOT_DIR/terraform/environments/$ENVIRONMENT"
[[ -d "$TF_DIR" ]] || { echo "Missing Terraform environment: $ENVIRONMENT" >&2; exit 1; }

printf 'This will delete Kubernetes resources and Terraform infrastructure for %s. Type the environment name to continue: ' "$ENVIRONMENT"
read -r CONFIRMATION
[[ "$CONFIRMATION" == "$ENVIRONMENT" ]] || { echo "Confirmation did not match; no resources were changed."; exit 1; }

kubectl delete -f "$ROOT_DIR/k8s/$ENVIRONMENT/" --ignore-not-found=true
terraform -chdir="$TF_DIR" init -input=false
terraform -chdir="$TF_DIR" plan -destroy -input=false -out=tfplan
terraform -chdir="$TF_DIR" apply -input=false tfplan
rm -f "$TF_DIR/tfplan"
