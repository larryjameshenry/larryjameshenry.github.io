# Research Report: Designing a Centralized YAML Template Repository

## 1. Executive Summary & User Intent
- **Core Definition:** A centralized template repository is a dedicated Git project containing reusable Azure DevOps YAML files, structured logically (Stages/Jobs/Steps) and versioned strictly using Semantic Versioning (SemVer) tags.
- **User Intent:** The reader wants to know *exactly* how to organize their files (folder structure), how to name them to avoid confusion, and how to safely update them without breaking downstream pipelines. They need a "clean code" standard for infrastructure.
- **Relevance:** As of late 2025, maintaining hundreds of pipelines is untenable. A centralized, versioned library is the prerequisite for scaling DevOps across an enterprise.

## 2. Key Technical Concepts & Details
- **Core Components:**
    - **One Repo to Rule Them All:** A single repo (e.g., `ado-templates`) reduces permission complexity compared to scattered repos.
    - **Resource Definition:** The `resources` block in YAML is the "import statement" that connects a pipeline to the template repo.
    - **Git Tags:** Immutable markers (`refs/tags/v1.2.0`) used to freeze a version of the library.
- **Key Terminology:**
    - **Scope:** The context in which a template runs (Stage, Job, or Step).
    - **Pinned Version:** Explicitly referencing a tag (e.g., `v1.0.0`) instead of a branch (`main`).
    - **Project Collection Build Service:** The system identity that needs permission to read the template repo.

## 3. Practical Implementation Data

### Standard Folder Structure
The industry-standard hierarchy mirrors the YAML schema itself:
```text
ado-templates/
├── stages/                 # Templates that define a full stage (e.g., 'Deploy to Prod')
│   ├── build-stage.yml
│   └── deploy-stage.yml
├── jobs/                   # Templates that define a job (e.g., 'Build Docker Image')
│   ├── build-dotnet.yml
│   └── run-tests.yml
├── steps/                  # Templates that define a sequence of steps (e.g., 'Nuget Restore')
│   ├── setup-nuget.yml
│   └── docker-login.yml
├── vars/                   # Variable templates
│   └── global-vars.yml
└── README.md
```

### Naming Conventions
- **Format:** `verb-technology.yml` or `technology-verb.yml`. Consistency is key.
- **Examples:**
    - `build-dotnet.yml` (Clear: It builds .NET)
    - `publish-artifact.yml` (Clear: It publishes artifacts)
- **Anti-Patterns:** `common.yml`, `utils.yml` (Too vague).

### Versioning Workflow (SemVer)
1.  **Development:** Work on a feature branch.
2.  **Merge:** Pull Request to `main`.
3.  **Release:** Tag the commit on `main`.
    ```bash
    git tag -a v1.1.0 -m "Added support for .NET 8"
    git push origin v1.1.0
    ```
4.  **Consumption:**
    ```yaml
    resources:
      repositories:
        - repository: templates
          type: git
          name: Infrastructure/ado-templates
          ref: refs/tags/v1.1.0  # Immutable!
    ```

## 4. Best Practices vs. Anti-Patterns

### Best Practices (Do This)
- **Atomic Templates:** A step template should *only* contain steps. A job template should *only* contain jobs. Mixing scopes causes YAML parsing errors.
- **Parameter Documentation:** Use comments above the `parameters` block to describe inputs, defaults, and allowed values.
- **Internal Templates:** Use an `_internal/` folder or `_` prefix for templates that are helpers and not meant for public consumption.

### Anti-Patterns (Don't Do This)
- **Referencing `@main`:** This is the #1 cause of pipeline outages. One bug in `main` breaks everyone.
- **Monolithic Repos:** Mixing application code and templates in the same repo. It complicates versioning.
- **Changing Inputs:** Never remove a parameter or change its type in a Minor/Patch release. That is a Major breaking change.

## 5. Edge Cases & Troubleshooting
- **Permission Error (403):** The consuming pipeline fails to checkout the template repo.
    - *Fix:* Grant "Reader" access to `Project Collection Build Service (OrgName)` on the `ado-templates` repo.
- **"Infinite Recursion":** A template calls itself or creates a loop.
    - *Fix:* Enforce a strict dependency flow: Stages -> Jobs -> Steps. Never go backwards.
- **"Template not found":** Usually caused by referencing a tag that hasn't been pushed.
    - *Fix:* Verify `git push --tags` was run.

## 6. Industry Context (2025)
- **Catalog:** Azure DevOps "Pipeline Catalog" is emerging as a way to publish templates as versioned artifacts, but Git Tags remain the most flexible and widely used method for internal libraries.

## 7. References & Authority
- **Microsoft Docs:** "Security through templates" (recommends separate repos).
- **SemVer.org:** Standard versioning rules.
