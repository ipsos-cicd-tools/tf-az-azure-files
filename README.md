# Terraform Azure Files Module

This module provisions a production-ready Azure Files storage account with a comprehensive set of security, networking, backup, and monitoring controls.

### Storage

StorageV2 storage account with Zone-Redundant Storage (ZRS), large file share support, and infrastructure encryption enabled
SMB shares configured for SMB 3.0/3.1.1 with Kerberos (AES-256) and NTLMv2 authentication
Optional Active Directory (Kerberos) integration for identity-based file access

### Networking

Optional private endpoint for the file sub-resource — created when the `private_endpoint` object is provided — with a custom NIC name and private DNS zone group registration
Public network access disabled by default; IP allowlisting and VNet service-endpoint subnets available for exceptions

### Backup

Optional Azure Recovery Services Vault (Zone-Redundant) with a configurable backup policy supporting daily, weekly, monthly, and yearly retention — created when the `backup` object is provided, or attach the policy to an existing vault via `existing_recovery_services_vault`

### Security

Per-account Microsoft Defender for Storage (always on) with malware scanning (up to 5 TB/month) and optional sensitive data discovery; the subscription-level Defender plan is opt-in via `enable_defender_subscription_pricing`
Soft delete for file shares (configurable retention, 1–365 days)
Optional CanNotDelete resource locks on the storage account and private endpoint

### Monitoring & Alerting

Log Analytics Workspace with 365-day default retention — or bring your own via `existing_log_analytics_workspace_id`
Diagnostic settings for storage account metrics (Transaction, Capacity) and file service audit logs (Read, Write, Delete)
Monitor alerts for:
High error rates (potential attack indicator)
Unusual deletion activity (potential data loss)
Authentication failures (unauthorized access attempts)
Action group sending email alerts to a configurable security address

### Terraform Outputs

- `id` — Resource ID of the storage account
- `storage_account_name` — Name of the storage account (for az CLI, AzCopy, SDK)
- `storage_account_principal_id` — Principal ID of the system-assigned managed identity
- `private_endpoint_id` — Resource ID of the private endpoint (null when not created)
- `log_analytics_workspace_id` — Workspace in use (created one, or `existing_log_analytics_workspace_id`)
- `recovery_services_vault_id` — Vault created by the module (null when backup is off or a BYO vault is used)
- `action_group_id` — Action group in use (created one, or `existing_action_group_id`)


## Module scope — what callers must provision themselves

This module provisions the storage account and surrounding infrastructure but **not the file shares**:

- Create `azurerm_storage_share` resources in your calling configuration (share names are caller-specific).
- To back up those shares, also create `azurerm_backup_protected_file_share` in the calling configuration, referencing the vault and policy this module creates (provide the `backup` object).
- When you provide `private_endpoint`, both `subnet_id` and `private_dns_zone_id` are required — without DNS zone registration SMB clients cannot resolve the storage account and mounts fail silently.

## Compatibility

- Terraform `>= 1.9.0`
- azurerm provider `>= 4.3.0, < 5.0.0` (pinned to 4.x)
- azuread provider `>= 2.0.0`

> **Upgrading from v1.x?** The input interface changed (flat `subnet_id`/`backup_policy`/`ad_*` were grouped into the `private_endpoint`/`backup`/`active_directory` objects, and backup + subscription Defender are now opt-in). See `modules/az-files/MIGRATION.md`.

## Usage

Consume the module by Git source, pinned to a released version tag. Optional features are created
based on the **presence of their config object** (`private_endpoint`, `backup`, `active_directory`);
`existing_*` inputs let you reuse externally-created resources instead of creating new ones.

### Minimal example

```hcl
module "az_files" {
  source = "git::https://github.com/ipsos-cicd-tools/tf-az-azure-files//modules/az-files?ref=2.0.0"

  az_files_storage_account_name        = "azemeaukfs01"
  az_files_storage_account_rg_name     = "rg-uk-files"
  az_files_storage_account_rg_location = "uksouth"
  tags                                 = { environment = "prod", owner = "platform-team" }
  security_alert_email                 = "secops@example.com"
}
```

This creates the storage account plus the always-on baseline (per-account Defender, Log Analytics
workspace, diagnostics, action group, metric/activity-log alerts). Private endpoint, backup, and
AD DS are **not** created unless you supply their config objects.

### Full example — every variable with sample values

