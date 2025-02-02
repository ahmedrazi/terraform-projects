# main.tf
terraform {
  required_providers {
    aci = {
      source = "CiscoDevNet/aci"
    }
  }
}

# Admin provider
provider "aci" {
  username = var.admin_username
  password = var.admin_password
  url      = var.apic_url
  insecure = true
}

# Create tenant user
resource "aci_local_user" "tenant_admin_user" {
  name              = var.tenant_username
  description       = "Restricted tenant user with external admin privileges"
  pwd               = var.tenant_password
  expires           = "no"
  clear_pwd_history = "yes"
}

# Create test tenant
resource "aci_tenant" "test_tenant" {
  name        = var.tenant_name
  description = "Test tenant for restricted access"
}

# Create user security domain
resource "aci_rest_managed" "user_security_domain" {
  dn         = "uni/userext/user-${var.tenant_username}/userdomain-all"
  class_name = "aaaUserDomain"
  content = {
    name = "all"
  }
  depends_on = [aci_local_user.tenant_admin_user]
}

# Assign restricted role to user
resource "aci_rest_managed" "user_domain_role" {
  dn         = "${aci_rest_managed.user_security_domain.dn}/role-tenant-ext-admin"
  class_name = "aaaUserRole"
  content = {
    name     = "tenant-ext-admin"
    privType = "writePriv"
  }
  depends_on = [aci_rest_managed.user_security_domain]
}

# Grant access to specific tenant
resource "aci_rest_managed" "user_tenant_access" {
  dn         = "uni/tn-${var.tenant_name}/domain-${var.tenant_name}"
  class_name = "aaaDomainRef"
  content = {
    name = var.tenant_name
  }
  depends_on = [
    aci_tenant.test_tenant,
    aci_rest_managed.user_domain_role
  ]
}

# Output tenant user details
output "tenant_user_details" {
  value = {
    username = aci_local_user.tenant_admin_user.name
    tenant   = aci_tenant.test_tenant.name
    role     = "tenant-ext-admin"
  }
}