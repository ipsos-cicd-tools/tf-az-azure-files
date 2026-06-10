# context-mode — MANDATORY routing rules

You have context-mode MCP tools available. These rules are NOT optional — they protect your context window from flooding. A single unrouted command can dump 56 KB into context and waste the entire session.

## BLOCKED commands — do NOT attempt these

### curl / wget — BLOCKED
Any Bash command containing `curl` or `wget` is intercepted and replaced with an error message. Do NOT retry.
Instead use:
- `ctx_fetch_and_index(url, source)` to fetch and index web pages
- `ctx_execute(language: "javascript", code: "const r = await fetch(...)")` to run HTTP calls in sandbox

### Inline HTTP — BLOCKED
Any Bash command containing `fetch('http`, `requests.get(`, `requests.post(`, `http.get(`, or `http.request(` is intercepted and replaced with an error message. Do NOT retry with Bash.
Instead use:
- `ctx_execute(language, code)` to run HTTP calls in sandbox — only stdout enters context

### WebFetch — BLOCKED
WebFetch calls are denied entirely. The URL is extracted and you are told to use `ctx_fetch_and_index` instead.
Instead use:
- `ctx_fetch_and_index(url, source)` then `ctx_search(queries)` to query the indexed content

## REDIRECTED tools — use sandbox equivalents

### Bash (>20 lines output)
Bash is ONLY for: `git`, `mkdir`, `rm`, `mv`, `cd`, `ls`, `npm install`, `pip install`, and other short-output commands.
For everything else, use:
- `ctx_batch_execute(commands, queries)` — run multiple commands + search in ONE call
- `ctx_execute(language: "shell", code: "...")` — run in sandbox, only stdout enters context

### Read (for analysis)
If you are reading a file to **Edit** it → Read is correct (Edit needs content in context).
If you are reading to **analyze, explore, or summarize** → use `ctx_execute_file(path, language, code)` instead. Only your printed summary enters context. The raw file content stays in the sandbox.

### Grep (large results)
Grep results can flood context. Use `ctx_execute(language: "shell", code: "grep ...")` to run searches in sandbox. Only your printed summary enters context.

## Tool selection hierarchy

1. **GATHER**: `ctx_batch_execute(commands, queries)` — Primary tool. Runs all commands, auto-indexes output, returns search results. ONE call replaces 30+ individual calls.
2. **FOLLOW-UP**: `ctx_search(queries: ["q1", "q2", ...])` — Query indexed content. Pass ALL questions as array in ONE call.
3. **PROCESSING**: `ctx_execute(language, code)` | `ctx_execute_file(path, language, code)` — Sandbox execution. Only stdout enters context.
4. **WEB**: `ctx_fetch_and_index(url, source)` then `ctx_search(queries)` — Fetch, chunk, index, query. Raw HTML never enters context.
5. **INDEX**: `ctx_index(content, source)` — Store content in FTS5 knowledge base for later search.

## Subagent routing

When spawning subagents (Agent/Task tool), the routing block is automatically injected into their prompt. Bash-type subagents are upgraded to general-purpose so they have access to MCP tools. You do NOT need to manually instruct subagents about context-mode.

## Output constraints

- Keep responses under 500 words.
- Write artifacts (code, configs, PRDs) to FILES — never return them as inline text. Return only: file path + 1-line description.
- When indexing content, use descriptive source labels so others can `ctx_search(source: "label")` later.

## ctx commands

| Command | Action |
|---------|--------|
| `ctx stats` | Call the `ctx_stats` MCP tool and display the full output verbatim |
| `ctx doctor` | Call the `ctx_doctor` MCP tool, run the returned shell command, display as checklist |
| `ctx upgrade` | Call the `ctx_upgrade` MCP tool, run the returned shell command, display as checklist |

---

# Codebase: tf-az-azure-files

## Purpose

This repository is a **reusable Terraform module** for deploying Azure Files (SMB file shares on Azure Storage). It is consumed by other Terraform repositories via Git source reference, not deployed directly.

## Repository Structure

```
modules/az-files/          # Primary module — use this one
  main.tf                  # All Azure resources
  variables.tf             # Input variables
  outputs.tf               # Outputs (storage account id)
  providers.tf             # Provider + Terraform version constraints
  README.md                # Module usage docs
.github/
  workflows/
    release.yml            # Semantic versioning release automation
    tf-validation.yml      # Terraform validate + fmt + docs CI
  src/
    terraform-validator.sh # Validation script
    tf-docs.yml            # terraform-docs config
```

> Ignore `modules/az-files-nait/` and `az-files-nait/` — not in scope.

## Module: `modules/az-files`

### Provider requirements
- Terraform `>= 1.6.6`
- `hashicorp/azurerm` `> 4.3.0`

### Resources provisioned

| Resource | Description |
|---|---|
| `azurerm_storage_account` | StorageV2, Standard, ZRS, large file shares, TLS 1.2, infrastructure encryption |
| `azurerm_private_endpoint` | File sub-resource PE with custom NIC name + private DNS zone group |
| `azurerm_management_lock` (×2) | CanNotDelete locks on storage account and PE (optional) |
| `azurerm_recovery_services_vault` | ZRS backup vault (optional) |
| `azurerm_backup_policy_file_share` | Daily/weekly/monthly/yearly retention policy (optional) |
| `azurerm_log_analytics_workspace` | 90-day retention workspace for diagnostics |
| `azurerm_monitor_diagnostic_setting` (×2) | Storage account metrics + file service audit logs |
| `azurerm_security_center_subscription_pricing` | Defender for Storage at subscription level |
| `azurerm_security_center_storage_defender` | Per-account malware scanning + sensitive data discovery |
| `azurerm_monitor_action_group` | Email action group for security alerts |
| `azurerm_monitor_metric_alert` (×3) | High error rate, high delete ops, auth failures |

### Key design decisions
- Public network access **off by default**; private endpoint is always provisioned
- SMB only: 3.0 and 3.1.1, Kerberos AES-256 + NTLMv2
- AD/Kerberos integration is **optional** — triggered only when `ad_storage_sid` is non-null
- `network_rules[0].private_link_access` is in `lifecycle.ignore_changes` (Azure manages it)
- Backup vault and locks are behind boolean feature flags

### Required variables
- `az_files_storage_account_name`
- `az_files_storage_account_rg_name`
- `az_files_storage_account_rg_location`
- `tags`
- `subnet_id`
- `security_alert_email`

### Outputs
- `id` — resource ID of the storage account

## Versioning & CI

- Commits follow **Conventional Commits** (`feat:`, `fix:`, `BREAKING CHANGE:`, `docs:`)
- Release workflow auto-bumps semver based on commit prefixes
- Module is consumed via: `git::https://github.com/ipsos-cicd-tools/tf-az-azure-files//modules/az-files?ref=<version>`
