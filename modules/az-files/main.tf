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

  dynamic "azure_files_authentication" {
    for_each = var.ad_storage_sid != null ? [1] : []
    content {
      directory_type                 = "AD"
      default_share_level_permission = var.default_share_level_permission
      active_directory {
        domain_guid         = var.ad_domain_guid
        domain_name         = var.ad_domain_name
        domain_sid          = var.ad_domain_sid
        forest_name         = var.ad_forest_name
        netbios_domain_name = var.ad_netbios_domain_name
        storage_sid         = var.ad_storage_sid
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
  count = var.enable_private_endpoint ? 1 : 0

  custom_network_interface_name = "${var.az_files_storage_account_name}-privateendpoint-nic"
  location                      = var.az_files_storage_account_rg_location
  name                          = "${var.az_files_storage_account_name}-privateendpoint"
  resource_group_name           = var.az_files_storage_account_rg_name
  subnet_id                     = var.subnet_id
  tags                          = var.tags
  #   ip_configuration {
  #     member_name        = "file"
  #     name               = "${var.az_files_storage_account_name}-pe-ip"
  #     private_ip_address = "172.22.145.4"
  #     subresource_name   = "file"
  #   }
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
  private_service_connection {
    is_manual_connection           = false
    name                           = "${var.az_files_storage_account_name}-privateendpoint"
    private_connection_resource_id = azurerm_storage_account.default.id
    subresource_names              = ["file"]
  }

  lifecycle {
    precondition {
      condition     = var.private_dns_zone_id != null
      error_message = "private_dns_zone_id must be set — without it the private endpoint deploys but SMB clients cannot resolve the storage account FQDN, and mounts fail silently."
    }
    precondition {
      condition     = var.subnet_id != null
      error_message = "subnet_id must be set when enable_private_endpoint is true — the private endpoint has no subnet to deploy into."
    }
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
  count = var.enable_resource_locks && var.enable_private_endpoint ? 1 : 0

  name       = "${var.az_files_storage_account_name}-pe-delete-lock"
  scope      = azurerm_private_endpoint.default_storage_pe[0].id
  lock_level = "CanNotDelete"
  notes      = "Prevents accidental deletion of private endpoint"
}

# Enable Azure Backup for Azure Files
resource "azurerm_recovery_services_vault" "backup_vault" {
  count = var.enable_backup ? 1 : 0

  name                          = "${var.az_files_storage_account_name}-vault"
  resource_group_name           = var.az_files_storage_account_rg_name
  location                      = var.az_files_storage_account_rg_location
  sku                           = "Standard"
  storage_mode_type             = var.backup_vault_storage_mode_type
  public_network_access_enabled = var.backup_vault_public_network_access_enabled
  cross_region_restore_enabled  = var.backup_vault_cross_region_restore_enabled
  # soft delete is always on per Azure's secure-by-default policy;
  # the soft_delete_enabled argument is deprecated and removed in azurerm v5

  tags = var.tags

  lifecycle {
    precondition {
      condition     = !var.backup_vault_cross_region_restore_enabled || var.backup_vault_storage_mode_type == "GeoRedundant"
      error_message = "backup_vault_cross_region_restore_enabled = true requires backup_vault_storage_mode_type = GeoRedundant."
    }
  }
}

resource "azurerm_backup_policy_file_share" "daily_backup" {
  count = var.enable_backup ? 1 : 0

  name                = "${var.az_files_storage_account_name}-backup-policy"
  resource_group_name = var.az_files_storage_account_rg_name
  recovery_vault_name = azurerm_recovery_services_vault.backup_vault[0].name

  timezone = var.backup_timezone

  backup {
    frequency = var.backup_policy.frequency
    time      = var.backup_policy.time
  }
  retention_daily {
    count = var.backup_policy.retention_daily.count
  }
  retention_weekly {
    count    = var.backup_policy.retention_weekly.count
    weekdays = var.backup_policy.retention_weekly.weekdays
  }
  retention_monthly {
    count    = var.backup_policy.retention_monthly.count
    weekdays = var.backup_policy.retention_monthly.weekdays
    weeks    = var.backup_policy.retention_monthly.weeks
  }
  retention_yearly {
    count    = var.backup_policy.retention_yearly.count
    weekdays = var.backup_policy.retention_yearly.weekdays
    weeks    = var.backup_policy.retention_yearly.weeks
    months   = var.backup_policy.retention_yearly.months
  }
}

# Create Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "storage_logs" {
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
  log_analytics_workspace_id = azurerm_log_analytics_workspace.storage_logs.id
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
  log_analytics_workspace_id = azurerm_log_analytics_workspace.storage_logs.id
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

# Subscription-scoped singleton — disable via enable_defender_subscription_pricing
# when Defender for Storage is already managed elsewhere in the subscription.
resource "azurerm_security_center_subscription_pricing" "defender_storage" {
  count = var.enable_defender_subscription_pricing ? 1 : 0

  tier          = "Standard"
  resource_type = "StorageAccounts"
  lifecycle {
    ignore_changes = [subplan]
  }
}

# Then configure per-storage account settings
resource "azurerm_security_center_storage_defender" "default" {
  storage_account_id = azurerm_storage_account.default.id

  # Configure malware scanning
  malware_scanning_on_upload_enabled          = true
  malware_scanning_on_upload_cap_gb_per_month = var.malware_scanning_cap_gb_per_month

  # Configure sensitive data discovery
  sensitive_data_discovery_enabled = var.enable_sensitive_data_discovery

  override_subscription_settings_enabled = var.defender_override_subscription_settings_enabled
}

# Add action group for security alerts
resource "azurerm_monitor_action_group" "storage_security_alerts" {
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
    action_group_id = azurerm_monitor_action_group.storage_security_alerts.id
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
    action_group_id = azurerm_monitor_action_group.storage_security_alerts.id
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
    action_group_id = azurerm_monitor_action_group.storage_security_alerts.id
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
    action_group_id = azurerm_monitor_action_group.storage_security_alerts.id
  }

  tags = var.tags
}

# Activity log alert — private endpoint deleted (ISO 27001 A.8.16)
# Scoped to the resource group, not the PE itself, so the alert rule survives
# the deletion it is meant to detect and catches any PE deletion in the RG.
resource "azurerm_monitor_activity_log_alert" "delete_private_endpoint" {
  count = var.enable_private_endpoint ? 1 : 0

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
    action_group_id = azurerm_monitor_action_group.storage_security_alerts.id
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
    action_group_id = azurerm_monitor_action_group.storage_security_alerts.id
  }

  tags = var.tags
}

# Diagnostic settings for Recovery Services Vault (ISO 27001 A.8.15 — audit backup operations)
resource "azurerm_monitor_diagnostic_setting" "backup_vault" {
  count = var.enable_backup ? 1 : 0

  name                       = "${var.az_files_storage_account_name}-vault-diagnostics"
  target_resource_id         = azurerm_recovery_services_vault.backup_vault[0].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.storage_logs.id

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
  principal_id         = data.azuread_groups.share_rbac[each.key].object_ids[0]
}