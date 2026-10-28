#!/usr/bin/env bash
set -euo pipefail

: "${VAULT_ADDR:=http://127.0.0.1:18200}"
: "${VAULT_TOKEN_FILE:=$HOME/.vault-edgeblueprint-runtime-token}"

if [[ ! -f "$VAULT_TOKEN_FILE" || ! -r "$VAULT_TOKEN_FILE" ]]; then
  printf 'Vault token file is missing or unreadable: %s\n' "$VAULT_TOKEN_FILE" >&2
  exit 1
fi
if [[ "$(stat -c '%a' "$VAULT_TOKEN_FILE")" != "600" ]]; then
  printf 'Vault token file must be mode 600: %s\n' "$VAULT_TOKEN_FILE" >&2
  exit 1
fi
VAULT_TOKEN="$(<"$VAULT_TOKEN_FILE")"
if [[ -z "$VAULT_TOKEN" ]]; then
  printf 'Vault token file is empty: %s\n' "$VAULT_TOKEN_FILE" >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$ROOT_DIR/.runtime-secrets"
umask 077
mkdir -p "$OUT_DIR"
chmod 700 "$OUT_DIR"

fetch_secret() {
  local path="$1" field="$2" output="$3" payload value tmp
  payload="$(printf 'header = "X-Vault-Token: %s"\nurl = "%s/v1/secret/data/%s"\n' "$VAULT_TOKEN" "$VAULT_ADDR" "$path" | \
    curl --config - --fail --silent --show-error)"
  value="$(PAYLOAD="$payload" FIELD="$field" python3 - <<'PY'
import json, os, sys
payload = json.loads(os.environ["PAYLOAD"])
value = payload.get("data", {}).get("data", {}).get(os.environ["FIELD"], "")
if not isinstance(value, str) or not value:
    raise SystemExit("required Vault secret is missing")
sys.stdout.write(value)
PY
)"
  tmp="$OUT_DIR/.${output}.tmp"
  umask 077
  printf '%s' "$value" > "$tmp"
  chmod 600 "$tmp"
  mv -f "$tmp" "$OUT_DIR/$output"
}

fetch_secret edgeblueprint/postgres_password postgres_password postgres_password.txt
fetch_secret edgeblueprint/telemetry_api_token telemetry_api_token telemetry_api_token.txt
# Optional integrations remain disabled until their Vault values are provisioned.
if [[ "${ENABLE_CLOUDFLARE_TUNNEL:-false}" == "true" ]]; then
  fetch_secret edgeblueprint/cloudflare_tunnel_token cloudflare_tunnel_token cloudflare_tunnel_token.txt
fi

printf 'Vault secrets synchronized to %s\n' "$OUT_DIR"
