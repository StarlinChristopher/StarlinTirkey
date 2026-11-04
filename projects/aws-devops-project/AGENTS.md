# AWS Agent Guidance

These are project defaults for AI coding agents working with AWS. Project-specific requirements in existing code and infrastructure take precedence.

## AWS research and implementation

- For AWS tasks, search current AWS documentation and load the relevant installed skill before designing or changing AWS resources, SDK code, or infrastructure as code.
- Prefer the AWS MCP server for AWS documentation and API interactions. Use the AWS CLI when the MCP server is unavailable.
- Verify service behavior, API parameters, permissions, quotas, Region support, and pricing against current AWS documentation. State uncertainty when details cannot be verified.
- Prefer infrastructure as code, consistent with this repository's Terraform layout, over direct changes to live resources.
- Follow the AWS Well-Architected Framework and use least-privilege IAM permissions.
- Do not create, modify, or delete live AWS resources without explicit user approval. Preview changes and explain expected cost and impact before applying.
- Never report an inventory count or absence based on partial results. Check all relevant pages, Regions, and resource scopes; describe any limits in the search.
- Confirm live behavior from deployed resources and active versions, not just stored templates or descriptions.

## Security and credentials

- Never put access keys, session tokens, passwords, or other secrets in source code, Terraform variables committed to Git, container images, logs, or agent configuration.
- Use AWS CLI login, IAM Identity Center, or the environment's approved role-based credentials; do not request or persist long-lived keys.
- Do not read or print AWS credential-cache contents. Verify identity with `aws sts get-caller-identity` only after the user finishes browser sign-in.
- Avoid broad permissions and public network access; document any necessary exception.

## This project

- Infrastructure is managed under `terraform/`, with application and deployment configuration elsewhere in this repository.
- Inspect the existing modules and environment conventions before proposing AWS resources. Preserve the established project structure and validate Terraform changes with `terraform fmt` and `terraform validate` where applicable.
- Keep changes scoped to this repository. Do not modify neighboring projects or the user's shared Windows AWS credentials.

<!-- BEGIN AWS Agent Toolkit rules -->
# AWS Guidance

- Where these AWS rules conflict with the project's own instructions, the project's instructions take precedence.
- Prefer the AWS MCP Server for AWS interactions because it provides sandboxed execution, observability, and audit logging. If unavailable, use the AWS CLI directly.
- For AWS tasks involving building, configuring, migrating, debugging, operating services, writing SDK code, authoring CDK or CloudFormation, or explaining AWS service behavior, search current AWS documentation and load the matching installed skill first. Prefer that guidance over general knowledge.
- Verify AWS API parameters, permissions, limits, error codes, Region support, and pricing against current documentation. State uncertainty when unable to confirm details.
- Before reporting counts or absence, read every results page and search every relevant Region and resource scope. Describe limits if the inventory is partial.
- Confirm live behavior from deployed resources and active versions, not stored templates or descriptions. State causes as confirmed only when read data, configuration, or logs prove them.
- Prefer infrastructure as code over direct AWS CLI changes for infrastructure, and follow the AWS Well-Architected Framework.
- Do not use em dashes in AWS resource names or descriptions; use hyphens.
- Before concluding that resources are absent, inspect all plausible locations, including buckets, databases, and log groups.
- Do not infer missing records from metadata or a single empty query. Inspect the records through another method across the full time range.

## Secret Safety

- Never expose credentials, access tokens, API keys, or passwords. Do not retrieve secret values with Secrets Manager APIs or access its agent daemon directly.
- For application secret references, use runtime resolution such as `{{resolve:secretsmanager:secret-id:SecretString:json-key}}` with `asm-exec`.
<!-- END AWS Agent Toolkit rules -->
