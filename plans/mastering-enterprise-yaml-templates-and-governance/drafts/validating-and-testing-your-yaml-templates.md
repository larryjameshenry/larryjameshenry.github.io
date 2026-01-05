## Front Matter (YAML format)
---
title: "Validating and Testing Your YAML Templates"
date: 2025-12-23T10:00:00
draft: false
description: "Stop breaking production pipelines. Learn how to unit test your Azure DevOps YAML templates using Pester and the Pipeline Dry-Run API."
series: ["Mastering Enterprise YAML Templates & Governance"]
tags: ["Azure DevOps", "Pester", "PowerShell", "Testing", "Infrastructure as Code"]
categories: ["DevOps", "Testing"]
weight: 4
---

"I’ll just trigger a build and see if it fails."

If this is your testing strategy for pipeline templates, you are playing Russian Roulette with your development team's productivity. A single syntax error in a shared template can bring down hundreds of builds instantly.

As YAML logic grows complex—introducing object parameters, loops, and conditional insertion—syntax errors and logical bugs become harder to spot with the naked eye. To maintain a robust enterprise template library, you need a testing strategy that validates your infrastructure code *before* it merges to the main branch.

This article bridges the gap between infrastructure and software engineering. We will cover a three-tiered testing strategy: local linting with VS Code, compilation validation using the Azure DevOps Dry Run API, and logical unit testing with Pester.

### Level 1: Static Analysis and Linting

The first line of defense is your IDE. You should catch basic type errors (e.g., passing a string where a boolean is expected) before you even save the file.

#### VS Code Extensions
Microsoft provides the official **Azure Pipelines** extension for VS Code. It offers syntax highlighting and autocompletion, but its real power lies in schema validation.

To enable strict validation, you can bind the extension to a specific schema. If you use custom tasks, you can download your organization's specific schema and configure VS Code to use it.

**Configuration (`.vscode/settings.json`):**
```json
{
  "azure-pipelines.customSchemaFile": "./service-schema.json"
}
```

With this configured, VS Code will underline invalid properties in red. It catches common mistakes like `vmImage: ubuntu-latest` (correct) vs `vm-image: ubuntu-latest` (incorrect property name).

### Level 2: The "Dry Run" API (Preview Mode)

Linting catches syntax, but it cannot catch logical errors during expansion. For example, if you iterate over a parameter that doesn't exist, linting might pass, but the pipeline will fail at runtime.

Azure DevOps provides an API endpoint that "compiles" the YAML into its final expanded form without actually running any jobs. This is the **Dry Run** check.

#### invoking the Preview API
You can automate this check in your Pull Request validation pipeline. The endpoint accepts your YAML content and returns the fully expanded pipeline.

**PowerShell Script (`scripts/validate-yaml.ps1`):**

```powershell
param (
    [string]$OrgUrl,
    [string]$Project,
    [int]$PipelineId,
    [string]$YamlPath,
    [string]$Token
)

$uri = "$OrgUrl/$Project/_apis/pipelines/$PipelineId/runs?api-version=7.1-preview.1"
$yamlContent = Get-Content $YamlPath -Raw

$body = @{
    previewRun = $true
    yamlOverride = $yamlContent
} | ConvertTo-Json

$headers = @{ Authorization = "Basic $([Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$Token")))" }

try {
    $response = Invoke-RestMethod -Uri $uri -Method Post -Body $body -ContentType "application/json" -Headers $headers
    Write-Host "YAML is valid. Final YAML:"
    Write-Host $response.finalYaml
}
catch {
    Write-Error "Validation Failed: $($_.Exception.Message)"
    exit 1
}
```

If the API returns a 200 OK, your YAML is structurally valid. If it fails, the API returns the exact expansion error (e.g., "Line 15: A mapping was not expected").

### Level 3: Logic Testing with Pester

The Dry Run API confirms *if* the YAML compiles. Pester confirms *what* the YAML does.

Pester is a testing framework for PowerShell. Since we cannot run the Azure DevOps engine locally, we use Pester to parse the YAML file into a PowerShell object and assert that specific structures exist.

#### Why Pester?
You want to verify scenarios like:
*   "If `isProduction` is true, the `CredScan` task must be present."
*   "If `environment` is 'Dev', the `Approval` job must NOT exist."

#### Practical Example: Writing a Unit Test
Let's test a secure build template (`jobs/build-secure.yml`) to ensure it enforces our governance rules.

