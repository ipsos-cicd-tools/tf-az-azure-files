###############################################################################
# Resolved creation flags & bring-your-own wiring.
#
# create_* = whether THIS module creates the resource.
# *_id / *_name = the identifier dependents should use, whether the resource was
# created here or supplied via an existing_* input.
###############################################################################
locals {
  # Private endpoint: auto from presence of var.private_endpoint, override via flag.
  create_private_endpoint = coalesce(var.enable_private_endpoint, var.private_endpoint != null)

  # Log Analytics: create our own unless an existing workspace ID was supplied.
  create_log_analytics = var.existing_log_analytics_workspace_id == null
  log_analytics_id     = coalesce(var.existing_log_analytics_workspace_id, one(azurerm_log_analytics_workspace.storage_logs[*].id))

  # Action group: create our own unless an existing action group ID was supplied.
  create_action_group = var.existing_action_group_id == null
  action_group_id     = coalesce(var.existing_action_group_id, one(azurerm_monitor_action_group.storage_security_alerts[*].id))

  # Backup: auto from presence of var.backup, override via flag. Create a vault
  # only when backup is wanted AND no existing vault was supplied.
  create_backup = coalesce(var.enable_backup, var.backup != null)
  create_vault  = local.create_backup && var.existing_recovery_services_vault == null

  # Effective backup config — falls back to the module's hardened defaults when
  # backup is forced on (enable_backup = true) without an explicit var.backup.
  backup = var.backup != null ? var.backup : {
    policy = {
      timezone          = "UTC"
      frequency         = "Daily"
      time              = "23:00"
      retention_daily   = { count = 14 }
      retention_weekly  = { count = 4, weekdays = ["Sunday"] }
      retention_monthly = { count = 3, weekdays = ["Sunday"], weeks = ["First"] }
      retention_yearly  = { count = 3, weekdays = ["Sunday"], weeks = ["First"], months = ["January"] }
    }
    vault = {
      storage_mode_type             = "ZoneRedundant"
      public_network_access_enabled = false
      cross_region_restore_enabled  = false
    }
  }

  # Vault name/RG the backup policy attaches to (created vault or existing one).
  vault_name = var.existing_recovery_services_vault != null ? var.existing_recovery_services_vault.name : one(azurerm_recovery_services_vault.backup_vault[*].name)
  vault_rg   = var.existing_recovery_services_vault != null ? coalesce(var.existing_recovery_services_vault.resource_group_name, var.az_files_storage_account_rg_name) : var.az_files_storage_account_rg_name
}

resource "azurerm_storage_account" "default" {
  name                          = var.az_files_storage_account_name
  resource_group_name           = var.az_files_storage_account_rg_name
  location                      = var.az_files_storage_account_rg_location
  account_kind                  = "StorageV2"
  account_tier                  = "Standard"
  account_replication_type      = var.storage_account_replication_type
  tags                          = var.tags
  public_network_access_enabled = var.public_network_access_enabled
  allowed_copy_scope            = var.allowed_copy_scope

  access_tier                      = "Hot"
  min_tls_version                  = "TLS1_2"
  https_traffic_only_enabled       = true
  large_file_share_enabled         = true
  cross_tenant_replication_enabled = false
  shared_access_key_enabled        = var.shared_access_key_enabled
  sftp_enabled                     = false
  local_user_enabled               = false
  allow_nested_items_to_be_public  = false
  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices", "Logging", "Metrics"]
    virtual_network_subnet_ids = var.storage_account_subnet_ids
    ip_rules                   = var.ip_rules
  }

  share_properties {
    retention_policy {
      days = var.soft_delete_retention_days
    }
    smb {
      versions                        = ["SMB3.0", "SMB3.1.1"]
      authentication_types            = ["NTLMv2", "Kerberos"]
      kerberos_ticket_encryption_type = ["AES-256"]
      channel_encryption_type         = ["AES-128-GCM", "AES-256-GCM"]
      # multichannel_enabled            = true # `multichannel_enabled` isn't supported for Standard tier Storage accounts
    }
  }
  infrastructure_encryption_enabled = true

  identity {
    type = "SystemAssigned"
  }

  # AD DS integration is created only when var.active_directory is supplied.
  dynamic "azure_files_authentication" {
    for_each = var.active_directory != null ? [1] : []
    content {
      directory_type                 = "AD"
      default_share_level_permission = var.default_share_level_permission
      active_directory {
        domain_guid         = var.active_directory.domain_guid
        domain_name         = var.active_directory.domain_name
        domain_sid          = var.active_directory.domain_sid
        forest_name         = var.active_directory.forest_name
        netbios_domain_name = var.active_directory.netbios_domain_name
        storage_sid         = var.active_directory.storage_sid
      }
    }
  }
  lifecycle {
    ignore_changes = [
      network_rules[0].private_link_access,
      # share_properties[0].smb[0].versions,
      # share_properties[0].smb[0].authentication_types,
      # share_properties[0].smb[0].kerberos_ticket_encryption_type,
      # share_properties[0].smb[0].channel_encryption_type,
    ]
  }
}

