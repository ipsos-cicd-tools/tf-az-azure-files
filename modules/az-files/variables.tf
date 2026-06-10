variable "az_files_storage_account_name" {
  description = "The name of the Azure Files storage account"
  type        = string
}

variable "az_files_storage_account_rg_name" {
  description = "The name of the resource group in which to create the Azure Files storage account"
  type        = string
}

variable "az_files_storage_account_rg_location" {
  description = "The location of the resource group in which to create the Azure Files storage account"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to the Azure Files storage account"
  type        = map(string)
}

variable "subnet_id" {
  description = "A list of subnet IDs to associate with the Azure Files storage account"
  type        = string
}

variable "private_dns_zone_id" {
  description = "The resource ID of the private DNS zone for file.core.windows.net"
  type        = string
  default     = null
}

variable "security_alert_email" {
  description = "Email address for security alerts"
  type        = string
}

variable "backup_policy" {
  description = "A map of backup policy settings for the Azure Files storage account"
  type = object({
    frequency = string
    time      = string
    retention_daily = object({
      count = number
    })
    retention_weekly = object({
      count    = number
      weekdays = list(string)
    })
    retention_monthly = object({
      count    = number
      weekdays = list(string)
      weeks    = list(string)
    })
    retention_yearly = object({
      count    = number
      weekdays = list(string)
      weeks    = list(string)
      months   = list(string)
    })
  })
  default = {
    frequency = "Daily"
    time      = "23:00"
    retention_daily = {
      count = 30
    }
    retention_weekly = {
      count    = 12
      weekdays = ["Sunday"]
    }
    retention_monthly = {
      count    = 12
      weekdays = ["Sunday"]
      weeks    = ["First"]
    }
    retention_yearly = {
      count    = 7
      weekdays = ["Sunday"]
      weeks    = ["First"]
      months   = ["January"]
    }
  }
}

variable "ad_domain_name" {
  description = "The primary domain name for Active Directory integration."
  type        = string
  default     = null
}

variable "ad_domain_guid" {
  description = "The domain GUID for Active Directory integration."
  type        = string
  default     = null
}

variable "ad_domain_sid" {
  description = "The domain SID for Active Directory integration."
  type        = string
  default     = null
}

variable "ad_forest_name" {
  description = "The forest name for Active Directory integration."
  type        = string
  default     = null
}

variable "ad_netbios_domain_name" {
  description = "The NetBIOS domain name for Active Directory integration."
  type        = string
  default     = null
}

variable "ad_storage_sid" {
  description = "The security identifier (SID) for the storage account in Active Directory. This is typically obtained after the storage account is domain joined."
  type        = string
  default     = null
}

variable "enable_backup" {
  description = "Whether to enable Azure Backup for the Azure Files storage account."
  type        = bool
  default     = true
}

variable "enable_resource_locks" {
  description = "Whether to enable resource locks for the Azure Files storage account and private endpoint."
  type        = bool
  default     = true
}

variable "soft_delete_retention_days" {
  description = "The number of days that soft-deleted file shares, files, or directories are retained. Must be between 1 and 365."
  type        = number
  default     = 14
  validation {
    condition     = var.soft_delete_retention_days >= 1 && var.soft_delete_retention_days <= 365
    error_message = "The soft_delete_retention_days must be between 1 and 365."
  }
}

variable "enable_sensitive_data_discovery" {
  description = "Whether to enable sensitive data discovery in Azure Defender for Storage."
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Whether to allow public network access to the Azure Files storage account. Setting this to false will disable all public network access, including from the Azure portal and Azure Storage Explorer. This is a security best practice when using private endpoints."
  type        = bool
  default     = false
}

variable "ip_rules" {
  description = "A list of public IP addresses to allow access to the Azure Files storage account. This is only applicable if public_network_access_enabled is set to true."
  type        = list(string)
  default     = []
}

variable "storage_account_subnet_ids" {
  description = "List of subnet IDs allowed to access the storage account via VNet service endpoints. Used alongside the private endpoint."
  type        = list(string)
  default     = []
}

variable "shared_access_key_enabled" {
  description = "Whether to allow access via storage account keys. Defaults to false (ISO 27001 A.8.5 — force Azure AD / Kerberos authentication only). Set to true if tooling requires key-based access (AzCopy --account-key, Azure Portal Storage Explorer, legacy scripts)."
  type        = bool
  default     = false
}

