# Research Report: Advanced YAML Logic: Objects, Loops, and Conditions

## 1. Executive Summary & User Intent
- **Core Definition:** Advanced YAML logic in Azure DevOps involves using template expressions (`${{ }}`) to programmatically generate pipeline structures (Stages, Jobs, Steps) at compile time using loops, conditional insertions, and complex object parameters.
- **User Intent:** The reader wants to move beyond static, linear pipelines. They need to generate 50 deployment jobs from a single list, conditionally include steps based on environment, and pass complex configuration objects instead of 20 individual string parameters.
- **Relevance:** Static YAML cannot scale to complex enterprise needs (e.g., multi-region deployments, dynamic test matrices). Mastering these features is the "graduation" from basic CI/CD user to Pipeline Architect.

## 2. Key Technical Concepts & Details
- **Core Components:**
    - **Object Parameters:** passing JSON-like structures (lists of maps) into templates.
    - **Compile-Time Expressions (`${{ }}`):** Evaluated *before* the pipeline runs. Used for loop expansion and removing steps.
    - **Runtime Expressions (`$[ ]`):** Evaluated *during* the pipeline run. Used for checking job status or variables.
- **Key Terminology:**
    - **Expansion:** The process where Azure DevOps parses the YAML, unrolls loops, and evaluates `${{ }}` expressions to create the final "expanded" YAML.
    - **Insertion:** Placing a step or job into the graph conditionally.

## 3. Practical Implementation Data

### The `object` Parameter Schema
Azure DevOps validates that an input *is* an object, but it does **not** validate the internal schema (properties) of that object.
**Pattern:**
```yaml
parameters:
  - name: environments
    type: object
    default:
      - name: dev
        region: eastus
      - name: prod
        region: westus
```

### Loops (`${{ each }}`)
- **List Iteration:**
  ```yaml
  - ${{ each item in parameters.myList }}:
      - script: echo ${{ item }}
  ```
- **Map/Dictionary Iteration:**
  ```yaml
  - ${{ each pair in parameters.myMap }}:
      - script: echo Key:${{ pair.key }} Value:${{ pair.value }}
  ```

### Conditional Logic
- **Compile-Time (Structure):**
  ```yaml
  - ${{ if eq(parameters.env, 'prod') }}:
      - task: Approval@1
  - ${{ else }}:
      - script: echo "Auto-approving non-prod"
  ```
- **Runtime (Execution):**
  ```yaml
  - task: PublishTestResults@2
    condition: failed() # Only runs if previous steps failed
  ```

## 4. Best Practices vs. Anti-Patterns

### Best Practices (Do This)
- **Use `convertToJson` for Debugging:** If you are unsure what an object contains, add a step to print it:
  `script: echo '${{ convertToJson(parameters.myObject) }}'`
- **Prefer Compile-Time for Structure:** If a step shouldn't run, remove it with `${{ if }}` rather than skipping it with `condition:`. This keeps the logs cleaner.
- **Group Related Params:** Instead of `envName`, `envRegion`, `envSub`, use a single `env` object.

### Anti-Patterns (Don't Do This)
- **Runtime loops:** You cannot use `${{ each }}` to loop over a variable that is set at runtime (e.g., output of a script). Compile-time loops only work on parameters and static variables.
- **Over-nesting:** Avoid nesting loops more than 2-3 levels deep. It makes the YAML unreadable and hard to debug.

## 5. Edge Cases & Troubleshooting
- **Error: "A mapping was not expected"**
    - *Cause:* Indentation issue inside a loop. The loop body must be indented relative to the `${{ each }}` keyword.
- **Error: "Unrecognized value"**
    - *Cause:* Trying to access a property that doesn't exist on an object parameter (e.g., `item.typo`). Since there is no schema validation, this fails silently or throws a generic error during expansion.
- **Limit:** Pipeline expansion depth/size limits exist but are generous (thousands of steps). The main limit is readability.

## 6. Industry Context (2025)
- **Trends:** Moving towards "Matrix" strategies for parallelization, but using `each` loops for *structural* generation (e.g., generating different jobs for Windows vs Linux vs Mac).

## 7. References & Authority
- **Microsoft Docs:** "Template expressions" and "Iterative insertion".
