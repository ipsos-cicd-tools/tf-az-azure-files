# Handoff: Roll local `az-files` changes UP into `tf-az-azure-files` (v1.0.3 → v1.0.4)

**Date**: 2026-07-23
**Goal**: Contribute the local module's divergences upstream so `ipsos-cicd-tools/tf-az-azure-files` can fully replace the local `modules/az-files` fork. Then migrate all Azure Files accounts/subscriptions to consume the remote module by version tag.
**Remote repo**: `ipsos-cicd-tools/tf-az-azure-files` @ `1.0.3`, module path `modules/az-files/`
**Local module**: `C:\Mihai\az-ipsos-uk\modules\az-files\`
**Verified**: 2026-07-23 against the actual `1.0.3` source (`main.tf`, `variables.tf`, `outputs.tf`, `providers.tf`) fetched from GitHub. All §3/§4/§8 claims confirmed against real source unless flagged otherwise.
**Updated 2026-07-28**: added brownfield `terraform import` requirements (§6.6), subnet service-endpoint + vnet-module dependency (§6.7), and reconciled `enable_defender_subscription_pricing` / `azuread_groups` changes from the `azemeaukfs02` rollout (PRs #14, #15).

---

## 0. ⚠️ Critical migration regression — `default_share_level_permission`

Remote v1.0.3 defaults `default_share_level_permission = "StorageFileDataSmbShareElevatedContributor"` (variables.tf, with a validation block). This is the **exact permission this project deliberately moved away from** — the current design is `Reader` as the fallback plus explicit per-group RBAC.

Because the role assignments are *also* not in remote yet (§3.1), a naive migration would **regress security twice**: every unassigned identity would fall back to ElevatedContributor, and the explicit group grants would disappear.

**On every migration you MUST**: set `default_share_level_permission = "StorageFileDataSmbShareReader"` in the caller, AND ensure the rolled-up role assignments (§3.1) exist in the module version you consume. Do not migrate to a plain v1.0.3.

---

## 1. TL;DR

The local module is ahead of v1.0.3 in a few places and behind it in many. To make the remote module a drop-in replacement everywhere:

1. **Add the local-only capabilities to the remote module** (§3) — this is the actual upstream work. Without these, migrating breaks the UK stack.
2. **Confirm the remote already covers everything else the local module does** (§4) — it mostly does; those become "free" once you migrate.
3. **Cut `tf-az-azure-files` v1.0.4** with the additions (§5).
4. **Migrate each consuming stack** to `source = git::…//modules/az-files?ref=1.0.4`, translating tfvars and running `state mv` where resource addresses change (§6).

The single biggest design decision (§3.1): the local hardcodes **three specific AAD group role assignments**. Different accounts/countries use different groups, so upstream this must become a **parameterised map**, not three fixed blocks.

---

## 2. Orientation: which way each difference flows

| Category | Direction | Section |
|---|---|---|
| Local has it, remote doesn't | **Roll UP into remote** (blocks migration otherwise) | §3 |
| Remote has it, local doesn't | Already upstream — local gains it on migration | §4 |
| Both have it, values differ | Decide the remote default / parameterise | §4 |

---

## 3. Roll UP into `tf-az-azure-files` (local-only — MUST be added upstream)

These exist only in the local module. If they aren't added to the remote module, migrating the UK stack (and any other AD + RBAC stack) loses functionality.

### 3.1 AAD group share-level RBAC assignments — **needs redesign for reuse**

Local (fixed, UK-specific):

| Resource | Local name | Role |
|---|---|---|
| `data.azuread_groups` | `all_employees` | — |
| `data.azuread_groups` | `admins` | — |
| `data.azuread_groups` | `users` | — |
| `azurerm_role_assignment` | `all_employees_contributor` | Storage File Data SMB Share Contributor |
| `azurerm_role_assignment` | `admins_elevated_contributor` | Storage File Data SMB Share Elevated Contributor |
| `azurerm_role_assignment` | `users_contributor` | Storage File Data SMB Share Contributor |

