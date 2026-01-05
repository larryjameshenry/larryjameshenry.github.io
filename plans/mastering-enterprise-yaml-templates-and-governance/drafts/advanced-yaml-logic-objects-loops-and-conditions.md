## Front Matter (YAML format)
---
title: "Advanced YAML Logic: Objects, Loops, and Conditions"
date: 2025-12-23T10:00:00
draft: false
description: "Unlock the full power of Azure DevOps YAML by mastering object parameters, `${{ each }}` loops, and conditional insertion to build dynamic, reusable pipelines."
series: ["Mastering Enterprise YAML Templates & Governance"]
tags: ["Azure DevOps", "YAML", "Automation", "Scripting", "CI/CD"]
categories: ["DevOps", "Advanced Techniques"]
weight: 3
---

Most people treat YAML as a static configuration file—a simple list of steps executed in order. But Azure DevOps YAML is actually a powerful templating language capable of loops, conditional logic, and complex data structures.

As your templates grow, you will hit limits with simple string parameters. You might need to deploy to a variable list of environments, or conditionally include a "Sign APK" step only for release branches. Hardcoding these variations leads to template bloat and maintenance nightmares.

This article is a deep dive into the "code" side of Pipeline-as-Code. You will learn how to pass JSON-like objects as parameters, generate dozens of jobs dynamically with loops, and use compile-time expressions to reshape your pipeline on the fly.

### Mastering Parameters: Beyond Strings

Standard parameters (`string`, `boolean`) are insufficient for complex pipelines. If you need to pass a list of environments, each with a name, region, and subscription ID, you shouldn't create `env1Name`, `env1Region`, `env2Name`, etc. You need Objects.

#### The `object` Type
The `object` parameter type allows you to pass complex, structured data into your templates. It accepts JSON-like YAML structures (lists of maps, nested dictionaries).

**Defining an Object Parameter:**

```yaml
# templates/deploy-app.yml
parameters:
  - name: environments
    type: object
    default:
      - name: 'dev'
        region: 'eastus'
        connection: 'Azure-Dev'
      - name: 'prod'
        region: 'westus'
        connection: 'Azure-Prod'

steps:
  - script: echo "Processing environment list..."
```

**Passing an Object from a Pipeline:**

```yaml
# azure-pipelines.yml
extends:
  template: templates/deploy-app.yml
  parameters:
    environments:
      - name: 'qa'
        region: 'northeurope'
        connection: 'Azure-QA'
      - name: 'uat'
        region: 'westeurope'
        connection: 'Azure-UAT'
```

#### The `stepList` and `jobList` Types
While `object` is generic, `stepList` and `jobList` are specialized types. They are strictly typed to accept Azure DevOps steps or jobs. Use these when you want to allow users to inject logic (as discussed in the previous article on Governance), and use `object` when passing configuration data.

### Dynamic Generation with Loops (`${{ each }}`)

The `${{ each }}` keyword allows you to iterate over object parameters. This happens at **compile time**, meaning Azure DevOps unrolls the loop and generates the final YAML before the pipeline starts running.

#### Iterating Over Lists
This is the most common pattern. You can iterate over a list of items to generate steps, jobs, or even stages.

```yaml
# Generates a script step for every item in the list
steps:
  - ${{ each env in parameters.environments }}:
    - script: echo "Deploying to ${{ env.name }} in region ${{ env.region }}"
      displayName: 'Deploy to ${{ env.name }}'
```

If you pass 3 environments, Azure DevOps sees 3 distinct script tasks in the final compiled YAML.

#### Iterating Over Key-Value Pairs
You can also iterate over a dictionary (map).

```yaml
parameters:
  - name: tags
    type: object
    default:
      Project: 'MyApp'
      CostCenter: '1234'

steps:
  - ${{ each pair in parameters.tags }}:
    - script: echo "Applying Tag: ${{ pair.key }} = ${{ pair.value }}"
```

### Conditional Logic: Compile-Time vs. Runtime

Understanding the difference between `${{ if }}` and `condition:` is critical for performance and log cleanliness.

#### Compile-Time Insertion (`${{ if }}`)
Compile-time expressions (`${{ }}`) are evaluated **before** the pipeline runs. If the condition is false, the step is *removed* from the pipeline graph entirely. It effectively doesn't exist.

**Use Case:** Structural changes. E.g., "Only include the Mac build job if the parameter `buildMac` is true."

```yaml
steps:
  - script: echo "Building..."
  
  # This step only exists in the graph if isRelease is true
  - ${{ if eq(parameters.isRelease, true) }}:
    - task: PublishArtifacts@1
      displayName: 'Publish Release'
  
  # New in 2024: else blocks!
  - ${{ else }}:
    - script: echo "Skipping publish for non-release build"
```

