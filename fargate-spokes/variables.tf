variable "kubernetes_version" {
  description = "EKS version"
  type        = string
}

variable "addons" {
  description = "EKS addons"
  type        = any
  default = {
    enable_aws_load_balancer_controller = true
    enable_metrics_server               = true
    enable_karpenter                    = true
    enable_aws_efs_csi_driver           = true
    enable_external_dns                 = true
  }
}

variable "kms_key_admin_roles" {
  description = "list of role ARNs to add to the KMS policy"
  type        = list(string)
  default     = []

}

variable "route53_zone_name" {
  description = "the Name of Route53 zone for external dns"
}


variable "env_config" {
  description = "Map of objects for per environment configuration"
  type = map(object({
    account_id = string
  }))
}

variable "default_env_config" {
  description = "The Default account ids that need to deploy resources to shared services account"
  type = map(object({
    account_id = string
  }))
}

variable "tenant" {
  description = "Name of the tenant where the cluster belongs to"
}

variable "vpc_name" {
}
