# application_profiles.tf

terraform {
  required_providers {
    aci = {
      source = "CiscoDevNet/aci"
    }
  }
}
# Default provider configuration (required)
provider "aci" {
  username = var.admin_username
  password = var.admin_password
  url      = var.apic_url
  insecure = true
}

# Provider for Tenant1
provider "aci" {
  alias    = "tenant1"
  username = var.tenant1_username
  password = var.tenant1_password
  url      = var.apic_url
  insecure = true
}

# Provider for Tenant2
provider "aci" {
  alias    = "tenant2"
  username = var.tenant2_username
  password = var.tenant2_password
  url      = var.apic_url
  insecure = true
}

# Data sources to get tenant information
data "aci_tenant" "tenant1" {
  name = "tenant1"
}

data "aci_tenant" "tenant2" {
  name = "tenant2"
}

# Create AP in Tenant1 using Tenant1 user (Should Succeed)
resource "aci_application_profile" "ap_tenant1" {
  provider    = aci.tenant1
  tenant_dn   = data.aci_tenant.tenant1.id
  name        = "ap1"
  description = "AP in tenant1"
}

# Create AP in Tenant2 using Tenant2 user (Should Succeed)
resource "aci_application_profile" "ap_tenant2" {
  provider    = aci.tenant2
  tenant_dn   = data.aci_tenant.tenant2.id
  name        = "ap2"
  description = "AP in tenant2"
}

# Try to create AP in Tenant2 using Tenant1 user (Should Fail)
resource "aci_application_profile" "ap_cross_tenant1" {
  provider    = aci.tenant1
  tenant_dn   = data.aci_tenant.tenant2.id
  name        = "ap1_cross"
  description = "Cross-tenant attempt from tenant1"
}

# Try to create AP in Tenant1 using Tenant2 user (Should Fail)
resource "aci_application_profile" "ap_cross_tenant2" {
  provider    = aci.tenant2
  tenant_dn   = data.aci_tenant.tenant1.id
  name        = "ap2_cross"
  description = "Cross-tenant attempt from tenant2"
}

# Output test results
output "test_results" {
  value = {
    tenant1_ap      = try(aci_application_profile.ap_tenant1.name, "Failed")
    tenant2_ap      = try(aci_application_profile.ap_tenant2.name, "Failed")
    cross_access_1  = try(aci_application_profile.ap_cross_tenant1.name, "Failed as expected")
    cross_access_2  = try(aci_application_profile.ap_cross_tenant2.name, "Failed as expected")
  }
}