locals {
  zip_name          = "index.zip"
  zip_name_location = "${var.zip_location}/${local.zip_name}"
}

data "archive_file" "function" {
  type        = "zip"
  source_dir  = var.file_location
  output_path = local.zip_name_location
}

resource "google_storage_bucket_object" "archive" {
  name   = local.zip_name
  bucket = var.bucket_name
  source = data.archive_file.function.output_path
}

resource "google_cloudfunctions_function" "function" {
  name                  = var.function_name
  description           = var.function_description
  runtime               = var.function_runtime
  available_memory_mb   = var.function_available_memory_mb
  source_archive_bucket = var.bucket_name
  source_archive_object = google_storage_bucket_object.archive.name
  trigger_http          = var.function_event_trigger != null ? false : var.function_trigger_http
  dynamic "event_trigger" {
    for_each = var.function_event_trigger != null ? [var.function_event_trigger] : []
    content {
      event_type = var.function_event_trigger.event_type
      resource   = var.function_event_trigger.resource
    }
  }
  entry_point           = var.function_entry_point
  timeout               = var.function_timeout
  environment_variables = var.function_environment_variables != null ? var.function_environment_variables : null
  dynamic "secret_environment_variables" {
    for_each = var.function_secret_environment_variables != null ? { for k, v in var.function_secret_environment_variables : k => v } : {}
    content {
      secret  = each.value.secret
      key     = each.value.key
      version = each.value.version
    }
  }
}

resource "google_service_account" "service_account" {
  account_id   = "${var.function_name}-sa"
  display_name = "${var.function_name} Service Account"
  description  = "${var.function_name} Service Account"
  project      = var.project_id
}

resource "google_cloudfunctions_function_iam_member" "roles" {
  for_each       = toset(concat(["roles/cloudfunctions.invoker"], var.function_iam_roles))
  project        = google_cloudfunctions_function.function.project
  region         = google_cloudfunctions_function.function.region
  cloud_function = google_cloudfunctions_function.function.name
  role           = each.value
  member         = "serviceAccount:${google_service_account.service_account.email}"
}
