################################################################################
# EKS Blueprints Addons
################################################################################
module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.16.3"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  # Using GitOps Bridge
  create_kubernetes_resources = false

  karpenter_node = {
    # Use static name so that it matches what is defined in `karpenter.yaml` example manifest
    iam_role_use_name_prefix = false
  }
  # EKS Blueprints Addons
  enable_cert_manager           = local.aws_addons.enable_cert_manager
  enable_aws_efs_csi_driver     = local.aws_addons.enable_aws_efs_csi_driver
  enable_aws_fsx_csi_driver     = local.aws_addons.enable_aws_fsx_csi_driver
  enable_aws_cloudwatch_metrics = local.aws_addons.enable_aws_cloudwatch_metrics
  enable_aws_privateca_issuer   = local.aws_addons.enable_aws_privateca_issuer
  enable_cluster_autoscaler     = local.aws_addons.enable_cluster_autoscaler
  enable_external_dns           = local.aws_addons.enable_external_dns
  # using pod identity for external secrets we don't need this
  #enable_external_secrets             = local.aws_addons.enable_external_secrets
  # using pod identity for external secrets we don't need this
  #enable_aws_load_balancer_controller = local.aws_addons.enable_aws_load_balancer_controller
  enable_fargate_fluentbit            = local.aws_addons.enable_fargate_fluentbit
  enable_aws_for_fluentbit            = local.aws_addons.enable_aws_for_fluentbit
  enable_aws_node_termination_handler = local.aws_addons.enable_aws_node_termination_handler
  # using pod identity for karpenter we don't need this
  #enable_karpenter                    = local.aws_addons.enable_karpenter
  enable_velero                     = local.aws_addons.enable_velero
  enable_aws_gateway_api_controller = local.aws_addons.enable_aws_gateway_api_controller

  tags = local.tags
}
