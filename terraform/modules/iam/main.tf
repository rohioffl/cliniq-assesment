# Dedicated service account for Cloud Run — minimal roles only
resource "google_service_account" "cloudrun_sa" {
  account_id   = "rohit-cloudrun-sa"
  display_name = "Rohit Cloud Run Service Account"
  project      = var.project_id
}

# Allow Cloud Run to pull images from Artifact Registry
resource "google_project_iam_member" "artifact_registry_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.cloudrun_sa.email}"
}

# Allow Cloud Run to access Secret Manager secrets
resource "google_project_iam_member" "secret_manager_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.cloudrun_sa.email}"
}

# Allow Cloud Run to write logs
resource "google_project_iam_member" "log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.cloudrun_sa.email}"
}

# Allow Cloud Run to write metrics
resource "google_project_iam_member" "metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.cloudrun_sa.email}"
}

# Allow GitHub Actions to impersonate the CI/CD service account
# WIF pool + provider are created manually; reference them by the known name.
resource "google_service_account" "cicd_sa" {
  account_id   = "rohit-cicd-sa"
  display_name = "Rohit CI/CD Service Account"
  project      = var.project_id
}

resource "google_service_account_iam_member" "github_wif_binding" {
  service_account_id = google_service_account.cicd_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/projects/${var.project_number}/locations/global/workloadIdentityPools/${var.wif_pool_id}/attribute.repository/${var.github_repo}"
}

# CI/CD SA roles: push images + deploy Cloud Run
resource "google_project_iam_member" "cicd_artifact_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.cicd_sa.email}"
}

resource "google_project_iam_member" "cicd_cloudrun_developer" {
  project = var.project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${google_service_account.cicd_sa.email}"
}

resource "google_project_iam_member" "cicd_sa_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.cicd_sa.email}"
}