**The "all employees" dynamic group (added in this repo)**: the `all_employees` assignment resolves the AAD **dynamic** group `MDM-USR-Global-All-Dynamic_All_Employees` and grants it `Storage File Data SMB Share Contributor` at the storage-account scope. This was introduced in this repo (via `var.all_employees_group`, wired through `terraform/main.tf` and set in `terraform.tfvars`) to solve a specific problem: **country/region users cannot be enumerated in advance**, so rather than maintain per-country groups, all Ipsos employees get share-level Contributor and **NTFS ACLs do the per-folder filtering**. It pairs with `default_share_level_permission = "StorageFileDataSmbShareReader"` (the fallback for anything outside the group) — see §0. Because it is a dynamic, org-wide "all staff" group, membership is automatic; the security control that actually constrains access is NTFS ACLs, not group membership. Any account adopting this pattern must have well-maintained NTFS ACLs (documented as a precondition in the calling stack).

**⚠️ Performance — use `azuread_groups` (plural), not `azuread_group` (singular)**: The singular `data "azuread_group"` source pulls the **full members and owners list** on every read. For a large dynamic group like `MDM-USR-Global-All-Dynamic_All_Employees` this takes 5–6 minutes per plan. The plural `data "azuread_groups"` source returns **only object IDs** — it does not enumerate membership — and completes in seconds regardless of group size. This repo already uses the plural form; the upstream module's `for_each` design (below) **must also use the plural form** to avoid the same bottleneck.

The other two local groups are UK-specific: `az-uk-azfiles-admins` → Elevated Contributor (can manage ACLs), `MDM-USR-GB-United_Kingdom-Users` → Contributor.

**Problem**: three hardcoded groups/roles won't fit many accounts — other countries use different groups, and some accounts may want more or fewer assignments. The all-employees dynamic group is likely reusable across accounts, but the admin/country groups are not.

**Simpler alternative**: if a redesign is too invasive for v1.0.4, port the three group variables as-is (`all_employees_group`, `az_files_admins_group`, `intune_users_group`) with their data sources and role assignments — this matches exactly what this repo already runs and unblocks migration fastest. The map below is the cleaner long-term shape.

**Upstream design recommendation**: replace with a single parameterised map so each caller supplies its own groups:

```hcl
variable "share_level_role_assignments" {
  description = "Map of AAD group display name => SMB share role to assign on the storage account."
  type = map(object({
    group_display_name   = string
    role_definition_name = string  # e.g. "Storage File Data SMB Share Contributor"
  }))
  default = {}
}

# Use azuread_groups (plural): returns only object IDs, does NOT enumerate members.
# The singular azuread_group pulls the full membership list — minutes for large dynamic groups.
data "azuread_groups" "share_rbac" {
  for_each      = var.share_level_role_assignments
  display_names = [each.value.group_display_name]
}

resource "azurerm_role_assignment" "share_rbac" {
  for_each             = var.share_level_role_assignments
  scope                = azurerm_storage_account.default.id
  role_definition_name = each.value.role_definition_name
  principal_id         = data.azuread_groups.share_rbac[each.key].object_ids[0]
}
```

The UK stack then passes the equivalent of its current three groups via this map. This keeps the upstream module generic. **Note the migration `state mv` implication in §6.3** — moving from named resources to `for_each` keyed resources changes addresses.

### 3.2 `allowed_copy_scope = "AAD"` on the storage account

Local sets `allowed_copy_scope = "AAD"` (restricts object copy to same-AAD-tenant). Remote omits it.

**Upstream action**: add a variable, e.g. `allowed_copy_scope` (type `string`, default `null` to preserve current remote behaviour, allow `"AAD"` / `"PrivateLink"`). Set to `"AAD"` in the UK tfvars.

### 3.3 Anything else confirmed local-only

- The local module's `azure_files_authentication` **complex-object** variable is a different *shape* from remote's flat `ad_*` scalars (see §4.9 / §6.2). This is not a missing capability — remote can do AD auth — but the caller-facing interface differs, so it's a migration translation, not an upstream add. Decide in §6.2 whether to also add the object-style variable upstream for backward-compat, or translate all callers to flat scalars.

---

## 4. Already in remote v1.0.3 (local gains these on migration — verify defaults)

These need **no upstream work**; they already exist. The task is to confirm the remote defaults are safe for the *already-deployed* accounts, and set tfvars accordingly so the first `plan` after migration is clean.

