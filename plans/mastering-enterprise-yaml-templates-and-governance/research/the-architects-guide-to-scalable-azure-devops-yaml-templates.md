# Research Report: The Architect’s Guide to Scalable Azure DevOps YAML Templates

## 1. Executive Summary & User Intent
- **Core Definition:** A centralized, version-controlled repository of Azure DevOps YAML templates uses the `extends` keyword to enforce security and standardization across an enterprise's CI/CD pipelines.
- **User Intent:** The reader is a Platform Engineer or Architect seeking a strategic blueprint, not just syntax. They want to know *how* to organize files, *why* to use specific patterns (like `extends`), and *how* to enforce usage without breaking every team's build.
- **Relevance:** As of late 2025, "Pipeline Sprawl" is a major technical debt. Security mandates (e.g., SBOM generation, Credential Scanning) require a single point of enforcement. Moving from "Copy-Paste" to "Inheritance" is the only scalable solution.

## 2. Key Technical Concepts & Details
- **Core Components:**
    - **Centralized Repo:** A dedicated Git repo (e.g., `ado-templates`) separate from application code.
    - **Template Types:**
        - **Includes (`- template:`)**: Injects content directly. No structural enforcement. Good for small utility steps.
        - **Extends (`extends:`):** Inherits from a base template. Enforces structure ("Skeleton"). The consuming pipeline supplies parameters, not arbitrary steps.
    - **Service Connection Checks:** The "Required Template" check on a Service Connection forces any pipeline using that connection to extend a specific template.

- **Key Terminology:**
    - **Golden Path:** A pre-approved, easy-to-use template that handles 80% of use cases (e.g., "Build & Deploy .NET to Azure").
    - **InnerSource:** The practice of allowing app teams to submit PRs to the central template repo to add features they need.
    - **SemVer (Semantic Versioning):** Using `v1.0.0` tags to manage releases.

## 3. Practical Implementation Data

### Standard Folder Structure
The industry standard structure separates concerns by scope:
```text
ado-templates/
├── stages/                 # Full stage definitions (Build, Deploy)
│   ├── build-dotnet.yml
│   └── deploy-webapp.yml
├── jobs/                   # Reusable jobs (run on an agent)
│   ├── run-unit-tests.yml
│   └── build-docker-image.yml
├── steps/                  # Atomic task lists
│   ├── setup-nuget.yml
│   └── security-scan.yml
├── vars/                   # Variable groups/files
│   └── global-settings.yml
└── README.md
```

### Naming Conventions
Pattern: `technology-verb-scope.yml`
- **Good:** `dotnet-build-job.yml`, `docker-push-step.yml`
- **Bad:** `build.yml` (ambiguous), `common-steps.yml` (dumping ground)

### The "Golden Path" Implementation
**The Base Template (`jobs/build-secure.yml`):**
```yaml
parameters:
  - name: buildSteps
    type: stepList
    default: []

jobs:
  - job: SecureBuild
    pool:
      vmImage: 'ubuntu-latest'
    steps:
      - checkout: self
      
      # Mandatory Security Step (Injected)
      - task: CredScan@3
        displayName: 'Security: Credential Scan'

      # User Logic (Injected)
      - ${{ parameters.buildSteps }}

      # Mandatory Compliance Step
      - task: PublishSecurityAnalysisLogs@3
```

**The Consuming Pipeline (`azure-pipelines.yml`):**
```yaml
resources:
  repositories:
    - repository: templates
      type: git
      name: PlatformEngineering/ado-templates
      ref: refs/tags/v1.2.0  # Pinned Version!

extends:
  template: jobs/build-secure.yml@templates
  parameters:
    buildSteps:
      - script: dotnet build
        displayName: 'My Custom Build'
```

## 4. Best Practices vs. Anti-Patterns

### Best Practices (Do This)
- **Use `stepList` Parameters:** Strictly type your parameters to prevent arbitrary YAML injection where you don't want it.
- **Pin to Git Tags:** Always reference `ref: refs/tags/v1.0.0`. This makes builds immutable. If you reference `main`, a bad merge breaks production immediately.
- **Lock Down the Repo:** Restrict who can push to `main` or create tags in the template repo.
- **Use "Required Template" Checks:** Configure Service Connections (e.g., "Prod-Connection") to *require* that the pipeline extends `templates/deploy-prod.yml`. This prevents "rogue" pipelines from deploying to Prod.

### Anti-Patterns (Don't Do This)
- **The "Common" File:** Creating a massive `common.yml` file. It becomes a dependency nightmare.
- **Hardcoded Secrets:** Never put secrets in templates. Use Key Vault references passed as parameters.
- **Relative Paths:** Don't use `../../` to reference templates. It breaks when directory structures change. Always use the full path from root.

## 5. Edge Cases & Troubleshooting
- **"Template not found" Error:**
    - *Cause:* The consuming pipeline doesn't have permissions to read the `ado-templates` repo.
    - *Fix:* Grant "Reader" access to the "Project Collection Build Service" account on the template repo.
- **Parameter Type Mismatches:**
    - *Cause:* Passing a single step object when a `stepList` is expected.
    - *Fix:* Always use the `-` list syntax even for a single item in the consuming pipeline.
- **Circular Dependencies:**
    - *Limit:* Azure DevOps has a depth limit for nested templates (around 50 levels, but 10 is a practical max).

## 6. Industry Context (2025)
- **Trends:**
    - **Component Governance:** Moving beyond just code, governance now covers the pipeline definition itself.
    - **Decorators:** Pipeline Decorators are an alternative to `extends` for auto-injecting steps, but `extends` is preferred for clarity and developer experience.
    - **Catalog:** Azure DevOps is moving towards a "Pipeline Catalog" model where validated templates are published as artifacts.

## 7. References & Authority
- **Microsoft Docs:** "Security through templates" and "Required template check".
- **SemVer.org:** Semantic Versioning 2.0.0 standard.
