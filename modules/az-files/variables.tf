###############################################################################
# Required core inputs
###############################################################################

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

###############################################################################
# Optional features — presence-based creation.
#
# Each optional feature follows one pattern:
#   * a nullable CONFIG OBJECT   -> provide it to create the feature
#   * an optional existing_* ID  -> provide it to skip creation and reuse an
#                                   externally-managed resource
#   * an optional enable_* flag  -> tri-state override (null = auto/infer from
#                                   presence, true = force on, false = force off)
###############################################################################

# ---- Private endpoint --------------------------------------------------------

variable "private_endpoint" {
  description = "Private endpoint configuration for the file sub-resource. Provide this object to create a private endpoint (recommended for production). Leave null (default) to reach the account via VNet service endpoints (storage_account_subnet_ids) or public access instead. Creation can be overridden with enable_private_endpoint."
  type = object({
    subnet_id           = string
    private_dns_zone_id = string
  })
  default = null
}

variable "enable_private_endpoint" {
  description = "Override for private-endpoint creation. null (default) = auto: create when var.private_endpoint is set. true = force on (requires private_endpoint). false = force off even if private_endpoint is set."
  type        = bool
  default     = null

  validation {
    condition     = var.enable_private_endpoint != true || var.private_endpoint != null
    error_message = "enable_private_endpoint = true requires var.private_endpoint (subnet_id + private_dns_zone_id) to be set."
  }
}

# ---- On-prem AD DS (SMB Kerberos) integration --------------------------------

variable "active_directory" {
  description = "On-prem AD DS integration for SMB Kerberos auth (directory_type = 'AD'). Provide this object to domain-join the storage account. Leave null (default) for no AD integration. All fields are required by Azure when directory_type is 'AD'. storage_sid is typically obtained after the account is domain joined."
  type = object({
    domain_name         = string
    domain_guid         = string
    domain_sid          = string
    forest_name         = string
    netbios_domain_name = string
    storage_sid         = string
  })
  default = null
}

# ---- Azure Backup ------------------------------------------------------------

variable "backup" {
  description = "Azure Backup configuration for the file share. Provide this object (even empty `{}`) to create a Recovery Services vault + daily/weekly/monthly/yearly backup policy. Leave null (default) for no backup. NOTE: this changes the pre-rework default (backup was on by default); pass `backup = {}` to keep the previous behaviour. Individual policy/vault fields default to the module's hardened schedule (14 daily / 4 weekly / 3 monthly / 3 yearly, ZoneRedundant vault)."
  type = object({
    policy = optional(object({
      timezone        = optional(string, "UTC")
      frequency       = optional(string, "Daily")
      time            = optional(string, "23:00")
      retention_daily = optional(object({ count = number }), { count = 14 })
      retention_weekly = optional(object({
        count    = number
        weekdays = list(string)
      }), { count = 4, weekdays = ["Sunday"] })
      retention_monthly = optional(object({
        count    = number
        weekdays = list(string)
        weeks    = list(string)
      }), { count = 3, weekdays = ["Sunday"], weeks = ["First"] })
      retention_yearly = optional(object({
        count    = number
        weekdays = list(string)
        weeks    = list(string)
        months   = list(string)
      }), { count = 3, weekdays = ["Sunday"], weeks = ["First"], months = ["January"] })
    }), {})
    vault = optional(object({
      storage_mode_type             = optional(string, "ZoneRedundant")
      public_network_access_enabled = optional(bool, false)
      cross_region_restore_enabled  = optional(bool, false)
    }), {})
  })
  default = null

  validation {
    condition     = var.backup == null || contains(["LocallyRedundant", "ZoneRedundant", "GeoRedundant"], var.backup.vault.storage_mode_type)
    error_message = "backup.vault.storage_mode_type must be LocallyRedundant, ZoneRedundant, or GeoRedundant."
  }

  validation {
    condition     = var.backup == null || !var.backup.vault.cross_region_restore_enabled || var.backup.vault.storage_mode_type == "GeoRedundant"
    error_message = "backup.vault.cross_region_restore_enabled = true requires backup.vault.storage_mode_type = GeoRedundant."
  }
}

