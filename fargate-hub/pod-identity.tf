################################################################################
# External Secrets EKS Access
################################################################################
module "external_secrets_pod_identity" {
  count   = local.aws_addons.enable_external_secrets ? 1 : 0
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.4.0"

  name = "external-secrets"

  attach_custom_policy = true
  policy_statements = [
    {
      sid       = "ArgoCD"
      actions   = ["ecr:GetAuthorizationToken"]
      resources = ["*"]
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
    }
  }

  tags = local.tags
}

################################################################################
# CloudWatch Observability EKS Access
################################################################################
module "aws_cloudwatch_observability_pod_identity" {
  count   = local.aws_addons.enable_aws_cloudwatch_observability ? 1 : 0
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.4.0"

  name = "aws-cloudwatch-observability"

  attach_aws_cloudwatch_observability_policy = true

  # Pod Identity Associations
  associations = {
    addon = {
      cluster_name    = module.eks.cluster_name
      namespace       = "amazon-cloudwatch"
      service_account = "cloudwatch-agent"
    }
  }

  tags = local.tags
}

################################################################################
# EBS CSI EKS Access
################################################################################
module "aws_ebs_csi_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.4.0"

  name = "aws-ebs-csi"

  attach_aws_ebs_csi_policy = true
  aws_ebs_csi_kms_arns      = ["arn:aws:kms:*:*:key/*"]

  # Pod Identity Associations
  associations = {
    addon = {
      cluster_name    = module.eks.cluster_name
      namespace       = "kube-system"
      service_account = "ebs-csi-controller-sa"
    }
  }

  tags = local.tags
}

################################################################################
# AWS ALB Ingress Controller EKS Access
################################################################################
module "aws_lb_controller_pod_identity" {
  count   = local.aws_addons.enable_aws_load_balancer_controller ? 1 : 0
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.4.0"

  name = "aws-lbc"

  attach_aws_lb_controller_policy = true


  # Pod Identity Associations
  associations = {
    addon = {
      cluster_name    = module.eks.cluster_name
      namespace       = local.aws_load_balancer_controller.namespace
      service_account = local.aws_load_balancer_controller.service_account
    }
  }

  tags = local.tags
}

################################################################################
# Karpenter EKS Access
################################################################################

module "argocd_hub_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.4.0"

  name = "argocd"

  attach_custom_policy = true
  policy_statements = [
    {
      sid       = "ArgoCD"
      actions   = ["sts:AssumeRole", "sts:TagSession"]
      resources = ["*"]
    }
  ]

  # Pod Identity Associations
  association_defaults = {
    namespace = "argocd"
  }
  associations = {
    controller = {
      cluster_name    = module.eks.cluster_name
      service_account = "argocd-application-controller"
    }
    server = {
      cluster_name    = module.eks.cluster_name
      service_account = "argocd-server"
    }
  }

  tags = local.tags
}


################################################################################
# CloudWatch Observability EKS Access
################################################################################
module "external_dns_pod_identity" {
  count   = local.aws_addons.enable_external_dns ? 1 : 0
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.4.0"

  name = "external_dns"

  attach_external_dns_policy = true
  attach_custom_policy       = true
  policy_statements = [
    {
      sid       = "Extra"
      actions   = ["route53:ChangeResourceRecordSets"]
      resources = [data.aws_route53_zone.selected.arn]
    }
  ]
  external_dns_hosted_zone_arns = [data.aws_route53_zone.selected.arn]
  # Pod Identity Associations
  associations = {
    addon = {
      cluster_name    = module.eks.cluster_name
      namespace       = "external-dns"
      service_account = "external-dns-sa"
    }
  }

  tags = local.tags
}
