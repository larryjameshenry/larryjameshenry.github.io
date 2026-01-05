## Front Matter (YAML format)
---
title: "Advanced YAML Logic: Objects, Loops, and Conditions"
date: 2025-12-23T10:00:00
draft: true
description: "Unlock the full power of Azure DevOps YAML by mastering object parameters, `${{ each }}` loops, and conditional insertion to build dynamic, reusable pipelines."
series: ["Mastering Enterprise YAML Templates & Governance"]
tags: ["Azure DevOps", "YAML", "Automation", "Scripting", "CI/CD"]
categories: ["DevOps", "Advanced Techniques"]
weight: 3
---

## Article Structure Outline

### Introduction (150-200 words target)
**Hook:** Most people treat YAML as a static configuration file—a list of steps executed in order. But Azure DevOps YAML is actually a templating language capable of loops, conditional logic, and complex data structures.

**Problem/Context:** As your templates grow, you’ll hit limits with simple string parameters. You might need to deploy to a variable list of environments, or conditionally include a build step only for "release" branches. Hardcoding these variations leads to template bloat.

**What Reader Will Learn:** This article is a deep dive into the "code" side of Pipeline-as-Code. You will learn how to pass JSON-like objects as parameters, generate dozens of jobs dynamically with loops, and use compile-time expressions to reshape your pipeline on the fly.

**Preview:** We’ll cover the `object` parameter type, the `${{ each }}` keyword for iteration, and the critical difference between compile-time (`${{ }}`) and runtime (`$[ ]`) expressions.

### Mastering Parameters: Beyond Strings

#### The `object` Type
**Key Points:**
- Limitations of string/boolean parameters.
- defining structured data (e.g., a list of environments with properties like `name`, `region`, `connection`).
- Syntax for defining and passing objects.

**Content Notes:**
- [PLACEHOLDER: Code snippet: Defining an `object` parameter schema]
- [PLACEHOLDER: Code snippet: Passing a complex object from a pipeline]

#### The `stepList` and `jobList` Types
**Key Points:**
- Recap from previous article: allowing users to inject code.
- Why these specific types are safer than generic objects for pipeline structures.

### Dynamic Generation with Loops (`${{ each }}`)

#### Iterating Over Lists
**Key Points:**
- Syntax: `${{ each item in parameters.list }}`.
- Use Case: Generating a deployment job for every environment in a list.
- Accessing properties: `${{ item.property }}`.

**Content Notes:**
- [PLACEHOLDER: Code example: Looping through a list of regions to create parallel deployments]

#### Iterating Over Key-Value Pairs
**Key Points:**
- Looping through dictionaries.
- Use Case: Setting multiple variables dynamically.

### Conditional Logic: Compile-Time vs. Runtime

#### Compile-Time Insertion (`${{ if }}`)
**Key Points:**
- How `if` statements work during YAML parsing.
- Removing entire steps or jobs from the graph based on parameters.
- Example: Including a "Sign APK" step only if `parameters.isRelease` is true.

**Content Notes:**
- [PLACEHOLDER: Visual Diagram: How the pipeline graph changes based on the condition]
- [PLACEHOLDER: Code snippet: Conditional step insertion]

#### Runtime Conditions (`condition:`)
**Key Points:**
- The standard `condition: succeeded()` syntax.
- The difference: Runtime conditions keep the step in the graph but skip it; Compile-time conditions remove it entirely.
- When to use which (Security vs. Logic).

### Practical Example: The "Matrix" Deployment Template

**Scenario:** A single pipeline that deploys a web app to a dynamic list of regions defined by the user.

**Requirements:**
- User provides a list of regions (EastUS, WestUS).
- For each region, a "Deploy" job is created.
- If the region is "WestEurope", an extra "Compliance Check" step must run.

**Implementation:**
- Step 1: Define `parameters: regions` (type: object).
- Step 2: Use `${{ each region in parameters.regions }}` to generate jobs.
- Step 3: Inside the loop, use `${{ if eq(region.name, 'WestEurope') }}` to insert the check.

**Code Example:**
[PLACEHOLDER: `deploy-matrix.yml` template]
[PLACEHOLDER: Consuming pipeline passing the list]

**Expected Results:**
The pipeline graph dynamically expands. Users see 2 deployment jobs. The WestEurope job has an extra step visible in the logs.

### Best Practices and Tips

**Do's:**
- ✓ **Do** use `object` parameters to group related data (e.g., `environment.name` and `environment.url`) instead of `envName`, `envUrl`.
- ✓ **Do** use strict indentation when writing loops; YAML is sensitive to whitespace.
- ✓ **Do** use `${{ else }}` blocks (introduced recently) for fallback logic.

**Don'ts:**
- ✗ **Don't** over-engineer. If a loop makes the template unreadable, consider breaking it into two simple templates.
- ✗ **Don't** confuse `${{ variables.var }}` (compile time) with `$(var)` (runtime macro).

**Performance Tips:**
- Excessive looping (hundreds of iterations) can cause pipeline compilation timeouts. Keep lists reasonable.

**Security Considerations:**
- Be careful when looping over user-provided strings to generate command line arguments (Injection risk).

### Troubleshooting Common Issues

**Issue 1: "A mapping was not expected"**
- **Cause:** Indentation error inside an `${{ each }}` loop.
- **Solution:** Ensure the looped content is indented correctly relative to the parent context.

**Issue 2: "Unrecognized value"**
- **Cause:** Trying to access an object property that doesn't exist.
- **Solution:** Validate input or use safe navigation if available (or checking definition).

### Conclusion

**Key Takeaways:**
1. YAML is a functional programming language for your infrastructure.
2. Use `object` parameters to create rich, typed interfaces for your templates.
3. Use `${{ each }}` to respect DRY principles and generate repetitive jobs.
4. Use `${{ if }}` to structurally change the pipeline based on inputs.

**Next Steps:**
- Refactor your biggest "copy-paste" pipeline using loops.
- Experiment with passing a JSON object to a template.
- Read the next article on **Validating and Testing** to learn how to catch logic errors in these complex templates.

**Related Articles in This Series:**
- [Enforcing Governance with `extends` Templates]
- [Validating and Testing Your YAML Templates]
- [Securely Handling Secrets in Reusable Templates]

---

## Author Notes (Not in final article)

**Target Word Count:** 1500-1800 words

**Tone:** Technical, "Code-heavy", Educational.

**Audience Level:** Advanced

**Key Terms to Define:**
- **Compile-Time Expression:** Evaluated when the pipeline run is requested, before any agent starts.
- **Runtime Expression:** Evaluated by the agent while the job is running.

**Internal Linking Opportunities:**
- Link to "Troubleshooting" section when discussing indentation errors.

**Code Example Types Needed:**
- Complex YAML structures (Lists of Maps).
- Side-by-side comparison of Compile-Time vs Runtime syntax.
- Screenshot of the "Expanded" YAML in Azure DevOps logs.

**Visual Elements to Consider:**
- Diagram: The "Expansion" phase of the pipeline run.
