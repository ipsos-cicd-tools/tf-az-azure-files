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
  security_alert_email  = 
  tags  = 
  
  ## Optional Variables ##
  ad_domain_guid  =   null
  ad_domain_name  =   null
  ad_domain_sid  =   null
  ad_forest_name  =   null
  ad_netbios_domain_name  =   null
  ad_storage_sid  =   null
  alert_threshold_auth_failures  =   20
  alert_threshold_high_deletes  =   50
  alert_threshold_high_errors  =   100
  allowed_copy_scope  =   null
  backup_policy  =   {
  "frequency": "Daily",
  "retention_daily": {
    "count": 14
  },
  "retention_monthly": {
    "count": 3,
    "weekdays": [
      "Sunday"
    ],
    "weeks": [
      "First"
    ]
  },
  "retention_weekly": {
    "count": 4,
    "weekdays": [
      "Sunday"
    ]
  },
  "retention_yearly": {
    "count": 3,
    "months": [
      "January"
    ],
    "weekdays": [
      "Sunday"
    ],
    "weeks": [
      "First"
    ]
  },
  "time": "23:00"
}
  backup_timezone  =   "UTC"
  backup_vault_cross_region_restore_enabled  =   false
  backup_vault_public_network_access_enabled  =   false
  backup_vault_storage_mode_type  =   "ZoneRedundant"
  default_share_level_permission  =   "StorageFileDataSmbShareContributor"
  defender_override_subscription_settings_enabled  =   true
  enable_backup  =   true
  enable_defender_subscription_pricing  =   true
  enable_private_endpoint  =   true
  enable_resource_locks  =   true
  enable_sensitive_data_discovery  =   true
  ip_rules  =   []
  log_analytics_retention_days  =   365
  malware_scanning_cap_gb_per_month  =   5000
  private_dns_zone_id  =   null
  public_network_access_enabled  =   false
  share_level_role_assignments  =   {}
  shared_access_key_enabled  =   false
  soft_delete_retention_days  =   14
  storage_account_replication_type  =   "ZRS"
  storage_account_subnet_ids  =   []
  subnet_id  =   null
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
| <a name="input_ad_domain_guid"></a> [ad\_domain\_guid](#input\_ad\_domain\_guid) | The domain GUID for Active Directory integration. | `string` | `null` | no |
| <a name="input_ad_domain_name"></a> [ad\_domain\_name](#input\_ad\_domain\_name) | The primary domain name for Active Directory integration. | `string` | `null` | no |
| <a name="input_ad_domain_sid"></a> [ad\_domain\_sid](#input\_ad\_domain\_sid) | The domain SID for Active Directory integration. | `string` | `null` | no |
| <a name="input_ad_forest_name"></a> [ad\_forest\_name](#input\_ad\_forest\_name) | The forest name for Active Directory integration. | `string` | `null` | no |
| <a name="input_ad_netbios_domain_name"></a> [ad\_netbios\_domain\_name](#input\_ad\_netbios\_domain\_name) | The NetBIOS domain name for Active Directory integration. | `string` | `null` | no |
| <a name="input_ad_storage_sid"></a> [ad\_storage\_sid](#input\_ad\_storage\_sid) | The security identifier (SID) for the storage account in Active Directory. This is typically obtained after the storage account is domain joined. | `string` | `null` | no |
| <a name="input_alert_threshold_auth_failures"></a> [alert\_threshold\_auth\_failures](#input\_alert\_threshold\_auth\_failures) | Authentication failure count threshold that triggers the auth-failure alert. Tune per environment (ISO 27001 A.8.16). | `number` | `20` | no |
| <a name="input_alert_threshold_high_deletes"></a> [alert\_threshold\_high\_deletes](#input\_alert\_threshold\_high\_deletes) | Delete operation count threshold that triggers the high-delete-activity alert. Tune per environment (ISO 27001 A.8.16). | `number` | `50` | no |
| <a name="input_alert_threshold_high_errors"></a> [alert\_threshold\_high\_errors](#input\_alert\_threshold\_high\_errors) | Transaction error count threshold that triggers the high-error-rate alert. Tune per environment to avoid alert fatigue (ISO 27001 A.8.16). | `number` | `100` | no |
| <a name="input_allowed_copy_scope"></a> [allowed\_copy\_scope](#input\_allowed\_copy\_scope) | Restrict object copy operations to the same AAD tenant ('AAD') or same private link network ('PrivateLink'). Null leaves the setting at Azure's default (unrestricted). Set to 'AAD' to prevent cross-tenant data exfiltration (ISO 27001 A.8.12). | `string` | `null` | no |
| <a name="input_az_files_storage_account_name"></a> [az\_files\_storage\_account\_name](#input\_az\_files\_storage\_account\_name) | The name of the Azure Files storage account | `string` | n/a | yes |
| <a name="input_az_files_storage_account_rg_location"></a> [az\_files\_storage\_account\_rg\_location](#input\_az\_files\_storage\_account\_rg\_location) | The location of the resource group in which to create the Azure Files storage account | `string` | n/a | yes |
| <a name="input_az_files_storage_account_rg_name"></a> [az\_files\_storage\_account\_rg\_name](#input\_az\_files\_storage\_account\_rg\_name) | The name of the resource group in which to create the Azure Files storage account | `string` | n/a | yes |
| <a name="input_backup_policy"></a> [backup\_policy](#input\_backup\_policy) | A map of backup policy settings for the Azure Files storage account | <pre>object({<br>    frequency = string<br>    time      = string<br>    retention_daily = object({<br>      count = number<br>    })<br>    retention_weekly = object({<br>      count    = number<br>      weekdays = list(string)<br>    })<br>    retention_monthly = object({<br>      count    = number<br>      weekdays = list(string)<br>      weeks    = list(string)<br>    })<br>    retention_yearly = object({<br>      count    = number<br>      weekdays = list(string)<br>      weeks    = list(string)<br>      months   = list(string)<br>    })<br>  })</pre> | <pre>{<br>  "frequency": "Daily",<br>  "retention_daily": {<br>    "count": 14<br>  },<br>  "retention_monthly": {<br>    "count": 3,<br>    "weekdays": [<br>      "Sunday"<br>    ],<br>    "weeks": [<br>      "First"<br>    ]<br>  },<br>  "retention_weekly": {<br>    "count": 4,<br>    "weekdays": [<br>      "Sunday"<br>    ]<br>  },<br>  "retention_yearly": {<br>    "count": 3,<br>    "months": [<br>      "January"<br>    ],<br>    "weekdays": [<br>      "Sunday"<br>    ],<br>    "weeks": [<br>      "First"<br>    ]<br>  },<br>  "time": "23:00"<br>}</pre> | no |
| <a name="input_backup_timezone"></a> [backup\_timezone](#input\_backup\_timezone) | Timezone for the file share backup schedule (e.g. 'UTC', 'Romance Standard Time'). Uses Windows timezone names. | `string` | `"UTC"` | no |
| <a name="input_backup_vault_cross_region_restore_enabled"></a> [backup\_vault\_cross\_region\_restore\_enabled](#input\_backup\_vault\_cross\_region\_restore\_enabled) | Whether to enable cross-region restore on the Recovery Services Vault. Requires backup\_vault\_storage\_mode\_type = GeoRedundant. | `bool` | `false` | no |
| <a name="input_backup_vault_public_network_access_enabled"></a> [backup\_vault\_public\_network\_access\_enabled](#input\_backup\_vault\_public\_network\_access\_enabled) | Whether to allow public network access to the Recovery Services Vault. Set to true if access via the Azure Portal or public internet is required (e.g., for on-demand backup/restore operations through the portal UI). | `bool` | `false` | no |
| <a name="input_backup_vault_storage_mode_type"></a> [backup\_vault\_storage\_mode\_type](#input\_backup\_vault\_storage\_mode\_type) | Storage replication type for the Recovery Services Vault. Use GeoRedundant together with backup\_vault\_cross\_region\_restore\_enabled = true for cross-region DR. | `string` | `"ZoneRedundant"` | no |
| <a name="input_default_share_level_permission"></a> [default\_share\_level\_permission](#input\_default\_share\_level\_permission) | Default share-level permission granted to ALL authenticated identities on the share. Defaults to Contributor: this is the sanctioned mechanism for an org-wide 'all employees' baseline, replacing a cloud-only/dynamic Entra 'all staff' group (which does NOT work for AD DS share-level RBAC — its SID isn't in the on-prem Kerberos ticket). NTFS ACLs still enforce per-folder access. Set to Reader or None for a stricter least-privilege posture (ISO 27001 A.8.2) and grant elevated access to specific groups via share\_level\_role\_assignments. | `string` | `"StorageFileDataSmbShareContributor"` | no |
| <a name="input_defender_override_subscription_settings_enabled"></a> [defender\_override\_subscription\_settings\_enabled](#input\_defender\_override\_subscription\_settings\_enabled) | Whether the per-storage-account Defender settings (malware scanning cap, sensitive data discovery) override the subscription-level Defender policy. Keep true to guarantee this module's security posture applies regardless of subscription defaults (ISO 27001 A.8.12). | `bool` | `true` | no |
| <a name="input_enable_backup"></a> [enable\_backup](#input\_enable\_backup) | Whether to enable Azure Backup for the Azure Files storage account. | `bool` | `true` | no |
| <a name="input_enable_defender_subscription_pricing"></a> [enable\_defender\_subscription\_pricing](#input\_enable\_defender\_subscription\_pricing) | Whether this module manages the subscription-level Defender for Storage plan (azurerm\_security\_center\_subscription\_pricing). This is a subscription-scoped singleton — set to false if Defender for Storage is already enabled by another Terraform configuration, another instance of this module, or Azure Policy, to avoid state conflicts. | `bool` | `true` | no |
| <a name="input_enable_private_endpoint"></a> [enable\_private\_endpoint](#input\_enable\_private\_endpoint) | Whether to provision a private endpoint (and its optional management lock) for the file sub-resource. Defaults to true. Set to false for accounts reached via the VNet service-endpoint rule (storage\_account\_subnet\_ids) or public access instead. When false, subnet\_id and private\_dns\_zone\_id are not required. | `bool` | `true` | no |
| <a name="input_enable_resource_locks"></a> [enable\_resource\_locks](#input\_enable\_resource\_locks) | Whether to enable resource locks for the Azure Files storage account and private endpoint. | `bool` | `true` | no |
| <a name="input_enable_sensitive_data_discovery"></a> [enable\_sensitive\_data\_discovery](#input\_enable\_sensitive\_data\_discovery) | Whether to enable sensitive data discovery in Azure Defender for Storage. | `bool` | `true` | no |
| <a name="input_ip_rules"></a> [ip\_rules](#input\_ip\_rules) | A list of public IP addresses to allow access to the Azure Files storage account. This is only applicable if public\_network\_access\_enabled is set to true. | `list(string)` | `[]` | no |
| <a name="input_log_analytics_retention_days"></a> [log\_analytics\_retention\_days](#input\_log\_analytics\_retention\_days) | Retention period in days for the Log Analytics Workspace. ISO 27001 A.8.15 recommends at least 365 days for audit log retention. | `number` | `365` | no |
| <a name="input_malware_scanning_cap_gb_per_month"></a> [malware\_scanning\_cap\_gb\_per\_month](#input\_malware\_scanning\_cap\_gb\_per\_month) | Monthly cap in GB for Defender for Storage malware scanning on upload. Set to 0 for unlimited (ISO 27001 A.8.12). | `number` | `5000` | no |
| <a name="input_private_dns_zone_id"></a> [private\_dns\_zone\_id](#input\_private\_dns\_zone\_id) | The resource ID of the private DNS zone for file.core.windows.net. Required only when enable\_private\_endpoint is true. | `string` | `null` | no |
| <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled) | Whether to allow public network access to the Azure Files storage account. Setting this to false will disable all public network access, including from the Azure portal and Azure Storage Explorer. This is a security best practice when using private endpoints. | `bool` | `false` | no |
| <a name="input_security_alert_email"></a> [security\_alert\_email](#input\_security\_alert\_email) | Email address for security alerts | `string` | n/a | yes |
| <a name="input_share_level_role_assignments"></a> [share\_level\_role\_assignments](#input\_share\_level\_role\_assignments) | Map of share-level SMB RBAC assignments. Each entry resolves an AAD group by display name and grants it the specified role on the storage account. Uses azuread\_groups (plural) — returns only object IDs, does not enumerate membership, so plan times stay fast. IMPORTANT: for AD DS auth (directory\_type = 'AD'), only on-prem AD security groups synced to Entra ID (Assigned membership) are honored — their SID must be present in the on-prem Kerberos ticket. Cloud-only/dynamic-membership groups are NOT matched and will silently fail. For an all-authenticated baseline, use default\_share\_level\_permission instead of a dynamic 'all staff' group. | <pre>map(object({<br>    group_display_name   = string<br>    role_definition_name = string<br>  }))</pre> | `{}` | no |
| <a name="input_shared_access_key_enabled"></a> [shared\_access\_key\_enabled](#input\_shared\_access\_key\_enabled) | Whether to allow access via storage account keys. Defaults to false (ISO 27001 A.8.5 — force Azure AD / Kerberos authentication only). Set to true if tooling requires key-based access (AzCopy --account-key, Azure Portal Storage Explorer, legacy scripts). | `bool` | `false` | no |
| <a name="input_soft_delete_retention_days"></a> [soft\_delete\_retention\_days](#input\_soft\_delete\_retention\_days) | The number of days that soft-deleted file shares, files, or directories are retained. Must be between 1 and 365. | `number` | `14` | no |
| <a name="input_storage_account_replication_type"></a> [storage\_account\_replication\_type](#input\_storage\_account\_replication\_type) | Replication type for the storage account. Use LRS in regions without availability zones, GRS for geo-redundancy independent of the backup vault. | `string` | `"ZRS"` | no |
| <a name="input_storage_account_subnet_ids"></a> [storage\_account\_subnet\_ids](#input\_storage\_account\_subnet\_ids) | List of subnet IDs allowed to access the storage account via VNet service endpoints. Used alongside the private endpoint. | `list(string)` | `[]` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | The ID of the subnet in which to create the private endpoint. Required only when enable\_private\_endpoint is true. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to the Azure Files storage account | `map(string)` | n/a | yes |
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | Resource ID of the storage account. |
| <a name="output_log_analytics_workspace_id"></a> [log\_analytics\_workspace\_id](#output\_log\_analytics\_workspace\_id) | Resource ID of the Log Analytics Workspace. Use this to add additional diagnostic sinks from the calling module. |
| <a name="output_private_endpoint_id"></a> [private\_endpoint\_id](#output\_private\_endpoint\_id) | Resource ID of the file storage private endpoint. Null when enable\_private\_endpoint is false. |
| <a name="output_storage_account_name"></a> [storage\_account\_name](#output\_storage\_account\_name) | Name of the storage account. Use for az CLI, AzCopy, or SDK references. |
| <a name="output_storage_account_principal_id"></a> [storage\_account\_principal\_id](#output\_storage\_account\_principal\_id) | Principal ID of the storage account's system-assigned managed identity. Assign Key Vault or other RBAC roles to this principal. |
<!-- END_TF_DOCS -->