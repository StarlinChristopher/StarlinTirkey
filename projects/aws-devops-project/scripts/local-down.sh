#!/usr/bin/env bash
set -euo pipefail
ENVIRONMENT="${1:-dev}"
case "$ENVIRONMENT" in dev|staging|prod) ;; *) echo 'Usage: local-down.sh {dev|staging|prod}' >&2; exit 2 ;; esac
CLUSTER="aws-devops-${ENVIRONMENT}"
command -v k3d >/dev/null || { echo 'Install k3d to remove the local cluster.' >&2; exit 127; }
k3d cluster delete "$CLUSTER"
