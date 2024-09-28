################################################################################
# Secret Required to Register spoke to HUB
################################################################################
resource "aws_secretsmanager_secret" "spoke_cluster_secret" {
  provider                = aws.shared-services
  name                    = "fleet-hub-cluster/fleet-spoke-${terraform.workspace}"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "argocd_cluster_secret_version" {
  provider  = aws.shared-services
  secret_id = aws_secretsmanager_secret.spoke_cluster_secret.id
  secret_string = jsonencode({
    cluster_name = module.eks.cluster_name
    environment  = local.environment
    metadata     = local.addons_metadata
    addons       = local.addons
    server       = module.eks.cluster_endpoint
    config = {
      tlsClientConfig = {
        insecure = false,
        caData   = module.eks.cluster_certificate_authority_data
      },
      awsAuthConfig = {
        clusterName = module.eks.cluster_name,
        roleARN     = aws_iam_role.spoke.arn
      }
    }
  })
}

################################################################################
# Secret Policy to allow Spoke account to read the secret from the Hub account
################################################################################

data "aws_iam_policy_document" "allow_cross_account_access" {
  provider = aws.shared-services
  statement {
    sid    = "EnableSpokeAWSAccountToReadTheSecret"
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${local.shared_services_account.account_id}:root",
        "${aws_iam_role.shared_services_secret_access_role.arn}"
      ]
    }

    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      "arn:aws:secretsmanager:${local.region}:${local.shared_services_account.account_id}:secret:fleet-hub-cluster*"
    ]
  }
}

resource "aws_secretsmanager_secret_policy" "spoke_cluster_secret_policy" {
  provider   = aws.shared-services
  secret_arn = aws_secretsmanager_secret.spoke_cluster_secret.arn
  policy     = data.aws_iam_policy_document.allow_cross_account_access.json
}

################################################################################
# External Secrets EKS Pod Identity for Extenal Secrets
# In this example we use external secrets For both Fleet namespace and Notmal External secret namespace
################################################################################
module "external_secrets_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.4.0"

  name = "external-secrets"
  # Give Permitions to External secret to Assume Remote From Hub Account
  policy_statements = [
    {
      sid       = "crossaccount"
      actions   = ["sts:AssumeRole", "sts:TagSession"]
      resources = [aws_iam_role.shared_services_secret_access_role.arn]
    }
  ]
  attach_external_secrets_policy        = true
  external_secrets_ssm_parameter_arns   = ["arn:aws:ssm:*:*:parameter/*"]         # In case you want to restrict access to specific SSM parameters "arn:aws:ssm:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:parameter/${local.name}/*"
  external_secrets_secrets_manager_arns = ["arn:aws:secretsmanager:*:*:secret:*"] # In case you want to restrict access to specific Secrets Manager secrets "arn:aws:secretsmanager:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:secret:${local.name}/*"
  external_secrets_kms_key_arns         = ["arn:aws:kms:*:*:key/*"]               # In case you want to restrict access to specific KMS keys "arn:aws:kms:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:key/*"
  external_secrets_create_permission    = false

  # Pod Identity Associations
  associations = {
    addon = {
      cluster_name    = module.eks.cluster_name
      namespace       = local.external_secrets.namespace
      service_account = local.external_secrets.service_account
    },
    fleet = {
      cluster_name    = module.eks.cluster_name
      namespace       = local.external_secrets.namespace_fleet
      service_account = local.external_secrets.service_account
    }
  }

  tags = local.tags
}

################################################################################
# Creating Role on the HUB account that is Assumed by the External Secret
################################################################################

resource "aws_iam_role" "shared_services_secret_access_role" {
  provider = aws.shared-services
  name     = "SecretAccessRole-${terraform.workspace}"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : module.external_secrets_pod_identity.iam_role_arn
        },
        "Action" : ["sts:AssumeRole", "sts:TagSession"]
      }
    ]
  })
}

resource "aws_iam_policy" "secret_access_policy" {
  provider = aws.shared-services
  name     = "SecretAccessPolicy-${terraform.workspace}"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        "Resource" : [
          # Secret Created by the Hub
          "arn:aws:secretsmanager:${local.region}:${local.shared_services_account.account_id}:secret:fleet-hub-cluster*",
          # Existing Secret with information about the private repos that Spoke needs access
          "arn:aws:secretsmanager:${local.region}:${local.shared_services_account.account_id}:secret:stinky-badger*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "kms:Decrypt"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_secret_access_policy" {
  provider   = aws.shared-services
  role       = aws_iam_role.shared_services_secret_access_role.name
  policy_arn = aws_iam_policy.secret_access_policy.arn
}

################################################################################
# ArgoCD EKS Access
################################################################################
resource "aws_iam_role" "spoke" {
  name               = "${local.name}-argocd-spoke"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole", "sts:TagSession"]
    principals {
      type        = "AWS"
      identifiers = [data.aws_ssm_parameter.argocd_hub_role.value]
    }
  }
}

# Reading parameter created by hub cluster to allow access of argocd to spoke clusters
data "aws_ssm_parameter" "argocd_hub_role" {
  provider = aws.shared-services
  name     = "/fleet-hub/argocd-hub-role"
}