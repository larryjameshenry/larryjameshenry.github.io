---
title: "Fact Check Report: Automating FinOps (Azure Focus)"
date: 2025-12-09T00:00:00
target_draft: "plans/devops-automation/drafts/automating-finops-controlling-cloud-costs-in-your-pipeline.md"
status: "Passed with Revisions"
---

# Fact Check & Technical Validation

## 1. Technical Accuracy
### 1.1 Infracost GitHub Actions Version
*   **Claim:** Uses `infracost/actions/setup@v2` and `comment@v2`.
*   **Reality:** Version `v3` is the current stable release (released late 2023/2024).
*   **Action:** Update workflow to use `@v3` for both actions to ensure compatibility and access to latest features.

### 1.2 PowerShell "Reaper" Script Logic
*   **Claim:** `$_.PowerState -eq 'VM running'` works directly on `Get-AzVM -Status` output.
*   **Reality:** The `PSVirtualMachine` object returned by `Get-AzVM -Status` does **not** have a top-level `PowerState` property. Power State is nested within the `Statuses` array (e.g., `Code: PowerState/running`).
*   **Action:** Rewrite the script to correctly parse the status:
    ```powershell
    $status = $vm.Statuses | Where-Object { $_.Code -like 'PowerState/*' }
    if ($status.DisplayStatus -eq 'VM running') { ... }
    ```

### 1.3 Azure Policy JSON Syntax
*   **Claim:** `"exists": "false"` (string) in the `if` block.
*   **Reality:** While the ARM engine often tolerates strings, the strictly correct JSON type for the `exists` operator is a **boolean** (`false`).
*   **Action:** Change `"false"` to `false` (no quotes) for strict correctness.

## 2. Fact Verification
*   **Claim:** "Azure Spot Virtual Machines... can be evicted with 30 seconds of notice." -> **Verified.** (Standard Azure SLA for Spot).
*   **Claim:** "Azure Hybrid Benefit... reduce runtime costs by up to 40%." -> **Verified.** (Microsoft documents savings of 40-50% vs. PAYG).
*   **Claim:** "Allowed virtual machine size SKUs" is a built-in policy. -> **Verified.**

## 3. Best Practices
*   **Managed Identity:** The draft correctly suggests using System Assigned Managed Identity. This is the security best practice over Service Principals for automation.
*   **Tagging:** `CostCenter` is a standard FinOps tag.

## 4. Recommendations
1.  **Update PowerShell Script:** The current script will fail to find running VMs. It needs the logic fix.
2.  **Bump Infracost Version:** Move to v3.
3.  **JSON Type Fix:** Remove quotes around `false` in the policy snippet.
