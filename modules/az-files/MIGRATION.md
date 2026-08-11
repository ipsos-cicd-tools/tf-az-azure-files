# Migration guide — az-files v1 → v2 (conditional resources + bring-your-own)

**This is a breaking (major) release.** The module now creates optional resources based on
the *presence of their configuration* rather than standalone `enable_*` booleans, and it can
reuse externally-created resources via `existing_*` inputs. Flat inputs have been grouped into
optional objects.

## ⚠️ Default-behaviour changes (read first)

Two features that were **on by default** are now **opt-in**:

| Feature | Old default | New default | Keep old behaviour |
|---|---|---|---|
| Azure Backup (vault + policy) | created | **not created** | pass `backup = {}` (uses the default schedule) |
| Subscription-level Defender plan | managed (`true`) | **not managed** (`false`) | set `enable_defender_subscription_pricing = true` |

Per-account Defender for Storage (malware scanning + sensitive-data discovery) remains **always
on** — the account-level threat protection is unchanged. The subscription-level plan is a
subscription-scoped singleton and is now opt-in to avoid conflicts when it is already managed by
Azure Policy or another module instance.

Everything else that was always-on stays always-on: TLS 1.2, public access off, per-account
Defender, share soft-delete, diagnostics, metric/activity-log alerts.

## Input mapping (old → new)

### Private endpoint
```hcl
# OLD
enable_private_endpoint = true
subnet_id               = "/subscriptions/.../subnets/snet-files"
private_dns_zone_id     = "/subscriptions/.../privateDnsZones/privatelink.file.core.windows.net"

# NEW — presence of the object creates the PE
private_endpoint = {
  subnet_id           = "/subscriptions/.../subnets/snet-files"
  private_dns_zone_id = "/subscriptions/.../privateDnsZones/privatelink.file.core.windows.net"
}
# (omit private_endpoint entirely to NOT create one)
```

### Azure Backup
```hcl
# OLD
enable_backup                             = true
backup_policy                             = { frequency = "Daily", time = "23:00", retention_daily = { count = 14 }, ... }
backup_timezone                           = "UTC"
backup_vault_storage_mode_type            = "ZoneRedundant"
backup_vault_public_network_access_enabled = false
backup_vault_cross_region_restore_enabled  = false

# NEW — one object; every field is optional and defaults to the old hardened values
backup = {
  policy = { time = "23:00", retention_daily = { count = 14 } }  # partial override; rest defaulted
  vault  = { storage_mode_type = "ZoneRedundant" }
}
# backup = {}  keeps the exact previous default policy/vault
```

### On-prem AD DS
```hcl
# OLD
ad_domain_name         = "corp.example.com"
ad_domain_guid         = "..."
ad_domain_sid          = "..."
ad_forest_name         = "corp.example.com"
ad_netbios_domain_name = "CORP"
ad_storage_sid         = "..."

# NEW — presence of the object enables AD DS; all six fields required
active_directory = {
  domain_name         = "corp.example.com"
  domain_guid         = "..."
  domain_sid          = "..."
  forest_name         = "corp.example.com"
  netbios_domain_name = "CORP"
  storage_sid         = "..."
}
```

## New: bring-your-own (externally-created) resources

Supply an identifier to skip creation and wire dependents to the existing resource:

```hcl
# Send diagnostics to a central workspace instead of creating one
existing_log_analytics_workspace_id = "/subscriptions/.../workspaces/central-logs"

# Route all alerts to a shared action group instead of creating one
existing_action_group_id = "/subscriptions/.../actionGroups/central-sec-alerts"
# (security_alert_email is then not required)

# Attach the backup policy to a central vault instead of creating one
# (name + RG, because the backup policy references the vault by name, not ID)
existing_recovery_services_vault = {
  name                = "central-rsv"
  resource_group_name = "rg-backup"   # optional; defaults to the storage account's RG
}
```

## Override flags (tri-state)

`enable_private_endpoint` and `enable_backup` are now tri-state:

- `null` (default) — **auto**: create when the matching config object is provided.
- `true` — force on (private endpoint requires `private_endpoint`; backup falls back to the
  default policy if `backup` is null).
- `false` — force off even if the config object is provided.

`enable_resource_locks` (default `true`) and `enable_sensitive_data_discovery` (default `true`)
are unchanged plain booleans.

## New outputs

`recovery_services_vault_id` and `action_group_id` are now exported.
`log_analytics_workspace_id` now returns the existing workspace ID when one is supplied.

## Provider / Terraform requirements

- `azurerm` is pinned to **`>= 4.3.0, < 5.0.0`** (previously `> 4.3.0`, which allowed 5.x).
- Terraform **`>= 1.9.0`** (cross-variable input validation).
