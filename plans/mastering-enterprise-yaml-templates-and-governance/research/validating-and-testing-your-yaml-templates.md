# Research Report: Validating and Testing Your YAML Templates

## 1. Executive Summary & User Intent
- **Core Definition:** Testing Azure DevOps YAML templates involves a multi-layered approach: static analysis (linting), compilation validation (Dry Run API), and logical unit testing (Pester).
- **User Intent:** The reader is likely a DevOps Engineer who has broken production one too many times by "testing in prod." They want a safe, local way to verify their changes *before* committing or merging.
- **Relevance:** As pipeline logic moves from visual editors to code (`extends`, loops, objects), the risk of syntax errors increases. "Shift Left" testing for infrastructure is now a standard requirement.

## 2. Key Technical Concepts & Details
- **Core Components:**
    - **VS Code Extension:** "Azure Pipelines" by Microsoft. Provides real-time schema validation.
    - **Dry Run API:** `POST /pipelines/{id}/runs?previewRun=true`. Compiles the YAML on the server without executing jobs.
    - **Pester:** PowerShell testing framework. Used to parse YAML as an object and assert properties (e.g., "Job A must exist").
    - **PowerShell-YAML:** A module wrapper around `YamlDotNet` to convert YAML strings to PowerShell objects.
- **Key Terminology:**
    - **Expansion:** The process of unrolling loops and evaluating `${{ }}` expressions.
    - **Schema:** The `service-schema.json` that defines valid YAML structure.

## 3. Practical Implementation Data

### Level 1: VS Code Linting
- **Extension:** Azure Pipelines (Microsoft).
- **Configuration:**
  ```json
  // .vscode/settings.json
  {
    "azure-pipelines.customSchemaFile": "./schema.json" // Optional: for custom tasks
  }
  ```
- **Benefit:** Catches "Unexpected property" and type mismatches instantly.

### Level 2: The Dry Run API
This is the most accurate check because it uses the actual Azure DevOps compilation engine.
- **Endpoint:** `POST https://dev.azure.com/{org}/{project}/_apis/pipelines/{pipelineId}/runs?api-version=7.1-preview.1`
- **Body:**
  ```json
  {
    "previewRun": true,
    "yamlOverride": "..." // The content of your YAML file
  }
  ```
- **Response:** Returns the *expanded* YAML. If compilation fails, it returns a detailed error message (e.g., "Line 10: Mapping not allowed").

### Level 3: Unit Testing with Pester
We can't simulate the Azure DevOps engine locally, but we can test the *structure* of our templates.

**Pattern:**
1. Read the YAML file.
2. Convert to PowerShell Object (`ConvertFrom-Yaml`).
3. Assert that specific parameters exist.
4. Assert that the template logic produces the expected task names.

**Pester Script Example:**
```powershell
Describe "Secure Build Template" {
    $yaml = Get-Content "jobs/build-secure.yml" -Raw | ConvertFrom-Yaml

    It "Should have a 'buildSteps' parameter of type 'stepList'" {
        $param = $yaml.parameters | Where-Object { $_.name -eq 'buildSteps' }
        $param.type | Should -Be 'stepList'
    }

    It "Should include the CredScan task" {
        $tasks = $yaml.jobs[0].steps.task
        $tasks | Should -Contain "CredScan@3"
    }
}
```

## 4. Best Practices vs. Anti-Patterns

### Best Practices (Do This)
- **CI Validation:** Run the Dry Run API check on every Pull Request.
- **Test the "Golden Path":** Create a `tests/pipeline.yml` that consumes your templates and validating *that* file validates the entire chain.
- **Use Pester for Logic:** If you have complex `if/else` logic, write a Pester test that checks if the correct tasks are present in the parsed object.

### Anti-Patterns (Don't Do This)
- **The "Commit & Pray" Method:** Making small edits and running the pipeline repeatedly to see if it works.
- **Ignoring Schema Warnings:** If VS Code shows a yellow squiggly line, fix it. It usually means you are relying on deprecated behavior.

## 5. Edge Cases & Troubleshooting
- **Error: "Invalid expansion"**
    - *Cause:* Using a parameter inside a loop incorrectly or a type mismatch.
    - *Fix:* Use the Dry Run API to see the expansion error log.
- **Limitation:** Pester cannot evaluate `${{ if }}` expressions because they are Azure-specific syntax. You can only test the *static* content of the YAML file with Pester. To test expansion, you *must* use the API.

## 6. Industry Context (2025)
- **Trends:** Moving towards "Policy as Code" (OPA/Kyverno) for validating pipeline output, but Pester remains the standard for PowerShell-heavy shops.

## 7. References & Authority
- **Microsoft Docs:** REST API Reference for Pipelines.
- **GitHub:** `powershell-yaml` module documentation.
