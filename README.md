# Terraform Single-Root Network Scaffold

Single Terraform root to manage **multi-account / multi-region** networking.
Includes minimal modules and a global root with provider aliases.

## Quick Start

1. Update `repo/stacks/prod/core/backend.tf` (S3 bucket/DynamoDB table).
2. Set auth in `repo/stacks/prod/core/providers.tf` (profile or assume_role).
3. Edit `repo/stacks/prod/core/all.auto.tfvars` (VPC definitions per account/region).
4. Run:
   ```bash
   terraform -chdir=stacks/prod/core init
   terraform -chdir=stacks/prod/core fmt
   terraform -chdir=stacks/prod/core validate
   terraform -chdir=stacks/prod/core plan
   terraform -chdir=stacks/prod/core apply -auto-approve
   ```

> NAT Gateways incur cost. For practice, remove `nat` or set `per_az=false`.
