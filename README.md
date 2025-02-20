# terraform-aws-github-oidc-role

Creates an OIDC enabled AWS role to be used via the [aws-actions/configure-aws-credentials](https://github.com/aws-actions/configure-aws-credentials) github action.

- Branches take top priority—if a branch is allowed, it overrides everything else.

- Environments serve as a fallback—**if a branch is not allowed, but the environment is**, the workflow runs.

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
