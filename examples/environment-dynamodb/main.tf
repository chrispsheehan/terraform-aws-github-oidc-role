module "github_oidc_role" {
  source = "../.."

  deploy_role_name = "example-dev-github-oidc-role"
  github_repo      = "octo-org/octo-repo"
  state_bucket     = "example-terraform-state-bucket"

  state_locking_mode = "dynamodb"
  state_lock_table   = "example-terraform-lock-table"

  deploy_environments = ["dev"]

  allowed_role_actions = [
    "lambda:*",
    "logs:*",
  ]
  allowed_role_resources = ["*"]
}
