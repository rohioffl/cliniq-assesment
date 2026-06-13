output "cloud_run_url" {
  description = "Cloud Run service URL"
  value       = module.cloud_run.service_url
}

output "cloud_sql_private_ip" {
  description = "Cloud SQL private IP"
  value       = module.cloud_sql.private_ip
  sensitive   = true
}

output "cloudrun_sa_email" {
  description = "Cloud Run service account email"
  value       = module.iam.cloudrun_sa_email
}

output "artifact_registry_image" {
  description = "Full image path in Artifact Registry"
  value       = local.artifact_registry_image
}
