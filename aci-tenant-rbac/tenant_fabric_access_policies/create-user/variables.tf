# variables.tf
variable "admin_username" {
  description = "Username for APIC admin account"
  type        = string
}

variable "admin_password" {
  description = "Password for APIC admin account"
  type        = string
  sensitive   = true
}

variable "tenant_username" {
  description = "Username for tenant admin account"
  type        = string
  default     = "tenant_admin_user"
}

variable "tenant_password" {
  description = "Password for tenant admin account"
  type        = string
  sensitive   = true
}

variable "apic_url" {
  description = "URL of the APIC"
  type        = string
}

variable "tenant_name" {
  description = "Name of the tenant to be created"
  type        = string
  default     = "test_tenant"
}

variable "insecure" {
  description = "Skip TLS verification"
  type        = bool
  default     = true
}