variable "enable_backup" {
  description = "Override for Azure Backup creation. null (default) = auto: create when var.backup is set. true = force on (uses the default policy when var.backup is null). false = force off even if var.backup is set."
  type        = bool
  default     = null
}

# ---- Bring-your-own (externally-created) resources ---------------------------

variable "existing_log_analytics_workspace_id" {
  description = "Resource ID of an existing Log Analytics Workspace to send diagnostics to. When set, the module does NOT create its own workspace and points all diagnostic settings at this one (e.g. a central/hub logging workspace). Leave null (default) to create a dedicated workspace."
  type        = string
  default     = null
}

variable "existing_action_group_id" {
  description = "Resource ID of an existing Monitor Action Group to route all security alerts to. When set, the module does NOT create its own action group (and security_alert_email is not required). Leave null (default) to create a dedicated action group from security_alert_email."
  type        = string
  default     = null
}

variable "existing_recovery_services_vault" {
  description = "An existing Recovery Services vault to attach the backup policy to instead of creating one. Given as name + resource group (the backup policy resource references the vault by name, not ID). resource_group_name defaults to the storage account's resource group. Only used when backup is enabled."
  type = object({
    name                = string
    resource_group_name = optional(string)
  })
  default = null
}

# ---- Subscription-level Defender (singleton) ---------------------------------

variable "enable_defender_subscription_pricing" {
  description = "Whether THIS module manages the subscription-level Defender for Storage plan (a subscription-scoped singleton). Defaults to false (opt-in): leave it off when Defender for Storage is already enabled by Azure Policy, another module instance, or another configuration in the same subscription, to avoid state conflicts. Per-account Defender (malware scanning, sensitive-data discovery) is always enabled regardless of this flag."
  type        = bool
  default     = false
}

###############################################################################
# Security / posture toggles (retained from prior interface)
###############################################################################

variable "security_alert_email" {
  description = "Email address for security alerts. Required unless existing_action_group_id is set (in which case alerts route to the existing action group and no email receiver is created)."
  type        = string
  default     = null

  validation {
    condition     = var.existing_action_group_id != null || var.security_alert_email != null
    error_message = "security_alert_email must be set unless existing_action_group_id is provided."
  }
}

variable "enable_resource_locks" {
  description = "Whether to enable CanNotDelete resource locks on the storage account and (when created) the private endpoint."
  type        = bool
  default     = true
}

variable "enable_sensitive_data_discovery" {
  description = "Whether to enable sensitive data discovery in the per-account Defender for Storage settings."
  type        = bool
  default     = true
}

variable "defender_override_subscription_settings_enabled" {
  description = "Whether the per-storage-account Defender settings (malware scanning cap, sensitive data discovery) override the subscription-level Defender policy. Keep true to guarantee this module's security posture applies regardless of subscription defaults (ISO 27001 A.8.12)."
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Whether to allow public network access to the Azure Files storage account. Setting this to false disables all public network access (including the Azure portal and Storage Explorer). Security best practice when using private endpoints."
  type        = bool
  default     = false
}

variable "shared_access_key_enabled" {
  description = "Whether to allow access via storage account keys. Defaults to false (ISO 27001 A.8.5 — force Azure AD / Kerberos auth only). Set true if tooling requires key-based access (AzCopy --account-key, Portal Storage Explorer, legacy scripts)."
  type        = bool
  default     = false
}

variable "ip_rules" {
  description = "A list of public IP addresses/CIDRs allowed to access the storage account. Only applicable if public_network_access_enabled is true."
  type        = list(string)
  default     = []
}

