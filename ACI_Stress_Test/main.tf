# This tells Terraform to use the Cisco ACI provider
terraform {
  required_providers {
    aci = {
      source = "CiscoDevNet/aci"
      version = "~> 2.0"
    }
  }
}

# Configure the connection to your APIC
provider "aci" {
  username = var.apic_username   # APIC username
  password = var.apic_password   # APIC password
  url      = var.apic_url       # APIC URL
  insecure = true              # Allow insecure HTTPS connection
}

# Define the variables we'll use
variable "apic_username" {
  description = "APIC username"
  type        = string
}

variable "apic_password" {
  description = "APIC password"
  type        = string
  sensitive   = true    # This hides the password in logs
}

variable "apic_url" {
  description = "APIC URL (example: https://my-apic.company.com)"
  type        = string
}

# Create 3 test tenants
resource "aci_tenant" "tenants" {
  count = 10   # This will create 3 tenants
  
  name        = "test-tenant-${count.index + 1}"   # Names will be test-tenant-1, test-tenant-2, etc.
  description = "Test tenant ${count.index + 1} created by Terraform"
}

# Create a VRF in each tenant
resource "aci_vrf" "vrfs" {
  count = 10   # Create one VRF for each tenant
  
  tenant_dn   = aci_tenant.tenants[count.index].id   # Link each VRF to its tenant
  name        = "test-vrf-${count.index + 1}"        # Names will be test-vrf-1, test-vrf-2, etc.
  description = "Test VRF created by Terraform"
}

# Show what was created
output "created_tenants" {
  value = [for tenant in aci_tenant.tenants : tenant.name]
  description = "List of tenants that were created"
}

# Show both tenants and VRFs that were created
output "resources_created" {
  value = {
    tenants = [for tenant in aci_tenant.tenants : {
      name = tenant.name
      id   = tenant.id
    }]
    vrfs = [for vrf in aci_vrf.vrfs : {
      name      = vrf.name
      tenant_dn = vrf.tenant_dn
    }]
  }
  description = "List of tenants and VRFs that were created"
}