# test.tf
terraform {
  required_providers {
    aci = {
      source = "CiscoDevNet/aci"
    }
  }
}

# Provider using tenant user credentials
provider "aci" {
  username = var.tenant_username
  password = var.tenant_password
  url      = var.apic_url
  insecure = true
}

# Reference existing tenant
data "aci_tenant" "test_tenant" {
  name = var.tenant_name
}

# Test App Profile creation (should succeed)
resource "aci_application_profile" "test_ap" {
  tenant_dn   = data.aci_tenant.test_tenant.id
  name        = "test_ap"
  description = "Test AP created by tenant user"
}

# Test EPG creation (should succeed)
resource "aci_application_epg" "test_epg" {
  name                   = "test_epg"
  application_profile_dn = aci_application_profile.test_ap.id
  description           = "Test EPG created by tenant user"
}

# Test creating VRF (should succeed)
resource "aci_vrf" "test_vrf" {
  tenant_dn   = data.aci_tenant.test_tenant.id
  name        = "test_vrf"
  description = "Test VRF created by tenant user"
}

# Test fabric access (should fail)
resource "aci_rest_managed" "fabric_dns" {
  dn         = "uni/fabric/dnsp-default"
  class_name = "dnsProfile"
  content = {
    name = "default"
  }
}

# Try to create AAEP (Should Fail)
resource "aci_attachable_access_entity_profile" "test_aaep" {
  name        = "test_aaep"
  description = "Test AAEP creation attempt"
}

# Try to modify BGP Route Reflector (Should Fail)
resource "aci_rest_managed" "bgp_rr" {
  dn         = "uni/fabric/bgpInstP-default/rr"
  class_name = "bgpRRNodePEp"
  content = {
    id = "1"
  }
}

# Try to create VLAN Pool (Should Fail)
resource "aci_vlan_pool" "test_vlan_pool" {
  name        = "test_vlan_pool"
  description = "Test VLAN pool creation attempt"
  alloc_mode  = "static"
}

# Try to modify System Settings (Should Fail)
resource "aci_rest_managed" "system_settings" {
  dn         = "uni/fabric/comm-default"
  class_name = "commPol"
  content = {
    name = "default"
  }
}




/*
output "test_results" {
  value = {
    tenant_access = try(data.aci_tenant.test_tenant.name, "Failed")
    app_profile   = try(aci_application_profile.test_ap.name, "Failed")
    epg_creation  = try(aci_application_epg.test_epg.name, "Failed")
    vrf_creation  = try(aci_vrf.test_vrf.name, "Failed")
    fabric_access = try(aci_rest_managed.fabric_dns.id, "Failed as expected")
  }
}
*/

# Updated output block to include all test results
output "test_results" {
  value = {
    # Successful Operations
    tenant_access = data.aci_tenant.test_tenant.name
    app_profile   = aci_application_profile.test_ap.name
    epg_creation  = aci_application_epg.test_epg.name
    vrf_creation  = aci_vrf.test_vrf.name
    
    # Failed Operations (Expected)
    fabric_dns    = try(aci_rest_managed.fabric_dns.id, "Failed as expected")
    aaep_access   = try(aci_attachable_access_entity_profile.test_aaep.name, "Failed as expected")
    bgp_rr_access = try(aci_rest_managed.bgp_rr.id, "Failed as expected")
    vlan_pool     = try(aci_vlan_pool.test_vlan_pool.name, "Failed as expected")
    system_access = try(aci_rest_managed.system_settings.id, "Failed as expected")
  }

  description = <<-EOF
    Test Results for Tenant User Access:
    
    Successful Operations (Should Succeed):
    - Tenant Access: Access to assigned tenant
    - App Profile: Creation of Application Profile
    - EPG Creation: Creation of End Point Group
    - VRF Creation: Creation of VRF
    
    Failed Operations (Should Fail):
    - Fabric DNS: Attempt to modify fabric DNS settings
    - AAEP Access: Attempt to create AAEP
    - BGP RR Access: Attempt to modify BGP Route Reflector
    - VLAN Pool: Attempt to create VLAN pool
    - System Access: Attempt to modify system settings
    EOF
}