| Remote capability | Remote default | Watch-out for existing accounts |
|---|---|---|
| `azurerm_private_endpoint.default_storage_pe` + `private_endpoint_lock` | active | UK stack currently has PE **commented out / removed**. Migrating re-introduces it — see §6.4. `precondition` requires `private_dns_zone_id != null`. |
| Azure Backup stack (`recovery_services_vault`, `backup_policy_file_share`, vault diag) | `enable_backup = true` | Net-new resources on every account. Set `enable_backup` per environment; set `backup_timezone` (UK = `"GMT Standard Time"`). |
| 3 activity-log alerts (`delete_storage_account`, `delete_private_endpoint`, `regenerate_storage_key`) + `data.azurerm_resource_group.current` | present | Net-new; harmless. |
| `identity { type = "SystemAssigned" }` | present | Adding identity to an existing SA is non-destructive but shows a diff. |
| `https_traffic_only_enabled = true`, `sftp_enabled = false`, `local_user_enabled = false` | present | Hardening; verify no existing account relies on SFTP/local users. |
| `shared_access_key_enabled` | `false` | **Breaking if any account/app still uses account keys.** Audit before migrating each account; override to `true` where needed. |
| `public_network_access_enabled` | `false` | UK stack currently `true` (PE still being built out). Set `true` in UK tfvars until PE verified, else SMB mounts break. |
| `enabled_metric {}` diag syntax | correct (v4+) | Local still uses deprecated `metric {}`. Remote is right; no action beyond migrating. |
| `retention_in_days` via `log_analytics_retention_days` | `365` | Local hardcodes `90` (non-compliant). Remote default is better; keep `365`. |
| Defender pricing/defender toggles (`enable_defender_subscription_pricing`, `enable_sensitive_data_discovery`, `defender_override_subscription_settings_enabled`) with `ignore_changes = [subplan]` | mostly `true` | `azurerm_security_center_subscription_pricing` is **subscription-singleton**. If another stack in the same subscription manages it, set `enable_defender_subscription_pricing = false` to avoid state fights. **PR #14 already added `enable_defender_subscription_pricing` to the *local* module** (as a `count` guard on the pricing resource; set `false` for `azemeaukfs02`). Remote's version is a superset (adds `ignore_changes = [subplan]`) — prefer it on migration; no functionality lost. |
| `enable_resource_locks` toggle on locks | `true` | Local locks are always-on; remote toggle is a superset. Fine. |
| Parameterised alert thresholds, replication type, soft-delete days, malware cap | defaults match local | No behaviour change. |
| Outputs: `storage_account_name`, `storage_account_principal_id`, `private_endpoint_id`, `log_analytics_workspace_id` | present | Local only had `id`. Local gains these. |
| `required_version = ">=1.6.6"` | present | Ensure consuming stacks satisfy it. |

**Naming difference to reconcile**: local `storage_account_ip_rules` vs remote `ip_rules`. Callers must rename in tfvars on migration (§6.1).

---

## 5. Cutting v1.0.4 (upstream checklist)

In `ipsos-cicd-tools/tf-az-azure-files`:

1. Add `share_level_role_assignments` variable + `for_each` data source + role assignment (§3.1).
2. Add `allowed_copy_scope` variable and wire it into `azurerm_storage_account.default` (§3.2).
3. (Decision) Optionally add an object-style `azure_files_authentication` variable for backward-compat, or document the flat `ad_*` interface as the only one (§6.2).
4. Update README with the new variables + a migration note from the local fork.
5. Tag `1.0.4`. Follow existing repo conventions for CHANGELOG/versioning.

After v1.0.4 exists, the local `modules/az-files/` fork can be deleted once all callers are migrated (§6).

---

## 6. Per-account rollout / migration plan

Repeat for each Azure Files account/subscription currently on the local fork (or on an older remote ref).

### 6.1 Translate tfvars
- Rename `storage_account_ip_rules` → `ip_rules`.
- Replace the local `azure_files_authentication = { … }` object with remote's flat `ad_*` vars + `default_share_level_permission` (§6.2), unless you added the object variable upstream.
- Convert the three RBAC blocks into `share_level_role_assignments = { … }` entries (§3.1).
- Add: `allowed_copy_scope = "AAD"`, `public_network_access_enabled` (true until PE verified), `enable_backup`, `backup_timezone`, `log_analytics_retention_days = 365`, defender toggles, `shared_access_key_enabled` (audit first).
- Set `enable_defender_subscription_pricing = false` if another stack in the subscription manages Defender pricing (§6.5).
- If using the VNet service-endpoint rule: set `service_endpoints = ["Microsoft.Storage"]` on the subnet **and** ensure the vnet module is `≥ 1.0.5` (§6.7).

