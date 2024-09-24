locals {
  # This is an example how a secret could look like with private github using github apps
  git_secrets = {
    # fleet = {
    #   name                       = var.secret_name_git_data_fleet
    #   url                        = "${var.gitops_org}/${var.gitops_fleet_repo_name}.git"
    #   repo                       = var.gitops_fleet_repo_name
    #   github_app_id              = var.github_app_id
    #   github_app_installation_id = var.github_app_installation_id
    #   github_private_key         = var.github_private_key
    #   basepath                   = var.gitops_fleet_basepath
    #   path                       = var.gitops_fleet_path
    #   revision                   = var.gitops_fleet_revision
    # }
    addons = {
      name                       = var.secret_name_git_data_addons
      org                        = var.gitops_org
      url                        = "https://github.com/${var.gitops_org}/${var.gitops_addons_repo_name}.git"
      repo                       = var.gitops_addons_repo_name
      github_app_id              = var.github_app_id
      github_app_installation_id = var.github_app_installation_id
      github_private_key         = var.github_private_key
      basepath                   = var.gitops_addons_basepath
      path                       = var.gitops_addons_path
      revision                   = var.gitops_addons_revision
    }
  }
}
resource "kubernetes_secret" "git_secrets" {
  depends_on = [kubernetes_namespace.argocd]

  for_each = {
    # git-fleet = {
    #   type                    = "git"
    #   url                     = local.git_secrets.fleet.url
    #   githubAppID             = local.git_secrets.fleet.github_app_id
    #   githubAppInstallationID = local.git_secrets.fleet.github_app_installation_id
    #   githubAppPrivateKey     = local.git_secrets.fleet.github_private_key
    # }
    git-addons = {
      type = "git"
      url  = local.git_secrets.addons.url
      # githubAppID             = local.git_secrets.addons.github_app_id
      # githubAppInstallationID = local.git_secrets.addons.github_app_installation_id
      # githubAppPrivateKey     = local.git_secrets.addons.github_private_key
    }
    argocd-bitnami = {
      type      = "helm"
      url       = "charts.bitnami.com/bitnami"
      name      = "Bitnami"
      enableOCI = true
    }
  }

  metadata {
    name      = each.key
    namespace = kubernetes_namespace.argocd.metadata[0].name
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = each.value
}

resource "aws_secretsmanager_secret" "git_data" {
  for_each = {
    for key, value in local.git_secrets :
    key => value if var.push_model && var.private_git
  }

  name                    = each.value.name
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "git_data_version" {
  for_each = {
    for key, value in local.git_secrets :
    key => value if var.push_model
  }

  secret_id = aws_secretsmanager_secret.git_data[each.key].id
  secret_string = jsonencode({
    org      = var.gitops_org
    url      = each.value.url
    repo     = each.value.repo
    basepath = each.value.basepath
    path     = each.value.path
    revision = each.value.revision
  })
}
