## Front Matter (YAML format)
---
title: "Securely Handling Secrets in Reusable Templates"
date: 2025-12-23T10:00:00
draft: true
description: "Build secure-by-design pipelines. Learn how to manage secrets, Service Connections, and Workload Identity Federation within shared Azure DevOps templates."
series: ["Mastering Enterprise YAML Templates & Governance"]
tags: ["Azure DevOps", "Security", "Key Vault", "DevSecOps", "Identity Management"]
categories: ["Security", "DevOps"]
weight: 5
---

## Article Structure Outline

### Introduction (150-200 words target)
**Hook:** A shared template that logs a password to the console isn't a tool; it's a vulnerability. When you centralize your pipelines, you also centralize your risk. One bad line of code can expose credentials across fifty projects.

**Problem/Context:** Managing secrets in a single pipeline is hard enough. Doing it in a template—where you don't know who is consuming it or what variables they have—is exponentially harder. Hardcoding, accidental logging, and passing secrets as plain-text parameters are rampant issues.

**What Reader Will Learn:** This article defines the "Zero Trust" approach to pipeline templates. You’ll learn how to pass Service Connections safely, fetch secrets from Key Vaults dynamically, and adopt Workload Identity Federation to eliminate secrets entirely.

**Preview:** We’ll explore the "Parameter vs. Variable" debate for secrets, demonstrate the secure way to use `AzureKeyVault@2`, and show how to lock down Service Connections so only specific templates can use them.

### The "Golden Rule" of Secrets in Templates

#### Parameters vs. Variables
**Key Points:**
- **Never** pass a secret as a string parameter (`parameters.password`).
- Why parameters are expanded at compile time (and often visible in logs/API).
- The correct pattern: Pass the *name* of the variable (`parameters.secretVariableName`) and map it at runtime.

**Content Notes:**
- [PLACEHOLDER: Code snippet: The Anti-Pattern (passing a secret directly)]
- [PLACEHOLDER: Code snippet: The Secure Pattern (passing the variable name)]

#### Secret Masking
**Key Points:**
- How Azure DevOps automatically masks variables marked as "Secret".
- The danger of base64 encoding or string manipulation breaking the mask.

### Pattern 1: Dynamic Key Vault Access

#### Parameterizing the Vault Name
**Key Points:**
- The template shouldn't know *which* Key Vault to use; the consumer should tell it.
- Using `AzureKeyVault@2` inside the template.
- Filtering which secrets are fetched to apply the Principle of Least Privilege.

**Content Notes:**
- [PLACEHOLDER: Example template that accepts `keyVaultName` and `secretFilter` as parameters]

### Pattern 2: Service Connections & Identity

#### Parameterizing Service Connections
**Key Points:**
- Service Connections are just string names in YAML.
- Accepting the connection name as a parameter allows one template to deploy to Dev, Test, and Prod.
- **Security Check:** Ensuring the pipeline has permission to use the connection (Authorized Resources).

#### Moving to Workload Identity Federation (WIF)
**Key Points:**
- The end of "Client Secrets" and rotating keys.
- How WIF works with Azure Service Connections.
- Why templates using WIF are inherently more secure (no secrets to leak).

### Practical Example: The "Zero-Knowledge" Deployment

**Scenario:** A generic deployment template that needs to connect to a database using a password, but the template itself must never see or log that password.

**Requirements:**
- Consumer pipeline defines the Key Vault.
- Template fetches the DB connection string.
- Template uses the connection string in a script without exposing it.

**Implementation:**
- Step 1: Consumer passes `kvName: 'my-prod-kv'`.
- Step 2: Template runs `AzureKeyVault@2` to get `db-connection-string`.
- Step 3: Template maps `$(db-connection-string)` to an environment variable `env: DB_CONN`.
- Step 4: Script uses `$env:DB_CONN`.

**Code Example:**
[PLACEHOLDER: `deploy-db.yml` template using `env` mapping]
[PLACEHOLDER: Consuming pipeline]

**Expected Results:**
The script connects successfully. The logs show `***` instead of the connection string.

### Best Practices and Tips

**Do's:**
- ✓ **Do** map secrets to environment variables explicitly (`env: MY_SECRET: $(mySecret)`).
- ✓ **Do** use Workload Identity Federation for all new Azure Service Connections.
- ✓ **Do** use "Library" Variable Groups to organize secrets by environment.

**Don'ts:**
- ✗ **Don't** echo variables to debug them.
- ✗ **Don't** use `$(variable)` syntax inside a script; use environment variables instead to avoid injection attacks.

**Performance Tips:**
- Fetching secrets takes time; fetch only what you need.

**Security Considerations:**
- **Audit Logging:** Ensure you know *who* triggered the pipeline that accessed the Key Vault.
- **Governance:** Use Azure Policy to restrict Key Vault access to specific IP ranges (Azure DevOps IPs).

### Troubleshooting Common Issues

**Issue 1: "Input required: connectedServiceName"**
- **Cause:** Passing a variable `$(connectionName)` to a task input that requires a compile-time string.
- **Solution:** Some tasks (like AzureKeyVault) require the connection name to be known at compile time or passed via parameters, not runtime variables.

**Issue 2: Secrets not masked in logs**
- **Cause:** The secret was likely transformed (e.g., to uppercase or base64) before being logged.
- **Solution:** Azure DevOps only masks the *exact string*. Avoid transformations.

### Conclusion

**Key Takeaways:**
1. Parameters are for configuration; Variables are for secrets.
2. Never pass a raw secret into a template parameter.
3. Use Workload Identity to remove secrets from the equation entirely.
4. Always map secrets to environment variables in your scripts.

**Next Steps:**
- Audit your existing templates for plain-text password parameters.
- Migrate your Service Connections to Workload Identity Federation.
- You have now completed the "Mastering Enterprise YAML Templates" series!

**Related Articles in This Series:**
- [The Architect’s Guide to Scalable Azure DevOps YAML Templates]
- [Enforcing Governance with `extends` Templates]
- [Validating and Testing Your YAML Templates]

---

## Author Notes (Not in final article)

**Target Word Count:** 1500-1800 words

**Tone:** Serious, Security-focused.

**Audience Level:** Advanced

**Key Terms to Define:**
- **Workload Identity Federation:** A method of authentication that allows software workloads to access resources without managing secrets (using OIDC).
- **Environment Variable vs Macro:** The difference between `$env:VAR` (OS level) and `$(VAR)` (Azure DevOps replacement).

**Internal Linking Opportunities:**
- Link to "Pillar Post" for the overall governance strategy.

**Code Example Types Needed:**
- "Good vs Bad" comparison for passing secrets.
- YAML snippet for `AzureKeyVault` task.
- PowerShell script showing safe environment variable usage.

**Visual Elements to Consider:**
- Diagram: How Workload Identity trusts the Azure DevOps OIDC token.
