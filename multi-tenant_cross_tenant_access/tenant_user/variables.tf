# variables.tf

# Admin credentials
variable "admin_username" {
  description = "Admin username"
  type        = string
}

variable "admin_password" {
  description = "Admin password"
  type        = string
  sensitive   = true
}

# Tenant credentials
variable "tenant1_username" {
  description = "Username for tenant1 admin"
  type        = string
}

variable "tenant2_username" {
  description = "Username for tenant2 admin"
  type        = string
}

variable "tenant1_password" {
  description = "Password for tenant1 admin"
  type        = string
  sensitive   = true
}

variable "tenant2_password" {
  description = "Password for tenant2 admin"
  type        = string
  sensitive   = true
}

# APIC connection
variable "apic_url" {
  description = "APIC URL"
  type        = string
}

variable "insecure" {
  description = "Skip TLS verification"
  type        = bool
  default     = true
}