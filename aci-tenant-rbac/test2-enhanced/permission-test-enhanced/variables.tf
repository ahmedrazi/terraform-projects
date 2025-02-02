# variables.tf
variable "tenant_username" {
  description = "Username for tenant account"
  type        = string
  default     = "tenant_admin_user"
}

variable "tenant_password" {
  description = "Password for tenant account"
  type        = string
  sensitive   = true
}

variable "apic_url" {
  description = "URL of the APIC"
  type        = string
}

variable "tenant_name" {
  description = "Name of the tenant to be tested"
  type        = string
  default     = "test_tenant"
}

variable "insecure" {
  description = "Skip TLS verification"
  type        = bool
  default     = true
}