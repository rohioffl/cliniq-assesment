variable "project_id" {
  type = string
}

variable "project_number" {
  description = "GCP project number (numeric) — needed to build the WIF principal set"
  type        = string
}

variable "github_repo" {
  description = "GitHub repo in format owner/repo (e.g. myorg/rohit)"
  type        = string
  default     = "myorg/rohit"
}

variable "wif_pool_id" {
  description = "ID of the manually-created Workload Identity Pool (e.g. github-actions-pool)"
  type        = string
  default     = "github-actions-pool"
}

variable "wif_provider_id" {
  description = "ID of the manually-created WIF provider (e.g. github-provider)"
  type        = string
  default     = "github-provider"
}
