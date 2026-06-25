module "github_oidc_role" {
  source = "../.."

  deploy_role_name = "example-deployments-github-oidc-role"
  github_repo      = "octo-org/octo-repo"
  state_bucket     = "example-terraform-state-bucket"

  state_locking_mode = "s3"

  allow_deployments = true

  allowed_role_actions = [
    "codedeploy:*",
    "s3:*",
  ]
  allowed_role_resources = ["*"]
}
