# main.tf
terraform {
  required_providers {
    aci = {
      source = "CiscoDevNet/aci"
    }
  }
}

# Admin provider for creating users and tenants
provider "aci" {
  username = var.admin_username
  password = var.admin_password
  url      = var.apic_url
  insecure = true
}

# Provider for Tenant1
provider "aci" {
  alias    = "tenant1"
  username = "tenant1_admin"
  password = var.tenant1_password
  url      = var.apic_url
  insecure = true
}

# Provider for Tenant2
provider "aci" {
  alias    = "tenant2"
  username = "tenant2_admin"
  password = var.tenant2_password
  url      = var.apic_url
  insecure = true
}

# Create User1
resource "aci_local_user" "tenant1_user" {
  name              = "tenant1_admin"
  description       = "User for tenant1"
  pwd              = var.tenant1_password
  expires          = "no"
  clear_pwd_history = "yes"
}

# Create User2
resource "aci_local_user" "tenant2_user" {
  name              = "tenant2_admin"
  description       = "User for tenant2"
  pwd              = var.tenant2_password
  expires          = "no"
  clear_pwd_history = "yes"
}

# Create Tenant1
resource "aci_tenant" "tenant1" {
  name        = "tenant1"
  description = "Tenant1 created for isolation testing"
}

# Create Tenant2
resource "aci_tenant" "tenant2" {
  name        = "tenant2"
  description = "Tenant2 created for isolation testing"
}

# Create Security Domain for Tenant1
resource "aci_rest_managed" "sec_domain1" {
  dn         = "uni/userext/domain-${aci_tenant.tenant1.name}"
  class_name = "aaaDomain"
  content = {
    name = aci_tenant.tenant1.name
  }
  depends_on = [aci_tenant.tenant1]
}

# Create Security Domain for Tenant2
resource "aci_rest_managed" "sec_domain2" {
  dn         = "uni/userext/domain-${aci_tenant.tenant2.name}"
  class_name = "aaaDomain"
  content = {
    name = aci_tenant.tenant2.name
  }
  depends_on = [aci_tenant.tenant2]
}

# Map Security Domain to Tenant1
resource "aci_rest_managed" "tenant1_security_map" {
  dn         = "uni/tn-${aci_tenant.tenant1.name}/domain-${aci_tenant.tenant1.name}"
  class_name = "aaaDomainRef"
  content = {
    name = aci_tenant.tenant1.name
  }
  depends_on = [aci_rest_managed.sec_domain1]
}

# Map Security Domain to Tenant2
resource "aci_rest_managed" "tenant2_security_map" {
  dn         = "uni/tn-${aci_tenant.tenant2.name}/domain-${aci_tenant.tenant2.name}"
  class_name = "aaaDomainRef"
  content = {
    name = aci_tenant.tenant2.name
  }
  depends_on = [aci_rest_managed.sec_domain2]
}

# Map User1 to Security Domain and assign role
resource "aci_rest_managed" "user1_domain_role" {
  dn         = "uni/userext/user-${aci_local_user.tenant1_user.name}/userdomain-${aci_tenant.tenant1.name}"
  class_name = "aaaUserDomain"
  content = {
    name = aci_tenant.tenant1.name
  }
  depends_on = [aci_local_user.tenant1_user, aci_rest_managed.sec_domain1]
}

# Map User2 to Security Domain and assign role
resource "aci_rest_managed" "user2_domain_role" {
  dn         = "uni/userext/user-${aci_local_user.tenant2_user.name}/userdomain-${aci_tenant.tenant2.name}"
  class_name = "aaaUserDomain"
  content = {
    name = aci_tenant.tenant2.name
  }
  depends_on = [aci_local_user.tenant2_user, aci_rest_managed.sec_domain2]
}

# Assign Role to User1
resource "aci_rest_managed" "user1_role" {
  dn         = "${aci_rest_managed.user1_domain_role.dn}/role-admin"
  class_name = "aaaUserRole"
  content = {
    name     = "admin"
    privType = "writePriv"
  }
  depends_on = [aci_rest_managed.user1_domain_role]
}

# Assign Role to User2
resource "aci_rest_managed" "user2_role" {
  dn         = "${aci_rest_managed.user2_domain_role.dn}/role-admin"
  class_name = "aaaUserRole"
  content = {
    name     = "admin"
    privType = "writePriv"
  }
  depends_on = [aci_rest_managed.user2_domain_role]
}

# Cross-Tenant Access Tests
# Try to create AP in Tenant1 using Tenant1 user (Should Succeed)
resource "aci_application_profile" "ap_tenant1" {
  provider    = aci.tenant1
  tenant_dn   = aci_tenant.tenant1.id
  name        = "ap1"
  description = "AP in tenant1"
  depends_on  = [aci_rest_managed.user1_role, aci_rest_managed.tenant1_security_map]
}

# Try to create AP in Tenant2 using Tenant2 user (Should Succeed)
resource "aci_application_profile" "ap_tenant2" {
  provider    = aci.tenant2
  tenant_dn   = aci_tenant.tenant2.id
  name        = "ap2"
  description = "AP in tenant2"
  depends_on  = [aci_rest_managed.user2_role, aci_rest_managed.tenant2_security_map]
}

resource "aci_application_profile" "ap_cross_tenant1" {
  provider    = aci.tenant1
  tenant_dn   = aci_tenant.tenant2.id
  name        = "ap1_cross"
  description = "Cross-tenant attempt from tenant1"
  depends_on  = [aci_rest_managed.user1_role, aci_rest_managed.tenant2_security_map]
}

# Try to create AP in Tenant1 using Tenant2 user (Should Fail)
resource "aci_application_profile" "ap_cross_tenant2" {
  provider    = aci.tenant2
  tenant_dn   = aci_tenant.tenant1.id
  name        = "ap2_cross"
  description = "Cross-tenant attempt from tenant2"
  depends_on  = [aci_rest_managed.user2_role, aci_rest_managed.tenant1_security_map]
}


# Update output block to include cross-tenant test results
output "test_results" {
  value = {
    tenant1_created = try(aci_tenant.tenant1.name, "Failed")
    tenant2_created = try(aci_tenant.tenant2.name, "Failed")
    tenant1_ap      = try(aci_application_profile.ap_tenant1.name, "Failed")
    tenant2_ap      = try(aci_application_profile.ap_tenant2.name, "Failed")
    cross_access_1  = try(aci_application_profile.ap_cross_tenant1.name, "Failed as expected")
    cross_access_2  = try(aci_application_profile.ap_cross_tenant2.name, "Failed as expected")
  }
}