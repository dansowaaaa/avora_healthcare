# Avora on AWS (Terraform)

Infrastructure as code for **Avora**, a fictional healthcare appointment platform (demo only, no real medical data).

- `app/` – the static frontend (see `app/README.md`)
- `infra/` – Terraform for the AWS environment
- `docs/` – architecture notes and the build plan

## Prerequisites

- Terraform >= 1.5
- AWS CLI configured with an IAM user (never root keys): `aws sts get-caller-identity` should work

## Usage

```bash
cd infra
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

When you are done for the day:

```bash
terraform destroy
```

## Safety

State files and `*.tfvars` are git-ignored. Never commit access keys, `.pem` files, or state.