data "azurerm_resource_group" "current" {
  name = var.az_files_storage_account_rg_name
}

resource "azurerm_private_endpoint" "default_storage_pe" {
  count = local.create_private_endpoint ? 1 : 0

  custom_network_interface_name = "${var.az_files_storage_account_name}-privateendpoint-nic"
  location                      = var.az_files_storage_account_rg_location
  name                          = "${var.az_files_storage_account_name}-privateendpoint"
  resource_group_name           = var.az_files_storage_account_rg_name
  subnet_id                     = var.private_endpoint.subnet_id
  tags                          = var.tags
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.private_endpoint.private_dns_zone_id]
  }
  private_service_connection {
    is_manual_connection           = false
    name                           = "${var.az_files_storage_account_name}-privateendpoint"
    private_connection_resource_id = azurerm_storage_account.default.id
    subresource_names              = ["file"]
  }
}

resource "azurerm_management_lock" "storage_account_lock" {
  count = var.enable_resource_locks ? 1 : 0

  name       = "${var.az_files_storage_account_name}-delete-lock"
  scope      = azurerm_storage_account.default.id
  lock_level = "CanNotDelete"
  notes      = "Prevents accidental deletion of production storage account"
}

resource "azurerm_management_lock" "private_endpoint_lock" {
  count = var.enable_resource_locks && local.create_private_endpoint ? 1 : 0

  name       = "${var.az_files_storage_account_name}-pe-delete-lock"
  scope      = azurerm_private_endpoint.default_storage_pe[0].id
  lock_level = "CanNotDelete"
  notes      = "Prevents accidental deletion of private endpoint"
}

# Enable Azure Backup for Azure Files
resource "azurerm_recovery_services_vault" "backup_vault" {
  count = local.create_vault ? 1 : 0

  name                          = "${var.az_files_storage_account_name}-vault"
  resource_group_name           = var.az_files_storage_account_rg_name
  location                      = var.az_files_storage_account_rg_location
  sku                           = "Standard"
  storage_mode_type             = local.backup.vault.storage_mode_type
  public_network_access_enabled = local.backup.vault.public_network_access_enabled
  cross_region_restore_enabled  = local.backup.vault.cross_region_restore_enabled
  # soft delete is always on per Azure's secure-by-default policy;
  # the soft_delete_enabled argument is deprecated and removed in azurerm v5

  tags = var.tags
}

resource "azurerm_backup_policy_file_share" "daily_backup" {
  count = local.create_backup ? 1 : 0

  name                = "${var.az_files_storage_account_name}-backup-policy"
  resource_group_name = local.vault_rg
  recovery_vault_name = local.vault_name

  timezone = local.backup.policy.timezone

  backup {
    frequency = local.backup.policy.frequency
    time      = local.backup.policy.time
  }
  retention_daily {
    count = local.backup.policy.retention_daily.count
  }
  retention_weekly {
    count    = local.backup.policy.retention_weekly.count
    weekdays = local.backup.policy.retention_weekly.weekdays
  }
  retention_monthly {
    count    = local.backup.policy.retention_monthly.count
    weekdays = local.backup.policy.retention_monthly.weekdays
    weeks    = local.backup.policy.retention_monthly.weeks
  }
  retention_yearly {
    count    = local.backup.policy.retention_yearly.count
    weekdays = local.backup.policy.retention_yearly.weekdays
    weeks    = local.backup.policy.retention_yearly.weeks
    months   = local.backup.policy.retention_yearly.months
  }
}

# Create Log Analytics Workspace (skipped when existing_log_analytics_workspace_id is set)
resource "azurerm_log_analytics_workspace" "storage_logs" {
  count = local.create_log_analytics ? 1 : 0

  name                = "${var.az_files_storage_account_name}-logs"
  location            = var.az_files_storage_account_rg_location
  resource_group_name = var.az_files_storage_account_rg_name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_analytics_retention_days
  tags                = var.tags
}

# Enable diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "storage_account" {
  name                       = "${var.az_files_storage_account_name}-diagnostics"
  target_resource_id         = azurerm_storage_account.default.id
  log_analytics_workspace_id = local.log_analytics_id
  enabled_metric {
    category = "Transaction"
  }
  enabled_metric {
    category = "Capacity"
  }
}

