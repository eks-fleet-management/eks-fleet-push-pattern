variable "kubernetes_version" {
  description = "EKS version"
  type        = string
}

variable "addons" {
  description = "EKS addons"
  type        = any
}

variable "kms_key_admin_roles" {
  description = "list of role ARNs to add to the KMS policy"
  type        = list(string)
  default     = []

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
