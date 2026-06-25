module "github_oidc_role" {
  source = "../.."

  deploy_role_name = "example-release-github-oidc-role"
  github_repo      = "octo-org/octo-repo"
  state_bucket     = "example-terraform-state-bucket"

  state_locking_mode = "s3"

  deploy_tags = ["v*"]

  allowed_role_actions = [
    "ecr:*",
    "ecs:*",
  ]
  allowed_role_resources = ["*"]
}
