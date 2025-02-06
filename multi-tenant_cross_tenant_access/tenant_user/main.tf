# users_tenants.tf

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

# Create User1
resource "aci_local_user" "tenant1_user" {
  name              = var.tenant1_username
  description       = "User for tenant1"
  pwd              = var.tenant1_password
  expires          = "no"
  clear_pwd_history = "yes"
}

# Create User2
resource "aci_local_user" "tenant2_user" {
  name              = var.tenant2_username
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

# Output the tenant IDs for use in Phase 2
output "tenant1_id" {
  value = aci_tenant.tenant1.id
}

output "tenant2_id" {
  value = aci_tenant.tenant2.id
}