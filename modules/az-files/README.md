<!-- BEGIN_TF_DOCS -->
## Usage
Basic usage of this module is as follows:
```
module "az-files" {
  source  = "git::https://github.com/ipsos-cicd-tools/<repo name>//modules/az-files?ref=<version number>"
  
  ## Required Variables ##
  az_files_storage_account_name  = 
  az_files_storage_account_rg_location  = 
  az_files_storage_account_rg_name  = 
  security_alert_email  = 
  subnet_id  = 
  tags  = 
  
  ## Optional Variables ##
  ad_domain_guid  =   null
  ad_domain_name  =   null
  ad_domain_sid  =   null
  ad_forest_name  =   null
  ad_netbios_domain_name  =   null
  ad_storage_sid  =   null
  backup_policy  =   {
  "frequency": "Daily",
  "retention_daily": {
    "count": 30
  },
  "retention_monthly": {
    "count": 12,
    "weekdays": [
      "Sunday"
    ],
    "weeks": [
      "First"
    ]
  },
  "retention_weekly": {
    "count": 12,
    "weekdays": [
      "Sunday"
    ]
  },
  "retention_yearly": {
    "count": 7,
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
  enable_backup  =   true
  enable_resource_locks  =   true
  enable_sensitive_data_discovery  =   true
  ip_rules  =   []
  private_dns_zone_id  =   null
  public_network_access_enabled  =   false
  soft_delete_retention_days  =   14
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
| [azurerm_monitor_diagnostic_setting.file_service](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_monitor_diagnostic_setting.storage_account](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_monitor_metric_alert.auth_failures](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert) | resource |
| [azurerm_monitor_metric_alert.high_delete_operations](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert) | resource |
| [azurerm_monitor_metric_alert.high_error_rate](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert) | resource |
| [azurerm_private_endpoint.default_storage_pe](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_recovery_services_vault.backup_vault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/recovery_services_vault) | resource |
| [azurerm_security_center_storage_defender.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/security_center_storage_defender) | resource |
| [azurerm_security_center_subscription_pricing.defender_storage](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/security_center_subscription_pricing) | resource |
| [azurerm_storage_account.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ad_domain_guid"></a> [ad\_domain\_guid](#input\_ad\_domain\_guid) | The domain GUID for Active Directory integration. | `string` | `null` | no |
| <a name="input_ad_domain_name"></a> [ad\_domain\_name](#input\_ad\_domain\_name) | The primary domain name for Active Directory integration. | `string` | `null` | no |
| <a name="input_ad_domain_sid"></a> [ad\_domain\_sid](#input\_ad\_domain\_sid) | The domain SID for Active Directory integration. | `string` | `null` | no |
| <a name="input_ad_forest_name"></a> [ad\_forest\_name](#input\_ad\_forest\_name) | The forest name for Active Directory integration. | `string` | `null` | no |
| <a name="input_ad_netbios_domain_name"></a> [ad\_netbios\_domain\_name](#input\_ad\_netbios\_domain\_name) | The NetBIOS domain name for Active Directory integration. | `string` | `null` | no |
| <a name="input_ad_storage_sid"></a> [ad\_storage\_sid](#input\_ad\_storage\_sid) | The security identifier (SID) for the storage account in Active Directory. This is typically obtained after the storage account is domain joined. | `string` | `null` | no |
| <a name="input_az_files_storage_account_name"></a> [az\_files\_storage\_account\_name](#input\_az\_files\_storage\_account\_name) | The name of the Azure Files storage account | `string` | n/a | yes |
| <a name="input_az_files_storage_account_rg_location"></a> [az\_files\_storage\_account\_rg\_location](#input\_az\_files\_storage\_account\_rg\_location) | The location of the resource group in which to create the Azure Files storage account | `string` | n/a | yes |
| <a name="input_az_files_storage_account_rg_name"></a> [az\_files\_storage\_account\_rg\_name](#input\_az\_files\_storage\_account\_rg\_name) | The name of the resource group in which to create the Azure Files storage account | `string` | n/a | yes |
| <a name="input_backup_policy"></a> [backup\_policy](#input\_backup\_policy) | A map of backup policy settings for the Azure Files storage account | <pre>object({<br>    frequency = string<br>    time      = string<br>    retention_daily = object({<br>      count = number<br>    })<br>    retention_weekly = object({<br>      count    = number<br>      weekdays = list(string)<br>    })<br>    retention_monthly = object({<br>      count    = number<br>      weekdays = list(string)<br>      weeks    = list(string)<br>    })<br>    retention_yearly = object({<br>      count    = number<br>      weekdays = list(string)<br>      weeks    = list(string)<br>      months   = list(string)<br>    })<br>  })</pre> | <pre>{<br>  "frequency": "Daily",<br>  "retention_daily": {<br>    "count": 30<br>  },<br>  "retention_monthly": {<br>    "count": 12,<br>    "weekdays": [<br>      "Sunday"<br>    ],<br>    "weeks": [<br>      "First"<br>    ]<br>  },<br>  "retention_weekly": {<br>    "count": 12,<br>    "weekdays": [<br>      "Sunday"<br>    ]<br>  },<br>  "retention_yearly": {<br>    "count": 7,<br>    "months": [<br>      "January"<br>    ],<br>    "weekdays": [<br>      "Sunday"<br>    ],<br>    "weeks": [<br>      "First"<br>    ]<br>  },<br>  "time": "23:00"<br>}</pre> | no |
| <a name="input_enable_backup"></a> [enable\_backup](#input\_enable\_backup) | Whether to enable Azure Backup for the Azure Files storage account. | `bool` | `true` | no |
| <a name="input_enable_resource_locks"></a> [enable\_resource\_locks](#input\_enable\_resource\_locks) | Whether to enable resource locks for the Azure Files storage account and private endpoint. | `bool` | `true` | no |
| <a name="input_enable_sensitive_data_discovery"></a> [enable\_sensitive\_data\_discovery](#input\_enable\_sensitive\_data\_discovery) | Whether to enable sensitive data discovery in Azure Defender for Storage. | `bool` | `true` | no |
| <a name="input_ip_rules"></a> [ip\_rules](#input\_ip\_rules) | A list of public IP addresses to allow access to the Azure Files storage account. This is only applicable if public\_network\_access\_enabled is set to true. | `list(string)` | `[]` | no |
| <a name="input_private_dns_zone_id"></a> [private\_dns\_zone\_id](#input\_private\_dns\_zone\_id) | The resource ID of the private DNS zone for file.core.windows.net | `string` | `null` | no |
| <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled) | Whether to allow public network access to the Azure Files storage account. Setting this to false will disable all public network access, including from the Azure portal and Azure Storage Explorer. This is a security best practice when using private endpoints. | `bool` | `false` | no |
| <a name="input_security_alert_email"></a> [security\_alert\_email](#input\_security\_alert\_email) | Email address for security alerts | `string` | n/a | yes |
| <a name="input_soft_delete_retention_days"></a> [soft\_delete\_retention\_days](#input\_soft\_delete\_retention\_days) | The number of days that soft-deleted file shares, files, or directories are retained. Must be between 1 and 365. | `number` | `14` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | A list of subnet IDs to associate with the Azure Files storage account | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to the Azure Files storage account | `map(string)` | n/a | yes |
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | n/a |
<!-- END_TF_DOCS -->