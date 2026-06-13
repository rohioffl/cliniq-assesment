output "cloudrun_sa_email" {
  value = google_service_account.cloudrun_sa.email
}

output "cicd_sa_email" {
  value = google_service_account.cicd_sa.email
}

output "workload_identity_provider" {
  value = "projects/${var.project_number}/locations/global/workloadIdentityPools/${var.wif_pool_id}/providers/${var.wif_provider_id}"
}
