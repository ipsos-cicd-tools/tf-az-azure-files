# Terraform Azure Files Module

This module provisions a production-ready Azure Files storage account with a comprehensive set of security, networking, backup, and monitoring controls.

### Storage

StorageV2 storage account with Zone-Redundant Storage (ZRS), large file share support, and infrastructure encryption enabled
SMB shares configured for SMB 3.0/3.1.1 with Kerberos (AES-256) and NTLMv2 authentication
Optional Active Directory (Kerberos) integration for identity-based file access

### Networking

Private endpoint for the file sub-resource, with a custom NIC name and private DNS zone group registration
Public network access disabled by default; IP allowlisting available for exceptions

### Backup

Azure Recovery Services Vault (Zone-Redundant) with a configurable backup policy supporting daily, weekly, monthly, and yearly retention

### Security

Microsoft Defender for Storage with malware scanning (up to 5 TB/month) and optional sensitive data discovery
Soft delete for file shares (configurable retention, 1–365 days)
Optional CanNotDelete resource locks on the storage account and private endpoint

### Monitoring & Alerting

Log Analytics Workspace with 90-day retention
Diagnostic settings for storage account metrics (Transaction, Capacity) and file service audit logs (Read, Write, Delete)
Monitor alerts for:
High error rates (potential attack indicator)
Unusual deletion activity (potential data loss)
Authentication failures (unauthorized access attempts)
Action group sending email alerts to a configurable security address

### Terraform Outputs

`id` - Resource ID of the storage account


## Compatibility
Any compatability concerns go here

## Useage 
More specific useage examples can be found in the ***modules*** folder under the corresponding module name

```
module "module_name" {
source  = "git::https://github.com/ipsos-cicd-tools/tf-az-azure-files//modules/az-files?ref=<version number>"

## Required Variables

az_files_storage_account_name  = 
az_files_storage_account_rg_name  = 
az_files_storage_account_rg_location  = 
tags =
subnet_id =
security_alert_email =

## Optional Variables (default values shown)

private_dns_zone_id = null
backup_policy = {
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
ad_domain_name = null
ad_domain_guid = null
ad_domain_sid = null
ad_forest_name = null
ad_netbios_domain_name = null
ad_storage_sid = null
enable_backup = true
enable_resource_locks = true
soft_delete_retention_days = 14
enable_sensitive_data_discovery = true
public_network_access_enabled = false
ip_rules = []
}
```
<br>
<br>
<br>

# Committing to a GitHub Repository Using Semantic Versioning

![GitHub](https://img.shields.io/badge/GitHub-Semantic%20Versioning-brightgreen)

Semantic Versioning is a versioning scheme that helps maintainers and users of a software project understand the nature of changes between versions. When committing to a GitHub repository that follows Semantic Versioning, it's essential to adhere to certain guidelines to maintain version consistency and clarity.

## Semantic Versioning Basics

Semantic Versioning follows a `MAJOR.MINOR.PATCH` format, where:

- ![Major](https://img.shields.io/badge/MAJOR-red)![1.0.0](https://img.shields.io/badge/1.0.0-grey) indicates incompatible changes (backwards-incompatible).
- ![Minor](https://img.shields.io/badge/MINOR-yellow)![0.1.0](https://img.shields.io/badge/0.1.0-grey) denotes new features that are backward-compatible.
- ![Patch](https://img.shields.io/badge/PATCH-brightgreen)![0.0.1](https://img.shields.io/badge/0.0.1-grey) represents bug fixes and backward-compatible improvements.

## Commit Message Conventions

To maintain SemVer in your GitHub repository, commit messages should follow a specific convention. Each commit message should include:

1. **Type**: A one-word type that describes the nature of the change. Common types include:
   - ![Breaking_Change](https://img.shields.io/badge/BREAKING__CHANGE:-red) A major change that would break existing deployments (increment ![MAJOR](https://img.shields.io/badge/MAJOR-red)).
   - ![Feature](https://img.shields.io/badge/feat:-yellow) A new module introduced (increment ![MINOR](https://img.shields.io/badge/MINOR-yellow)).
   - ![Bug Fix](https://img.shields.io/badge/fix:-brightgreen) A bug fix (increment ![PATCH](https://img.shields.io/badge/PATCH-brightgreen)).
   - ![Documentation](https://img.shields.io/badge/docs:-lightgrey) Documentation updates (increment ![NONE](https://img.shields.io/badge/none-lightgrey)).

2. **Description**: A brief, concise description of the change.

3. **Jira Task** (Optional): Add the task ID to the related Jira task or epic.

### Example Commit Message
``` 
git commit -m "fix: added description to resource TST-34"