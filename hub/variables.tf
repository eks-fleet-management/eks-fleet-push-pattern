variable "push_model" {
  description = "If Push model is enables it will create resources relevant to agent push to the spoke clusters"
  default     = false
}

variable "vpc_cidr" {
  default = "10.1.0.0/16"
}

variable "private_git" {
  description = "If its a private git will deploy the Secrets in EKS and on aws secrets"
  default     = false
}

variable "github_app_id" {
  description = "The github app id for the privat repo"
  default     = ""
}

variable "github_app_installation_id" {
  description = "The github app instalation id"
  default     = ""
}

variable "github_private_key" {
  description = "The github app ssh key"
  default     = ""
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.30"
}

variable "kms_key_admin_roles" {
  description = "list of role ARNs to add to the KMS policy"
  type        = list(string)
  default     = []
}

variable "addons" {
  description = "Kubernetes addons"
  type        = any
  default = {
    enable_aws_load_balancer_controller = true
    enable_metrics_server               = true
    enable_external_secrets             = true
    enable_argocd                       = false
  }
}

variable "secret_name_git_data_fleet" {
  description = "Secret name for Git data fleet"
  type        = string
  default     = ""
}

variable "secret_name_git_data_addons" {
  description = "Secret name for Git data addons"
  type        = string
  default     = ""
}

# Setting Up repositories for ArgoCD
variable "gitops_org" {
  description = "Github organization"
  default     = "eks-fleet-management"
}
# FLeet Repos for Agent Model
variable "gitops_fleet_repo_name" {
  description = "Git repository name for addons"
  default     = ""
}
variable "gitops_fleet_basepath" {
  description = "Git repository base path for addons"
  default     = ""
}
variable "gitops_fleet_path" {
  description = "Git repository path for addons"
  default     = ""
}
variable "gitops_fleet_revision" {
  description = "Git repository revision/branch/ref for addons"
  default     = ""
}
# Addons Repo Information
variable "gitops_addons_repo_name" {
  description = "Git repository name for addons"
  default     = "gitops-addons"
}
variable "gitops_addons_basepath" {
  description = "Git repository base path for addons"
  default     = ""
}
variable "gitops_addons_path" {
  description = "Git repository path for addons"
  default     = ""
}
variable "gitops_addons_revision" {
  description = "Git repository revision/branch/ref for addons"
  default     = "HEAD"
}
