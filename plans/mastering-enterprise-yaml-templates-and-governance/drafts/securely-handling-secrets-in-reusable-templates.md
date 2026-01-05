## Front Matter (YAML format)
---
title: "Securely Handling Secrets in Reusable Templates"
date: 2025-12-23T10:00:00
draft: false
description: "Build secure-by-design pipelines. Learn how to manage secrets, Service Connections, and Workload Identity Federation within shared Azure DevOps templates."
series: ["Mastering Enterprise YAML Templates & Governance"]
tags: ["Azure DevOps", "Security", "Key Vault", "DevSecOps", "Identity Management"]
categories: ["Security", "DevOps"]
weight: 5
---

A shared template that logs a password to the console isn't a tool; it's a vulnerability.

When you centralize your pipelines, you also centralize your risk. One bad line of code in a shared template can expose credentials across fifty different projects. Managing secrets in a single pipeline is challenging enough, but doing it in a template—where you don't know who is consuming it or what variables they possess—requires a "Zero Trust" approach.

This article defines the secure patterns for handling secrets in reusable templates. You will learn how to avoid the "Parameter Expansion" trap, pass Service Connections safely, and adopt Workload Identity Federation (WIF) to eliminate the need for secrets entirely.

### The "Golden Rule" of Secrets in Templates

#### Parameters vs. Variables
The most common security mistake in YAML templates is passing a secret as a string parameter.

**The Anti-Pattern:**
```yaml
# templates/deploy-db.yml
parameters:
  - name: dbPassword # NEVER DO THIS
    type: string

steps:
  - script: echo "Connecting with ${{ parameters.dbPassword }}"
```

**Why this fails:** Template parameters are expanded at **compile time**. This means Azure DevOps replaces `${{ parameters.dbPassword }}` with the literal string value *before* the pipeline runs. If you have verbose logging enabled, or if the script errors out and prints the command line, your secret is now visible in plain text in the logs.

**The Secure Pattern:**
Pass the **name** of the variable, not the value.

```yaml
# templates/deploy-db.yml
parameters:
  - name: passwordVariableName
    type: string

steps:
  - powershell: |
      # Map the variable dynamically at runtime
      $password = Get-Content Env:MY_PASSWORD
      ./deploy.ps1 -Password $password
    env:
      # Use the macro syntax to map the variable securely
      MY_PASSWORD: $($(parameters.passwordVariableName))
```

In this pattern, the template never "sees" the secret during compilation. It only handles the reference to the secret, which is resolved by the agent at runtime.

### Pattern 1: Dynamic Key Vault Access

Hardcoding Key Vault names in templates limits their reusability. Instead, allow the consumer to specify which Vault to use, and let the template handle the fetching logic safely.

**The Template (`steps/fetch-secrets.yml`):**

```yaml
parameters:
  - name: keyVaultName
    type: string
  - name: serviceConnection
    type: string
  - name: secretsFilter
    type: string
    default: '*'

steps:
  - task: AzureKeyVault@2
    displayName: 'Fetch Secrets from ${{ parameters.keyVaultName }}'
    inputs:
      azureSubscription: ${{ parameters.serviceConnection }}
      KeyVaultName: ${{ parameters.keyVaultName }}
      SecretsFilter: ${{ parameters.secretsFilter }}
      RunAsPreJob: false # Important: Run as a task to control timing
```

**Why this is secure:**
1.  **Least Privilege:** The consumer can pass a specific `secretsFilter` (e.g., `'DB-Password,API-Key'`) so the pipeline only fetches what it needs, rather than downloading the entire vault.
2.  **Auditability:** The `AzureKeyVault` task logs exactly which secrets were downloaded (by name, not value), creating an audit trail.

### Pattern 2: Service Connections & Identity

Service Connections are the keys to your kingdom. In a shared template model, you need to ensure that a Dev pipeline cannot use a Prod service connection.

#### Parameterizing Service Connections
Service Connections are referenced by string names in YAML. You should accept the connection name as a parameter to allow one template to deploy to multiple environments.

```yaml
parameters:
  - name: azureConnection
    type: string

steps:
  - task: AzureCLI@2
    inputs:
      azureSubscription: ${{ parameters.azureConnection }}
      scriptType: bash
      scriptLocation: inlineScript
      inlineScript: az group list
```

**Security Check:** Azure DevOps enforces permissions at the **Pipeline** level. Even if a user passes `Prod-Connection` to your template, the pipeline will fail immediately if that specific pipeline has not been authorized to use that Service Connection.

