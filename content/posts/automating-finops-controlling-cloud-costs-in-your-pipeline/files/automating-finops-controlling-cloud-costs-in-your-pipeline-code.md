---
title: "Code Audit: Automating FinOps (Azure Focus)"
date: 2025-12-09T00:00:00
target_draft: "plans/devops-automation/drafts/automating-finops-controlling-cloud-costs-in-your-pipeline.md"
status: "Issues Found"
---

# Code Validation Report

## 1. PowerShell Script (Reaper)
**Status:** 🔴 **Critical Issue**

*   **Snippet:**
    ```powershell
    $vms = Get-AzVM -Status | Where-Object { 
        $_.Tags['AutoShutdown'] -eq 'true' -and $_.PowerState -eq 'VM running' 
    }
    ```
*   **Problem:** The `Get-AzVM -Status` object (`PSVirtualMachine`) does NOT have a top-level property called `PowerState`. The status is buried in the `Statuses` array.
*   **Corrected Code:**
    ```powershell
    # Connect using Managed Identity
    Connect-AzAccount -Identity

    # Get all VMs with status
    $vms = Get-AzVM -Status 

    foreach ($vm in $vms) {
        # Check for Tag
        if ($vm.Tags['AutoShutdown'] -eq 'true') {
            # Parse Status correctly
            $status = $vm.Statuses | Where-Object { $_.Code -like 'PowerState/*' }
            
            if ($status.DisplayStatus -eq 'VM running') {
                Write-Output "Stopping VM: $($vm.Name)"
                Stop-AzVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -Force
            }
        }
    }
    ```

## 2. GitHub Actions Workflow (Infracost)
**Status:** 🟡 **Warning**

*   **Snippet:** `uses: infracost/actions/setup@v2`
*   **Problem:** Using older `@v2` actions.
*   **Recommendation:** Upgrade to `@v3`.
    ```yaml
    - name: Setup Infracost
      uses: infracost/actions/setup@v3
      with:
        api-key: ${{ secrets.INFRACOST_API_KEY }}

    - name: Post Cost Comment
      uses: infracost/actions/comment@v3
      with:
        path: /tmp/infracost.json
        behavior: update
    ```

## 3. Azure Policy JSON
**Status:** 🟡 **Warning**

*   **Snippet:** `"exists": "false"`
*   **Problem:** While Azure Policy engine is lenient, `"false"` as a string is technically incorrect for boolean fields.
*   **Recommendation:** Remove quotes.
    ```json
    {
      "if": {
        "field": "tags['CostCenter']",
        "exists": false
      },
      "then": {
        "effect": "deny"
      }
    }
    ```

## 4. Summary of Changes Required
1.  **Rewrite PowerShell logic** to correctly iterate and filter VM statuses.
2.  **Update GitHub Action versions** to `v3`.
3.  **Fix JSON syntax** for boolean `exists` check.
