#!/usr/bin/env bash
set -euo pipefail
: "${AWS_DEV_ROLE_ARN:?Set AWS_DEV_ROLE_ARN to your dev IAM role ARN.}"
: "${AWS_STAGING_ROLE_ARN:?Set AWS_STAGING_ROLE_ARN to your staging IAM role ARN.}"
: "${AWS_PROD_ROLE_ARN:?Set AWS_PROD_ROLE_ARN to your prod IAM role ARN.}"
SOURCE_PROFILE="${AWS_SOURCE_PROFILE:-StarlinTirkey}"
AWS_CONFIG_FILE="${AWS_CONFIG_FILE:-$HOME/.aws/config}"
if ! AWS_PROFILE="$SOURCE_PROFILE" aws sts get-caller-identity --query Arn --output text >/dev/null 2>&1; then
  echo "Source profile '$SOURCE_PROFILE' has no active AWS credentials. Configure SSO or another supported credential source first." >&2
  exit 1
fi
python3 - "$AWS_CONFIG_FILE" "$SOURCE_PROFILE" "${AWS_DEV_ROLE_ARN}" "${AWS_STAGING_ROLE_ARN}" "${AWS_PROD_ROLE_ARN}" <<'PY'
import os
import re
import sys
import tempfile

path, source, dev, staging, prod = sys.argv[1:]
roles = {"aws-dev": dev, "aws-staging": staging, "aws-prod": prod}
for name, arn in roles.items():
    if not re.fullmatch(r"arn:aws(?:-[a-z]+)?:iam::[0-9]{12}:role/[A-Za-z0-9+=,.@_/-]+", arn):
        raise SystemExit(f"{name} role ARN is malformed; no files were changed")
if not re.fullmatch(r"[A-Za-z0-9_+=,.@-]+", source):
    raise SystemExit("Source profile name contains unsupported characters")

try:
    with open(path, encoding="utf-8") as stream:
        original = stream.read()
except FileNotFoundError:
    original = ""

sections = {
    f"profile {name}": f"[profile {name}]\nrole_arn = {arn}\nsource_profile = {source}\nregion = us-east-1\noutput = json"
    for name, arn in roles.items()
}
lines = original.splitlines()
kept = []
current = None
for line in lines:
    match = re.match(r"^\s*\[([^]]+)\]\s*$", line)
    if match:
        current = match.group(1)
    if current not in sections:
        kept.append(line)

while kept and not kept[-1].strip():
    kept.pop()
result = "\n".join(kept + ([""] if kept else []) + [sections[name] for name in sections]) + "\n"
os.makedirs(os.path.dirname(path) or ".", mode=0o700, exist_ok=True)
mode = 0o600
try:
    mode = os.stat(path).st_mode & 0o777
except FileNotFoundError:
    pass
fd, temp = tempfile.mkstemp(prefix=".aws-config-", dir=os.path.dirname(path) or ".")
try:
    with os.fdopen(fd, "w", encoding="utf-8") as stream:
        stream.write(result)
        stream.flush()
        os.fsync(stream.fileno())
    os.chmod(temp, mode)
    os.replace(temp, path)
except BaseException:
    try:
        os.unlink(temp)
    except FileNotFoundError:
        pass
    raise
print(f"Configured aws-dev, aws-staging, aws-prod in {path}")
PY
