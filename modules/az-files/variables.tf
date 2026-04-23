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