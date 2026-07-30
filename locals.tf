locals {
  oidc_domain           = "token.actions.githubusercontent.com"
  uses_dynamodb_locking = var.state_locking_mode == "dynamodb"
  repo_owner            = split("/", var.github_repo)[0]
  repo_name             = split("/", var.github_repo)[1]
  repo_prefixes = [
    format("repo:%s", var.github_repo),
    format("repo:%s@*/%s@*", local.repo_owner, local.repo_name),
  ]
  repo_subject_contexts = concat(
    [for ref in var.deploy_branches : format("ref:refs/heads/%s", ref)],
    [for ref in var.deploy_tags : format("ref:refs/tags/%s", ref)],
    [for ref in var.deploy_environments : format("environment:%s", ref)],
    var.allow_deployments ? ["deployment"] : [],
  )
  repo_subjects = flatten([
    for prefix in local.repo_prefixes : [
      for context in local.repo_subject_contexts :
      format("%s:%s", prefix, context)
    ]
  ])

  assume_identity_policy_name  = "${var.deploy_role_name}-assume-oidc-role"
  state_management_policy_name = "${var.deploy_role_name}-state-management"
  role_management_policy_name  = "${var.deploy_role_name}-oidc-role-management"
  defined_access_policy_name   = "${var.deploy_role_name}-defined-access"

  oidc_assume_actions = [
    "sts:AssumeRoleWithWebIdentity",
    "sts:TagSession"
  ]
  s3_state_actions = [
    "s3:ListBucket",
    "s3:GetBucketLocation",
    "s3:GetBucketPolicy",
    "s3:GetBucketPublicAccessBlock",
    "s3:GetBucketVersioning",
    "s3:GetEncryptionConfiguration",
    "s3:GetObject",
    "s3:PutObject",
    "s3:DeleteObject",
  ]
  dynamodb_state_actions = local.uses_dynamodb_locking ? [
    "dynamodb:ListTables",
    "dynamodb:DescribeTable",
    "dynamodb:GetItem",
    "dynamodb:PutItem",
    "dynamodb:DeleteItem",
    "dynamodb:DescribeContinuousBackups",
    "dynamodb:DescribeTimeToLive",
    "dynamodb:ListTagsOfResource"
  ] : []
  oidc_management_actions = [
    "iam:GetOpenIDConnectProvider"
  ]
  role_management_actions = [
    "iam:GetRole",
    "iam:ListRolePolicies",
    "iam:ListAttachedRolePolicies",
    "iam:UpdateAssumeRolePolicy"
  ]
  policy_management_actions = [
    "iam:GetPolicy",
    "iam:GetPolicyVersion",
    "iam:GetPolicyVersions",
    "iam:ListPolicyVersions",
    "iam:CreatePolicyVersion",
    "iam:DeletePolicyVersion",
  ]
}
