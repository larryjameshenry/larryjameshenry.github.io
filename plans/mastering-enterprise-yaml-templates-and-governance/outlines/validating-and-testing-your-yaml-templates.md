## Front Matter (YAML format)
---
title: "Validating and Testing Your YAML Templates"
date: 2025-12-23T10:00:00
draft: true
description: "Stop breaking production pipelines. Learn how to unit test your Azure DevOps YAML templates using Pester and the Pipeline Dry-Run API."
series: ["Mastering Enterprise YAML Templates & Governance"]
tags: ["Azure DevOps", "Pester", "PowerShell", "Testing", "Infrastructure as Code"]
categories: ["DevOps", "Testing"]
weight: 4
---

## Article Structure Outline

### Introduction (150-200 words target)
**Hook:** "I’ll just trigger a build and see if it fails." If this is your testing strategy for pipeline templates, you are playing Russian Roulette with your development team's productivity.

**Problem/Context:** As YAML logic grows complex (loops, conditions, objects), syntax errors and logical bugs become harder to spot. A single indentation error in a shared template can bring down hundreds of builds.

**What Reader Will Learn:** This article bridges the gap between infrastructure and software engineering. You will learn how to lint your YAML locally, validate compilation using the Azure DevOps API (without running a job), and write true unit tests for your logic using Pester.

**Preview:** We’ll start with simple VS Code validation, move to the "Dry Run" API endpoint, and finally build a robust Pester test suite that asserts your template generates the expected steps.

### Level 1: Static Analysis and Linting

#### VS Code Extensions
**Key Points:**
- The official Azure Pipelines extension.
- Setting up the schema validation (pointing to the correct schema URL).
- Catching basic type errors (string vs boolean) locally.

**Content Notes:**
- [PLACEHOLDER: Screenshot of VS Code showing a schema validation error]

#### The "Dry Run" API (Preview Mode)
**Key Points:**
- Did you know Azure DevOps has an API that compiles YAML but doesn't run it?
- Calling the `POST /pipelines/{id}/preview` endpoint.
- Catching "Template file not found" and "Invalid expansion" errors before merge.

**Content Notes:**
- [PLACEHOLDER: PowerShell script to invoke the Preview API]
- [PLACEHOLDER: Example of the JSON response containing the expanded YAML]

### Level 2: Logic Testing with Pester

#### Why Pester?
**Key Points:**
- Pester isn't just for PowerShell code; it's a testing framework.
- We can use it to parse our YAML and assert its structure.
- Testing scenarios: "If parameter X is true, Step Y must exist."

#### Parsing YAML in PowerShell
**Key Points:**
- Using `powershell-yaml` module to convert `.yml` files to PowerShell objects.
- Inspecting the object structure (Jobs > Steps > Tasks).

**Content Notes:**
- [PLACEHOLDER: Code snippet: Converting YAML to a PowerShell object]

### Practical Example: Writing a Unit Test for a Template

**Scenario:** We have a template `deploy.yml` that conditionally includes a "Swap Slots" step only if `parameters.environment` is "Production". We need to test this logic.

**Requirements:**
- Test Case 1: When env is 'Production', 'AzureAppServiceManage' task should exist.
- Test Case 2: When env is 'Staging', 'AzureAppServiceManage' task should NOT exist.

**Implementation:**
- Step 1: Install `Pester` and `powershell-yaml`.
- Step 2: Write `deploy.Tests.ps1`.
- Step 3: Mock the template expansion (or parse the raw logic if simple).
- Step 4: Run the test suite in the PR validation pipeline.

**Code Example:**
[PLACEHOLDER: Full Pester script asserting the presence of a specific task based on input]

**Expected Results:**
Pester output shows green checks for both scenarios.

### Level 3: Integration Testing (The Real Deal)

#### The "Test Pipeline" Strategy
**Key Points:**
- Creating a dedicated `azure-pipelines-test.yml` in your template repo.
- This pipeline consumes the templates from the *current branch* (`self`).
- It runs actual jobs (e.g., "Hello World" scripts) to prove the YAML is valid Azure DevOps syntax.

**Content Notes:**
- [PLACEHOLDER: Example `azure-pipelines-test.yml` file structure]

### Best Practices and Tips

**Do's:**
- ✓ **Do** run the "Dry Run" check on every Pull Request.
- ✓ **Do** use `powershell-yaml` to sanity check your parameter definitions.
- ✓ **Do** require passing tests before merging to `main`.

**Don'ts:**
- ✗ **Don't** rely solely on the "Validate" button in the web UI (it’s manual).
- ✗ **Don't** test your templates by breaking the `main` branch.

**Performance Tips:**
- Pester tests run in seconds; "Dry Run" API calls take 1-2 seconds. Use them freely.

**Security Considerations:**
- Ensure your test pipeline doesn't have permissions to deploy to real production environments.

### Troubleshooting Common Issues

**Issue 1: "YAML mapping not allowed"**
- **Cause:** Usually an indentation error or using a sequence dash `-` where a map `key: value` is expected.
- **Solution:** Use a strict Linter in VS Code.

**Issue 2: Pester cannot parse Azure DevOps specific syntax (`${{ }}`)**
- **Cause:** `powershell-yaml` sees `${{ }}` as just a string.
- **Solution:** You are testing the *structure* of the file, not the Azure DevOps compilation engine. For compilation testing, use the API.

### Conclusion

**Key Takeaways:**
1. "Testing in Production" is unprofessional for Platform Engineers.
2. Use the "Dry Run" API to catch compilation errors.
3. Use Pester to catch logical errors in your templates.
4. Automate these checks in a PR validation pipeline.

**Next Steps:**
- Create a `tests/` folder in your template repository.
- Write a simple "Dry Run" script.
- Read the final article on **Securely Handling Secrets** to ensure your well-tested templates are also secure.

**Related Articles in This Series:**
- [Designing a Centralized YAML Template Repository]
- [Advanced YAML Logic: Objects, Loops, and Conditions]
- [Securely Handling Secrets in Reusable Templates]

---

## Author Notes (Not in final article)

**Target Word Count:** 1500-1800 words

**Tone:** Pragmatic, Engineering-focused.

**Audience Level:** Intermediate/Advanced

**Key Terms to Define:**
- **Linting:** Automated checking of source code for programmatic and stylistic errors.
- **Dry Run:** A simulation of a process to see what the output would be without actually executing the effects.

**Internal Linking Opportunities:**
- Link to "Advanced Logic" article when discussing testing complex conditionals.

**Code Example Types Needed:**
- PowerShell script for API call.
- Pester Test file (`.Tests.ps1`).
- JSON response schema.

**Visual Elements to Consider:**
- Diagram: The "Test Pyramid" applied to Pipelines (Linting > Unit > Integration).
