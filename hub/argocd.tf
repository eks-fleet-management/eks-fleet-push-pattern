################################################################################
# GitOps Bridge: Namespace
################################################################################
resource "kubernetes_namespace" "argocd" {
  depends_on = [module.eks]
  metadata {
    name = local.argocd_namespace
  }
}

################################################################################
# ArgoCD Pod identity
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

# Creating parameter for argocd hub role for the spoke clusters to read
resource "aws_ssm_parameter" "argocd_hub_role" {
  name  = "/fleet-hub/argocd-hub-role"
  type  = "String"
  value = module.argocd_hub_pod_identity.iam_role_arn
}

################################################################################
# GitOps Bridge: Bootstrap
################################################################################
module "gitops_bridge_bootstrap" {
  source  = "gitops-bridge-dev/gitops-bridge/helm"
  version = "0.1.0"
  cluster = {
    cluster_name = module.eks.cluster_name
    environment  = local.environment
    metadata     = local.addons_metadata
    addons       = local.addons
  }

  apps = local.argocd_apps
  argocd = {
    name             = "argocd"
    namespace        = local.argocd_namespace
    chart_version    = "7.4.1"
    values           = [file("${path.module}/argocd-initial-values.yaml")]
    timeout          = 600
    create_namespace = false
  }
  depends_on = [kubernetes_secret.git_secrets, kubectl_manifest.karpenter_node_pool]
}
