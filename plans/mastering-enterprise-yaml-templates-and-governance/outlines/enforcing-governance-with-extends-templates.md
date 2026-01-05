## Front Matter (YAML format)
---
title: "Enforcing Governance with `extends` Templates"
date: 2025-12-23T10:00:00
draft: true
description: "Master the `extends` keyword in Azure DevOps to enforce mandatory security scans, policy checks, and standard workflows across your entire organization."
series: ["Mastering Enterprise YAML Templates & Governance"]
tags: ["Azure DevOps", "DevSecOps", "Governance", "Security", "YAML Pipelines"]
categories: ["Security", "DevOps"]
weight: 2
---

## Article Structure Outline

### Introduction (150-200 words target)
**Hook:** In a traditional DevOps model, security is often a "gate" at the end. In a modern DevSecOps model, security is the *road* itself. But how do you pave that road so developers can't accidentally (or intentionally) drive off-road?

**Problem/Context:** Using standard `include` templates allows developers to mix and match logic, but it offers zero guarantee that a security scan actually ran. If a developer can delete the line `- template: security-scan.yml`, your governance is broken.

**What Reader Will Learn:** This article dives deep into the `extends` keyword—the architectural bedrock of governed pipelines. You’ll learn how to wrap developer logic inside a rigid security skeleton that enforces compliance without hindering velocity.

**Preview:** We will cover the technical difference between `extends` and `steps`, how to use "Insertion Points" to allow safe customization, and how to enforce these templates using Azure DevOps "Required Templates" checks.

### The Governance Gap: Why `steps` Templates Fail

#### The "Optional" Problem
**Key Points:**
- Standard templates (`- template: file.yml`) are just copy-paste shortcuts.
- Developers have full control over the root `azure-pipelines.yml`.
- There is no way to prevent a developer from removing a critical compliance step.

**Content Notes:**
- [PLACEHOLDER: Code snippet showing how easy it is to remove a security step in a standard pipeline]

#### The "Skeleton" Solution (`extends`)
**Key Points:**
- `extends` controls the *entire* pipeline structure.
- The developer's file becomes a parameter file, not a logic file.
- Security steps are defined in the parent, wrapping the user's content.

### Architecting the "Skeleton" Template

#### Defining the Structure
**Key Points:**
- Creating a base template that defines the mandatory lifecycle (Restore -> Build -> Test -> Scan -> Publish).
- Using `parameters` to accept the user's build steps.
- The concept of "Pre-Steps" and "Post-Steps".

**Content Notes:**
- [PLACEHOLDER: Diagram: The "Sandwich" pattern (Mandatory Pre-steps -> User Steps -> Mandatory Post-steps)]
- [PLACEHOLDER: Code example of a base template utilizing `${{ parameters.buildSteps }}`]

#### Injection Points for Flexibility
**Key Points:**
- Users need flexibility (e.g., adding a custom linter).
- Defining strictly typed parameters (`type: stepList`) to allow safe injection.
- Where to allow injection: Before Build, After Build, never during Scan.

### Advanced Enforcement: Required Templates Checks

#### The "Force Field" for Service Connections
**Key Points:**
- Even with `extends`, a developer could theoretically just not use it.
- Using "Approvals and Checks" on Service Connections / Environments.
- The "Required Template" check: "You can only deploy to Production if your pipeline extends `templates/secure-deploy.yml`."

**Content Notes:**
- [PLACEHOLDER: Screenshot of the "Required Template" configuration in Azure DevOps Project Settings]

### Pipeline Decorators (Alternative Approach)

#### When `extends` Isn't Enough
**Key Points:**
- Decorators inject logic into *every* pipeline in the organization, regardless of YAML content.
- Pros: Zero developer effort, absolute coverage.
- Cons: High risk of breaking pipelines, harder to debug, less visibility.
- Why `extends` is usually preferred for granular control.

