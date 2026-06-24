module "github_oidc_role" {
  source = "../.."

  deploy_role_name = "example-shared-github-oidc-role"
  github_repo      = "octo-org/octo-repo"
  state_bucket     = "example-terraform-state-bucket"

  state_locking_mode = "dynamodb"
  state_lock_table   = "example-terraform-lock-table"

  deploy_branches     = ["main", "release/*"]
  deploy_tags         = ["v*"]
  deploy_environments = ["dev", "prod"]
  allow_deployments   = true

  allowed_role_actions = [
    "iam:*",
    "lambda:*",
    "s3:*",
  ]
  allowed_role_resources = ["*"]
}