```hcl
module "az_files" {
  source = "git::https://github.com/ipsos-cicd-tools/tf-az-azure-files//modules/az-files?ref=2.0.0"

  # ---- Required ----
  az_files_storage_account_name        = "azemeaukfs01"
  az_files_storage_account_rg_name     = "rg-uk-files"
  az_files_storage_account_rg_location = "uksouth"
  tags = {
    environment = "prod"
    costcenter  = "12345"
    owner       = "platform-team"
  }
  # Required unless existing_action_group_id is set (see BYO below)
  security_alert_email = "secops@example.com"

  # ---- Optional features (created only when the object is provided) ----

  # Private endpoint (recommended for prod). Omit to skip.
  private_endpoint = {
    subnet_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet-uk/subnets/snet-files"
    private_dns_zone_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dns/providers/Microsoft.Network/privateDnsZones/privatelink.file.core.windows.net"
  }

  # On-prem AD DS (SMB Kerberos). Omit for no AD integration. All six fields required together.
  active_directory = {
    domain_name         = "corp.example.com"
    domain_guid         = "11111111-2222-3333-4444-555555555555"
    domain_sid          = "S-1-5-21-1111111111-2222222222-3333333333"
    forest_name         = "corp.example.com"
    netbios_domain_name = "CORP"
    storage_sid         = "S-1-5-21-1111111111-2222222222-3333333333-4444" # use the DEPLOYED SA's SID
  }

  # Azure Backup. `backup = {}` uses the hardened defaults below. Omit entirely to skip backup.
  # Every field is optional; values shown are the module defaults.
  backup = {
    policy = {
      timezone          = "GMT Standard Time"
      frequency         = "Daily"
      time              = "23:00"
      retention_daily   = { count = 14 }
      retention_weekly  = { count = 4, weekdays = ["Sunday"] }
      retention_monthly = { count = 3, weekdays = ["Sunday"], weeks = ["First"] }
      retention_yearly  = { count = 3, weekdays = ["Sunday"], weeks = ["First"], months = ["January"] }
    }
    vault = {
      storage_mode_type             = "ZoneRedundant" # LocallyRedundant | ZoneRedundant | GeoRedundant
      public_network_access_enabled = false
      cross_region_restore_enabled  = false           # requires storage_mode_type = GeoRedundant
    }
  }

  # ---- Bring-your-own: reuse externally-created resources (skip creation) ----
  existing_log_analytics_workspace_id = null # e.g. "/subscriptions/.../workspaces/central-logs"
  existing_action_group_id            = null # e.g. "/subscriptions/.../actionGroups/central-sec"
  existing_recovery_services_vault    = null # e.g. { name = "central-rsv", resource_group_name = "rg-backup" }

  # ---- Tri-state overrides (null = auto from presence, true = force on, false = force off) ----
  enable_private_endpoint = null
  enable_backup           = null

  # Subscription-scoped Defender plan (singleton). Opt-in — leave false when another
  # config/module/Azure Policy already manages it. Per-account Defender is always on.
  enable_defender_subscription_pricing = false

  # ---- Security / posture toggles (defaults shown) ----
  enable_resource_locks                           = true
  enable_sensitive_data_discovery                 = true
  defender_override_subscription_settings_enabled = true
  public_network_access_enabled                   = false
  shared_access_key_enabled                       = false   # ⚠ true breaks Azure AD/Kerberos-only posture (allows account keys)
  ip_rules                                        = []       # e.g. ["203.0.113.10"]
  storage_account_subnet_ids                      = []       # service-endpoint subnets; needs Microsoft.Storage SE + vnet >= 1.0.5
  allowed_copy_scope                              = "AAD"    # null | "AAD" | "PrivateLink"
  storage_account_replication_type                = "ZRS"    # LRS | ZRS | GRS
  soft_delete_retention_days                      = 14       # 1–365

  # ---- Share-level SMB RBAC ----
  # Baseline permission for ALL authenticated identities (org-wide; NTFS ACLs refine per-folder).
  default_share_level_permission = "StorageFileDataSmbShareContributor" # None | ...Reader | ...Contributor | ...ElevatedContributor
  # Grant specific groups a role. Each display name must resolve to EXACTLY one Entra group.
  share_level_role_assignments = {
    admins = {
      group_display_name   = "az-uk-azfiles-admins"
      role_definition_name = "Storage File Data SMB Share Elevated Contributor"
    }
    users = {
      group_display_name   = "MDM-USR-GB-United_Kingdom-Users"
      role_definition_name = "Storage File Data SMB Share Contributor"
    }
  }

  # ---- Monitoring thresholds & Defender cap (defaults shown) ----
  log_analytics_retention_days      = 365  # 30–730 (only when the module creates its own workspace)
  alert_threshold_high_errors       = 100
  alert_threshold_high_deletes      = 50
  alert_threshold_auth_failures     = 20
  malware_scanning_cap_gb_per_month = 5000 # 0 = unlimited
}
```

> Per-variable reference documentation (auto-generated by terraform-docs) lives in
> [`modules/az-files/README.md`](modules/az-files/README.md).
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