Cisco ACI Terraform Automation
This repository contains Terraform configurations for automating the deployment and management of Cisco Application Centric Infrastructure (ACI) resources. The project demonstrates Infrastructure as Code (IaC) principles applied to ACI fabric management.
Overview
This Terraform configuration automates the creation of ACI resources including:

Tenants
VRFs (Virtual Routing and Forwarding)
Bridge Domains (planned)
Application Profiles (planned)
EPGs (Endpoint Groups) (planned)

The configuration uses a structured approach to create resources in a hierarchical manner, following ACI's object model.
Features

Modular Design: Resources are organized hierarchically, matching ACI's object model
Scalable: Easily add or modify resources using Terraform's for_each and count features
Maintainable: Clean, well-documented code following Terraform best practices
Secure: Sensitive credentials managed through variables and not tracked in git

Prerequisites

Terraform >= 0.13
Access to Cisco APIC controller
Basic understanding of Cisco ACI concepts
aci provider credentials

Usage

Clone the repository
Create a terraform.tfvars file with your APIC credentials
Initialize and apply the Terraform configuration:

bashCopyterraform init
terraform plan
terraform apply
Configuration Structure
Copy.
├── main.tf          # Main Terraform configuration
├── variables.tf     # Variable definitions
├── outputs.tf      # Output definitions
└── terraform.tfvars # Variables values (not in repo)
Contributing
Contributions are welcome! Please feel free to submit a Pull Request.
License
This project is licensed under the MIT License - see the LICENSE file for details.
Disclaimer
This is a demonstration/learning project. Always test thoroughly before using in a production environment.