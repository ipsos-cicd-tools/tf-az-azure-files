<!-- BEGIN_TF_DOCS -->
## Usage
Basic usage of this module is as follows:
```
module "az-files" {
  source  = "git::https://github.com/ipsos-cicd-tools/tf-az-azure-files//modules/az-files?ref=<version number>"
  
  ## Required Variables ##
  az_files_storage_account_name  = 
  az_files_storage_account_rg_location  = 
  az_files_storage_account_rg_name  = 
  tags  = 
  
  ## Optional Variables ##
  active_directory  =   null
  alert_threshold_auth_failures  =   20
  alert_threshold_high_deletes  =   50
  alert_threshold_high_errors  =   100
  allowed_copy_scope  =   null
  backup  =   null
  default_share_level_permission  =   "StorageFileDataSmbShareContributor"
  defender_override_subscription_settings_enabled  =   true
  enable_backup  =   null
  enable_defender_subscription_pricing  =   false
  enable_private_endpoint  =   null
  enable_resource_locks  =   true
  enable_sensitive_data_discovery  =   true
  existing_action_group_id  =   null
  existing_log_analytics_workspace_id  =   null
  existing_recovery_services_vault  =   null
  ip_rules  =   []
  log_analytics_retention_days  =   365
  malware_scanning_cap_gb_per_month  =   5000
  private_endpoint  =   null
  public_network_access_enabled  =   false
  security_alert_email  =   null
  share_level_role_assignments  =   {}
  shared_access_key_enabled  =   false
  soft_delete_retention_days  =   14
  storage_account_replication_type  =   "ZRS"
  storage_account_subnet_ids  =   []
}
```
## Resources

