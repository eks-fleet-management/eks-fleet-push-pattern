# variable "ssh_key_basepath" {
#   description = "path to .ssh directory"
#   type        = string
#   default     = "./private-key"
# }

# variable "secret_name_git_data_fleet" {
#   description = "Secret name for Git data fleet"
#   type        = string
#   default     = "stinky-badger/git-data-fleet"
# }

# variable "secret_name_git_data_addons" {
#   description = "Secret name for Git data addons"
#   type        = string
#   default     = "stinky-badger/git-data-addons"
# }

# variable "secret_name_git_data_platform" {
#   description = "Secret name for Git data platform"
#   type        = string
#   default     = "stinky-badger/git-data-platform"
# }

# variable "secret_name_git_data_workload" {
#   description = "Secret name for Git data workload"
#   type        = string
#   default     = "stinky-badger/git-data-workload"
# }

# variable "gitops_fleet_basepath" {
#   description = "Git repository base path for addons"
#   default     = ""
# }
# variable "gitops_fleet_path" {
#   description = "Git repository path for addons"
#   default     = "bootstrap"
# }
# variable "gitops_fleet_revision" {
#   description = "Git repository revision/branch/ref for addons"
#   default     = "HEAD"
# }
# variable "gitops_fleet_repo_name" {
#   description = "Git repository name for addons"
#   default     = "gitops-fleet"
# }
# variable "gitops_addons_basepath" {
#   description = "Git repository base path for addons"
#   default     = ""
# }
# variable "gitops_addons_path" {
#   description = "Git repository path for addons"
#   default     = "bootstrap"
# }
# variable "gitops_addons_revision" {
#   description = "Git repository revision/branch/ref for addons"
#   default     = "HEAD"
# }
# variable "gitops_addons_repo_name" {
#   description = "Git repository name for addons"
#   default     = "fleet-gitops-addons"
# }

# variable "gitops_platform_basepath" {
#   description = "Git repository base path for platform"
#   default     = ""
# }
# variable "gitops_platform_path" {
#   description = "Git repository path for workload"
#   default     = "bootstrap"
# }
# variable "gitops_platform_revision" {
#   description = "Git repository revision/branch/ref for workload"
#   default     = "HEAD"
# }
# variable "gitops_platform_repo_name" {
#   description = "Git repository name for platform"
#   default     = "fleet-gitops-platform"
# }

# variable "gitops_workload_basepath" {
#   description = "Git repository base path for workload"
#   default     = ""
# }
# variable "gitops_workload_path" {
#   description = "Git repository path for workload"
#   default     = ""
# }
# variable "gitops_workload_revision" {
#   description = "Git repository revision/branch/ref for workload"
#   default     = "HEAD"
# }
# variable "gitops_workload_repo_name" {
#   description = "Git repository name for workload"
#   default     = "fleet-gitops-apps"
# }

# locals {
#   github_app_id              = "977675"
#   github_app_installation_id = "54085417"
#   ssh_key_basepath           = var.ssh_key_basepath
#   github_private_key         = file("${local.ssh_key_basepath}/gitops_ssh.pem")
#   gitops_org                 = "https://github.com/The-Stinky-Badger"
#   # Specific
#   gitops_fleet_repo_name    = "fleet-gitops"
#   gitops_fleet_url          = "${local.gitops_org}/${local.gitops_fleet_repo_name}.git"
#   gitops_addons_repo_name   = "fleet-gitops-addons"
#   gitops_addons_url         = "${local.gitops_org}/${local.gitops_addons_repo_name}.git"
#   gitops_workload_repo_name = "fleet-gitops-workload"
#   gitops_workload_url       = "${local.gitops_org}/${local.gitops_workload_repo_name}.git"
#   gitops_platform_repo_name = "fleet-gitops-platform"
#   gitops_platform_url       = "${local.gitops_org}/${local.gitops_platform_repo_name}.git"
# }

# resource "aws_secretsmanager_secret" "git_data_fleet" {
#   name                    = var.secret_name_git_data_fleet
#   recovery_window_in_days = 0
# }

# resource "aws_secretsmanager_secret_version" "git_data_version_fleet" {
#   secret_id = aws_secretsmanager_secret.git_data_fleet.id
#   secret_string = jsonencode({
#     url                     = local.gitops_fleet_url
#     org                     = local.gitops_org
#     repo                    = local.gitops_fleet_repo_name
#     githubAppID             = local.github_app_id
#     githubAppInstallationID = local.github_app_installation_id
#     githubAppPrivateKey     = local.github_private_key
#     basepath                = var.gitops_fleet_basepath
#     path                    = var.gitops_fleet_path
#     revision                = var.gitops_fleet_revision
#   })
# }

# resource "aws_secretsmanager_secret" "git_data_addons" {
#   name                    = var.secret_name_git_data_addons
#   recovery_window_in_days = 0
# }

# resource "aws_secretsmanager_secret_version" "git_data_version_addons" {
#   secret_id = aws_secretsmanager_secret.git_data_addons.id
#   secret_string = jsonencode({
#     org                     = local.gitops_org
#     url                     = local.gitops_addons_url
#     repo                    = local.gitops_addons_repo_name
#     githubAppID             = local.github_app_id
#     githubAppInstallationID = local.github_app_installation_id
#     githubAppPrivateKey     = local.github_private_key
#     basepath                = var.gitops_addons_basepath
#     path                    = var.gitops_addons_path
#     revision                = var.gitops_addons_revision
#   })
# }

# resource "aws_secretsmanager_secret" "git_data_platform" {
#   name                    = var.secret_name_git_data_platform
#   recovery_window_in_days = 0
# }

# resource "aws_secretsmanager_secret_version" "git_data_platform" {
#   secret_id = aws_secretsmanager_secret.git_data_platform.id
#   secret_string = jsonencode({
#     org                     = local.gitops_org
#     url                     = local.gitops_platform_url
#     repo                    = local.gitops_platform_repo_name
#     githubAppID             = local.github_app_id
#     githubAppInstallationID = local.github_app_installation_id
#     githubAppPrivateKey     = local.github_private_key
#     basepath                = var.gitops_platform_basepath
#     path                    = var.gitops_platform_path
#     revision                = var.gitops_platform_revision
#   })
# }

# resource "aws_secretsmanager_secret" "git_data_workload" {
#   name                    = var.secret_name_git_data_workload
#   recovery_window_in_days = 0
# }

# resource "aws_secretsmanager_secret_version" "git_data_workload" {
#   secret_id = aws_secretsmanager_secret.git_data_workload.id
#   secret_string = jsonencode({
#     org                     = local.gitops_org
#     url                     = local.gitops_workload_url
#     repo                    = local.gitops_workload_repo_name
#     githubAppID             = local.github_app_id
#     githubAppInstallationID = local.github_app_installation_id
#     githubAppPrivateKey     = local.github_private_key
#     basepath                = var.gitops_fleet_basepath
#     path                    = var.gitops_fleet_path
#     revision                = var.gitops_fleet_revision
#   })
# }
