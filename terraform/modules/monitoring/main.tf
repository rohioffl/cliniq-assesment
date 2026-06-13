# --- Notification Channels ---

resource "google_monitoring_notification_channel" "email" {
  display_name = "Rohit Email Alert"
  type         = "email"
  project      = var.project_id

  labels = {
    email_address = var.alert_email
  }
}

resource "google_monitoring_notification_channel" "google_chat" {
  display_name = "Rohit Google Chat"
  type         = "webhook_tokenauth"
  project      = var.project_id

  labels = {
    url = var.google_chat_webhook_url
  }
}

# --- Log-based Metrics ---

resource "google_logging_metric" "error_count" {
  name    = "rohit/error_count"
  project = var.project_id
  filter  = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"${var.cloud_run_service_name}\" AND severity>=ERROR"

  metric_descriptor {
    metric_kind  = "DELTA"
    value_type   = "INT64"
    unit         = "1"
    display_name = "Rohit Error Count"
  }
}

resource "google_logging_metric" "request_latency" {
  name    = "rohit/request_latency"
  project = var.project_id
  filter  = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"${var.cloud_run_service_name}\" AND httpRequest.latency!=\"\""

  metric_descriptor {
    metric_kind  = "DELTA"
    value_type   = "DISTRIBUTION"
    unit         = "ms"
    display_name = "Rohit Request Latency"
  }

  value_extractor = "EXTRACT(httpRequest.latency)"

  bucket_options {
    explicit_buckets {
      bounds = [0, 100, 500, 1000, 2000, 5000]
    }
  }
}

# --- CPU Alert: >70% → Google Chat warning ---

resource "google_monitoring_alert_policy" "cpu_warning" {
  display_name = "Rohit CPU Warning (>70%)"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "Cloud Run CPU > 70%"
    condition_threshold {
      filter          = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"${var.cloud_run_service_name}\" AND metric.type=\"run.googleapis.com/container/cpu/utilizations\""
      duration        = "60s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.70

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_PERCENTILE_99"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.google_chat.name]
  severity              = "WARNING"

  alert_strategy {
    auto_close = "1800s"
  }
}

# --- CPU Alert: >80% (sustained) → Email critical ---

resource "google_monitoring_alert_policy" "cpu_critical" {
  display_name = "Rohit CPU Critical (>80%)"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "Cloud Run CPU > 80% sustained"
    condition_threshold {
      filter          = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"${var.cloud_run_service_name}\" AND metric.type=\"run.googleapis.com/container/cpu/utilizations\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.80

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_PERCENTILE_99"
      }
    }
  }

  notification_channels = [
    google_monitoring_notification_channel.email.name,
    google_monitoring_notification_channel.google_chat.name
  ]
  severity = "CRITICAL"

  alert_strategy {
    auto_close = "3600s"
  }
}

# --- Memory Alert: >70% → Google Chat warning ---

resource "google_monitoring_alert_policy" "memory_warning" {
  display_name = "Rohit Memory Warning (>70%)"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "Cloud Run Memory > 70%"
    condition_threshold {
      filter          = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"${var.cloud_run_service_name}\" AND metric.type=\"run.googleapis.com/container/memory/utilizations\""
      duration        = "60s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.70

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_PERCENTILE_99"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.google_chat.name]
  severity              = "WARNING"

  alert_strategy {
    auto_close = "1800s"
  }
}

# --- Memory Alert: >80% (sustained) → Email critical ---

resource "google_monitoring_alert_policy" "memory_critical" {
  display_name = "Rohit Memory Critical (>80%)"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "Cloud Run Memory > 80% sustained"
    condition_threshold {
      filter          = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"${var.cloud_run_service_name}\" AND metric.type=\"run.googleapis.com/container/memory/utilizations\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.80

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_PERCENTILE_99"
      }
    }
  }

  notification_channels = [
    google_monitoring_notification_channel.email.name,
    google_monitoring_notification_channel.google_chat.name
  ]
  severity = "CRITICAL"

  alert_strategy {
    auto_close = "3600s"
  }
}

# --- Error Rate Alert ---

resource "google_monitoring_alert_policy" "error_rate" {
  display_name = "Rohit High Error Rate"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "Error log count > 10 in 5 minutes"
    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/rohit/error_count\" AND resource.type=\"cloud_run_revision\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 10

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = [
    google_monitoring_notification_channel.email.name,
    google_monitoring_notification_channel.google_chat.name
  ]
  severity = "CRITICAL"

  alert_strategy {
    auto_close = "3600s"
  }

  depends_on = [google_logging_metric.error_count]
}
