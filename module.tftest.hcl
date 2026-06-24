provider "aws" {
  region                      = "eu-west-2"
  access_key                  = "mock"
  secret_key                  = "mock"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_requesting_account_id  = true
}

override_data {
  target = data.aws_caller_identity.this
  values = {
    account_id = "123456789012"
  }
}

override_data {
  target = data.aws_iam_openid_connect_provider.this
  values = {
    arn            = "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
    client_id_list = ["sts.amazonaws.com"]
  }
}

override_data {
  target = data.aws_s3_bucket.tf_state_bucket
  values = {
    arn = "arn:aws:s3:::example-terraform-state-bucket"
  }
}

override_data {
  target = data.aws_dynamodb_table.tf_lock_table[0]
  values = {
    arn = "arn:aws:dynamodb:eu-west-2:123456789012:table/example-terraform-lock-table"
  }
}

run "dynamodb_locking_plan" {
  command = plan

  variables {
    deploy_role_name   = "example-github-oidc-role"
    github_repo        = "octo-org/octo-repo"
    state_bucket       = "example-terraform-state-bucket"
    state_locking_mode = "dynamodb"
    state_lock_table   = "example-terraform-lock-table"
    deploy_branches    = ["main"]
  }

  assert {
    condition     = local.uses_dynamodb_locking
    error_message = "Expected DynamoDB locking mode to be enabled."
  }

  assert {
    condition     = length(regexall("dynamodb:", data.aws_iam_policy_document.state_management.json)) > 0
    error_message = "Expected state management policy to include DynamoDB permissions."
  }
}

run "s3_lockfile_plan" {
  command = plan

  variables {
    deploy_role_name   = "example-github-oidc-role"
    github_repo        = "octo-org/octo-repo"
    state_bucket       = "example-terraform-state-bucket"
    state_locking_mode = "s3_lockfile"
    state_lock_table   = null
    deploy_branches    = ["main"]
  }

  assert {
    condition     = !local.uses_dynamodb_locking
    error_message = "Expected S3 lockfile mode to disable DynamoDB locking."
  }

  assert {
    condition     = length(regexall("dynamodb:", data.aws_iam_policy_document.state_management.json)) == 0
    error_message = "Expected state management policy to exclude DynamoDB permissions in S3 lockfile mode."
  }
}

run "environment_subject_plan" {
  command = plan

  variables {
    deploy_role_name     = "example-github-oidc-role"
    github_repo          = "octo-org/octo-repo"
    state_bucket         = "example-terraform-state-bucket"
    state_locking_mode   = "dynamodb"
    state_lock_table     = "example-terraform-lock-table"
    deploy_environments  = ["dev"]
    allowed_role_actions = ["lambda:*", "logs:*"]
  }

  assert {
    condition     = contains(local.repo_subjects, "repo:octo-org/octo-repo:environment:dev")
    error_message = "Expected environment subject to be included."
  }

  assert {
    condition     = length(regexall("lambda:\\*", data.aws_iam_policy_document.defined.json)) > 0
    error_message = "Expected defined policy to include Lambda permissions."
  }
}

run "tag_subject_plan" {
  command = plan

  variables {
    deploy_role_name     = "example-github-oidc-role"
    github_repo          = "octo-org/octo-repo"
    state_bucket         = "example-terraform-state-bucket"
    state_locking_mode   = "s3_lockfile"
    deploy_tags          = ["v*"]
    allowed_role_actions = ["ecr:*", "ecs:*"]
  }

  assert {
    condition     = contains(local.repo_subjects, "repo:octo-org/octo-repo:ref:refs/tags/v*")
    error_message = "Expected tag subject to be included."
  }

  assert {
    condition     = length(regexall("ecr:\\*", data.aws_iam_policy_document.defined.json)) > 0
    error_message = "Expected defined policy to include ECR permissions."
  }
}

run "deployment_subject_plan" {
  command = plan

  variables {
    deploy_role_name     = "example-github-oidc-role"
    github_repo          = "octo-org/octo-repo"
    state_bucket         = "example-terraform-state-bucket"
    state_locking_mode   = "s3_lockfile"
    allow_deployments    = true
    allowed_role_actions = ["codedeploy:*", "s3:*"]
  }

  assert {
    condition     = contains(local.repo_subjects, "repo:octo-org/octo-repo:deployment")
    error_message = "Expected deployment subject to be included."
  }

  assert {
    condition     = length(regexall("codedeploy:\\*", data.aws_iam_policy_document.defined.json)) > 0
    error_message = "Expected defined policy to include CodeDeploy permissions."
  }
}

run "combined_subjects_plan" {
  command = plan

  variables {
    deploy_role_name     = "example-github-oidc-role"
    github_repo          = "octo-org/octo-repo"
    state_bucket         = "example-terraform-state-bucket"
    state_locking_mode   = "dynamodb"
    state_lock_table     = "example-terraform-lock-table"
    deploy_branches      = ["main", "release/*"]
    deploy_tags          = ["v*"]
    deploy_environments  = ["dev", "prod"]
    allow_deployments    = true
    allowed_role_actions = ["iam:*", "lambda:*", "s3:*"]
  }

  assert {
    condition     = contains(local.repo_subjects, "repo:octo-org/octo-repo:ref:refs/heads/main")
    error_message = "Expected branch subject to be included."
  }

  assert {
    condition     = contains(local.repo_subjects, "repo:octo-org/octo-repo:ref:refs/heads/release/*")
    error_message = "Expected wildcard branch subject to be included."
  }

  assert {
    condition     = contains(local.repo_subjects, "repo:octo-org/octo-repo:ref:refs/tags/v*")
    error_message = "Expected wildcard tag subject to be included."
  }

  assert {
    condition     = contains(local.repo_subjects, "repo:octo-org/octo-repo:environment:prod")
    error_message = "Expected environment subject to be included."
  }

  assert {
    condition     = contains(local.repo_subjects, "repo:octo-org/octo-repo:deployment")
    error_message = "Expected deployment subject to be included."
  }
}
