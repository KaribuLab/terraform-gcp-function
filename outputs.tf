output "function_id" {
  description = "The ID of the function"
  value       = google_cloudfunctions2_function.function.id
}

output "function_name" {
  description = "The name of the function"
  value       = google_cloudfunctions2_function.function.name
}

output "function_url" {
  description = "The URL of the function"
  value       = google_cloudfunctions2_function.function.service_config[0].uri
  sensitive   = true
}

output "function_state" {
  description = "The state of the function"
  value       = google_cloudfunctions2_function.function.state
}

output "service_account_email" {
  description = "The email of the service account"
  value       = google_service_account.service_account.email
}

output "function_environment" {
  description = "The environment of the function"
  value       = google_cloudfunctions2_function.function.environment
}
