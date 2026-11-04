# Enterprise EKS experience

This isolated Terraform root creates a private EKS control plane, managed node group, multi-tier public/private subnets, per-environment security boundaries, NAT, AWS service endpoints, and cluster audit/control-plane logs. It is intentionally separate from the legacy `terraform/environments` ECS example.

## Environment roots

- `environments/dev`: 2 AZs and 1 NAT gateway for lower-cost development.
- `environments/staging`: 3 AZs and one NAT gateway per AZ.
- `environments/prod`: 3 AZs, one NAT gateway per AZ, and a larger node group.

Copy the environment's `terraform.tfvars.example` to ignored `terraform.tfvars`. Authenticate the matching role profile before running Terraform. Planning queries AWS availability zones and therefore requires valid credentials and network access. Do not apply without reviewing cost and security impact.

```sh
AWS_PROFILE=aws-dev terraform -chdir=terraform/eks/environments/dev init
AWS_PROFILE=aws-dev terraform -chdir=terraform/eks/environments/dev plan
aws eks update-kubeconfig --name aws-devops-dev --region us-east-1 --profile aws-dev
```

## AWS role profiles

The project script adds role profiles to the user's AWS config only after the source profile can call STS and all target role ARNs are supplied. Set `AWS_DEV_ROLE_ARN`, `AWS_STAGING_ROLE_ARN`, and `AWS_PROD_ROLE_ARN`, then run `scripts/configure-aws-profiles.sh`. The IAM roles must trust the source profile's principal. It never writes access keys or session tokens.

## Local Kubernetes

Build the app image, create a local k3d cluster, then apply manifests:

```sh
docker build -f app/Dockerfile -t aws-devops-backend:local app
./scripts/local-up.sh dev
kubectl apply -f k8s/dev/
```

`./scripts/local-down.sh dev` deletes only the named local k3d cluster. Docker Compose runs the HTTP app locally without AWS infrastructure.
