# EdgeBluePrint

## Local development prerequisites

Install Docker Desktop with Compose support, Git, `curl`, OpenSSL, and `jq`.

On Ubuntu or WSL:

```bash
sudo apt-get update
sudo apt-get install --yes curl jq openssl
```

Verify the tools:

```bash
docker compose version
curl --version
jq --version
openssl version
```

The local API smoke test requires the Compose stack and reads its bearer token from `.runtime-secrets/telemetry_api_token.txt`:

```bash
./tests/smoke.sh
```

For live service output:

```bash
docker compose logs -f
```