variable "storage_account_subnet_ids" {
  description = "List of subnet IDs allowed to access the storage account via VNet service endpoints. Can be used alongside or instead of a private endpoint."
  type        = list(string)
  default     = []
}

variable "allowed_copy_scope" {
  description = "Restrict object copy operations to the same AAD tenant ('AAD') or same private link network ('PrivateLink'). Null leaves Azure's default (unrestricted). Set to 'AAD' to prevent cross-tenant data exfiltration (ISO 27001 A.8.12)."
  type        = string
  default     = null
  validation {
    condition     = var.allowed_copy_scope == null || contains(["AAD", "PrivateLink"], var.allowed_copy_scope)
    error_message = "allowed_copy_scope must be null, 'AAD', or 'PrivateLink'."
  }
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

variable "soft_delete_retention_days" {
  description = "The number of days that soft-deleted file shares, files, or directories are retained. Must be between 1 and 365."
  type        = number
  default     = 14
  validation {
    condition     = var.soft_delete_retention_days >= 1 && var.soft_delete_retention_days <= 365
    error_message = "The soft_delete_retention_days must be between 1 and 365."
  }
}

###############################################################################
# Share-level RBAC
###############################################################################

variable "default_share_level_permission" {
  description = "Default share-level permission granted to ALL authenticated identities on the share. Defaults to Contributor: the sanctioned mechanism for an org-wide 'all employees' baseline, replacing a cloud-only/dynamic Entra 'all staff' group (which does NOT work for AD DS share-level RBAC — its SID isn't in the on-prem Kerberos ticket). NTFS ACLs still enforce per-folder access. Set to Reader or None for a stricter least-privilege posture (ISO 27001 A.8.2) and grant elevated access to specific groups via share_level_role_assignments."
  type        = string
  default     = "StorageFileDataSmbShareContributor"
  validation {
    condition     = contains(["None", "StorageFileDataSmbShareReader", "StorageFileDataSmbShareContributor", "StorageFileDataSmbShareElevatedContributor"], var.default_share_level_permission)
    error_message = "default_share_level_permission must be None, StorageFileDataSmbShareReader, StorageFileDataSmbShareContributor, or StorageFileDataSmbShareElevatedContributor."
  }
}

variable "share_level_role_assignments" {
  description = "Map of share-level SMB RBAC assignments. Each entry resolves an AAD group by display name and grants it the specified role on the storage account. Uses azuread_groups (plural) — returns only object IDs, does not enumerate membership, so plan times stay fast. IMPORTANT: for AD DS auth (directory_type = 'AD'), only on-prem AD security groups synced to Entra ID (Assigned membership) are honored — their SID must be present in the on-prem Kerberos ticket. Cloud-only/dynamic-membership groups are NOT matched and will silently fail. For an all-authenticated baseline, use default_share_level_permission instead of a dynamic 'all staff' group."
  type = map(object({
    group_display_name   = string
    role_definition_name = string
  }))
  default = {}

  validation {
    condition = alltrue([
      for v in values(var.share_level_role_assignments) :
      contains([
        "Storage File Data SMB Share Reader",
        "Storage File Data SMB Share Contributor",
        "Storage File Data SMB Share Elevated Contributor"
      ], v.role_definition_name)
    ])
    error_message = "role_definition_name must be one of: 'Storage File Data SMB Share Reader', 'Storage File Data SMB Share Contributor', or 'Storage File Data SMB Share Elevated Contributor'."
  }
}

###############################################################################
# Monitoring thresholds & Defender cap
###############################################################################

variable "log_analytics_retention_days" {
  description = "Retention period in days for the Log Analytics Workspace (only used when the module creates its own workspace). ISO 27001 A.8.15 recommends at least 365 days for audit log retention."
  type        = number
  default     = 365
  validation {
    condition     = var.log_analytics_retention_days >= 30 && var.log_analytics_retention_days <= 730
    error_message = "log_analytics_retention_days must be between 30 and 730."
  }
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
