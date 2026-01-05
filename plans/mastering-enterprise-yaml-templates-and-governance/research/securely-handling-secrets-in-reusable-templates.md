# Research Report: Securely Handling Secrets in Reusable Templates

## 1. Executive Summary & User Intent
- **Core Definition:** Secure secret handling in Azure DevOps templates involves abstracting credential access using Workload Identity Federation (WIF) or dynamic Key Vault fetches, ensuring secrets are never passed as static parameters or logged during expansion.
- **User Intent:** The reader wants to stop hardcoding passwords and PATs. They need a pattern for templates that can deploy to any environment (Dev/Prod) without the template itself "knowing" the secrets.
- **Relevance:** With the rise of "Supply Chain Attacks," hardcoded secrets in shared templates are a massive liability. Workload Identity is now the Microsoft-recommended standard, replacing legacy Service Principals with secrets.

## 2. Key Technical Concepts & Details
- **Core Components:**
    - **Workload Identity Federation (WIF):** Uses OIDC tokens instead of client secrets. Trusts the Azure DevOps pipeline identity to access Azure resources.
    - **AzureKeyVault@2 Task:** dynamically fetches secrets at runtime based on filters.
    - **Environment Variable Mapping:** The only secure way to pass a secret to a script (`env: MY_SECRET: $(Var)`).
- **Key Terminology:**
    - **Parameter Expansion:** The phase where `${{ parameters.password }}` is replaced with the literal string value. If this happens in a logged command, the secret is leaked.
    - **Secret Masking:** Azure DevOps tries to replace known secrets with `***`, but it fails if the secret is base64 encoded or transformed.

## 3. Practical Implementation Data

### The "Anti-Pattern" (Why Parameters Leak)
If you pass a secret like this:
```yaml
parameters:
  - name: dbPassword
    type: string

steps:
  - script: echo "Connecting with ${{ parameters.dbPassword }}" # LEAK!
```
The pipeline expands this *before* execution. The log will show the actual password if masking fails or if the logs are verbose.

### Pattern 1: Dynamic Key Vault Access
Instead of passing the secret, pass the *name* of the vault.

```yaml
parameters:
  - name: keyVaultName
    type: string

steps:
  - task: AzureKeyVault@2
    inputs:
      azureSubscription: 'MyServiceConnection'
      KeyVaultName: ${{ parameters.keyVaultName }}
      SecretsFilter: 'DB-Password,API-Key'
```

### Pattern 2: Workload Identity Federation (WIF)
**Configuration Steps:**
1.  **Project Settings > Service Connections**.
2.  **New Service Connection > Azure Resource Manager**.
3.  Select **Workload Identity Federation (Automatic)**.
4.  Azure DevOps creates a Federated Credential in Azure AD that trusts this specific project/pipeline.
5.  **Result:** No client secrets to rotate or leak.

### Pattern 3: Secure Script Usage
Always map secrets to `env` variables. Never use `$(Secret)` inline.

```yaml
steps:
  - powershell: |
      # Safe: Accessed from process environment
      $conn = $env:DB_CONNECTION_STRING
      ./deploy-db.ps1 -ConnectionString $conn
    env:
      DB_CONNECTION_STRING: $(MySecretVariable)
```

## 4. Best Practices vs. Anti-Patterns

### Best Practices (Do This)
- **Use WIF:** Migrate all Service Connections to Workload Identity.
- **Map to Env:** Explicitly map secrets in the `env:` block of tasks.
- **Variable Groups:** Use Library Variable Groups linked to Key Vaults for environment-specific config.

### Anti-Patterns (Don't Do This)
- **Echoing Variables:** `Write-Host $(Secret)` is asking for trouble.
- **Client Secrets:** Avoid Service Connections that rely on a "Client Secret" (password) that expires.
- **Transforming Secrets:** Don't base64 encode a secret before using it; Azure DevOps won't recognize the encoded string as a secret and won't mask it.

## 5. Edge Cases & Troubleshooting
- **Error: "Input required: connectedServiceName"**
    - *Cause:* You cannot use a runtime variable (`$(ConnName)`) for the `azureSubscription` input of a task. It must be a compile-time string or parameter (`${{ parameters.ConnName }}`).
- **Secret Leaking in Logs:**
    - *Cause:* The secret was likely transformed (e.g., to uppercase or JSON) or passed as a command-line argument that the OS logged.

## 6. Industry Context (2025)
- **Trends:** "Secretless" architecture is the standard. Services like Azure SQL now support Azure AD Auth, meaning you don't even need a connection string—just the WIF identity.

## 7. References & Authority
- **Microsoft Docs:** "Workload identity federation".
- **Azure DevOps Blog:** "Securing your pipelines with OIDC".
