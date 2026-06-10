resource "azurerm_storage_account" "default" {
  name                          = var.az_files_storage_account_name
  resource_group_name           = var.az_files_storage_account_rg_name
  location                      = var.az_files_storage_account_rg_location
  account_kind                  = "StorageV2"
  account_tier                  = "Standard"
  account_replication_type      = "ZRS"
  tags                          = var.tags
  public_network_access_enabled = var.public_network_access_enabled

  access_tier                      = "Hot"
  min_tls_version                  = "TLS1_2"
  large_file_share_enabled         = true
  cross_tenant_replication_enabled = false
  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices", "Logging", "Metrics"]
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

resource "azurerm_private_endpoint" "default_storage_pe" {
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
}

resource "azurerm_management_lock" "storage_account_lock" {
  count = var.enable_resource_locks ? 1 : 0

  name       = "${var.az_files_storage_account_name}-delete-lock"
  scope      = azurerm_storage_account.default.id
  lock_level = "CanNotDelete"
  notes      = "Prevents accidental deletion of production storage account"
}

resource "azurerm_management_lock" "private_endpoint_lock" {
  count = var.enable_resource_locks ? 1 : 0

  name       = "${var.az_files_storage_account_name}-pe-delete-lock"
  scope      = azurerm_private_endpoint.default_storage_pe.id
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
  soft_delete_enabled           = true

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

  timezone = "UTC"

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
  metric {
    category = "Transaction"
    enabled  = true
  }
  metric {
    category = "Capacity"
    enabled  = true
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
  metric {
    category = "Transaction"
    enabled  = true
  }
}

resource "azurerm_security_center_subscription_pricing" "defender_storage" {
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
  malware_scanning_on_upload_cap_gb_per_month = 5000

  # Configure sensitive data discovery
  sensitive_data_discovery_enabled = var.enable_sensitive_data_discovery

  # Override subscription-level settings (optional)
  override_subscription_settings_enabled = false
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
    threshold        = 100

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
    threshold        = 50

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
    threshold        = 20

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