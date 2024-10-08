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

# module "external_dns_pod_identity" {
#   count   = local.aws_addons.enable_external_dns ? 1 : 0
#   source  = "terraform-aws-modules/eks-pod-identity/aws"
#   version = "~> 1.4.0"

#   name = "external_dns"

#   attach_external_dns_policy = true
#   attach_custom_policy       = true
#   policy_statements = [
#     {
#       sid       = "Extra"
#       actions   = ["route53:ChangeResourceRecordSets"]
#       resources = [try(data.aws_route53_zone.selected.arn, "")]
#     }
#   ]
#   external_dns_hosted_zone_arns = [try(data.aws_route53_zone.selected.arn,null)]
#   # Pod Identity Associations
#   associations = {
#     addon = {
#       cluster_name    = module.eks.cluster_name
#       namespace       = "external-dns"
#       service_account = "external-dns-sa"
#     }
#   }

#   tags = local.tags
# }

# data "aws_route53_zone" "selected" {
#   name = var.route53_zone_name
# }