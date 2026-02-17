output "function_id" {
  description = "The ID of the function"
  value       = google_cloudfunctions_function.function.id
}

output "function_https_trigger_url" {
  description = "The HTTPS trigger URL of the function"
  value       = google_cloudfunctions_function.function.https_trigger_url
  sensitive   = true
  depends_on  = [google_cloudfunctions_function.function]
}

output "function_status" {
  description = "The status of the function"
  value       = google_cloudfunctions_function.function.status
  depends_on  = [google_cloudfunctions_function.function]
}

output "service_account_email" {
  description = "The email of the service account"
  value       = google_service_account.service_account.email
}