variable "alert_threshold_high_errors" {
  description = "Transaction error count threshold that triggers the high-error-rate alert. Tune per environment to avoid alert fatigue (ISO 27001 A.8.16)."
  type        = number
  default     = 100
}

variable "alert_threshold_high_deletes" {
  description = "Delete operation count threshold that triggers the high-delete-activity alert. Tune per environment (ISO 27001 A.8.16)."
  type        = number
  default     = 50
}

variable "alert_threshold_auth_failures" {
  description = "Authentication failure count threshold that triggers the auth-failure alert. Tune per environment (ISO 27001 A.8.16)."
  type        = number
  default     = 20
}

variable "malware_scanning_cap_gb_per_month" {
  description = "Monthly cap in GB for Defender for Storage malware scanning on upload. Set to 0 for unlimited (ISO 27001 A.8.12)."
  type        = number
  default     = 5000
  validation {
    condition     = var.malware_scanning_cap_gb_per_month >= 0
    error_message = "malware_scanning_cap_gb_per_month must be 0 (unlimited) or a positive number."
  }
}

variable "default_share_level_permission" {
  description = "Default share-level permission for AD-joined file shares. Supports principle of least privilege (ISO 27001 A.8.2)."
  type        = string
  default     = "StorageFileDataSmbShareElevatedContributor"
  validation {
    condition     = contains(["None", "StorageFileDataSmbShareReader", "StorageFileDataSmbShareContributor", "StorageFileDataSmbShareElevatedContributor"], var.default_share_level_permission)
    error_message = "default_share_level_permission must be None, StorageFileDataSmbShareReader, StorageFileDataSmbShareContributor, or StorageFileDataSmbShareElevatedContributor."
  }
}

variable "log_analytics_retention_days" {
  description = "Retention period in days for the Log Analytics Workspace. ISO 27001 A.8.15 recommends at least 365 days for audit log retention."
  type        = number
  default     = 365
  validation {
    condition     = var.log_analytics_retention_days >= 30 && var.log_analytics_retention_days <= 730
    error_message = "log_analytics_retention_days must be between 30 and 730."
  }
}

variable "backup_vault_storage_mode_type" {
  description = "Storage replication type for the Recovery Services Vault. Use GeoRedundant together with backup_vault_cross_region_restore_enabled = true for cross-region DR."
  type        = string
  default     = "ZoneRedundant"
  validation {
    condition     = contains(["LocallyRedundant", "ZoneRedundant", "GeoRedundant"], var.backup_vault_storage_mode_type)
    error_message = "backup_vault_storage_mode_type must be LocallyRedundant, ZoneRedundant, or GeoRedundant."
  }
}

variable "backup_vault_public_network_access_enabled" {
  description = "Whether to allow public network access to the Recovery Services Vault. Set to true if access via the Azure Portal or public internet is required (e.g., for on-demand backup/restore operations through the portal UI)."
  type        = bool
  default     = false
}

variable "backup_vault_cross_region_restore_enabled" {
  description = "Whether to enable cross-region restore on the Recovery Services Vault. Requires backup_vault_storage_mode_type = GeoRedundant."
  type        = bool
  default     = false
}

variable "storage_account_replication_type" {
  description = "Replication type for the storage account. Use LRS in regions without availability zones, GRS for geo-redundancy independent of the backup vault."
  type        = string
  default     = "ZRS"
  validation {
    condition     = contains(["LRS", "ZRS", "GRS"], var.storage_account_replication_type)
    error_message = "storage_account_replication_type must be LRS, ZRS, or GRS."
  }
}

variable "enable_defender_subscription_pricing" {
  description = "Whether this module manages the subscription-level Defender for Storage plan (azurerm_security_center_subscription_pricing). This is a subscription-scoped singleton — set to false if Defender for Storage is already enabled by another Terraform configuration, another instance of this module, or Azure Policy, to avoid state conflicts."
  type        = bool
  default     = true
}

variable "defender_override_subscription_settings_enabled" {
  description = "Whether the per-storage-account Defender settings (malware scanning cap, sensitive data discovery) override the subscription-level Defender policy. Keep true to guarantee this module's security posture applies regardless of subscription defaults (ISO 27001 A.8.12)."
  type        = bool
  default     = true
}

variable "backup_timezone" {
  description = "Timezone for the file share backup schedule (e.g. 'UTC', 'Romance Standard Time'). Uses Windows timezone names."
  type        = string
  default     = "UTC"
}