#### Runtime Conditions (`condition:`)
Runtime conditions are evaluated **during** execution. The step exists in the graph, but the agent decides whether to run it or skip it based on the condition.

**Use Case:** execution logic. E.g., "Only run this step if the previous step failed."

```yaml
steps:
  - script: ./run-tests.sh
  
  - task: PublishTestResults@2
    # This step always exists, but might be skipped
    condition: failed() 
```

**Performance Tip:** Prefer `${{ if }}` when possible. Removing a job from the graph saves the overhead of initializing an agent and checking conditions. Use `condition:` only when the decision depends on a runtime variable (like the output of a script).

### Practical Example: The "Matrix" Deployment Template

Let's build a powerful template that dynamically generates deployment jobs based on a user-provided list of regions.

**Scenario:** We need to deploy a web app to a dynamic list of Azure regions. If the region is "WestEurope", we must run an extra compliance check.

**1. The Template (`deploy-matrix.yml`)**

```yaml
parameters:
  - name: regions
    type: object
    default: []

jobs:
  # Loop through the list to generate a JOB for each region
  - ${{ each region in parameters.regions }}:
    - job: Deploy_${{ region.name }}
      displayName: 'Deploy to ${{ region.name }}'
      pool: ubuntu-latest
      steps:
        - checkout: none
        - script: echo "Deploying to ${{ region.name }}..."
        
        # Conditional Logic inside the loop
        - ${{ if eq(region.name, 'WestEurope') }}:
          - script: echo "Running EU Compliance Check..."
            displayName: 'EU Compliance'
```

**2. The Consuming Pipeline**

```yaml
extends:
  template: deploy-matrix.yml
  parameters:
    regions:
      - name: EastUS
      - name: WestEurope
      - name: SouthEastAsia
```

**Expected Results:**
The pipeline graph will expand to show 3 parallel jobs: `Deploy_EastUS`, `Deploy_WestEurope`, and `Deploy_SouthEastAsia`. Only the `Deploy_WestEurope` job will contain the "EU Compliance" step.

### Best Practices and Tips

#### Do's
*   **Use `convertToJson` for Debugging:** Azure DevOps doesn't validate the schema of an object parameter. If you are struggling to access a property, print the object to debug it:
    `script: echo '${{ convertToJson(parameters.myObject) }}'`
*   **Group Related Parameters:** Instead of passing `envName`, `envRegion`, and `envSub` as separate strings, group them into a single `env` object. This makes the interface cleaner.
*   **Use Strict Indentation:** YAML is whitespace-sensitive. Ensure your loop body is indented correctly relative to the `${{ each }}` keyword.

#### Don'ts
*   **Loop Over Runtime Variables:** You **cannot** use `${{ each }}` to iterate over a variable set by a script (e.g., `$(myList)`). Compile-time loops can only iterate over parameters or static variables defined in the YAML.
*   **Over-Nest Loops:** Avoid nesting loops more than 2 levels deep (e.g., looping over regions, then looping over services within regions). It makes the YAML extremely difficult to read and debug.

### Troubleshooting Common Issues

**Issue 1: "A mapping was not expected"**
*   **Cause:** This is almost always an indentation error inside a loop.
*   **Solution:** Ensure the items inside the loop (`- task: ...`) are indented one level deeper than the `${{ each }}` statement.

**Issue 2: "Unrecognized value"**
*   **Cause:** Trying to access a property that doesn't exist on the object (e.g., `${{ item.typo }}`). Since Azure DevOps doesn't validate the object schema, this might fail silently or throw a generic expansion error.
*   **Solution:** Double-check your parameter structure or add a default value using the `coalesce` function if the property might be missing.

### Conclusion

Azure DevOps YAML is a functional programming language for your infrastructure. By mastering object parameters, loops, and conditional insertion, you can create dynamic, reusable templates that adapt to complex enterprise requirements.

Use `${{ each }}` to generate repetitive structures and `${{ if }}` to structurally change the pipeline based on inputs. This moves you from maintaining static files to architecting a dynamic platform.

**Next Steps:**
1.  Refactor your biggest "copy-paste" pipeline using loops.
2.  Experiment with passing a JSON object to a template.
3.  Read the next article on **[Validating and Testing Your YAML Templates]** to learn how to catch logic errors in these complex templates before they break production.

**Related Articles in This Series:**
*   [Enforcing Governance with `extends` Templates]
*   [Validating and Testing Your YAML Templates]
*   [Securely Handling Secrets in Reusable Templates]
