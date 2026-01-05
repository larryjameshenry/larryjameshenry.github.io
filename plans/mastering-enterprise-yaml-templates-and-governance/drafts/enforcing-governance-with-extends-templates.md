## Front Matter (YAML format)
---
title: "Enforcing Governance with `extends` Templates"
date: 2025-12-23T10:00:00
draft: false
description: "Master the `extends` keyword in Azure DevOps to enforce mandatory security scans, policy checks, and standard workflows across your entire organization."
series: ["Mastering Enterprise YAML Templates & Governance"]
tags: ["Azure DevOps", "DevSecOps", "Governance", "Security", "YAML Pipelines"]
categories: ["Security", "DevOps"]
weight: 2
---

In a traditional DevOps model, security is often a "gate" at the end of the process—a manual check that slows down deployment. In a modern DevSecOps model, security is the *road* itself. But how do you pave that road so developers cannot accidentally (or intentionally) drive off-road?

Using standard `include` templates (`- template: file.yml`) allows developers to mix and match logic, but it offers zero guarantee that a security scan actually ran. If a developer can simply delete the line that runs the scanner, your governance model is broken.

This article dives deep into the `extends` keyword—the architectural bedrock of governed pipelines. You will learn how to wrap developer logic inside a rigid security skeleton that enforces compliance without hindering velocity.

### The Governance Gap: Why `steps` Templates Fail

#### The "Optional" Problem
Standard templates are essentially copy-paste shortcuts. They are excellent for reusing code but terrible for enforcing policy. When you provide a developer with a "Security Scan" template, you are relying on them to include it correctly.

Consider this standard pipeline:

```yaml
# azure-pipelines.yml
steps:
  - checkout: self
  - script: echo "Building..."
  
  # The developer *should* include this, but they don't have to.
  # - template: templates/security-scan.yml
```

The developer has full control over the `azure-pipelines.yml` file. They can delete the template reference, wrap it in a condition `if: false`, or move it to a non-blocking stage. From a governance perspective, this is a suggestion, not a mandate.

#### The "Skeleton" Solution (`extends`)
The `extends` keyword changes the relationship between the pipeline and the template. Instead of the pipeline *including* the template, the pipeline *inherits from* the template.

The template controls the entire structure—phases, jobs, and steps. The developer's YAML file essentially becomes a "parameters file" that supplies data to your template. Security steps defined in the parent template run automatically, and the developer has no mechanism to remove them.

### Architecting the "Skeleton" Template

#### Defining the Structure (The Sandwich Pattern)
The most effective pattern for governed templates is the "Sandwich Pattern." You define mandatory "Pre-Steps" (like restoring secure credentials or scanning source code) and mandatory "Post-Steps" (like uploading logs or cleaning up agents). The user's logic is injected into a specific slot in the middle.

#### Injection Points for Flexibility
To allow developers to build their specific applications, you define a parameter of type `stepList`. This tells Azure DevOps to accept a sequence of steps as a variable.

**The Base Template (`governed-build.yml`):**

```yaml
parameters:
  # The "Insertion Point" for user logic
  - name: buildSteps 
    type: stepList
    default: []

jobs:
  - job: SecureBuild
    pool: ubuntu-latest
    steps:
      - checkout: self
      
      # Mandatory Security Step (Top Bread)
      - task: CredScan@3
        displayName: 'Security: Credential Scan'

      # User Logic Injection (The Meat)
      - ${{ parameters.buildSteps }}

      # Mandatory Compliance Step (Bottom Bread)
      - task: PublishSecurityAnalysisLogs@3
```

In this architecture, the `CredScan` task always runs before the user's build steps, and the log publication always runs after.

### Advanced Enforcement: Required Templates Checks

Using `extends` creates a secure structure, but a developer could theoretically just create a new pipeline that *doesn't* extend your template. To close this loop, you must enforce usage at the resource level.

#### The "Force Field" for Service Connections
You can configure Azure DevOps to reject any pipeline attempting to use a Service Connection (e.g., your connection to Azure Production) unless it extends a specific template.

**Configuration Steps:**
1.  Navigate to **Project Settings** > **Service connections**.
2.  Select your critical connection (e.g., `Azure-Prod`).
3.  Click the three dots (menu) > **Approvals and Checks**.
4.  Add a **Required template** check.
5.  Select your template repository and the specific file (e.g., `templates/deploy-secure.yml`).

