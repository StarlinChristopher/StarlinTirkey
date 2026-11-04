# Guided App Runner deployment

The Guided experience deploys an immutable ECR image to AWS App Runner with managed scaling and an HTTP health check. Copy `terraform.tfvars.example` to a local `terraform.tfvars` and replace the example account, ECR digest, App Runner ECR access role, and optional instance role with values from your AWS account.

```sh
cp terraform.tfvars.example terraform.tfvars
AWS_PROFILE=aws-dev terraform init
AWS_PROFILE=aws-dev terraform validate
AWS_PROFILE=aws-dev terraform plan
```

The sample image and ARNs are placeholders. Review the plan and estimated service cost before applying. No resources are created by init, validate, or plan.
