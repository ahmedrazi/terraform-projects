# variables.tf
# Admin credentials
variable "admin_username" {
  description = "Admin username"
  type        = string
}

variable "admin_password" {
  description = "Admin password"
  type        = string
}

# Tenant user passwords
variable "tenant1_password" {
  description = "Password for tenant1 admin"
  type        = string
}

variable "tenant2_password" {
  description = "Password for tenant2 admin"
  type        = string
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