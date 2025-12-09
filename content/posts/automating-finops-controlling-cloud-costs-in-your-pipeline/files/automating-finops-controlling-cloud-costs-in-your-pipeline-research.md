---
title: "Research Dossier: Automating FinOps (Azure Focus)"
date: 2025-12-09T00:00:00
source_outline: "plans/devops-automation/outlines/automating-finops-controlling-cloud-costs-in-your-pipeline.md"
target_cloud: "Microsoft Azure"
---

# Research Dossier: Automating FinOps in Azure

## 1. Context & Problem Space
*   **The "Feedback Gap":** Developers provision resources (ARM/Bicep/Terraform) without seeing cost implications. Azure Bill arrives 30 days later.
*   **Goal:** "Shift Left" cost awareness to the Pull Request stage and "Shift Right" automated cleanup.
*   **Azure Specifics:** Azure Cost Management + Billing is the central hub, but it's reactive. We need proactive tools.

## 2. Technical Implementation Details

### 2.1 "Price Checks" in CI/CD (Infracost + Azure)
*   **Tool:** Infracost (Open Source).
*   **Why:** Best-in-class for Terraform/Azure price estimation.
*   **How it works:**
    1.  Parses Terraform plan (`tfplan`).
    2.  Queries Infracost Cloud Pricing API (mapped to Azure Retail Prices API).
    3.  Calculates diff (e.g., "This change adds +$150/month").
*   **GitHub Actions Integration:**
    *   **Action:** `infracost/actions`
    *   **Workflow:**
        ```yaml
        - name: Setup Infracost
          uses: infracost/actions/setup@v2
          with:
            api-key: ${{ secrets.INFRACOST_API_KEY }}

        - name: Run Infracost
          run: |
            infracost breakdown --path=./terraform \
                                --format=json \
                                --out-file=/tmp/infracost.json

        - name: Post to PR
          uses: infracost/actions/comment@v2
          with:
            path: /tmp/infracost.json
            behavior: update
        ```
*   **Key Metrics:**
    *   Supports `azurerm` Terraform provider.
    *   Can catch expensive SKU changes (e.g., `Standard_D2s_v3` -> `Standard_D64s_v3`).

### 2.2 Budget Guardrails (Azure Policy)
*   **Concept:** Prevent expensive resources from being created *at all*.
*   **Mechanism:** Azure Policy (Built-in or Custom).
*   **Specific Policy:** "Allowed virtual machine size SKUs".
    *   **Scope:** Assign to Development Resource Groups or Subscriptions.
    *   **Effect:** `Deny`.
    *   **Parameters:** List of allowed SKUs (e.g., `Standard_B1s`, `Standard_B2s`).
*   **OPA vs. Azure Policy:**
    *   OPA (Open Policy Agent) is great for Terraform plan analysis *before* apply.
    *   Azure Policy is the safety net *during* apply (ARM layer).
    *   *Recommendation:* Use Azure Policy for hard enforcement (it's native, free, and cannot be bypassed easily).

### 2.3 Tagging Strategy (Enforcement)
*   **Why:** "Untagged resources are unmanageable resources."
*   **Mandatory Tags:** `CostCenter`, `Owner`, `Environment`, `AutoShutdown` (for Reaper).
*   **Enforcement Tool:** Azure Policy.
*   **Policy Logic (Custom Definition):**
    *   **Condition:** `AnyOf` (Tag `CostCenter` exists = false).
    *   **Effect:** `Deny` (Block creation) OR `Modify` (Add "Unknown" if missing, but `Deny` is better for strict FinOps).
*   **Snippet (Azure Policy Rule):** 
    ```json
    {
      "if": {
        "field": "tags['CostCenter']",
        "exists": "false"
      },
      "then": {
        "effect": "deny"
      }
    }
    ```

### 2.4 The "Reaper" (Automated Cleanup)
*   **Concept:** "Lights Out" automation. Development environments don't need to run 24/7.
*   **Implementation:** Azure Automation Runbook (PowerShell).
*   **Identity:** Managed Identity (System Assigned) on the Automation Account.
*   **Role:** `Virtual Machine Contributor` on target subscription.
*   **Logic:**
    1.  **Trigger:** Schedule (e.g., Mon-Fri, 7 PM).
    2.  **Script:**
        *   `Connect-AzAccount -Identity`
        *   `$vms = Get-AzVM -Status | Where-Object { $_.Tags['AutoShutdown'] -eq 'true' -and $_.PowerState -eq 'VM running' }`
        *   `Stop-AzVM -Name $v.Name -ResourceGroupName $v.ResourceGroupName -Force`
*   **Cost Savings:** Shutting down 12 hours/day = ~50% cost reduction on compute.

### 2.5 Budget Alerts & Webhooks
*   **Tool:** Azure Cost Management > Budgets.
*   **Configuration:**
    *   **Scope:** Subscription or Resource Group.
    *   **Reset:** Monthly.
    *   **Thresholds:** 50%, 80%, 100% (Forecasted vs Actual).
*   **Action Group:**
    *   **Notification:** Email owner.
    *   **Automation:** **Webhook** -> Triggers **Azure Logic App**.
*   **Advanced Logic App Workflow:**
    *   *Trigger:* Webhook (Budget > 100%).
    *   *Action:* Post message to MS Teams channel "Cloud Cost Alerts".
    *   *Action (Aggressive):* Trigger Automation Runbook to "Stop Dev VMs".

### 2.6 Spot Instances (Azure Spot Virtual Machines)
*   **Use Case:** CI/CD Agents, Batch Processing, non-critical dev workloads.
*   **Mechanism:** Access unused Azure capacity at deep discounts (up to 90%).
*   **Risk:** Eviction (30-second notice).
*   **Automation:** Handle the "Scheduled Event" (Eviction) to gracefully terminate jobs.
*   **Terraform:** `priority = "Spot"`, `eviction_policy = "Deallocate"`.

## 3. Hands-On Lab Setup (Azure + GitHub)
*   **Scenario:** A developer tries to change a VM size in Terraform.
*   **Files Needed:**
    *   `main.tf` (Azure VM resource).
    *   `.github/workflows/infracost.yml`.
*   **Expected Outcome:** PR Comment showing the price hike.

## 4. Best Practices (Azure Specific)
*   **Reserved Instances (RIs):** For production databases/VMs that run 24/7. (Commitment = Savings).
*   **Hybrid Benefit:** Reuse on-prem Windows Server licenses in Azure (save ~40%).
*   **Advisor:** Use Azure Advisor recommendations programmatically (via API) to find "Orphaned Disks" and "Underutilized VMs".