**Prerequisites:**
```powershell
Install-Module -Name Pester -Force
Install-Module -Name powershell-yaml -Force
```

**The Test Script (`tests/build-secure.Tests.ps1`):**

```powershell
Describe "Secure Build Template Structure" {
    # 1. Parse the YAML file into an object
    $yamlPath = Join-Path $PSScriptRoot "../jobs/build-secure.yml"
    $yaml = Get-Content $yamlPath -Raw | ConvertFrom-Yaml

    Context "Parameter Definitions" {
        It "Should accept a 'buildSteps' parameter of type 'stepList'" {
            $param = $yaml.parameters | Where-Object { $_.name -eq 'buildSteps' }
            $param.type | Should -Be 'stepList'
        }
    }

    Context "Mandatory Security Steps" {
        $steps = $yaml.jobs[0].steps

        It "Should include the CredScan task" {
            $credScan = $steps | Where-Object { $_.task -like "CredScan@*" }
            $credScan | Should -Not -BeNullOrEmpty
        }

        It "Should publish artifacts at the end" {
            $lastStep = $steps[-1]
            $lastStep.task | Should -Like "PublishBuildArtifacts@*"
        }
    }
}
```

**Running the Test:**
Execute `Invoke-Pester` in your terminal. You will see green checks for every assertion that passes. If someone accidentally deletes the `CredScan` task from the template, this test will fail, blocking the Pull Request.

### Integration Testing (The Real Deal)

While Pester tests the static structure, it cannot evaluate Azure DevOps template expressions (like `${{ if }}`). To test complex conditional logic, you need a **Test Pipeline**.

Create a dedicated pipeline file in your template repository (`azure-pipelines-test.yml`). This pipeline should consume the templates *from the current branch*.

```yaml
# azure-pipelines-test.yml
trigger: none
pr:
  branches:
    include:
      - main

resources:
  repositories:
    - repository: self

stages:
  - stage: Test_Build_Template
    jobs:
      - template: jobs/build-secure.yml
        parameters:
          buildSteps:
            - script: echo "Testing the template..."
```

This pipeline acts as a comprehensive integration test. If the template contains invalid logic that causes the Dry Run to fail or the agent to error out, the PR build will fail.

### Best Practices and Tips

#### Do's
*   **Run the Dry Run Check on PRs:** This is the cheapest way to catch syntax errors.
*   **Use `powershell-yaml`:** This module is essential for parsing YAML into queryable objects in PowerShell.
*   **Test the "Golden Path":** Ensure your test pipeline covers the most common use case for your template.

#### Don'ts
*   **Rely on the Web UI Validator:** The "Validate" button in the browser is manual and easy to forget. Automate validation in your CI.
*   **Ignore Linting Warnings:** Yellow squiggly lines in VS Code usually indicate deprecated properties that will break in future API versions. Fix them immediately.

### Troubleshooting Common Issues

**Issue 1: "YAML mapping not allowed"**
*   **Cause:** Indentation errors. YAML is strict about hierarchy.
*   **Solution:** Use the VS Code formatter (Shift+Alt+F) to enforce consistent indentation.

**Issue 2: Pester cannot parse `${{ }}`**
*   **Cause:** `powershell-yaml` treats `${{ }}` as a simple string string. It does not evaluate the expression.
*   **Solution:** Pester tests the *structure* of the file (e.g., "Is there an `if` block?"). It does not test the *result* of the `if` block. For that, use the Integration Test pipeline.

### Conclusion

"Testing in Production" is unprofessional for Platform Engineers. By implementing VS Code linting, the Dry Run API, and Pester unit tests, you create a safety net that catches 99% of errors before they impact developers.

This completes the technical deep-dive into managing YAML templates. You now have the architecture, governance, logic, and testing strategies needed to run a world-class DevOps platform.

**Next Steps:**
1.  Create a `tests/` folder in your template repository.
2.  Write a simple `validate.ps1` script that calls the Dry Run API.
3.  Add `azure-pipelines-test.yml` to your repo to validate PRs automatically.
4.  Read the final article on **[Securely Handling Secrets in Reusable Templates]** to ensure your well-tested templates don't leak credentials.

**Related Articles in This Series:**
*   [Designing a Centralized YAML Template Repository]
*   [Advanced YAML Logic: Objects, Loops, and Conditions]
*   [Securely Handling Secrets in Reusable Templates]