### 6.2 AD auth interface change
Local passes a complex object; remote triggers the AD block when `ad_storage_sid != null` via flat scalars:
`ad_domain_name`, `ad_domain_guid`, `ad_domain_sid`, `ad_forest_name`, `ad_netbios_domain_name`, `ad_storage_sid`, plus `default_share_level_permission`.
For the UK account the confirmed values (from the deployed SA) are:
`domain_guid = c15f8a6c-701d-495a-ab47-49ad80e73985`, `domain_name = ipsosgroup.ipsos.com`, `domain_sid = S-1-5-21-3343930222-3471731563-1258133589`, `forest_name = ipsosgroup.ipsos.com`, `netbios = ipsosgroup.ipsos.com`, `storage_sid = …-741823`.

### 6.3 Point the module source and run state moves
- Change `source` to `git::https://github.com/ipsos-cicd-tools/tf-az-azure-files//modules/az-files?ref=1.0.4`.
- Resource addresses that change require `terraform state mv` (no Azure change):
  - RBAC: `azurerm_role_assignment.all_employees_contributor` → `azurerm_role_assignment.share_rbac["<key>"]` (and the two others). Same for the `data.azuread_group` sources.
  - Any resource the remote names differently than the local (e.g. PE `default-pe` vs remote `default_storage_pe`) — align via `state mv` before plan.
- Run `terraform plan` and confirm **no destroy/recreate** on the storage account, PE, or file shares.

### 6.4 Private endpoint & public access sequencing (per account)
1. Migrate with `public_network_access_enabled = true` and PE created by the module.
2. Verify PE resolves and SMB mounts work.
3. Flip `public_network_access_enabled = false` in a follow-up apply.

