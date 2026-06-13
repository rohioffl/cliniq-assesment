provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

locals {
  # Use placeholder on first deploy (before CI/CD pushes the real image).
  # Cloud Run lifecycle ignore_changes means Terraform won't revert it after CI/CD updates it.
  artifact_registry_image = var.image_tag == "latest" ? "gcr.io/cloudrun/hello" : "${var.region}-docker.pkg.dev/${var.project_id}/rohit/rohit-api:${var.image_tag}"
}

module "vpc" {
  source     = "./modules/vpc"
  project_id = var.project_id
  region     = var.region
}

module "iam" {
  source         = "./modules/iam"
  project_id     = var.project_id
  project_number = var.project_number
  github_repo    = var.github_repo
}

module "secret_manager" {
  source      = "./modules/secret_manager"
  project_id  = var.project_id
  db_password = module.cloud_sql.db_password
  sa_email    = module.iam.cloudrun_sa_email
}

module "cloud_sql" {
  source         = "./modules/cloud_sql"
  project_id     = var.project_id
  region         = var.region
  db_name        = var.db_name
  db_user        = var.db_user
  vpc_network_id = module.vpc.network_id
  depends_on     = [module.vpc]
}

module "cloud_run" {
  source                = "./modules/cloud_run"
  project_id            = var.project_id
  region                = var.region
  image                 = local.artifact_registry_image
  sa_email              = module.iam.cloudrun_sa_email
  vpc_connector_id      = module.vpc.vpc_connector_id
  db_host               = module.cloud_sql.private_ip
  db_name               = var.db_name
  db_user               = var.db_user
  db_password_secret_id = module.secret_manager.db_password_secret_id
  min_instance_count    = var.min_instance_count
  max_instance_count    = var.max_instance_count
  depends_on            = [module.cloud_sql, module.iam, module.secret_manager]
}

module "monitoring" {
  source                  = "./modules/monitoring"
  project_id              = var.project_id
  cloud_run_service_name  = module.cloud_run.service_name
  alert_email             = var.alert_email
  google_chat_webhook_url = var.google_chat_webhook_url
  depends_on              = [module.cloud_run]
}
