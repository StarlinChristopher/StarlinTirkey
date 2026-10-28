#!/usr/bin/env bash
set -euo pipefail

: "${VAULT_ADDR:?Set VAULT_ADDR to the non-local Vault HTTPS endpoint}"
: "${VAULT_JWT_ROLE:?Set VAULT_JWT_ROLE to the restricted GitHub OIDC role}"
: "${VAULT_JWT:?Set VAULT_JWT from the GitHub Actions OIDC token}"
: "${VAULT_TOKEN_FILE:=$(mktemp)}"

cleanup() {
  rm -f "$VAULT_TOKEN_FILE"
}
trap cleanup EXIT
umask 077

if [[ "$VAULT_ADDR" != https://* ]]; then
  printf 'VAULT_ADDR must use HTTPS outside local development.\n' >&2
  exit 1
fi

login_payload="$(jq -cn --arg role "$VAULT_JWT_ROLE" --arg jwt "$VAULT_JWT" '{role:$role,jwt:$jwt}')"
login_response="$(curl --fail --silent --show-error \
  --header 'Content-Type: application/json' \
  --data "$login_payload" \
  "$VAULT_ADDR/v1/auth/jwt/login")"
VAULT_TOKEN="$(jq -er '.auth.client_token // empty' <<<"$login_response")"
[[ -n "$VAULT_TOKEN" ]] || { printf 'Vault JWT login returned no client token.\n' >&2; exit 1; }
printf '%s' "$VAULT_TOKEN" > "$VAULT_TOKEN_FILE"
chmod 600 "$VAULT_TOKEN_FILE"
unset VAULT_JWT

write_secret() {
  local name="$1" value payload
  value="$(openssl rand -base64 48 | tr -d '\n')"
  payload="$(jq -cn --arg name "$name" --arg value "$value" '{data:{($name):$value}}')"
  curl --fail --silent --show-error \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --header 'Content-Type: application/json' \
    --data "$payload" \
    "$VAULT_ADDR/v1/secret/data/edgeblueprint/$name" >/dev/null
  unset value payload
}

write_secret postgres_password
write_secret telemetry_api_token

VAULT_TOKEN_FILE="$VAULT_TOKEN_FILE" VAULT_ADDR="$VAULT_ADDR" \
  "$(dirname "${BASH_SOURCE[0]}")/sync-vault-secrets.sh" >/dev/null
printf '%s\n' 'Vault secrets rotated and synchronized without printing secret contents.'
