terraform {
  # >= 1.9.0 required: input variable validation blocks reference other variables
  # (e.g. subnet_id/private_dns_zone_id presence vs enable_* overrides), which
  # Terraform only supports from 1.9.0 onward.
  required_version = ">=1.9.0"

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # Pinned to azurerm 4.x. `> 4.3.0` alone would allow 5.x, whose breaking
      # changes (e.g. removal of recovery-vault soft_delete_enabled) are not yet
      # validated for this module.
      version = ">= 4.3.0, < 5.0.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.0.0"
    }
  }
}