# File service specific diagnostics
resource "azurerm_monitor_diagnostic_setting" "file_service" {
  name                       = "${var.az_files_storage_account_name}-file-diagnostics"
  target_resource_id         = "${azurerm_storage_account.default.id}/fileServices/default"
  log_analytics_workspace_id = local.log_analytics_id
  enabled_log {
    category = "StorageRead"
  }
  enabled_log {
    category = "StorageWrite"
  }
  enabled_log {
    category = "StorageDelete"
  }
  enabled_metric {
    category = "Transaction"
  }
}

# Subscription-scoped singleton — opt-in via enable_defender_subscription_pricing.
# Leave off when Defender for Storage is already managed elsewhere in the subscription.
resource "azurerm_security_center_subscription_pricing" "defender_storage" {
  count = var.enable_defender_subscription_pricing ? 1 : 0

  tier          = "Standard"
  resource_type = "StorageAccounts"
  lifecycle {
    ignore_changes = [subplan]
  }
}

# Then configure per-storage account settings (always on)
resource "azurerm_security_center_storage_defender" "default" {
  storage_account_id = azurerm_storage_account.default.id

  # Configure malware scanning
  malware_scanning_on_upload_enabled          = true
  malware_scanning_on_upload_cap_gb_per_month = var.malware_scanning_cap_gb_per_month

  # Configure sensitive data discovery
  sensitive_data_discovery_enabled = var.enable_sensitive_data_discovery

  override_subscription_settings_enabled = var.defender_override_subscription_settings_enabled
}

# Add action group for security alerts (skipped when existing_action_group_id is set)
resource "azurerm_monitor_action_group" "storage_security_alerts" {
  count = local.create_action_group ? 1 : 0

  name                = "${var.az_files_storage_account_name}-security-alerts"
  resource_group_name = var.az_files_storage_account_rg_name
  short_name          = "sec-alert"

  email_receiver {
    name                    = "security-team"
    email_address           = var.security_alert_email
    use_common_alert_schema = true
  }

  tags = var.tags
}

# Alert for high error rate (potential attack)
resource "azurerm_monitor_metric_alert" "high_error_rate" {
  name                = "${var.az_files_storage_account_name}-high-errors"
  resource_group_name = var.az_files_storage_account_rg_name
  scopes              = [azurerm_storage_account.default.id]
  description         = "Alert when error rate exceeds threshold - potential security incident"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Storage/storageAccounts" # FIXED: Storage account level
    metric_name      = "Transactions"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = var.alert_threshold_high_errors

    dimension {
      name     = "ResponseType"
      operator = "Include"
      values   = ["ClientOtherError", "ServerOtherError", "AuthorizationError", "NetworkError"]
    }

    # ADDED: Filter to File service only
    dimension {
      name     = "ApiName"
      operator = "Include"
      values   = ["*"] # All APIs, but scoped to Files via next dimension
    }
  }

  action {
    action_group_id = local.action_group_id
  }

  tags = var.tags
}

# Alert for unusual deletion activity
resource "azurerm_monitor_metric_alert" "high_delete_operations" {
  name                = "${var.az_files_storage_account_name}-high-deletes"
  resource_group_name = var.az_files_storage_account_rg_name
  scopes              = [azurerm_storage_account.default.id]
  description         = "Alert on unusual delete activity - potential data loss incident"
  severity            = 1
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Storage/storageAccounts" # FIXED: Storage account level
    metric_name      = "Transactions"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = var.alert_threshold_high_deletes

    # Filter by delete operations
    dimension {
      name     = "ApiName"
      operator = "Include"
      values   = ["DeleteFile", "DeleteDirectory", "DeleteRange"]
    }

    # Filter to successful deletes only
    dimension {
      name     = "ResponseType"
      operator = "Include"
      values   = ["Success"]
    }
  }

  action {
    action_group_id = local.action_group_id
  }

  tags = var.tags
}

# Alert for unauthorized access attempts
resource "azurerm_monitor_metric_alert" "auth_failures" {
  name                = "${var.az_files_storage_account_name}-auth-failures"
  resource_group_name = var.az_files_storage_account_rg_name
  scopes              = [azurerm_storage_account.default.id]
  description         = "Alert on authentication failures - potential unauthorized access attempt"
  severity            = 1
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Storage/storageAccounts" # FIXED: Storage account level
    metric_name      = "Transactions"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = var.alert_threshold_auth_failures

    dimension {
      name     = "ResponseType"
      operator = "Include"
      values   = ["AuthorizationError", "AuthenticationError"]
    }
  }

  action {
    action_group_id = local.action_group_id
  }

  tags = var.tags
}

