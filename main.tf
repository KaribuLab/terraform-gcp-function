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

resource "google_service_account" "service_account" {
  account_id   = "${var.function_name}-sa"
  display_name = "${var.function_name} Service Account"
  description  = "${var.function_name} Service Account"
  project      = var.project_id
}

resource "google_project_iam_member" "function_roles" {
  for_each = toset(var.function_iam_roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_cloudfunctions2_function" "function" {
  name        = var.function_name
  location    = var.region
  description = var.function_description
  project     = var.project_id

  build_config {
    runtime     = var.function_runtime
    entry_point = var.function_entry_point
    
    source {
      storage_source {
        bucket = var.bucket_name
        object = google_storage_bucket_object.archive.name
      }
    }

    dynamic "environment_variables" {
      for_each = var.function_build_environment_variables != null ? { for k, v in var.function_build_environment_variables : k => v } : {}
      content {
        key   = environment_variables.key
        value = environment_variables.value
      }
    }
  }

  service_config {
    max_instance_count               = var.function_max_instance_count
    min_instance_count               = var.function_min_instance_count
    available_memory                 = var.function_available_memory
    timeout_seconds                  = var.function_timeout
    max_instance_request_concurrency = var.function_max_instance_request_concurrency
    available_cpu                    = var.function_available_cpu
    service_account_email            = google_service_account.service_account.email
    ingress_settings                 = var.function_ingress_settings
    all_traffic_on_latest_revision   = var.function_all_traffic_on_latest_revision
    
    dynamic "environment_variables" {
      for_each = var.function_environment_variables != null ? var.function_environment_variables : {}
      content {
        key   = environment_variables.key
        value = environment_variables.value
      }
    }

    dynamic "secret_environment_variables" {
      for_each = var.function_secret_environment_variables != null ? var.function_secret_environment_variables : {}
      content {
        key        = secret_environment_variables.key
        project_id = var.project_id
        secret     = secret_environment_variables.value.secret
        version    = secret_environment_variables.value.version
      }
    }

    dynamic "secret_volumes" {
      for_each = var.function_secret_volumes != null ? var.function_secret_volumes : {}
      content {
        mount_path = secret_volumes.value.mount_path
        project_id = var.project_id
        secret     = secret_volumes.value.secret
        
        dynamic "versions" {
          for_each = secret_volumes.value.versions != null ? secret_volumes.value.versions : []
          content {
            version = versions.value.version
            path    = versions.value.path
          }
        }
      }
    }
  }

  dynamic "event_trigger" {
    for_each = var.function_event_trigger != null ? [var.function_event_trigger] : []
    content {
      trigger_region        = var.function_event_trigger_region
      event_type            = event_trigger.value.event_type
      pubsub_topic          = event_trigger.value.pubsub_topic
      service_account_email = google_service_account.service_account.email
      retry_policy          = event_trigger.value.retry_policy

      dynamic "event_filters" {
        for_each = event_trigger.value.event_filters != null ? event_trigger.value.event_filters : []
        content {
          attribute = event_filters.value.attribute
          value     = event_filters.value.value
          operator  = event_filters.value.operator
        }
      }
    }
  }

  labels = var.function_labels

  depends_on = [
    google_project_iam_member.function_roles
  ]
}

resource "google_cloud_run_service_iam_member" "invoker" {
  for_each = var.function_invoker_members != null ? toset(var.function_invoker_members) : toset([])
  project  = google_cloudfunctions2_function.function.project
  location = google_cloudfunctions2_function.function.location
  service  = google_cloudfunctions2_function.function.name
  role     = "roles/run.invoker"
  member   = each.value
}
