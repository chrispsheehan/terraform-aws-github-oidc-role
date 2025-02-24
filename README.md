# terraform-aws-github-oidc-role

Creates an OIDC enabled AWS role to be used via the [aws-actions/configure-aws-credentials](https://github.com/aws-actions/configure-aws-credentials) github action.

- Branches take top priority—if a branch is allowed, it overrides everything else.

- Environments serve as a fallback—**if a branch is not allowed, but the environment is**, the workflow runs. *Deployment branches and tag* settings within github environment are inherited.

- Tags can allow deployments from versioned releases if neither branch nor environment is explicitly allowed.

- `allow_deployments` acts as a global override—if enabled, all workflows can assume the role.

- IAM role permissions (`allowed_role_actions` and `allowed_role_resources`) determine AWS access.

- Updated to `allowed_role_actions` and `allowed_role_resources` can be made when assumed with this role.

## requirements

The OIDC provider is pulled in via the below data block. Please ensure this exists as per [docs](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html).

```tf
locals {
  oidc_domain = "token.actions.githubusercontent.com"
}

data "aws_caller_identity" "current" {}

data "aws_iam_openid_connect_provider" "this" {
  arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_domain}"
}
```

## usage

```tf
module "github-oidc-role" {
  source  = "chrispsheehan/github-oidc-role/aws"
  version = "0.0.3"

  deploy_role_name = "your_deploy_role_name"
  state_bucket     = "700011111111-eu-west-2-project-deploy-tfstate"
  state_lock_table = "project-deploy-tf-lockid"
  github_repo      = "chrisheehan/project"

  allowed_role_actions = [
    "s3:*"
  ]
  allowed_role_resources = ["*"]

  # explicit limit github actions to deploy run on main branch only
  deploy_branches = ["main"]

  # explicit limit actions run/triggered from tag
  deploy_tags = ["*"]

  # limit branches/tags etc set within github environment settings 
  deploy_environments = ["dev", "prod"]
}
```

## github action

```yaml
name: Deploy Environment

on:
  workflow_call:

# These permissions are needed to interact with GitHub's OIDC Token endpoint
permissions:
    id-token: write
    contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ vars.AWS_ACCOUNT_ID }}:role/your_deploy_role_name
          aws-region: ${{ vars.AWS_REGION }}
      - name: deploy
        run: terraform apply -auto-approve
```