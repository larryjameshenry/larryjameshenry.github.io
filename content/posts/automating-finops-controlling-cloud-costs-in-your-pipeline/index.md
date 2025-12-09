---
title: "Automating FinOps: Controlling Cloud Costs in Your Pipeline"
date: 2025-12-04T00:00:00
description: "Stop cloud bill shock before it happens. Learn how to integrate cost estimation tools like Infracost and automated cleanup scripts into your DevOps workflow."
series: ["DevOps Automation"]
tags: ["finops automation", "cloud cost optimization", "infracost tutorial", "azure policy", "powershell"]
categories: ["PowerShell", "DevOps"]
weight: 4
image: images/featured-image.jpg
---

The only thing scaling faster than your Kubernetes cluster is your Azure bill.

Developers often provision infrastructure using Terraform or Bicep with zero visibility into the financial impact. The finance team usually discovers the overspend 30 days later when the invoice arrives. This "Feedback Gap" is the root cause of cloud waste.

This guide details how to shift cost awareness left. By automating FinOps, you reveal the price tag of infrastructure changes *before* they merge and automatically reap resources that no longer serve a purpose. We will focus on implementing "Price Checks" in GitHub Actions using Infracost and building "Reaper" scripts with Azure Automation.

## Shifting Cost Left

The most effective way to reduce cloud spend is to prevent expensive resources from being provisioned in the first place.

### The "Price Check" Workflow

Waiting for the monthly bill is too late to fix a budget overrun. You need to inject cost data into the pull request (PR) workflow.

Tools like **Infracost** sit between your infrastructure-as-code (IaC) definition and the cloud provider. When a developer opens a PR, Infracost parses the Terraform plan, queries the Azure Retail Prices API, and calculates the cost difference.

If a developer changes a Virtual Machine SKU from `Standard_D2s_v3` (approx. $70/month) to `Standard_D64s_v3` (approx. $2,200/month), Infracost posts a comment on the PR highlighting the +$2,130/month increase. This immediate feedback loop forces the developer to justify the cost or revert the change before it merges.

### Budget Guardrails with Azure Policy

While price checks provide visibility, you also need hard guardrails. Azure Policy is the native mechanism to enforce these limits at the ARM (Azure Resource Manager) layer.

A common pattern is restricting allowed SKUs in development environments. You can assign the built-in policy **"Allowed virtual machine size SKUs"** to your Dev subscription and configure it to `Deny` any creation request that isn't on the approved list (e.g., `Standard_B1s`, `Standard_B2s`).

Unlike Open Policy Agent (OPA), which evaluates Terraform plans logically, Azure Policy acts as the final safety net during deployment. If a user attempts to bypass the Terraform pipeline and create an expensive resource via the Portal or CLI, Azure Policy will block the request.

## Managing Infrastructure Lifecycle

Once resources are running, the goal shifts to efficient lifecycle management.

### The Tagging Strategy

You cannot manage what you cannot measure. "Untagged" resources are effectively invisible to cost allocation tools.

You must enforce a mandatory tagging standard. Critical tags include:
*   `CostCenter`: Who pays for this?
*   `Owner`: Who manages this?
*   `Environment`: Is this Prod or Dev?
*   `AutoShutdown`: Should this be turned off at night?

Use Azure Policy to enforce this. The following custom policy rule denies the creation of any resource that lacks a `CostCenter` tag:

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

### The "Reaper" Pattern

Development environments do not need to run 24/7. A VM running strictly during business hours (Mon-Fri, 7 AM - 7 PM) costs roughly 65% less than one running continuously.

We can automate this "Lights Out" behavior using **Azure Automation Runbooks**.

1.  **Identity:** Enable a System Assigned Managed Identity for your Automation Account and grant it the `Virtual Machine Contributor` role on the target subscription.
2.  **Trigger:** Set a recurring schedule (e.g., Daily at 7 PM).
3.  **Logic:** The runbook executes a PowerShell script that finds running VMs tagged for shutdown and deallocates them.

**PowerShell Reaper Script:**

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

## Hands-On: Implementing Infracost in GitHub Actions

In this scenario, we will configure a GitHub Actions workflow that runs `terraform plan`, calculates the cost, and comments on the PR.

**Prerequisites:**
*   A GitHub repository with Terraform code targeting Azure.
*   An Infracost API key (Free tier is sufficient).

### Implementation Steps

1.  **Store API Key:** Add your Infracost API key to your GitHub repository secrets as `INFRACOST_API_KEY`.
2.  **Create Workflow:** Create a file at `.github/workflows/infracost.yml`.

**Workflow Configuration:**

```yaml
name: Infracost Price Check

on: [pull_request]

jobs:
  infracost:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write # Required to post comments

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Infracost
        uses: infracost/actions/setup@v3
        with:
          api-key: ${{ secrets.INFRACOST_API_KEY }}

      - name: Run Infracost breakdown
        run: |
          infracost breakdown --path=./terraform \
                              --format=json \
                              --out-file=/tmp/infracost.json

      - name: Post Cost Comment
        uses: infracost/actions/comment@v3
        with:
          path: /tmp/infracost.json
          behavior: update # Updates the existing comment if re-run
```

**Verification:**
Open a Pull Request that modifies a resource (e.g., change a VM size). Within moments, the `github-actions` bot will comment with a detailed cost table showing the monthly difference.

## Best Practices & Optimization

*   **Gamify Savings:** Create a leaderboard. Visibility drives competition, and teams will actively optimize their specific spend to rank higher.
*   **Use Spot Instances:** For stateless workloads like CI/CD agents or batch processing, use Azure Spot Virtual Machines. They offer discounts up to 90% but can be evicted with 30 seconds of notice. Handle the eviction event to terminate jobs gracefully.
*   **Azure Hybrid Benefit:** If you possess on-premises Windows Server licenses with Software Assurance, apply them to your Azure VMs. This can reduce runtime costs by up to 40%.
*   **Advisor Automation:** Don't just read Azure Advisor recommendations manually. Query the Advisor API programmatically to identify "Orphaned Disks" and "Underutilized VMs" and pipe those alerts into your ticketing system.

## Troubleshooting Common Issues

**"Infracost doesn't support my resource"**
Some niche or newly released Azure resources may not yet be mapped in the Infracost pricing API. In these cases, Infracost will warn you. You can suppress these warnings or use custom price files if you have negotiated rates.

**"Developers ignore the cost comments"**
Alert fatigue is real. If every PR shows a change of $0.01, developers will stop reading. Configure Infracost or your CI pipeline to fail the build only if the cost increase exceeds a specific threshold (e.g., > $50/month), or use the `behavior: update` setting to keep the noise to a single comment per PR.

## Conclusion

Visibility changes behavior. When developers see the financial impact of their code immediately, they self-regulate. When you combine this "Shift Left" approach with "Shift Right" automation like Reaper scripts and Policy enforcement, you bridge the gap between Engineering and Finance.

Automation is cleaner. Scripts don't forget to turn off the lights. Humans do.

**Next Steps:**
*   Install the Infracost VS Code extension for real-time feedback while coding.
*   Audit your development environment: How many resources are running right now with no active users?
*   Read the next guide: *The Rise of AIOps: Leveraging AI for Smarter DevOps Automation*.
