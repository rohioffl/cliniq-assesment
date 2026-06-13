variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "project_number" {
  description = "GCP project number (numeric)"
  type        = string
}

variable "github_repo" {
  description = "GitHub repo in format owner/repo used for WIF binding"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "latest"
}

variable "db_name" {
  description = "Cloud SQL database name"
  type        = string
  default     = "rohit"
}

variable "db_user" {
  description = "Cloud SQL database user"
  type        = string
  default     = "rohit_user"
}

variable "alert_email" {
  description = "Email address for critical alerts"
  type        = string
}

variable "google_chat_webhook_url" {
  description = "Google Chat webhook URL for warning alerts"
  type        = string
  sensitive   = true
}

variable "min_instance_count" {
  description = "Minimum Cloud Run instances"
  type        = number
  default     = 1
}

variable "max_instance_count" {
  description = "Maximum Cloud Run instances"
  type        = number
  default     = 10
}
