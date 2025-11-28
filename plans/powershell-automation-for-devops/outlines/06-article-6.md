---
title: "Integrating PowerShell into CI/CD Pipelines (GitHub Actions, Azure DevOps)"
date: 2025-11-26T12:45:00
draft: true
description: "Learn how to seamlessly integrate PowerShell scripts into GitHub Actions and Azure DevOps pipelines for robust, cross-platform automation."
series: ["powershell-automation-for-devops"]
tags: ["PowerShell", "DevOps", "CI/CD", "GitHub Actions", "Azure DevOps"]
categories: ["Automation"]
weight: 6
---

## Article Structure Outline

### Introduction (150-200 words target)
**Hook:** "It works on my machine" is the developer's famous last words. How do you ensure your perfectly crafted PowerShell automation runs reliably everywhere, every time?

**Problem/Context:** Manual script execution is error-prone, unscalable, and lacks audit trails. In modern DevOps, automation must be automatedΓÇötriggered by events, not humans.

**What Reader Will Learn:**
- How to execute PowerShell scripts within GitHub Actions and Azure DevOps.
- Strategies for managing secrets and environment variables securely.
- Techniques for passing data between pipeline steps using PowerShell.
- Best practices for cross-platform script execution (Windows vs. Linux runners).

**Preview:** We will break down the specific syntax for both major platforms, explore how to handle dependencies, and build a real-world deployment pipeline example.

### 1. PowerShell in the CI/CD Ecosystem

#### 1.1 The Role of PowerShell in Pipelines
**Key Points:**
- Ideally suited for "glue code" (orchestrating disparate tools).
- Cross-platform capabilities (PowerShell Core/7+) mean one script for Linux and Windows runners.
- Access to rich object models for validating build states (unlike Bash/sh text streams).

**Content Notes:**
- [PLACEHOLDER: Comparison table: PowerShell vs. Bash in CI/CD contexts]
- [PLACEHOLDER: Diagram showing PowerShell wrapping CLI tools (git, docker, az cli)]

#### 1.2 The "Runner" Environment
**Key Points:**
- Understanding ephemeral build agents.
- Pre-installed software vs. installing modules on the fly.
- The importance of `pwsh` (Core) vs. `powershell` (Desktop) executables.

**Content Notes:**
- [PLACEHOLDER: Code to check `$PSVersionTable` inside a pipeline]

### 2. Implementing PowerShell in GitHub Actions

#### 2.1 The `run` Key and Shell Context
**Key Points:**
- Using `shell: pwsh` to enforce PowerShell Core.
- Multiline scripts vs. calling external `.ps1` files.
- Handling exit codes (GitHub Actions fails on non-zero exit).

**Content Notes:**
- [PLACEHOLDER: YAML snippet showing a basic inline script]
- [PLACEHOLDER: YAML snippet calling a script file with arguments]

#### 2.2 interacting with GitHub Environment
**Key Points:**
- accessing `${{ secrets.MY_SECRET }}` as environment variables.
- Using GitHub Filesystem variables (`$env:GITHUB_WORKSPACE`).
- Writing to `$env:GITHUB_OUTPUT` and `$env:GITHUB_ENV` to pass values to subsequent steps.

**Content Notes:**
- [PLACEHOLDER: Example: Setting a pipeline variable from PowerShell]
- [PLACEHOLDER: Example: Securely mapping a secret to a script parameter]

### 3. Implementing PowerShell in Azure DevOps

#### 3.1 The PowerShell Task (`PowerShell@2`)
**Key Points:**
- Inline script vs. File Path options.
- "ErrorActionPreference" settings within the task configuration.
- Working with Azure Service Connections inside PowerShell.

**Content Notes:**
- [PLACEHOLDER: YAML snippet for `PowerShell@2` task]
- [PLACEHOLDER: Screenshot of the Classic Editor task (briefly, focus on YAML)]

#### 3.2 Logging and VSO Commands
**Key Points:**
- Using `Write-Host` effectively (logs).
- The Magic of Logging Commands: `##vso[task.setvariable]` and `##vso[task.logissue]`.
- interacting with artifacts (publishing/downloading) via script logic.