#### Moving to Workload Identity Federation (WIF)
The safest secret is the one that doesn't exist. Workload Identity Federation (WIF) allows Azure DevOps to authenticate to Azure without managing "Client Secrets" (passwords) that expire and leak.

**Configuration Steps:**
1.  Go to **Project Settings > Service Connections**.
2.  Create a new **Azure Resource Manager** connection.
3.  Select **Workload Identity Federation (automatic)**.
4.  Azure DevOps will create a Federated Credential in Azure AD that trusts the OpenID Connect (OIDC) token issued by your pipeline.

When you use this connection in a template, there are no secrets to rotate, no SPNs to manage, and nothing to leak in the logs.

### Practical Example: The "Zero-Knowledge" Deployment

Let's build a deployment template that connects to a database. The template needs the password to run a script, but we want to ensure the template itself never exposes it.

**1. The Template (`deploy-db.yml`)**

```yaml
parameters:
  - name: keyVaultName
    type: string
  - name: azureConnection
    type: string

steps:
  # 1. Fetch the secret (Runtime Variable: $(db-password))
  - task: AzureKeyVault@2
    inputs:
      azureSubscription: ${{ parameters.azureConnection }}
      KeyVaultName: ${{ parameters.keyVaultName }}
      SecretsFilter: 'db-password'

  # 2. Use the secret securely
  - powershell: |
      $connString = "Server=tcp:prod.database.windows.net;Password=$($env:SQL_PASS);"
      Write-Host "Deploying to DB..." 
      # Do NOT Write-Host the connection string!
      ./update-schema.ps1 -ConnectionString $connString
    env:
      # Explicitly map the secret to an environment variable
      SQL_PASS: $(db-password)
```

**2. The Consuming Pipeline**

```yaml
extends:
  template: deploy-db.yml
  parameters:
    keyVaultName: 'prod-secrets-kv'
    azureConnection: 'Azure-Prod-WIF'
```

**Expected Results:**
The script successfully connects to the database. If you inspect the logs, you will see `***` wherever the password might have appeared. Because we mapped it to an environment variable (`$env:SQL_PASS`), the value was never passed as a command-line argument, which avoids OS-level logging risks.

### Best Practices and Tips

#### Do's
*   **Use `env:` Mapping:** Always map secrets to environment variables in `PowerShell@2` or `Bash@3` tasks. This is the only secure way to pass secrets to scripts.
*   **Use Variable Groups:** For environment-specific configuration that isn't sensitive (like URLs), use Library Variable Groups. For secrets, link those Variable Groups to Key Vaults.
*   **Migrate to WIF:** Audit your existing Service Connections. If any are using "Service Principal (manual)" with a client secret, plan a migration to Workload Identity Federation.

#### Don'ts
*   **Echo Secrets:** Never run `Write-Host $(mySecret)` to "debug". It defeats the purpose of masking.
*   **Base64 Encode Secrets:** Azure DevOps masking only works on the exact string. If you base64 encode a secret (`VGh...`), Azure DevOps won't recognize it as a secret and will print it in plain text.
*   **Pass Secrets as Arguments:** Avoid `./script.sh --password $(mySecret)`. If the script crashes or the OS logs process creation events, the command line arguments (including the password) may be visible.

### Troubleshooting Common Issues

**Issue 1: "Input required: connectedServiceName"**
*   **Cause:** You tried to use a runtime variable (`$(connectionName)`) for the `azureSubscription` input.
*   **Solution:** Service Connection inputs MUST be known at compile time. You must use a parameter (`${{ parameters.connectionName }}`) or a hardcoded string.

**Issue 2: Secrets appearing in logs**
*   **Cause:** The secret contains special characters (like quotes) that broke the command line parsing, or the secret was transformed (e.g., converted to JSON) before being printed.
*   **Solution:** Ensure you are using `env:` mapping, which bypasses command-line parsing issues entirely.

### Conclusion

Secure secret handling is the litmus test for a mature DevOps platform. By following the "Golden Rule" (parameters for config, variables for secrets) and adopting Workload Identity Federation, you can build templates that are both flexible and secure.

You have now completed the **Mastering Enterprise YAML Templates & Governance** series. You have the architecture, the governance controls, the logic, the testing strategy, and the security patterns to build a world-class CI/CD platform.

**Related Articles in This Series:**
*   [The Architect’s Guide to Scalable Azure DevOps YAML Templates]
*   [Enforcing Governance with `extends` Templates]
*   [Validating and Testing Your YAML Templates]
