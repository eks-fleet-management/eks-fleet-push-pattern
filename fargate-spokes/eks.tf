################################################################################
# EKS Cluster
################################################################################
#tfsec:ignore:aws-eks-enable-control-plane-logging
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.24.1"

  cluster_name                   = local.name
  cluster_version                = local.cluster_version
  cluster_endpoint_public_access = true
  authentication_mode            = "API"

  vpc_id     = data.aws_vpc.vpc.id
  subnet_ids = data.aws_subnets.intra_subnets.ids

  enable_cluster_creator_admin_permissions = true
  # Fargate profiles use the cluster primary security group so these are not utilized
  create_cluster_security_group = false
  create_node_security_group    = false
  fargate_profiles = {
    kube_system = {
      name = "kube-system"
      selectors = [
        {
          namespace = "kube-system"
          labels    = { k8s-app = "kube-dns" }
        },
        {
          namespace = "kube-system"
          labels    = { "app.kubernetes.io/name" = "karpenter" }
        }
      ]
    }
  }

  access_entries = {
    # This is the role that will be assume by the hub cluster role to access the spoke cluster
    argocd = {
      principal_arn = aws_iam_role.spoke.arn

      policy_associations = {
        argocd = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
    kube-admins = {
      principal_arn = tolist(data.aws_iam_roles.eks_admin_role.arns)[0]
      policy_associations = {
        admins = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  # EKS Addons
  cluster_addons = {
    coredns = {
      configuration_values = jsonencode({
        computeType = "fargate"
        resources = {
          limits = {
            cpu    = "0.25"
            memory = "256M"
          }
          requests = {
            cpu    = "0.25"
            memory = "256M"
          }
        }
      })
    }
    kube-proxy = {
      most_recent = true
    }
    eks-pod-identity-agent = {
      most_recent = true
    }
    vpc-cni = {
      # Specify the VPC CNI addon should be deployed before compute to ensure
      # the addon is configured before data plane compute resources are created
      # See README for further details
      # before_compute = true
      most_recent = true # To ensure access to the latest settings provided
      configuration_values = jsonencode({
        env = {
          # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        },
        enableNetworkPolicy = "true"
      })
    }
  }
  tags = merge(local.tags, {
    # NOTE - if creating multiple security groups with this module, only tag the
    # security group that Karpenter should utilize with the following tag
    # (i.e. - at most, only one security group should have this tag in your account)
    "karpenter.sh/discovery" = local.name
  })
}

module "karpenter" {
  depends_on = [module.eks]
  source     = "terraform-aws-modules/eks/aws//modules/karpenter"
  version    = "~> 20.24"

  cluster_name          = module.eks.cluster_name
  namespace             = local.karpenter.namespace
  enable_v1_permissions = true
  # Name needs to match role name passed to the EC2NodeClass
  node_iam_role_use_name_prefix = false
  node_iam_role_name            = local.karpenter.role_name

  # EKS Fargate does not support pod identity
  create_pod_identity_association = false
  enable_irsa                     = true
  irsa_oidc_provider_arn          = module.eks.oidc_provider_arn
  irsa_namespace_service_accounts = ["kube-system:karpenter"]

  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
  tags = local.tags
}

resource "helm_release" "karpenter" {
  depends_on          = [module.karpenter]
  name                = "karpenter"
  namespace           = local.karpenter.namespace
  create_namespace    = true
  repository          = "oci://public.ecr.aws/karpenter"
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart               = "karpenter"
  version             = "1.0.2"
  wait                = false

  values = [
    <<-EOT
    settings:
      clusterName: ${module.eks.cluster_name}
      clusterEndpoint: ${module.eks.cluster_endpoint}
      interruptionQueue: ${module.karpenter.queue_name}
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: ${module.karpenter.iam_role_arn}
    webhook:
      enabled: false
    EOT
  ]

  # lifecycle {
  #   ignore_changes = [
  #     repository_password
  #   ]
  # }
}

# Initial Karpenter Configuration for platform addons

resource "kubectl_manifest" "karpenter_init_nodeclass" {
  depends_on = [helm_release.karpenter]
  yaml_body  = <<-YAML
apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: platform
spec:
  amiSelectorTerms:
    - alias: bottlerocket@latest
  role: ${module.karpenter.node_iam_role_name}
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: ${module.eks.cluster_name}
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: ${module.eks.cluster_name}
  tags:
    karpenter.sh/discovery: ${module.eks.cluster_name}
  YAML
}

resource "kubectl_manifest" "karpenter_init_nodepool" {
  depends_on = [kubectl_manifest.karpenter_init_nodeclass]
  yaml_body  = <<-YAML
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: platform
spec:
  template:
    spec:
      nodeClassRef:
        group: karpenter.k8s.aws
        kind: EC2NodeClass
        name: platform
      taints:
        - key: CriticalAddonsOnly
          effect: NoSchedule
      requirements:
        - key: "karpenter.k8s.aws/instance-category"
          operator: In
          values: ["c", "m", "r"]
        - key: "karpenter.k8s.aws/instance-cpu"
          operator: In
          values: ["4", "8", "16", "32"]
        - key: "karpenter.k8s.aws/instance-hypervisor"
          operator: In
          values: ["nitro"]
        - key: "karpenter.k8s.aws/instance-generation"
          operator: Gt
          values: ["2"]
  limits:
    cpu: 1000
  disruption:
    consolidationPolicy: WhenEmpty
    consolidateAfter: 30s
  YAML
}