| Name | Type |
|------|------|
| [azurerm_backup_policy_file_share.daily_backup](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/backup_policy_file_share) | resource |
| [azurerm_log_analytics_workspace.storage_logs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) | resource |
| [azurerm_management_lock.private_endpoint_lock](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) | resource |
| [azurerm_management_lock.storage_account_lock](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) | resource |
| [azurerm_monitor_action_group.storage_security_alerts](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_action_group) | resource |
| [azurerm_monitor_activity_log_alert.delete_private_endpoint](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_activity_log_alert) | resource |
| [azurerm_monitor_activity_log_alert.delete_storage_account](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_activity_log_alert) | resource |
| [azurerm_monitor_activity_log_alert.regenerate_storage_key](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_activity_log_alert) | resource |
| [azurerm_monitor_diagnostic_setting.backup_vault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_monitor_diagnostic_setting.file_service](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_monitor_diagnostic_setting.storage_account](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_monitor_metric_alert.auth_failures](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert) | resource |
| [azurerm_monitor_metric_alert.high_delete_operations](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert) | resource |
| [azurerm_monitor_metric_alert.high_error_rate](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert) | resource |
| [azurerm_private_endpoint.default_storage_pe](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_recovery_services_vault.backup_vault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/recovery_services_vault) | resource |
| [azurerm_role_assignment.share_rbac](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_security_center_storage_defender.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/security_center_storage_defender) | resource |
| [azurerm_security_center_subscription_pricing.defender_storage](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/security_center_subscription_pricing) | resource |
| [azurerm_storage_account.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azuread_groups.share_rbac](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/groups) | data source |
| [azurerm_resource_group.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_active_directory"></a> [active\_directory](#input\_active\_directory) | On-prem AD DS integration for SMB Kerberos auth (directory\_type = 'AD'). Provide this object to domain-join the storage account. Leave null (default) for no AD integration. All fields are required by Azure when directory\_type is 'AD'. storage\_sid is typically obtained after the account is domain joined. | <pre>object({<br/>    domain_name         = string<br/>    domain_guid         = string<br/>    domain_sid          = string<br/>    forest_name         = string<br/>    netbios_domain_name = string<br/>    storage_sid         = string<br/>  })</pre> | `null` | no |
| <a name="input_alert_threshold_auth_failures"></a> [alert\_threshold\_auth\_failures](#input\_alert\_threshold\_auth\_failures) | Authentication failure count threshold that triggers the auth-failure alert. Tune per environment (ISO 27001 A.8.16). | `number` | `20` | no |
| <a name="input_alert_threshold_high_deletes"></a> [alert\_threshold\_high\_deletes](#input\_alert\_threshold\_high\_deletes) | Delete operation count threshold that triggers the high-delete-activity alert. Tune per environment (ISO 27001 A.8.16). | `number` | `50` | no |
| <a name="input_alert_threshold_high_errors"></a> [alert\_threshold\_high\_errors](#input\_alert\_threshold\_high\_errors) | Transaction error count threshold that triggers the high-error-rate alert. Tune per environment to avoid alert fatigue (ISO 27001 A.8.16). | `number` | `100` | no |
| <a name="input_allowed_copy_scope"></a> [allowed\_copy\_scope](#input\_allowed\_copy\_scope) | Restrict object copy operations to the same AAD tenant ('AAD') or same private link network ('PrivateLink'). Null leaves Azure's default (unrestricted). Set to 'AAD' to prevent cross-tenant data exfiltration (ISO 27001 A.8.12). | `string` | `null` | no |
| <a name="input_az_files_storage_account_name"></a> [az\_files\_storage\_account\_name](#input\_az\_files\_storage\_account\_name) | The name of the Azure Files storage account | `string` | n/a | yes |
| <a name="input_az_files_storage_account_rg_location"></a> [az\_files\_storage\_account\_rg\_location](#input\_az\_files\_storage\_account\_rg\_location) | The location of the resource group in which to create the Azure Files storage account | `string` | n/a | yes |
| <a name="input_az_files_storage_account_rg_name"></a> [az\_files\_storage\_account\_rg\_name](#input\_az\_files\_storage\_account\_rg\_name) | The name of the resource group in which to create the Azure Files storage account | `string` | n/a | yes |
| <a name="input_backup"></a> [backup](#input\_backup) | Azure Backup configuration for the file share. Provide this object (even empty `{}`) to create a Recovery Services vault + daily/weekly/monthly/yearly backup policy. Leave null (default) for no backup. NOTE: this changes the pre-rework default (backup was on by default); pass `backup = {}` to keep the previous behaviour. Individual policy/vault fields default to the module's hardened schedule (14 daily / 4 weekly / 3 monthly / 3 yearly, ZoneRedundant vault). | <pre>object({<br/>    policy = optional(object({<br/>      timezone        = optional(string, "UTC")<br/>      frequency       = optional(string, "Daily")<br/>      time            = optional(string, "23:00")<br/>      retention_daily = optional(object({ count = number }), { count = 14 })<br/>      retention_weekly = optional(object({<br/>        count    = number<br/>        weekdays = list(string)<br/>      }), { count = 4, weekdays = ["Sunday"] })<br/>      retention_monthly = optional(object({<br/>        count    = number<br/>        weekdays = list(string)<br/>        weeks    = list(string)<br/>      }), { count = 3, weekdays = ["Sunday"], weeks = ["First"] })<br/>      retention_yearly = optional(object({<br/>        count    = number<br/>        weekdays = list(string)<br/>        weeks    = list(string)<br/>        months   = list(string)<br/>      }), { count = 3, weekdays = ["Sunday"], weeks = ["First"], months = ["January"] })<br/>    }), {})<br/>    vault = optional(object({<br/>      storage_mode_type             = optional(string, "ZoneRedundant")<br/>      public_network_access_enabled = optional(bool, false)<br/>      cross_region_restore_enabled  = optional(bool, false)<br/>    }), {})<br/>  })</pre> | `null` | no |
| <a name="input_default_share_level_permission"></a> [default\_share\_level\_permission](#input\_default\_share\_level\_permission) | Default share-level permission granted to ALL authenticated identities on the share. Defaults to Contributor: the sanctioned mechanism for an org-wide 'all employees' baseline, replacing a cloud-only/dynamic Entra 'all staff' group (which does NOT work for AD DS share-level RBAC — its SID isn't in the on-prem Kerberos ticket). NTFS ACLs still enforce per-folder access. Set to Reader or None for a stricter least-privilege posture (ISO 27001 A.8.2) and grant elevated access to specific groups via share\_level\_role\_assignments. | `string` | `"StorageFileDataSmbShareContributor"` | no |
| <a name="input_defender_override_subscription_settings_enabled"></a> [defender\_override\_subscription\_settings\_enabled](#input\_defender\_override\_subscription\_settings\_enabled) | Whether the per-storage-account Defender settings (malware scanning cap, sensitive data discovery) override the subscription-level Defender policy. Keep true to guarantee this module's security posture applies regardless of subscription defaults (ISO 27001 A.8.12). | `bool` | `true` | no |
| <a name="input_enable_backup"></a> [enable\_backup](#input\_enable\_backup) | Override for Azure Backup creation. null (default) = auto: create when var.backup is set. true = force on (uses the default policy when var.backup is null). false = force off even if var.backup is set. | `bool` | `null` | no |
| <a name="input_enable_defender_subscription_pricing"></a> [enable\_defender\_subscription\_pricing](#input\_enable\_defender\_subscription\_pricing) | Whether THIS module manages the subscription-level Defender for Storage plan (a subscription-scoped singleton). Defaults to false (opt-in): leave it off when Defender for Storage is already enabled by Azure Policy, another module instance, or another configuration in the same subscription, to avoid state conflicts. Per-account Defender (malware scanning, sensitive-data discovery) is always enabled regardless of this flag. | `bool` | `false` | no |
| <a name="input_enable_private_endpoint"></a> [enable\_private\_endpoint](#input\_enable\_private\_endpoint) | Override for private-endpoint creation. null (default) = auto: create when var.private\_endpoint is set. true = force on (requires private\_endpoint). false = force off even if private\_endpoint is set. | `bool` | `null` | no |
| <a name="input_enable_resource_locks"></a> [enable\_resource\_locks](#input\_enable\_resource\_locks) | Whether to enable CanNotDelete resource locks on the storage account and (when created) the private endpoint. | `bool` | `true` | no |
| <a name="input_enable_sensitive_data_discovery"></a> [enable\_sensitive\_data\_discovery](#input\_enable\_sensitive\_data\_discovery) | Whether to enable sensitive data discovery in the per-account Defender for Storage settings. | `bool` | `true` | no |
| <a name="input_existing_action_group_id"></a> [existing\_action\_group\_id](#input\_existing\_action\_group\_id) | Resource ID of an existing Monitor Action Group to route all security alerts to. When set, the module does NOT create its own action group (and security\_alert\_email is not required). Leave null (default) to create a dedicated action group from security\_alert\_email. | `string` | `null` | no |
| <a name="input_existing_log_analytics_workspace_id"></a> [existing\_log\_analytics\_workspace\_id](#input\_existing\_log\_analytics\_workspace\_id) | Resource ID of an existing Log Analytics Workspace to send diagnostics to. When set, the module does NOT create its own workspace and points all diagnostic settings at this one (e.g. a central/hub logging workspace). Leave null (default) to create a dedicated workspace. | `string` | `null` | no |
| <a name="input_existing_recovery_services_vault"></a> [existing\_recovery\_services\_vault](#input\_existing\_recovery\_services\_vault) | An existing Recovery Services vault to attach the backup policy to instead of creating one. Given as name + resource group (the backup policy resource references the vault by name, not ID). resource\_group\_name defaults to the storage account's resource group. Only used when backup is enabled. | <pre>object({<br/>    name                = string<br/>    resource_group_name = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_ip_rules"></a> [ip\_rules](#input\_ip\_rules) | A list of public IP addresses/CIDRs allowed to access the storage account. Only applicable if public\_network\_access\_enabled is true. | `list(string)` | `[]` | no |
| <a name="input_log_analytics_retention_days"></a> [log\_analytics\_retention\_days](#input\_log\_analytics\_retention\_days) | Retention period in days for the Log Analytics Workspace (only used when the module creates its own workspace). ISO 27001 A.8.15 recommends at least 365 days for audit log retention. | `number` | `365` | no |
| <a name="input_malware_scanning_cap_gb_per_month"></a> [malware\_scanning\_cap\_gb\_per\_month](#input\_malware\_scanning\_cap\_gb\_per\_month) | Monthly cap in GB for Defender for Storage malware scanning on upload. Set to 0 for unlimited (ISO 27001 A.8.12). | `number` | `5000` | no |
| <a name="input_private_endpoint"></a> [private\_endpoint](#input\_private\_endpoint) | Private endpoint configuration for the file sub-resource. Provide this object to create a private endpoint (recommended for production). Leave null (default) to reach the account via VNet service endpoints (storage\_account\_subnet\_ids) or public access instead. Creation can be overridden with enable\_private\_endpoint. | <pre>object({<br/>    subnet_id           = string<br/>    private_dns_zone_id = string<br/>  })</pre> | `null` | no |
| <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled) | Whether to allow public network access to the Azure Files storage account. Setting this to false disables all public network access (including the Azure portal and Storage Explorer). Security best practice when using private endpoints. | `bool` | `false` | no |
| <a name="input_security_alert_email"></a> [security\_alert\_email](#input\_security\_alert\_email) | Email address for security alerts. Required unless existing\_action\_group\_id is set (in which case alerts route to the existing action group and no email receiver is created). | `string` | `null` | no |
| <a name="input_share_level_role_assignments"></a> [share\_level\_role\_assignments](#input\_share\_level\_role\_assignments) | Map of share-level SMB RBAC assignments. Each entry resolves an AAD group by display name and grants it the specified role on the storage account. Uses azuread\_groups (plural) — returns only object IDs, does not enumerate membership, so plan times stay fast. IMPORTANT: for AD DS auth (directory\_type = 'AD'), only on-prem AD security groups synced to Entra ID (Assigned membership) are honored — their SID must be present in the on-prem Kerberos ticket. Cloud-only/dynamic-membership groups are NOT matched and will silently fail. For an all-authenticated baseline, use default\_share\_level\_permission instead of a dynamic 'all staff' group. | <pre>map(object({<br/>    group_display_name   = string<br/>    role_definition_name = string<br/>  }))</pre> | `{}` | no |
| <a name="input_shared_access_key_enabled"></a> [shared\_access\_key\_enabled](#input\_shared\_access\_key\_enabled) | Whether to allow access via storage account keys. Defaults to false (ISO 27001 A.8.5 — force Azure AD / Kerberos auth only). Set true if tooling requires key-based access (AzCopy --account-key, Portal Storage Explorer, legacy scripts). | `bool` | `false` | no |
| <a name="input_soft_delete_retention_days"></a> [soft\_delete\_retention\_days](#input\_soft\_delete\_retention\_days) | The number of days that soft-deleted file shares, files, or directories are retained. Must be between 1 and 365. | `number` | `14` | no |
| <a name="input_storage_account_replication_type"></a> [storage\_account\_replication\_type](#input\_storage\_account\_replication\_type) | Replication type for the storage account. Use LRS in regions without availability zones, GRS for geo-redundancy independent of the backup vault. | `string` | `"ZRS"` | no |
| <a name="input_storage_account_subnet_ids"></a> [storage\_account\_subnet\_ids](#input\_storage\_account\_subnet\_ids) | List of subnet IDs allowed to access the storage account via VNet service endpoints. Can be used alongside or instead of a private endpoint. | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to the Azure Files storage account | `map(string)` | n/a | yes |
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_action_group_id"></a> [action\_group\_id](#output\_action\_group\_id) | Resource ID of the Monitor Action Group in use for security alerts — the one created by this module, or existing\_action\_group\_id when supplied. |
| <a name="output_id"></a> [id](#output\_id) | Resource ID of the storage account. |
| <a name="output_log_analytics_workspace_id"></a> [log\_analytics\_workspace\_id](#output\_log\_analytics\_workspace\_id) | Resource ID of the Log Analytics Workspace in use — the workspace created by this module, or existing\_log\_analytics\_workspace\_id when supplied. Use to add additional diagnostic sinks from the calling module. |
| <a name="output_private_endpoint_id"></a> [private\_endpoint\_id](#output\_private\_endpoint\_id) | Resource ID of the file storage private endpoint. Null when no private endpoint is created. |
| <a name="output_recovery_services_vault_id"></a> [recovery\_services\_vault\_id](#output\_recovery\_services\_vault\_id) | Resource ID of the Recovery Services vault created by this module. Null when backup is disabled or an existing vault (existing\_recovery\_services\_vault) is used. |
| <a name="output_storage_account_name"></a> [storage\_account\_name](#output\_storage\_account\_name) | Name of the storage account. Use for az CLI, AzCopy, or SDK references. |
| <a name="output_storage_account_principal_id"></a> [storage\_account\_principal\_id](#output\_storage\_account\_principal\_id) | Principal ID of the storage account's system-assigned managed identity. Assign Key Vault or other RBAC roles to this principal. |
<!-- END_TF_DOCS -->