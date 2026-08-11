terraform {
  # >= 1.9.0 required: input variable validation blocks reference other variables
  # (e.g. subnet_id validation reads var.enable_private_endpoint), which Terraform
  # only supports from 1.9.0 onward.
  required_version = ">=1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">4.3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.0.0"
    }
  }
}