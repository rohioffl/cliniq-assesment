output "private_ip" {
  value     = google_sql_database_instance.main.private_ip_address
  sensitive = true
}

output "instance_name" {
  value = google_sql_database_instance.main.name
}

output "db_password" {
  value     = random_password.db_password.result
  sensitive = true
}
