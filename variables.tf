variable "project_id" {
  description = "The ID of the project"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

variable "file_location" {
  description = "The location of the function code"
  type        = string
}

variable "zip_location" {
  description = "The location of the zip file"
  type        = string
}

variable "bucket_name" {
  description = "The name of the bucket"
  type        = string
}

variable "function_name" {
  description = "The name of the function"
  type        = string
}

variable "function_description" {
  description = "The description of the function"
  type        = string
  default     = ""
}

variable "function_runtime" {
  description = "The runtime of the function (e.g., nodejs20, python311, go121)"
  type        = string
  default     = "nodejs20"
}

variable "function_entry_point" {
  description = "The entry point of the function"
  type        = string
}

# Build Config
variable "function_build_environment_variables" {
  description = "Build-time environment variables"
  type        = map(string)
  default     = null
}

# Service Config
variable "function_timeout" {
  description = "The timeout of the function in seconds"
  type        = number
  default     = 60
}

variable "function_available_memory" {
  description = "The amount of memory available for the function (e.g., 256M, 512M, 1Gi, 2Gi, 4Gi)"
  type        = string
  default     = "256M"
}

variable "function_available_cpu" {
  description = "The number of CPUs used in a single container instance (e.g., '1', '2', '4')"
  type        = string
  default     = "1"
}

variable "function_max_instance_count" {
  description = "The maximum number of instances for the function"
  type        = number
  default     = 100
}

variable "function_min_instance_count" {
  description = "The minimum number of instances for the function"
  type        = number
  default     = 0
}

variable "function_max_instance_request_concurrency" {
  description = "The maximum number of concurrent requests per instance"
  type        = number
  default     = 1
}

variable "function_ingress_settings" {
  description = "The ingress settings for the function (ALLOW_ALL, ALLOW_INTERNAL_ONLY, ALLOW_INTERNAL_AND_GCLB)"
  type        = string
  default     = "ALLOW_ALL"
}

variable "function_all_traffic_on_latest_revision" {
  description = "Whether 100% of traffic is routed to the latest revision"
  type        = bool
  default     = true
}

variable "function_environment_variables" {
  description = "Runtime environment variables"
  type        = map(string)
  default     = null
}

variable "function_secret_environment_variables" {
  description = "Secret environment variables from Secret Manager"
  type = map(object({
    secret  = string
    version = optional(string, "latest")
  }))
  default   = {}
  sensitive = true
}

variable "function_secret_volumes" {
  description = "Secret volumes to mount from Secret Manager"
  type = map(object({
    mount_path = string
    secret     = string
    versions = optional(list(object({
      version = string
      path    = string
    })), null)
  }))
  default   = {}
  sensitive = true
}

# Event Trigger
variable "function_event_trigger" {
  description = "Event trigger configuration for the function"
  type = object({
    event_type   = string
    pubsub_topic = optional(string, null)
    retry_policy = optional(string, "RETRY_POLICY_RETRY")
    event_filters = optional(list(object({
      attribute = string
      value     = string
      operator  = optional(string, null)
    })), null)
  })
  default = null
}

variable "function_event_trigger_region" {
  description = "The region for the event trigger (defaults to function region)"
  type        = string
  default     = null
}

# IAM
variable "function_deployer_service_account" {
  description = "Email de la SA que despliega la función (necesita actAs sobre la SA de la función)"
  type        = string
  default     = null
}

variable "function_iam_roles" {
  description = "List of IAM roles to grant to the function's service account"
  type        = list(string)
  default     = []
}

variable "function_invoker_members" {
  description = "List of members who can invoke the function (e.g., 'allUsers', 'user:email@example.com')"
  type        = list(string)
  default     = null
}

# Labels
variable "function_labels" {
  description = "Labels to apply to the function"
  type        = map(string)
  default     = {}
}
