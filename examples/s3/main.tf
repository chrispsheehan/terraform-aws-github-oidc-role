module "github_oidc_role" {
  source = "../.."

  deploy_role_name = "example-github-oidc-role"
  github_repo      = "octo-org/octo-repo"
  state_bucket     = "example-terraform-state-bucket"

  state_locking_mode = "s3"

  deploy_branches = ["main"]
}
