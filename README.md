# terraform-aws-github-oidc-role

Creates a least-privilege AWS IAM role for GitHub Actions using OIDC.

Bootstrap it once locally, then let GitHub Actions apply future changes by assuming the same role this module created.

## Behavior

- Branches take top priority. If a branch is allowed, it overrides everything else.
- Environments are fallback. If a branch is not allowed, but the environment is, the workflow can run.
- Tags enable deployments from versioned releases if neither branch nor environment is explicitly allowed.
- `allow_deployments` acts as a global override. If enabled, any workflow can assume the role.
- IAM permissions from `allowed_role_actions` and `allowed_role_resources` control AWS access.
- The role can update its own IAM permissions when assuming the role dynamically.

## Requirements

Before using this module, ensure the following already exist in your AWS account:

- A GitHub Actions OIDC provider (`token.actions.githubusercontent.com`). Verify it in the AWS Console: **IAM → Identity providers**.
- The Terraform backend resources (for example, the S3 bucket and DynamoDB lock table).

## Usage

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

## Examples

- [`examples/combined`](examples/combined)
- [`examples/deployments`](examples/deployments)
- [`examples/dynamodb`](examples/dynamodb)
- [`examples/environment-dynamodb`](examples/environment-dynamodb)
- [`examples/s3`](examples/s3)
- [`examples/tag-only`](examples/tag-only)

## Outputs

- `role_arn`: ARN of the IAM role created by the module.

## GitHub OIDC Subject Matching

The trust policy matches allowed GitHub OIDC `sub` claims with `StringLike`.

This module accepts both of these branch subject shapes:

- `repo:<owner>/<repo>:ref:refs/heads/<branch>`
- `repo:<owner>@<owner_id>/<repo>@<repo_id>:ref:refs/heads/<branch>`

The second format reflects current GitHub OIDC tokens that include stable
numeric owner and repository ids in the `sub` claim.

## GitHub Actions Example

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

## Testing

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