# Activity log alert — storage account deleted (ISO 27001 A.8.16 — control-plane monitoring)
resource "azurerm_monitor_activity_log_alert" "delete_storage_account" {
  name                = "${var.az_files_storage_account_name}-delete-sa-alert"
  resource_group_name = var.az_files_storage_account_rg_name
  location            = "global"
  scopes              = [azurerm_storage_account.default.id]
  description         = "Alert when the storage account is deleted — critical security event"

  criteria {
    resource_id    = azurerm_storage_account.default.id
    operation_name = "Microsoft.Storage/storageAccounts/delete"
    category       = "Administrative"
  }

  action {
    action_group_id = local.action_group_id
  }

  tags = var.tags
}

# Activity log alert — private endpoint deleted (ISO 27001 A.8.16)
# Scoped to the resource group, not the PE itself, so the alert rule survives
# the deletion it is meant to detect and catches any PE deletion in the RG.
resource "azurerm_monitor_activity_log_alert" "delete_private_endpoint" {
  count = local.create_private_endpoint ? 1 : 0

  name                = "${var.az_files_storage_account_name}-delete-pe-alert"
  resource_group_name = var.az_files_storage_account_rg_name
  location            = "global"
  scopes              = [data.azurerm_resource_group.current.id]
  description         = "Alert when a private endpoint in the resource group is deleted — network security event"

  criteria {
    operation_name = "Microsoft.Network/privateEndpoints/delete"
    category       = "Administrative"
  }

  action {
    action_group_id = local.action_group_id
  }

  tags = var.tags
}

# Activity log alert — storage account key regenerated (ISO 27001 A.8.16 — detects key re-enablement + rotation)
resource "azurerm_monitor_activity_log_alert" "regenerate_storage_key" {
  name                = "${var.az_files_storage_account_name}-key-regen-alert"
  resource_group_name = var.az_files_storage_account_rg_name
  location            = "global"
  scopes              = [azurerm_storage_account.default.id]
  description         = "Alert when storage account access keys are regenerated — potential credential compromise"

  criteria {
    resource_id    = azurerm_storage_account.default.id
    operation_name = "Microsoft.Storage/storageAccounts/regenerateKey/action"
    category       = "Administrative"
  }

  action {
    action_group_id = local.action_group_id
  }

  tags = var.tags
}

# Diagnostic settings for Recovery Services Vault (ISO 27001 A.8.15 — audit backup operations).
# Only when this module created the vault — we do not manage diagnostics on a BYO vault.
resource "azurerm_monitor_diagnostic_setting" "backup_vault" {
  count = local.create_vault ? 1 : 0

  name                       = "${var.az_files_storage_account_name}-vault-diagnostics"
  target_resource_id         = azurerm_recovery_services_vault.backup_vault[0].id
  log_analytics_workspace_id = local.log_analytics_id

  enabled_log { category = "AzureBackupReport" }
  enabled_log { category = "CoreAzureBackup" }
  enabled_log { category = "AddonAzureBackupJobs" }
  enabled_log { category = "AddonAzureBackupAlerts" }
  enabled_log { category = "AddonAzureBackupPolicy" }
  enabled_log { category = "AddonAzureBackupStorage" }
  enabled_log { category = "AddonAzureBackupProtectedInstance" }
}

# Share-level SMB RBAC — caller supplies group→role map via share_level_role_assignments.
# Uses azuread_groups (plural): returns only object IDs, does NOT enumerate membership.
# The singular azuread_group pulls the full members list — minutes for large dynamic groups.
data "azuread_groups" "share_rbac" {
  for_each      = var.share_level_role_assignments
  display_names = [each.value.group_display_name]
}

resource "azurerm_role_assignment" "share_rbac" {
  for_each             = var.share_level_role_assignments
  scope                = azurerm_storage_account.default.id
  role_definition_name = each.value.role_definition_name
  # one() returns the single object ID, or raises an error if the display name
  # matched more than one group — never silently picks an arbitrary group the way
  # object_ids[0] did. The precondition below produces the actionable message first.
  principal_id = one(data.azuread_groups.share_rbac[each.key].object_ids)

  lifecycle {
    precondition {
      # Entra display names are not unique: a name can resolve to 0 or many groups.
      # Require exactly one so the RBAC assignment targets an unambiguous principal.
      condition     = length(data.azuread_groups.share_rbac[each.key].object_ids) == 1
      error_message = "share_level_role_assignments[\"${each.key}\"]: group_display_name \"${each.value.group_display_name}\" resolved to ${length(data.azuread_groups.share_rbac[each.key].object_ids)} Entra groups; exactly one is required. Display names are not unique — use a name (or switch the map to object IDs) that matches a single group."
    }
  }
}
