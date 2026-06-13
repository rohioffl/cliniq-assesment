resource "google_secret_manager_secret" "db_password" {
  secret_id = "rohit-db-password"
  project   = var.project_id

  replication {
    auto {}
  }

  labels = {
    managed-by = "terraform"
    app        = "rohit"
  }
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = var.db_password
}

# Grant Cloud Run SA access to this specific secret only
resource "google_secret_manager_secret_iam_member" "cloudrun_db_password" {
  secret_id = google_secret_manager_secret.db_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.sa_email}"
  project   = var.project_id
}
