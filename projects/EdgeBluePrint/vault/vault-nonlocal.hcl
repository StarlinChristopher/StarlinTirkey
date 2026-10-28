# Non-local Vault configuration. Inject these values through the deployment secret manager.
# Never commit cloud credentials or KMS identifiers containing sensitive metadata.
ui = false
api_addr = "https://${VAULT_API_HOST}:8200"
cluster_addr = "https://${VAULT_CLUSTER_HOST}:8201"

storage "raft" {
  path    = "/vault/data"
  node_id = "${VAULT_NODE_ID}"
}

seal "awskms" {
  region     = "${VAULT_AWS_REGION}"
  kms_key_id = "${VAULT_AWSKMS_SEAL_KEY_ID}"
}

listener "tcp" {
  address         = "0.0.0.0:8200"
  cluster_address = "0.0.0.0:8201"
  tls_disable     = 0
  tls_cert_file   = "/vault/tls/server.crt"
  tls_key_file    = "/vault/tls/server.key"
}

telemetry {
  disable_hostname = true
}