**Content Notes:**
- [PLACEHOLDER: Code example: Script that sets a variable usable by a future task]
- [PLACEHOLDER: Code example: Script that fails the build with a custom error message]

### 4. Managing Dependencies and Modules

#### 4.1 "Just-in-Time" vs. "Baked-in"
**Key Points:**
- Pros/Cons of installing modules (`Install-Module`) during the pipeline run.
- Caching modules to speed up builds (`PSModulePath` strategies).
- Using a local `Modules` folder committed with the repo (vendoring).

**Content Notes:**
- [PLACEHOLDER: Script block for efficient module bootstrapping]
- [PLACEHOLDER: Performance comparison graph (conceptual)]

#### 4.2 Authentication for Private Feeds
**Key Points:**
- Authenticating with Azure Artifacts or private NuGet feeds.
- Managing `PSRepository` credentials securely in CI.

### Practical Example: A Cross-Platform Build & Deploy Pipeline

**Scenario:** A pipeline that versions a project, runs Pester tests, and "deploys" (simulated) a configuration if tests pass.

**Requirements:**
- Must run on `ubuntu-latest`.
- Must fail if Pester tests fail.
- Must use a secret API key.

**Implementation:**
- Step 1: Checkout code.
- Step 2: Bootstrap dependencies (Pester).
- Step 3: Execute Tests.
- Step 4: Run Deployment Script.

**Code Example:**
[PLACEHOLDER: Full `.github/workflows/main.yml` file]
[PLACEHOLDER: Corresponding `deploy.ps1` script]

**Expected Results:**
A green checkmark on GitHub, with logs showing test results and the simulated deployment output.

### Best Practices and Tips

**Do's:**
- Γ£ô Use explicit error handling (`$ErrorActionPreference = 'Stop'`) at the top of scripts.
- Γ£ô Validate inputs and environment variables early in the script.
- Γ£ô Use verbose logging (`Write-Verbose`) that can be toggled via pipeline variables.

**Don'ts:**
- Γ£ù Hardcode paths (use `$PSScriptRoot` or CI-provided workspace variables).
- Γ£ù Print secrets to the console (CI systems try to mask them, but don't risk it).
- Γ£ù Assume the "latest" version of a module is always safe (pin versions).

**Performance Tips:**
- Cache the `~/.local/share/powershell/Modules` directory.
- Avoid `Update-Module` if not strictly necessary on every run.

**Security Considerations:**
- Script injection risks if using user input (e.g., in PR titles).
- Principle of least privilege for the CI runner's identity.

### Troubleshooting Common Issues

**Issue 1: "Script file not found"**
- **Cause:** Confusion between Linux forward slashes `/` and Windows backslashes `\`.
- **Solution:** Use `Join-Path` or forward slashes (which work in PowerShell on Windows too).

**Issue 2: "The term 'Connect-AzAccount' is not recognized"**
- **Cause:** The Azure PowerShell module isn't loaded or the context isn't set.
- **Solution:** Use the `AzureCLI@2` or `AzurePowerShell@5` wrapper tasks which handle authentication, or manually install modules.

### Conclusion

**Key Takeaways:**
1. PowerShell allows you to reuse the same automation logic locally and in the cloud.
2. GitHub Actions and Azure DevOps have different syntaxes but share core PowerShell principles.
3. Proper exit code handling is critical for signaling success/failure to the pipeline.
4. VSO commands (Azure DevOps) and Environment Files (GitHub) are the bridges between script and platform.

**Next Steps:**
- Audit your current pipelines: where are you using rigid bash scripts that could be flexible PowerShell?
- Try converting a manual deployment checklist into a single `.ps1` run by a GitHub Action.

**Related Articles in This Series:**
- [Article 5: Managing Cloud Resources with PowerShell]
- [Article 7: Automated Testing with Pester]
- [Article 8: PowerShell Best Practices for Robust DevOps Scripts]
