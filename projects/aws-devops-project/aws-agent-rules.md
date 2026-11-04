# Custom AWS Agent Rules

Edit this file to customize how the agent builds on AWS for this project.

## Defaults

- AWS Region: set `AWS_REGION` in your shell or AWS profile; do not assume a production Region.
- AWS profile: use the active AWS CLI profile. Sign in with `aws login` or `aws sso login` as appropriate.
- Infrastructure as code: Terraform, following the existing `terraform/` project conventions.
- Deployment environment: ask before choosing or changing a production environment.
- Security posture: least privilege, private-by-default networking, encryption at rest and in transit, and no secrets in code or images.
- Change approval: inspect and plan first; request explicit approval before applying infrastructure changes or incurring AWS charges.

## Project-specific preferences

- Preferred AWS services: [fill in]
- Required Regions: [fill in]
- Naming and tagging conventions: [fill in]
- Cost ceiling or budget: [fill in]
- Compliance requirements: [fill in]
- Deployment and approval process: [fill in]
