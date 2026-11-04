#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
ENVIRONMENT="${1:-dev}"
case "$ENVIRONMENT" in
  dev|staging|prod) ;;
  *) echo "Usage: $0 {dev|staging|prod}" >&2; exit 2 ;;
esac
: "${IMAGE:?Set IMAGE to an immutable registry image reference, e.g. registry.example/app@sha256:<digest>}"
[[ "$IMAGE" =~ @sha256:[a-f0-9]{64}$ ]] || { echo "IMAGE must be pinned by sha256 digest." >&2; exit 2; }
TF_DIR="$ROOT_DIR/terraform/environments/$ENVIRONMENT"
MANIFEST_DIR="$ROOT_DIR/k8s/$ENVIRONMENT"
[[ -d "$TF_DIR" ]] || { echo "Missing Terraform environment: $ENVIRONMENT" >&2; exit 1; }
: "${AWS_PROFILE:?Set AWS_PROFILE to the named profile you authenticated with using aws login or aws sso login.}"

terraform -chdir="$TF_DIR" init -input=false -lockfile=readonly
terraform -chdir="$TF_DIR" validate
plan_file="$(mktemp "${TMPDIR:-/tmp}/aws-devops-${ENVIRONMENT}.XXXXXX.tfplan")"
trap 'rm -f "$plan_file"' EXIT
terraform -chdir="$TF_DIR" plan -input=false -out="$plan_file"
echo "Review the Terraform plan above. Applying infrastructure requires setting APPLY_TERRAFORM=true."
if [[ "${APPLY_TERRAFORM:-false}" == "true" ]]; then
  terraform -chdir="$TF_DIR" apply -input=false "$plan_file"
else
  echo "Terraform apply skipped; no live resources were changed."
  exit 0
fi
[[ -d "$MANIFEST_DIR" ]] || { echo "Missing Kubernetes manifest directory: $ENVIRONMENT" >&2; exit 1; }

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
cp "$MANIFEST_DIR"/*.yaml "$tmp_dir/"
sed -i "s|aws-devops-backend:local|$IMAGE|g" "$tmp_dir"/deployment.yaml
kubectl apply --dry-run=server -f "$tmp_dir/"
kubectl apply -f "$tmp_dir/"
kubectl rollout status -n "$ENVIRONMENT" deployment/backend-app --timeout=180s