Once configured, if a developer tries to deploy to Production using a custom pipeline, the job will fail immediately with a policy violation error.

### Pipeline Decorators (Alternative Approach)

Another governance tool is **Pipeline Decorators**. Decorators automatically inject steps into *every* pipeline in an organization, regardless of the YAML content.

**Comparison: Decorators vs. Extends**

| Feature | Pipeline Decorators | Extends Templates |
| :--- | :--- | :--- |
| **Scope** | Organization-wide (All pipelines) | Project/Pipeline specific |
| **Visibility** | Invisible to developers (Magic) | Explicit in YAML (`extends:`) |
| **Flexibility** | Rigid (runs on everything) | High (customizable via parameters) |
| **Maintenance** | Complex (Requires Extension dev) | Simple (Just YAML) |

For most Platform Engineering teams, `extends` is preferred because it is explicit, versionable via Git, and easier to debug than decorators.

### Practical Example: The Secure-by-Default Build

Let’s implement a real-world scenario where we enforce a Credential Scan while allowing the developer to define their build logic.

**1. Create the Template (`jobs/governed-build.yml`)**

```yaml
parameters:
  - name: steps
    type: stepList
    default: []

jobs:
  - job: Build
    pool: ubuntu-latest
    steps:
      - checkout: self
      
      - script: echo "Running Mandatory Security Scan..."
        displayName: 'Security Scan'
        
      # Inject user steps
      - ${{ parameters.steps }}
      
      - task: PublishBuildArtifacts@1
        displayName: 'Publish Artifacts'
```

**2. Create the Consuming Pipeline (`azure-pipelines.yml`)**

```yaml
trigger:
  - main

resources:
  repositories:
    - repository: templates
      type: git
      name: PlatformEngineering/ado-templates
      ref: refs/tags/v1.0.0

extends:
  template: jobs/governed-build.yml@templates
  parameters:
    steps:
      - script: npm install
        displayName: 'Install Dependencies'
      - script: npm run build
        displayName: 'Build App'
```

**Expected Results:**
When the pipeline runs, the logs show the "Security Scan" executing first. The developer has successfully defined their build steps (`npm install`, `npm run build`), but they are constrained within the safe environment defined by the Platform team.

### Best Practices and Tips

#### Do's
*   **Use `type: stepList`:** Always strictly type parameters that accept steps. Using `type: object` works but provides less validation.
*   **Lock Down the Repo:** The repository containing your `extends` templates must have strict branch policies. If a developer can edit the template, they can remove the security check.
*   **Provide Hooks:** Offer "Pre-Build" and "Post-Build" insertion points in your templates. If you don't offer flexibility, developers will try to bypass your governance.

#### Don'ts
*   **Over-Locking:** Don't hardcode the `pool` or `vmImage` unless necessary. If you force everyone to use `ubuntu-latest`, you block teams who need Windows agents. Use parameters to allow valid customization.
*   **Root Level Steps:** You cannot define `steps:` at the root of a file that uses `extends`. This causes immediate parsing errors.

### Troubleshooting Common Issues

**Issue 1: "Unexpected value 'steps'"**
*   **Cause:** The developer defined `steps:` in their `azure-pipelines.yml` while using `extends`.
*   **Solution:** When extending a template, the consumer cannot define root-level steps. They must pass their steps into the parameter defined by the template (e.g., `parameters.buildSteps`).

**Issue 2: "Job authorization scope"**
*   **Cause:** The extended template tries to access a resource (like a secure feed or repository) that the pipeline identity doesn't have access to.
*   **Solution:** Navigate to **Project Settings** > **Pipelines** > **Settings** and uncheck "Limit job authorization scope to current project" if your templates live in a different project.

### Conclusion

The `extends` keyword turns your pipeline into a managed service. It is the only reliable way to enforce security scans inside the YAML content itself. By pairing `extends` templates with "Required Template" checks on Service Connections, you create a robust governance model that is secure by default but flexible enough for real-world development.

**Next Steps:**
1.  Identify your "Non-Negotiable" security steps (e.g., CredScan, SBOM).
2.  Build your first `governed-build.yml` using the Sandwich Pattern.
3.  Read the next article to learn how to handle complex logic (loops and conditions) within these templates.

**Related Articles in This Series:**
*   [Designing a Centralized YAML Template Repository]
*   [Advanced YAML Logic: Objects, Loops, and Conditions]
*   [Securely Handling Secrets in Reusable Templates]
