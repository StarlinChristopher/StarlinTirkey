#!/usr/bin/env bash
set -euo pipefail

base_url="${BASE_URL:-https://localhost}"
token_file="${TOKEN_FILE:-.runtime-secrets/telemetry_api_token.txt}"
token="$(cat "$token_file")"

curl_args=(-k --fail-with-body --silent --show-error)
health="$(curl "${curl_args[@]}" "$base_url/health")"
test "$(jq -r .status <<<"$health")" = ok

telemetry="$(curl "${curl_args[@]}" -X POST "$base_url/telemetry" \
  -H "Authorization: Bearer $token" -H 'Content-Type: application/json' \
  --data '{"sensorId":"smoke-test","temperature":21.5}')"
test "$(jq -r .status <<<"$telemetry")" = ACCEPTED

search="$(curl "${curl_args[@]}" "$base_url/search?q=smoke-test" -H "Authorization: Bearer $token")"
test "$(jq -r '.results[] | select(.sensorId == "smoke-test") | .sensorId' <<<"$search" | head -n1)" = smoke-test
printf '%s\n' 'API smoke tests passed: /health, authenticated /telemetry, and /search'
