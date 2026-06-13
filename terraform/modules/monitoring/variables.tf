variable "project_id" { type = string }
variable "cloud_run_service_name" { type = string }
variable "alert_email" { type = string }
variable "google_chat_webhook_url" {
  type      = string
  sensitive = true
}
