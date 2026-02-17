variable "project_id" {
  description = "The ID of the project"
  type        = string
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

variable "bucket_location" {
  description = "The location of the bucket"
  type        = string
  default     = "US"
}

variable "function_timeout" {
  description = "The timeout of the function"
  type        = number
  default     = 60
}

variable "function_name" {
  description = "The name of the function"
  type        = string
}

variable "function_description" {
  description = "The description of the function"
  type        = string
}

variable "function_runtime" {
  description = "The runtime of the function"
  type        = string
  default     = "nodejs20"
}

variable "function_available_memory_mb" {
  description = "The available memory of the function"
  type        = number
  default     = 128
}

variable "function_event_trigger" {
  description = "The event trigger of the function"
  type = object({
    event_type = string
    resource   = string
  })
  default = null
}

variable "function_trigger_http" {
  description = "The trigger type of the function"
  type        = bool
  default     = true
}

variable "function_environment_variables" {
  description = "The environment variables of the function"
  type        = map(string)
  default     = null
}

variable "function_secret_environment_variables" {
  description = "The secret environment variables of the function"
  type = map(object({
    secret  = string
    key     = string
    version = optional(string, "latest")
  }))
  default   = null
  sensitive = true
}

variable "function_entry_point" {
  description = "The entry point of the function"
  type        = string
}

variable "function_iam_roles" {
  description = "The IAM role of the function"
  type        = list(string)
  default     = []
}