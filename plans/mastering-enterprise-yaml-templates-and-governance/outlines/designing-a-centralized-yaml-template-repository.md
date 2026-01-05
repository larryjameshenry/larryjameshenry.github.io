## Front Matter (YAML format)
---
title: "Designing a Centralized YAML Template Repository"
date: 2025-12-23T10:00:00
draft: true
description: "Learn how to structure, version, and organize a centralized Azure DevOps YAML template repository for maximum reusability and maintainability."
series: ["Mastering Enterprise YAML Templates & Governance"]
tags: ["Azure DevOps", "YAML Pipelines", "Git", "Versioning", "DevOps Best Practices"]
categories: ["DevOps", "Infrastructure as Code"]
weight: 1
---

## Article Structure Outline

### Introduction (150-200 words target)
**Hook:** A messy template repository is worse than no templates at all. If developers can't find the "standard build job" or trust that "v1" won't break tomorrow, they'll go back to copy-pasting inline YAML.

**Problem/Context:** As your library of templates grows, organization becomes critical. Without a clear structure and rigorous versioning strategy, you risk "dependency hell" where updating a shared template breaks 50 production pipelines instantly.

**What Reader Will Learn:** This article provides a concrete folder structure for your repository, a naming convention that scales, and a step-by-step guide to implementing Semantic Versioning (SemVer) with Git tags.

**Preview:** We’ll look at the "One Repo to Rule Them All" strategy, define the `/stages`, `/jobs`, and `/steps` hierarchy, and show you exactly how to release `v2.0.0` safely.

### The "Single Source of Truth" Strategy

#### One Repository vs. Distributed Templates
**Key Points:**
- Why a dedicated `azure-pipelines-templates` repository is preferred over scattering templates across project repos.
- Centralizing access controls and branch policies.
- simplifying the `resources` definition in consuming pipelines.

**Content Notes:**
- [PLACEHOLDER: Diagram: Multiple App Repos pointing to One Template Repo]

#### Permission Boundaries
**Key Points:**
- Who should be allowed to merge to `main`? (Platform Team vs. Product Teams).
- Protecting the "Production" tags.

### Structuring Your Filesystem

#### The Hierarchy: Stages, Jobs, and Steps
**Key Points:**
- Organizing by Azure DevOps scope, not by technology.
- Why `/steps/build-dotnet.yml` is better than `/dotnet/build-steps.yml`.
- Keeping templates atomic: A "Step" template should strictly be a list of steps.

**Content Notes:**
- [PLACEHOLDER: Recommended File Tree Structure (ASCII art)]
- [PLACEHOLDER: Explanation of folder responsibilities]

#### Naming Conventions That Scale
**Key Points:**
- Using verb-noun syntax (e.g., `build-docker-image.yml`, `deploy-webapp.yml`).
- Explicitly marking internal templates (e.g., `_internal/setup-agent.yml`).
- Avoiding generic names like `common.yml`.

### The Versioning Strategy: SemVer and Git Tags

#### Why "Main" Branch References Are Dangerous
**Key Points:**
- The risk of "floating" versions.
- How a bad merge to `main` instantly outages everyone referencing `@main`.

**Content Notes:**
- [PLACEHOLDER: Code snippet: The "Wrong Way" (referencing main)]

#### Implementing Semantic Versioning
**Key Points:**
- **Major (v1):** Breaking changes (removing parameters, changing logic significantly).
- **Minor (v1.1):** New features (adding optional parameters).
- **Patch (v1.1.1):** Bug fixes.
- Using Git Tags to create immutable release points.

**Content Notes:**
- [PLACEHOLDER: Git commands to tag and push a release]
- [PLACEHOLDER: Code snippet: The "Right Way" (referencing `refs/tags/v1.0.0`)]

### Documenting Your Templates

#### The `parameters` Block as Documentation
**Key Points:**
- Using comments directly above parameters.
- Leveraging `values` keys to restrict inputs and guide the user (IntelliSense).
- Setting sensible `default` values.

**Content Notes:**
- [PLACEHOLDER: Example YAML showing rich parameter documentation]

#### Markdown Readmes
**Key Points:**
- Why every root folder needs a `README.md`.
- Generating documentation automatically (optional mention of tools).

### Practical Example: A Complete Repository Setup

**Scenario:** Setting up a brand new template repository structure.

**Requirements:**
- Support for Building and Deploying web apps.
- Clear separation of "Steps" and "Jobs".
- Version 1.0.0 release.

**Implementation:**
- Step 1: Initialize Git Repo.
- Step 2: Create folders `/jobs`, `/steps`.
- Step 3: Add `jobs/build-web.yml`.
- Step 4: Tag commit as `v1.0.0`.

**Code Example:**
[PLACEHOLDER: ASCII Tree of the final structure]
[PLACEHOLDER: Sample `azure-pipelines.yml` consuming this specific version]

### Best Practices and Tips

**Do's:**
- ✓ **Do** use descriptive filenames that indicate the scope (job vs step).
- ✓ **Do** treat every PR to the template repo as a "Production Deployment."
- ✓ **Do** allow teams to pin to Major versions (e.g., `v1`) if you manage tags automatically, but specific tags (`v1.2.3`) are safer.

**Don'ts:**
- ✗ **Don't** change the inputs of a template without bumping the Major version.
- ✗ **Don't** mix "utility scripts" (PowerShell/Bash) inside the YAML folders; keep them in a `/scripts` folder.

**Performance Tips:**
- Keep template file sizes small; monolithic templates are hard to parse and debug.

**Security Considerations:**
- Ensure the template repo has "Block force push" enabled on all release tags.

### Troubleshooting Common Issues

**Issue 1: "Infinite Recursion"**
- **Cause:** A template calling itself, or circular references between generic job templates.
- **Solution:** Strict hierarchy (Stage calls Job, Job calls Step).

**Issue 2: "Tag not found"**
- **Cause:** The consuming pipeline performs a shallow fetch or the tag wasn't pushed to the remote.
- **Solution:** Ensure `git push --tags` was executed.

### Conclusion

**Key Takeaways:**
1. A single, centralized repository is the foundation of governance.
2. Structure folders by Pipeline Scope (Stages/Jobs/Steps), not tool name.
3. **Never** reference the `main` branch in production pipelines.
4. Use Git Tags to implement Semantic Versioning.
5. Document your inputs within the YAML parameters block.

**Next Steps:**
- Create your `azure-pipelines-templates` repository today.
- Define your folder structure.
- Read the next article to learn how to use these templates to enforce security with `extends`.

**Related Articles in This Series:**
- [The Architect’s Guide to Scalable Azure DevOps YAML Templates]
- [Enforcing Governance with `extends` Templates]
- [Validating and Testing Your YAML Templates]

---

## Author Notes (Not in final article)

**Target Word Count:** 1200-1500 words

**Tone:** Practical, Structured, "Clean Code" advocate.

**Audience Level:** Intermediate

**Key Terms to Define:**
- **SemVer (Semantic Versioning):** A universal versioning standard (Major.Minor.Patch).
- **Immutable:** Something that cannot be changed after creation (like a Git Tag, ideally).

**Internal Linking Opportunities:**
- Link to "Pillar Post" for the high-level strategy.
- Link to "Advanced Logic" when discussing internal logic within the file structure.

**Code Example Types Needed:**
- File tree diagrams (ASCII).
- Git CLI commands.
- Comparison of consuming a branch ref vs a tag ref.

**Visual Elements to Consider:**
- Diagram: "The Dependency Chain" (Pipeline -> Repo Resource -> Template File).
- Screenshot: Azure DevOps "Tags" view in the Repos section.
