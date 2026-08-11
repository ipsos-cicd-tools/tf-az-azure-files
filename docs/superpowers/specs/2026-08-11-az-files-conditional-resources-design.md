# Design: `az-files` conditional resource creation + bring-your-own-resource

**Date:** 2026-08-11
**Module:** `modules/az-files`
**Status:** Approved (pending written-spec review)

## Context

`modules/az-files` is a reusable, secure-by-default Azure Files module consumed by ~21
in-repo forks and a live UK deployment. Today its optional resources are gated by
independent `enable_*` boolean flags (all defaulting `true`), and related inputs are flat
top-level variables. Two things are awkward:

1. **No presence-based creation.** You must both provide inputs *and* remember the matching
   `enable_*` flag; a feature can be half-configured (inputs given, flag off, or vice-versa).
2. **No bring-your-own (BYO).** In hub-spoke / central-logging / central-backup setups the
   Log Analytics workspace, action group, or Recovery Services vault already exist, but the
   module always creates its own.

**Goal:** rework the module so each optional feature is created automatically when its inputs
are provided (and skipped when they aren't), and so a caller can pass an existing resource's
identifier to skip creation and wire dependents to it — without weakening the ISO 27001
secure-by-default posture for core security/monitoring.

## Design

### Core pattern (one shape for every optional feature)

Each optional feature is driven by up to three inputs, resolved in a single `locals` block:

- **Config object** (nullable) — the *presence signal*. Non-null ⇒ create.
- **`existing_*` input** (nullable) — *BYO*. Provided ⇒ skip creation, wire dependents to it.
- **`enable_*` override** (tri-state `bool`, default `null`) — `null` = auto (infer from
  presence), `true` = force on, `false` = force off. Preserves backward-compatible control.

```hcl
locals {
  create_private_endpoint = coalesce(var.enable_private_endpoint, var.private_endpoint != null)
  create_backup           = coalesce(var.enable_backup, var.backup != null || var.existing_recovery_services_vault != null)
  create_vault            = local.create_backup && var.existing_recovery_services_vault == null
  create_law              = var.existing_log_analytics_workspace_id == null
  create_action_group     = var.existing_action_group_id == null
  create_defender_sub     = coalesce(var.enable_defender_subscription_pricing, false) # opt-in singleton
  create_ad               = var.active_directory != null

  law_id          = coalesce(var.existing_log_analytics_workspace_id, one(azurerm_log_analytics_workspace.storage_logs[*].id))
  action_group_id = coalesce(var.existing_action_group_id, one(azurerm_monitor_action_group.storage_security_alerts[*].id))
  vault_name      = var.existing_recovery_services_vault != null ? var.existing_recovery_services_vault.name : one(azurerm_recovery_services_vault.backup_vault[*].name)
  vault_rg        = coalesce(try(var.existing_recovery_services_vault.resource_group_name, null), var.az_files_storage_account_rg_name)
}
```

### Input interface (grouped optional objects)

| New input | Type / default | Replaces | Effect |
|---|---|---|---|
| `private_endpoint` | `object({ subnet_id, private_dns_zone_id })` / `null` | `subnet_id`, `private_dns_zone_id` | non-null ⇒ create PE + PE lock + PE-delete alert |
| `backup` | `object({ policy = optional(object({…}), <defaults>), vault = optional(object({ storage_mode_type, public_network_access_enabled, cross_region_restore_enabled })) })` / `null` | `backup_policy`, `backup_vault_*` | non-null ⇒ create vault + policy + vault diagnostics |
| `active_directory` | `object({ domain_name, domain_guid, domain_sid, forest_name, netbios_domain_name, storage_sid })` / `null` | six `ad_*` vars | non-null ⇒ AD/Kerberos auth block |
| `existing_log_analytics_workspace_id` | `string` / `null` | — | skip LAW; point all diagnostics at it |
| `existing_action_group_id` | `string` / `null` | — | skip action group; route all alerts to it |
| `existing_recovery_services_vault` | `object({ name, resource_group_name = optional(string) })` / `null` | — | skip vault; attach backup policy to it |

**Why the vault BYO is name+RG, not an ID:** `azurerm_backup_policy_file_share` references the
vault by `recovery_vault_name` + `resource_group_name`, so a bare ID can't be wired in without
a lookup. LAW and action group *are* consumed by ID downstream, so those stay `existing_*_id`.

**Tri-state override flags** (change `bool` default `true` → `bool` default `null`):
`enable_private_endpoint`, `enable_backup`, `enable_defender_subscription_pricing`.
`enable_resource_locks` stays a plain `bool` (default `true`) — locks have no config object to
key on. `enable_sensitive_data_discovery` stays as-is (a per-account Defender setting, not a
resource gate).

### Creation matrix

| Resource(s) | New condition |
|---|---|
| storage account, per-account Defender, both diagnostic settings, 3 metric alerts, SA-delete + key-regen activity alerts | **always** |
| Log Analytics workspace | `count = local.create_law` |
| action group | `count = local.create_action_group` |
| private endpoint, PE lock, PE-delete activity alert | `local.create_private_endpoint` |
| backup vault + vault diagnostics | `local.create_vault` |
| backup policy | `local.create_backup` (wired to `local.vault_name` / `local.vault_rg`) |
| Defender subscription pricing | `local.create_defender_sub` (**opt-in, default off**) |
| AD auth block | `local.create_ad` |
| share RBAC (`azuread_groups` + role assignments) | `for_each` over `share_level_role_assignments` (unchanged) |

Diagnostics use `log_analytics_workspace_id = local.law_id`; all alerts use
`action_group_id = local.action_group_id`.

### Validation changes

- Old cross-variable validations on `subnet_id` / `private_dns_zone_id` are removed (those
  variables are gone; the object's required fields enforce completeness intrinsically).
- `security_alert_email` becomes optional (`default null`) with a validation: **required only
  when `existing_action_group_id == null`** (i.e. the module creates the action group).
- Backup cross-region-restore precondition stays, reading `backup.vault.*`.
- Terraform `required_version` stays `>= 1.9.0` (cross-variable validation already in use).

### Provider pin (azurerm 4.x)

`providers.tf` currently sets `version = ">4.3.0"`, which **permits azurerm 5.x** (latest is
5.0.1) — a latent breaking-upgrade risk (5.x removes `soft_delete_enabled` on the recovery
vault, etc.). Tighten to **`>= 4.3.0, < 5.0.0`** to stay on 4.x per decision. `azuread` stays
`>= 2.0.0`.

### Validation against Terraform MCP + Microsoft recommendations

Confirmed via the Terraform registry MCP (azurerm 4.x docs) and Azure best-practices tooling:

- **Syntax (4.x):** `azure_files_authentication.active_directory` requires `domain_name` and
  `domain_guid`, and `domain_sid`/`storage_sid`/`forest_name`/`netbios_domain_name` are all
  required when `directory_type = "AD"` → the grouped `active_directory` object marks all six
  required. `optional()` object defaults, `coalesce`, `one`, `try` are core language features
  available at `>= 1.9`. Storage/SMB/network_rules arguments are unchanged in 4.x.
- **Microsoft alignment (kept always-on):** TLS 1.2, public access off by default, private
  endpoint, **per-account Defender for Storage always-on** (malware scan + sensitive-data
  discovery with `override_subscription_settings_enabled`), share soft-delete, diagnostics to
  Log Analytics, ZRS default. No change to the secure baseline.
- **Deliberate deviations (documented, user-approved):** Azure **Backup** and
  **subscription-level Defender pricing** move from default-on to opt-in. Microsoft recommends
  both enabled; `MIGRATION.md` must call this out and give the restore-old-behavior recipe
  (`backup = {}` and `enable_defender_subscription_pricing = true`). Per-account Defender
  remaining always-on preserves account-level threat protection regardless of the subscription
  toggle.

### Outputs

Keep `id`, `storage_account_name`, `storage_account_principal_id`, `private_endpoint_id`,
`log_analytics_workspace_id` (already `coalesce`-safe). **Add** `recovery_services_vault_id`
(created vault or `null`) and `action_group_id` (`local.action_group_id`).

## Migration (breaking → major version bump)

Renaming flat inputs into objects is breaking. Deliverables:

- `MIGRATION.md` with an old→new mapping table (e.g. `subnet_id` + `private_dns_zone_id` →
  `private_endpoint = { subnet_id, private_dns_zone_id }`; `backup_policy` → `backup.policy`;
  `ad_*` → `active_directory`; new `existing_*` inputs).
- **Default-behavior changes to call out loudly:** backup and Defender-subscription-pricing
  move from default-on to **opt-in**. To retain old behavior: provide `backup = {}` (uses the
  built-in default policy) and set `enable_defender_subscription_pricing = true`.
- Regenerate `modules/az-files/README.md` (terraform-docs), update root `README.md` and
  `docs/az-files-module-update-handoff.md`. No `examples/` dir and no `az-files-nait`
  references exist, so the rename is self-contained to this module + docs.
- Major version tag via the semantic-release workflow (commit with `BREAKING CHANGE:` footer).

## Verification

1. `terraform fmt -check -recursive` and `terraform validate` (Terraform 1.13.4) on
   `modules/az-files`.
2. `terraform plan` against representative fixtures:
   - **Minimal:** only required inputs → no PE, no backup, no AD, no subscription Defender;
     core security/monitoring present.
   - **Full create:** `private_endpoint`, `backup`, `active_directory`, `share_level_role_assignments`
     provided → all resources created.
   - **BYO:** `existing_log_analytics_workspace_id`, `existing_action_group_id`,
     `existing_recovery_services_vault` set → those three not created; diagnostics/alerts/backup
     policy wired to the provided identifiers.
   - **Override:** `private_endpoint` provided but `enable_private_endpoint = false` → PE skipped.
3. Confirm no provider errors on the `one()`/`coalesce` wiring and that
   `security_alert_email` omission is accepted only alongside `existing_action_group_id`.
