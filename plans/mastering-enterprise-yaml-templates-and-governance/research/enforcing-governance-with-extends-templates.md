# Research Report: Enforcing Governance with `extends` Templates

## 1. Executive Summary & User Intent
- **Core Definition:** The `extends` keyword in Azure DevOps YAML allows a pipeline to inherit its entire structure (Stages/Jobs) from a parent template, effectively turning the user's pipeline into a parameters file for a secure "skeleton."
- **User Intent:** The reader wants to prevent developers from bypassing security steps (like CredScan) or deploying to production without approval. They are looking for a technical "force field" that wraps developer logic.
- **Relevance:** Compliance mandates (SBOM, Security Scans) are non-negotiable in 2025. Trusting developers to manually "include" these steps is a failed strategy. `extends` + "Required Template Checks" is the industry-standard solution.

## 2. Key Technical Concepts & Details
- **Core Components:**
    - **Extends Template:** Defines the *schema* and *lifecycle* of the pipeline.
    - **Consuming Pipeline:** Provides *data* (parameters) to the template.
    - **StepList Parameter:** A specific YAML type that allows users to pass a block of steps as a variable.
- **How it Works:** When a pipeline uses `extends`, Azure DevOps compiles the template first. It places the user-provided `stepList` into specific "slots" defined by the template author. The user cannot modify anything outside those slots.
- **Key Terminology:**
    - **Insertion Point:** The `${{ parameters.mySteps }}` line in the template where user logic is injected.
    - **Required Template Check:** A policy on a Service Connection that rejects any pipeline that does not extend a specific file.

## 3. Practical Implementation Data

### Standard Pattern: The "Sandwich"
The template wraps user logic with mandatory pre- and post-steps.

**Template (`governed-build.yml`):**
```yaml
parameters:
  - name: buildSteps
    type: stepList
    default: []

jobs:
  - job: Build
    pool: ubuntu-latest
    steps:
      - checkout: self
      - task: CredScan@3 # Mandatory PRE-step
      
      - ${{ parameters.buildSteps }} # User Logic Slot
      
      - task: PublishBuildArtifacts@1 # Mandatory POST-step
```

### Advanced Enforcement: Service Connection Checks
1.  Navigate to **Project Settings** > **Service connections**.
2.  Select your Prod connection (e.g., `Azure-Prod`).
3.  Click **Approvals and Checks** > **+** > **Required template**.
4.  Select your template repo and the specific file (`templates/deploy-secure.yml`).
5.  **Result:** If a pipeline tries to use `Azure-Prod` but does not extend `templates/deploy-secure.yml`, the deployment fails immediately.

## 4. Best Practices vs. Anti-Patterns

### Best Practices (Do This)
- **Use `type: stepList`:** Always strongly type your step parameters. Do not use generic `object` types for steps, as `stepList` provides better validation.
- **Lock Down the Repo:** The repo containing your `extends` templates must have strict branch policies. If a developer can edit the template, they can remove the security check.
- **Use "Approvals and Checks":** `extends` by itself is voluntary. You must pair it with a Service Connection check to make it mandatory for deployment.

### Anti-Patterns (Don't Do This)
- **Root Level Steps:** You cannot define `steps:` at the root of a file that uses `extends`. This causes the "Unexpected value 'steps'" error.
- **Over-Locking:** Don't hardcode everything. If you force the `pool` to be `ubuntu-18.04`, you will block teams who need `windows-latest`. Use parameters for flexibility.

### Comparison: Decorators vs. Extends
| Feature | Pipeline Decorators | Extends Templates |
| :--- | :--- | :--- |
| **Scope** | Organization-wide (All pipelines) | Project/Pipeline specific |
| **Visibility** | Invisible to developers | Explicit in YAML |
| **Flexibility** | Rigid (runs on everything) | High (parameters) |
| **Use Case** | Global logging, simple compliance | Complex workflows, standardized builds |

## 5. Edge Cases & Troubleshooting
- **Error: "Unexpected value 'steps'"**
    - *Cause:* The user defined `steps:` in their `azure-pipelines.yml` while using `extends`.
    - *Fix:* Move those steps into a parameter (e.g., `buildSteps:`).
- **Error: "Job authorization scope"**
    - *Cause:* The template tries to access a resource (repo/feed) that the pipeline identity doesn't have access to.
    - *Fix:* Check "Limit job authorization scope to current project" in Pipeline Settings.

## 6. Industry Context (2025)
- **Trends:** Moving away from "Global Pipeline Decorators" because they are hard to debug and "magic." The `extends` pattern is preferred because it is explicit and versionable.

## 7. References & Authority
- **Microsoft Docs:** "Security through templates" and "Required template check".
- **Azure DevOps Blog:** Best practices for governance.
