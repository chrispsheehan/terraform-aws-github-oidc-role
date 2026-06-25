# 🚀 terraform-aws-github-oidc-role

Creates a least-privilege OIDC-enabled AWS IAM role for GitHub Actions.

## 🔁 Self-Updating

Bootstrap it once locally and then leave CI to manage further changes!

That means you can change the role privileges in your repo, push the change, and let the current OIDC role apply the next version of itself. Wonderful :).

## 🔐 Priority Logic

- 🥇 **Branches take top priority** — if a branch is allowed, it overrides everything else.
- 🌱 **Environments are fallback** — if a branch is _not_ allowed, but the environment is, the workflow can run.
- 🏷️ **Tags** enable deployments from versioned releases if neither branch nor environment is explicitly allowed.
- ⚙️ **`allow_deployments`** acts as a global override — if enabled, _any_ workflow can assume the role.
- 🔑 IAM permissions (`allowed_role_actions`, `allowed_role_resources`) control AWS access.
- ✍️ IAM permissions can be updated when assuming the role dynamically.

---

## 📋 Requirements

Before using this module, ensure the following already exist in your AWS account:

- A GitHub Actions OIDC provider (`token.actions.githubusercontent.com`). Verify it in the AWS Console: **IAM → Identity providers**.
- The Terraform backend resources (for example, the S3 bucket and DynamoDB lock table).

---

## ⚙️ Usage

```hcl
module "github-oidc-role" {
  source  = "chrispsheehan/github-oidc-role/aws"
  version = "1.0.1"

  deploy_role_name = "your_deploy_role_name"
  state_bucket     = "700011111111-eu-west-2-project-deploy-tfstate"
  github_repo      = "chrispsheehan/project"

  allowed_role_actions   = ["s3:*"]
  allowed_role_resources = ["*"]

  state_locking_mode = "s3"
  state_lock_table   = "project-deploy-tf-lockid"

  deploy_branches     = ["main"]
  deploy_tags         = ["*"]
  deploy_environments = ["dev", "prod"]
}
```

After the initial bootstrap, this module can usually be applied by the same GitHub Actions role it created.

Additional working examples live in `examples/` so they can be validated in CI:

---

## 🤖 GitHub Action Example

```yaml
name: Apply OIDC Role

on:
  push:
    paths:
      - "path/to/your/oidc-stack/**"
      - "path/to/your/shared/oidc-module/**"

permissions:
  id-token: write
  contents: read

jobs:
  apply-oidc:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: hashicorp/setup-terraform@v4
      - uses: aws-actions/configure-aws-credentials@v6
        with:
          role-to-assume: arn:aws:iam::${{ vars.AWS_ACCOUNT_ID }}:role/your_deploy_role_name
          aws-region: ${{ vars.AWS_REGION }}
      - name: Apply OIDC stack
        run: |
          terraform init
          terraform apply -auto-approve
```

---

## 🧪 Testing

This repo validates the root module and all runnable example configurations in CI.

To run the module behavior tests locally:

```sh
terraform test
```

To run the same tests via Docker:

```sh
docker run --rm --entrypoint sh -v "$PWD":/workspace -w /workspace hashicorp/terraform:1.7.5 -lc \
  "terraform init -backend=false && terraform test"
```
