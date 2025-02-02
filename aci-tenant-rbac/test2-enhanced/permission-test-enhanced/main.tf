# main.tf
terraform {
  required_providers {
    aci = {
      source = "CiscoDevNet/aci"
    }
  }
}

provider "aci" {
  username = var.tenant_username
  password = var.tenant_password
  url      = var.apic_url
  insecure = true
}

# Store test results
locals {
  test_results = {
    allowed_operations = {
      tenant_access = {
        name   = try(data.aci_tenant.test_tenant.name, "")
        dn     = try(data.aci_tenant.test_tenant.id, "")
        status = try(data.aci_tenant.test_tenant.name != "", false) ? "SUCCESS" : "FAILED"
      }
      app_profile = {
        name   = try(aci_application_profile.test_ap.name, "")
        dn     = try(aci_application_profile.test_ap.id, "")
        status = try(aci_application_profile.test_ap.name != "", false) ? "SUCCESS" : "FAILED"
      }
      epg = {
        name   = try(aci_application_epg.test_epg.name, "")
        dn     = try(aci_application_epg.test_epg.id, "")
        status = try(aci_application_epg.test_epg.name != "", false) ? "SUCCESS" : "FAILED"
      }
      vrf = {
        name   = try(aci_vrf.test_vrf.name, "")
        dn     = try(aci_vrf.test_vrf.id, "")
        status = try(aci_vrf.test_vrf.name != "", false) ? "SUCCESS" : "FAILED"
      }
    }
    restricted_operations = {
      fabric_dns = {
        operation   = "Create Fabric DNS Profile"
        dn         = "uni/fabric/dnsp-default"
        class_name = "dnsProfile"
        status     = try(aci_rest_managed.fabric_dns.id != "", false) ? "UNEXPECTED SUCCESS" : "FAILED AS EXPECTED"
      }
      fabric_bgp = {
        operation   = "Configure BGP Route Reflector"
        dn         = "uni/fabric/bgpInstP-default/rr/node-1"
        class_name = "bgpRRNodePEp"
        status     = try(aci_rest_managed.bgp_rr.id != "", false) ? "UNEXPECTED SUCCESS" : "FAILED AS EXPECTED"
      }
      system_settings = {
        operation   = "Modify System Settings"
        dn         = "uni/fabric/comm-default"
        class_name = "commPol"
        status     = try(aci_rest_managed.system_settings.id != "", false) ? "UNEXPECTED SUCCESS" : "FAILED AS EXPECTED"
      }
      vlan_pool = {
        operation   = "Create VLAN Pool"
        dn         = "uni/infra/vlanns-[test_vlan_pool]-static"
        class_name = "fvnsVlanInstP"
        status     = try(aci_vlan_pool.test_vlan_pool.id != "", false) ? "UNEXPECTED SUCCESS" : "FAILED AS EXPECTED"
      }
      aaep = {
        operation   = "Create AAEP"
        dn         = "uni/infra/attentp-test_aaep"
        class_name = "infraAttEntityP"
        status     = try(aci_attachable_access_entity_profile.test_aaep.id != "", false) ? "UNEXPECTED SUCCESS" : "FAILED AS EXPECTED"
      }
    }
  }
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

# Test VRF creation (should succeed)
resource "aci_vrf" "test_vrf" {
  tenant_dn   = data.aci_tenant.test_tenant.id
  name        = "test_vrf"
  description = "Test VRF created by tenant user"
}

# Test: Fabric DNS Profile (should fail)
resource "aci_rest_managed" "fabric_dns" {
  dn         = "uni/fabric/dnsp-default"
  class_name = "dnsProfile"
  content = {
    name = "default"
  }
}

# Test: BGP RR configuration (should fail)
resource "aci_rest_managed" "bgp_rr" {
  dn         = "uni/fabric/bgpInstP-default/rr/node-1"
  class_name = "bgpRRNodePEp"
  content = {
    id = "1"
  }
}

# Test: System Settings (should fail)
resource "aci_rest_managed" "system_settings" {
  dn         = "uni/fabric/comm-default"
  class_name = "commPol"
  content = {
    name = "default"
  }
}

# Test: VLAN Pool (should fail)
resource "aci_vlan_pool" "test_vlan_pool" {
  name        = "test_vlan_pool"
  description = "Test VLAN pool creation attempt"
  alloc_mode  = "static"
}

# Test: AAEP (should fail)
resource "aci_attachable_access_entity_profile" "test_aaep" {
  name        = "test_aaep"
  description = "Test AAEP creation attempt"
}

output "permission_test_summary" {
  value = {
    allowed_operations = {
      for name, test in local.test_results.allowed_operations : name => {
        status      = test.status
        name        = test.name
        dn          = test.dn
        expectation = "Should Succeed"
      }
    }
    restricted_operations = {
      for name, test in local.test_results.restricted_operations : name => {
        operation   = test.operation
        status      = test.status
        dn          = test.dn
        class_name  = test.class_name
        expectation = "Should Fail"
      }
    }
  }
}

output "test_status_summary" {
  value = {
    successful_operations = [
      for name, test in local.test_results.allowed_operations :
      "${name} => ${test.status}"
    ]
    restricted_operations = [
      for name, test in local.test_results.restricted_operations :
      "${test.operation} => ${test.status}"
    ]
  }
}