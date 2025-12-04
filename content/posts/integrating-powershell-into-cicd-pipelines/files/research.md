The comprehensive research report has been generated and saved to `.gemini/tmp/powershell_research.md`.

Here is the full content of the report:

# Research Report: Integrating PowerShell into CI/CD Pipelines (Azure DevOps & GitHub Actions)

## 1. Executive Summary & User Intent
*   **Core Definition:** The practice of embedding PowerShell scripts within Continuous Integration and Continuous Deployment (CI/CD) workflows (specifically Azure DevOps and GitHub Actions) to automate build, test, and deployment tasks.
*   **User Intent:** The reader seeks a practical, "how-to" guide for reliability and security. They want to know the *exact* syntax to run scripts, how to pass secrets without leaking them, and how to ensure the pipeline stops immediately if a script fails.
*   **Relevance:** As of late 2025, PowerShell 7+ (Core) is the standard for cross-platform automation. Understanding how to invoke it correctly in YAML-based pipelines is critical for DevOps engineers managing hybrid environments (Windows/Linux).

## 2. Key Technical Concepts & "All-Inclusive" Details
*   **Core Components:**
    *   **Runners/Agents:** The Virtual Machines (VMs) executing the code (e.g., `ubuntu-latest`, `windows-latest`).
    *   **YAML:** The configuration language used by both platforms to define pipeline steps.
    *   **Shell Context:** The specific environment the script runs in (`pwsh` for PowerShell 7+, `powershell` for Windows PowerShell 5.1).
*   **How it Works:** The CI/CD orchestrator (Azure DevOps or GitHub Actions) spawns a shell process, injects environment variables (secrets, config), executes the script, and listens for an **Exit Code**.
    *   `Exit Code 0` = Success.
    *   `Exit Code Non-Zero` (e.g., 1) = Failure (stops the pipeline).
*   **Specific Limits:**
    *   **Azure DevOps:** Standard timeout is 60 minutes for hosted agents.
    *   **GitHub Actions:** Standard timeout is 6 hours for a job.
    *   **Log Size:** Excessive output (e.g., looping `Write-Host`) can be truncated or cause UI lag.

## 3. Practical Implementation (The "Solid" Part)

### A. Azure DevOps Integration
**Standard Pattern:** Use the `PowerShell@2` task for maximum control, or the `pwsh:` shortcut for brevity.

**Scenario 1: Inline Script (Simple)**
```yaml
steps:
- pwsh: |
    Write-Host "Starting build..."
    $version = "1.0.$env:BUILD_BUILDID"
    Write-Host "Build Version: $version"
  displayName: 'Print Build Version'
```

**Scenario 2: File-based Script with Arguments (Robust)**
```yaml
steps:
- task: PowerShell@2
  displayName: 'Run Deploy Script'
  inputs:
    targetType: 'filePath'
    filePath: '$(System.DefaultWorkingDirectory)/scripts/deploy.ps1'
    arguments: '-Environment "Production" -Verbose'
    pwsh: true  # Force PowerShell Core (7+)
    failOnStderr: true # Optional: Fail if ANY error text is written to stderr
```

### B. GitHub Actions Integration
**Standard Pattern:** Use the `run` keyword with `shell: pwsh` to ensure cross-platform compatibility.

**Scenario 1: Passing Secrets & Variables**
*   **Crucial:** Map secrets to *environment variables*, never pass them as command-line arguments (which allows them to be seen in process lists).

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Run Sensitive Script
        shell: pwsh
        env:
          # MAP SECRET TO ENV VARIABLE HERE
          API_KEY: ${{ secrets.PROD_API_KEY }}
        run: |
          # Access inside PowerShell as $env:API_KEY
          ./scripts/invoke-api.ps1 -Key $env:API_KEY
```

**Scenario 2: Setting Pipeline Outputs (Modern Syntax)**
*   **Note:** The old `::set-output` command is deprecated. Use `$env:GITHUB_OUTPUT`.

```yaml
      - name: Calculate Version
        id: versioning
        shell: pwsh
        run: |
          $ver = "1.2.3"
          # Write key=value to the special output file
          "APP_VERSION=$ver" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
      
      - name: Use Output
        run: echo "The version is ${{ steps.versioning.outputs.APP_VERSION }}"
```

## 4. Best Practices vs. Anti-Patterns

| Feature | **Do This (Best Practice)** | **Don't Do This (Anti-Pattern)** |
| :--- | :--- | :--- |
| **Error Handling** | Set `$ErrorActionPreference = 'Stop'` at the top of every script. | Rely on default behavior (Continue), which hides errors and reports "Success" even if commands fail. |
| **Secrets** | Map secrets to `$env:VAR` in YAML. | Pass secrets as arguments (`-ApiKey ${{ secrets.KEY }}`). |
| **Logging** | Use `Write-Output` for data, `Write-Warning`/`Verbose` for logs. | Use `Write-Host` for *everything*. (It creates noise and isn't always captured in structured logs). |
| **Exit Codes** | Explicitly `exit 1` in a `catch` block. | Allow the script to finish naturally after an error (which results in Exit Code 0). |
| **Modules** | Install modules (e.g., `Install-Module Pester`) in a separate "Setup" step with caching. | Install modules inside the main logic script every time (slow). |

## 5. Edge Cases & Troubleshooting
*   **The "Silent Failure":** A script throws a red error text but the pipeline stays green.
    *   *Cause:* `$ErrorActionPreference` was not set to `Stop`, and the script finished execution with exit code 0.
    *   *Fix:* Add `$ErrorActionPreference = 'Stop'` and wrap logic in `try { ... } catch { exit 1 }`.
*   **Azure PowerShell Context:**
    *   *Issue:* Standard `pwsh` tasks cannot access Azure resources by default.
    *   *Fix:* Use the specific `AzurePowerShell@5` task which handles the Service Principal authentication automatically.
*   **Windows vs. Linux Paths:**
    *   *Issue:* Hardcoding `C:\Temp\` breaks on Linux agents.
    *   *Fix:* Use `Join-Path` and automatic variables like `$env:TEMP` or `$env:GITHUB_WORKSPACE`.

## 6. Industry Context (2025)
*   **Shift to OIDC:** Instead of storing long-lived secrets (Client Secrets) for Azure/AWS, the industry is moving to **OpenID Connect (OIDC)** (Federated Credentials). This allows GitHub Actions to request a short-lived token from Azure directly without managing a stored secret.
*   **Deprecations:** GitHub Actions definitively deprecated the `Write-Host "::set-output..."` syntax. The `$env:GITHUB_OUTPUT` file method is the only supported standard.
*   **Pester 5+:** Unit testing infrastructure inside pipelines is now almost exclusively Pester 5. Ensure your test runner scripts are compatible with Pester 5 discovery phases.

## 7. References & Authority
*   **Microsoft Docs:** [Azure DevOps YAML Schema](https://learn.microsoft.com/azure/devops/pipelines/yaml-schema)
*   **GitHub Docs:** [Workflow Syntax for GitHub Actions](https://docs.github.com/actions/using-workflows/workflow-syntax-for-github-actions)
*   **Community Authority:** "The DevOps Collective" (OnRamper) and Pester framework documentation.