**Content Notes:**
- [PLACEHOLDER: Conceptual comparison table: Decorators vs Extends]

### Practical Example: The Secure-by-Default Build

**Scenario:** Enforcing a "Credential Scan" and "SonarQube Analysis" on every build, while letting the developer define how to compile their specific app.

**Requirements:**
- **Mandatory:** Checkout code.
- **Mandatory:** Run Credential Scanner.
- **User-Defined:** Build steps (npm install / dotnet build).
- **Mandatory:** Publish Test Results.

**Implementation:**
- Step 1: Create `jobs/governed-build.yml`.
- Step 2: Define `parameters: steps` (type: stepList).
- Step 3: Write the YAML to execute CredScan, then `${{ parameters.steps }}`, then Publish Results.
- Step 4: Create a consuming pipeline.

**Code Example:**
[PLACEHOLDER: The `governed-build.yml` file]
[PLACEHOLDER: The consuming `azure-pipelines.yml` file showing how clean it looks]

**Expected Results:**
The pipeline runs. The logs show CredScan executing *before* the user's build steps. If the user tries to remove CredScan, they can't—it's not in their file.

### Best Practices and Tips

**Do's:**
- ✓ **Do** use `type: stepList` for parameters accepting user logic.
- ✓ **Do** lock down the repository containing the `extends` templates.
- ✓ **Do** provide "hooks" for every stage (pre-build, post-build) to avoid blocking valid use cases.

**Don'ts:**
- ✗ **Don't** allow users to overwrite the `pool` or `container` if you need to enforce a secure agent.
- ✗ **Don't** use `extends` for simple utility tasks; keep it for high-level governance.

**Performance Tips:**
- Minimizing the number of nested templates to speed up YAML compilation.

**Security Considerations:**
- Ensure the "Required Template" check verifies the *source repository* of the template, not just the filename.

### Troubleshooting Common Issues

**Issue 1: "Unexpected value 'steps'"**
- **Cause:** Using `steps` keyword at the root of a file that uses `extends`.
- **Solution:** When extending, you cannot define root-level steps; they must be passed as parameters.

**Issue 2: "Job authorization scope"**
- **Cause:** The extended template tries to access resources not authorized for the pipeline.
- **Solution:** Check Project Settings > Pipelines > Settings > "Limit job authorization scope".

### Conclusion

**Key Takeaways:**
1. `extends` turns your pipeline into a managed service for your developers.
2. It is the only reliable way to enforce security scans inside the YAML content itself.
3. Use "Required Template" checks on Service Connections to close the loop.
4. Design for flexibility: give developers "slots" to insert their logic, but keep the frame rigid.

**Next Steps:**
- Identify your "Non-Negotiable" security steps.
- Build your first `governed-build.yml` using the "Sandwich Pattern".
- Read the next article to learn how to handle complex logic within these templates.

**Related Articles in This Series:**
- [Designing a Centralized YAML Template Repository]
- [Advanced YAML Logic: Objects, Loops, and Conditions]
- [Securely Handling Secrets in Reusable Templates]

---

## Author Notes (Not in final article)

**Target Word Count:** 1500-1800 words

**Tone:** Technical, Compliance-focused but developer-friendly.

**Audience Level:** Advanced

**Key Terms to Define:**
- **Insertion Point:** A specific place in a template where user-provided content is injected.
- **StepList:** A YAML data type representing a sequence of pipeline steps.

**Internal Linking Opportunities:**
- Link to "Designing a Centralized Repo" when discussing where to store these governed templates.

**Code Example Types Needed:**
- Comparison: Standard pipeline vs Extended pipeline.
- Syntax highlighting for `parameters: type: stepList`.
- Configuration screenshot (or description) for Service Connection checks.

**Visual Elements to Consider:**
- Diagram: "The Sandwich" (Security -> User Logic -> Security).
- Flowchart: How Azure DevOps evaluates a pipeline with `extends`.
