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
  description = "Resource ID of the file storage private endpoint."
  value       = azurerm_private_endpoint.default_storage_pe.id
}

output "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics Workspace. Use this to add additional diagnostic sinks from the calling module."
  value       = azurerm_log_analytics_workspace.storage_logs.id
}
