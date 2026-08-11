output "id" {
  description = "Resource ID of the storage account."
  value       = azurerm_storage_account.default.id
}

output "storage_account_name" {
  description = "Name of the storage account. Use for az CLI, AzCopy, or SDK references."
  value       = azurerm_storage_account.default.name
}

output "storage_account_principal_id" {
  description = "Principal ID of the storage account's system-assigned managed identity. Assign Key Vault or other RBAC roles to this principal."
  value       = azurerm_storage_account.default.identity[0].principal_id
}

output "private_endpoint_id" {
  description = "Resource ID of the file storage private endpoint. Null when no private endpoint is created."
  value       = one(azurerm_private_endpoint.default_storage_pe[*].id)
}

output "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics Workspace in use — the workspace created by this module, or existing_log_analytics_workspace_id when supplied. Use to add additional diagnostic sinks from the calling module."
  value       = local.log_analytics_id
}

output "recovery_services_vault_id" {
  description = "Resource ID of the Recovery Services vault created by this module. Null when backup is disabled or an existing vault (existing_recovery_services_vault) is used."
  value       = one(azurerm_recovery_services_vault.backup_vault[*].id)
}

output "action_group_id" {
  description = "Resource ID of the Monitor Action Group in use for security alerts — the one created by this module, or existing_action_group_id when supplied."
  value       = local.action_group_id
}