### 6.5 Subscription-singleton guard
Before applying in a subscription that already has Defender pricing managed elsewhere, set `enable_defender_subscription_pricing = false`. (This toggle now exists in both the local module — PR #14 — and remote v1.0.3+.)

### 6.6 Brownfield adoption — import pre-existing resources (per account)
Most accounts are **brownfield**: the storage account and its associated objects already exist before Terraform adopts them. On first `apply` these surface as `409 … already exists` / `RoleAssignmentExists` errors and the run fails. For each existing account, `terraform import` the pre-existing resources into state **before** the first apply (deployment is via GitHub Actions, but imports are one-off state operations run against the remote backend after `terraform init -reconfigure`):

- **Share-level role assignments** — any of `all_employees_contributor`, `admins_elevated_contributor`, `users_contributor` whose group already has the role at the SA scope. Get the assignment names from Azure:
  ```bash
  az role assignment list --scope "<storage-account-id>" \
    --query "[?contains(roleDefinitionName,'SMB Share')].{role:roleDefinitionName,principalId:principalId,name:name}" -o json
  ```
  then `terraform import 'module.<name>.azurerm_role_assignment.<label>' '<sa-id>/providers/Microsoft.Authorization/roleAssignments/<assignment-guid>'`.
- **`azurerm_security_center_storage_defender.default`** — the ATP settings object (`advancedThreatProtectionSettings/current`) **always exists** for any storage account, so it must be imported, never created. Import ID is the **storage account ID** itself. After import, expect an update-in-place if ATP was disabled (`isEnabled: false`) but the module enables malware scanning.
- Any other resource the module manages that already exists on the account (e.g. management locks, diagnostic settings) — import rather than recreate.

**For the upstream module this is not a code change** — it's a documented per-account onboarding runbook. Consider adding an `imports.tf` template (or `import {}` blocks) to the *caller* stacks so CI performs the imports automatically on first apply, then removing the blocks afterward.

### 6.7 Subnet service endpoint + vnet module version (precondition)
If the account restricts the storage account to a VNet via `virtual_network_subnet_ids` (network rule), the subnet **must have the `Microsoft.Storage` service endpoint** or Azure rejects the ACL with `NetworkAclsValidationFailure: SubnetsHaveNoServiceEndpointsConfigured`. This is a **cross-module dependency**:

- The **vnet module must wire `service_endpoints`** into its `azurerm_subnet` resource. `tf-az-vnet` **≥ 1.0.5** does this; **1.0.4 does not** (it silently drops the attribute and resets the subnet to `[]` on every apply, breaking the storage ACL — see §7). Bump consuming stacks to `ref=1.0.5` or later.
- The caller sets `service_endpoints = ["Microsoft.Storage"]` on the relevant subnet in tfvars.
- Do **not** try to fix this out-of-band (`az network vnet subnet update …`) — a vnet module older than 1.0.5 reverts it on the next apply.
- Alternatively, if the account uses a **private endpoint** instead of the service-endpoint VNet rule, this precondition does not apply.

---

## 7. Key risks

- **RBAC redesign (§3.1)**: the `for_each` migration changes state addresses. Without `state mv`, Terraform destroys + recreates role assignments (brief access disruption). Plan the moves explicitly.
- **`shared_access_key_enabled = false` default**: can break apps still using account keys. Audit each account.
- **PE re-introduction**: the UK stack deliberately removed the PE. Migrating re-adds it — sequence per §6.4 or SMB access can drop.
- **Deployed vs code SID drift**: local module had `storage_sid …-741844` hardcoded (wrong); deployed reality is `…-741823`. Use the deployed value (§6.2) to avoid a destructive AD re-join.
- **SMB `ignore_changes` removal**: remote no longer ignores SMB sub-attributes, so first plan may show drift-revert. Expected and correct.
- **Backup stack net-new**: budget/quota impact of Recovery Services Vaults across many accounts.
- **Brownfield 409s (§6.6)**: existing accounts fail first apply on `RoleAssignmentExists` and `azurerm_security_center_storage_defender` "already exists". Import the pre-existing resources before applying, or CI will keep failing partway through.
- **Subnet service-endpoint / vnet module version (§6.7)**: a vnet module < 1.0.5 does not wire `service_endpoints` and strips the subnet to `[]` on every apply, causing `NetworkAclsValidationFailure` on the storage account. Bump the vnet module to ≥ 1.0.5; out-of-band `az` fixes get reverted.

---

## 8. Appendix — factual resource/variable comparison

### Resources only in remote v1.0.3 (local gains on migration)
`azurerm_private_endpoint.default_storage_pe`, `azurerm_management_lock.private_endpoint_lock`, `azurerm_recovery_services_vault.backup_vault`, `azurerm_backup_policy_file_share.daily_backup`, `azurerm_monitor_diagnostic_setting.backup_vault`, `azurerm_monitor_activity_log_alert.{delete_storage_account,delete_private_endpoint,regenerate_storage_key}`, `data.azurerm_resource_group.current`, storage-account `identity {}` block.

### Resources only in local (roll up per §3)
`data.azuread_groups.{all_employees,admins,users}` (plural — returns object IDs only; see §3.1 performance note), `azurerm_role_assignment.{all_employees_contributor,admins_elevated_contributor,users_contributor}`, `allowed_copy_scope` attribute.

### Variables only in remote v1.0.3 (callers must supply/accept)
`ad_domain_name`, `ad_domain_guid`, `ad_domain_sid`, `ad_forest_name`, `ad_netbios_domain_name`, `ad_storage_sid`, `default_share_level_permission`, `enable_backup`, `backup_policy`, `backup_timezone`, `backup_vault_storage_mode_type`, `backup_vault_public_network_access_enabled`, `backup_vault_cross_region_restore_enabled`, `enable_resource_locks`, `soft_delete_retention_days`, `public_network_access_enabled`, `shared_access_key_enabled`, `ip_rules`, `storage_account_replication_type`, `enable_sensitive_data_discovery`, `enable_defender_subscription_pricing`, `defender_override_subscription_settings_enabled`, `malware_scanning_cap_gb_per_month`, `log_analytics_retention_days`, `alert_threshold_high_errors`, `alert_threshold_high_deletes`, `alert_threshold_auth_failures`.

### Variables only in local (roll up per §3 — as a map, not fixed)
`all_employees_group`, `az_files_admins_group`, `intune_users_group` → fold into `share_level_role_assignments`. Local `azure_files_authentication` object → translate to flat `ad_*` (or add upstream for compat).

### Variable renames to reconcile
`storage_account_ip_rules` (local) → `ip_rules` (remote).
