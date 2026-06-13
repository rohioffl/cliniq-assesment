output "email_channel_id" {
  value = google_monitoring_notification_channel.email.name
}

output "chat_channel_id" {
  value = google_monitoring_notification_channel.google_chat.name
}
