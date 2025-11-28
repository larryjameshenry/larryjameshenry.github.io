Here is the detailed outline for Article 4. I have generated the content based on the topic cluster plan and the breakdown instructions.

Since I currently lack the permissions to write files directly to your disk, please save the following content to:
`plans/powershell-automation-for-devops/outlines/04-article-4.md`

```markdown
---
title: "Infrastructure as Code with PowerShell DSC"
date: 2025-11-26T12:38:00
draft: true
description: "Learn how to implement Infrastructure as Code (IaC) using PowerShell Desired State Configuration (DSC) to define, enforce, and maintain consistent server environments."
series: ["powershell-automation-for-devops"]
tags: ["PowerShell", "DevOps", "DSC", "IaC", "Infrastructure as Code", "Configuration Management"]
categories: ["DevOps"]
weight: 4
---

## Article Structure Outline

### Introduction (150-200 words target)
**Hook:** Have you ever spent hours troubleshooting a server only to realize it drifted from its original configuration? Or manually configured ten servers hoping you didn't miss a single checkbox?

**Problem/Context:** In the era of DevOps, manual server configuration is slow, error-prone, and unscalable. "Configuration drift"ΓÇöwhere servers slowly diverge from their intended stateΓÇöis a constant enemy of reliability. Infrastructure as Code (IaC) solves this by treating infrastructure setup as software.

**What Reader Will Learn:**
- The core concepts of PowerShell Desired State Configuration (DSC).
- How to write and compile your first DSC configuration.
- How to apply configurations to enforce a desired state.
- The difference between Push and Pull modes.

**Preview:** We will explore the architecture of DSC, walk through a practical web server example, and discuss how DSC fits into a modern CI/CD pipeline.

### Understanding PowerShell DSC

#### What is Desired State Configuration?
**Key Points:**
- Definition of DSC as a management platform in PowerShell.
- The fundamental shift from procedural scripting ("how to do it") to declarative configuration ("what it should look like").
- The role of the Local Configuration Manager (LCM) as the engine that applies configurations.

**Content Notes:**
- [PLACEHOLDER: Diagram comparing Procedural Script (Step 1, Step 2, Step 3) vs. Declarative Configuration (Ensure X is Present)]
- [PLACEHOLDER: Explanation of "Idempotency" in the context of DSCΓÇöwhy running the same config twice is safe]

#### The DSC Architecture
**Key Points:**
- **Resources:** The building blocks (e.g., File, Service, Registry) that do the actual work.
- **Configurations:** The PowerShell scripts that define the environment using resources.
- **MOF Files:** The compiled output (Management Object Format) that the machine actually understands.
- **Nodes:** The target machines being configured.

**Content Notes:**
- [PLACEHOLDER: Visual flow: Configuration Script -> Compile -> MOF -> LCM -> Node]

### Writing Your First Configuration

#### Syntax and Structure
**Key Points:**
- The `Configuration` keyword (similar to `Function`).
- Importing DSC Resources (`Import-DscResource`).
- Defining `Node` blocks to target specific machines (or `localhost`).
- Using Resource blocks (e.g., `WindowsFeature`, `File`).

**Content Notes:**
- [PLACEHOLDER: Code block showing the basic skeleton of a Configuration]

#### Compiling the Configuration
**Key Points:**
- Running the configuration script to generate the `.mof` file.
- Understanding the output directory structure (folder named after the configuration).
- Handling parameters in configurations to make them dynamic.

**Content Notes:**
- [PLACEHOLDER: Example command to compile a configuration]
- [PLACEHOLDER: Screenshot of the generated MOF file in the output folder]

### Enforcing State: Push vs. Pull

#### Push Mode (The distinct "Start-DscConfiguration")
**Key Points:**
- Pushing configurations directly to nodes using `Start-DscConfiguration`.
- Ideal for development, testing, and smaller, simpler environments.
- Provides immediate feedback in the console.

**Content Notes:**
- [PLACEHOLDER: Example command `Start-DscConfiguration -Path ... -Wait -Verbose`]

#### Pull Mode (Centralized Management)
**Key Points:**
- Nodes periodically check a centralized Pull Server (or Azure Automation DSC) for configurations.
- Better for scalability, compliance reporting, and complex environments.
- Ensures continuous enforcement and drift correction without manual intervention.

**Content Notes:**
- [PLACEHOLDER: High-level diagram of Pull Server architecture]
- **Note:** We will focus on Push mode for the examples to keep it accessible, but explain why Pull is standard for Enterprise.

### Practical Example: Configuring an IIS Web Server

**Scenario:** We need to ensure a Windows Server always has the IIS Web Server installed, a specific website directory exists, and a default "Hello World" HTML file is present.

**Requirements:**
- 'Web-Server' role is installed.
- 'C:\Inetpub\wwwroot\MySite' directory exists.
- 'index.html' exists with specific welcome content.

**Implementation:**
- Step 1: Define the Configuration script `IISWebServer`.
- Step 2: Compile the MOF file.
- Step 3: Push the configuration to `localhost`.

**Code Example:**
```powershell
Configuration IISWebServer {
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'

    Node 'localhost' {
        # Install IIS Role
        WindowsFeature IIS {
            Ensure = 'Present'
            Name   = 'Web-Server'
        }

        # Create Website Directory
        File WebDirectory {
            Ensure          = 'Present'
            Type            = 'Directory'
            DestinationPath = 'C:\Inetpub\wwwroot\MySite'
        }

        # Create Home Page
        File HomePage {
            Ensure          = 'Present'
            DestinationPath = 'C:\Inetpub\wwwroot\MySite\index.html'
            Contents        = '<h1>Hello from PowerShell DSC!</h1>'
            DependsOn       = '[File]WebDirectory' # Ensure directory exists first
        }
    }
}

# Compile the configuration
IISWebServer
```

**Expected Results:**
- IIS features are installed (if not already).
- The folder structure is created.
- The HTML file is created.
- Running `Test-DscConfiguration` returns `$true`.

### Best Practices and Tips

**Do's:**
- Γ£ô Use parameters to make configurations reusable across environments (Dev, Test, Prod).
- Γ£ô Keep configurations simple and modular; use Composite Resources for complex logic.
- Γ£ô Store configuration scripts in version control (Git) just like application code.

**Don'ts:**
- Γ£ù Hardcode sensitive data like passwords (use `PSCredential` and encrypted MOF files).
- Γ£ù Mix complex procedural logic (loops, if-statements) inside the resource blocks unnecessarily.
- Γ£ù Ignore compilation errors; they are your first line of defense.

**Performance Tips:**
- Use `DependsOn` explicitly to ensure resources apply in the correct order, preventing dependency errors.
- Minimize the frequency of consistency checks (`ConfigurationModeFrequencyMins`) if performance is a concern on low-resource nodes.

**Security Considerations:**
- Always encrypt credentials in MOF files using certificates.
- Restrict who has write access to the Pull Server or the ability to push configurations.

### Troubleshooting Common Issues

**Issue 1: Resource Not Found**
- **Cause:** The required DSC module is not installed on the target node.
- **Solution:** Use `Install-Module` to get the resource from the PowerShell Gallery onto the node, or distribute it via the Pull Server.
- **Prevention:** Include module installation in your server bootstrapping process.

**Issue 2: Configuration Drifts Immediately**
- **Cause:** Another process or user is changing settings manually, or the LCM is not set to auto-correct.
- **Solution:** Review the LCM settings (`Get-DscLocalConfigurationManager`).
- **Prevention:** Set LCM `ConfigurationMode` to `ApplyAndAutoCorrect` to automatically fix drift.

### Conclusion

**Key Takeaways:**
1. DSC enables true Infrastructure as Code on Windows, allowing you to define the "what" instead of the "how".
2. Configurations are compiled into MOF files and applied by the Local Configuration Manager (LCM).
3. Use Push mode for testing and immediate changes, and Pull mode for scalable, continuous enforcement.
4. DSC is a critical skill for modern Windows DevOps, bridging the gap between Ops and Dev.

**Next Steps:**
- Try the IIS example on a test VM to see DSC in action.
- Explore `Get-DscResource` to discover what else you can configure out of the box.

**Related Articles in This Series:**
- [Article 3: Tooling Up for PowerShell DevOps]
- [Article 5: Managing Cloud Resources with PowerShell]

---

## Author Notes (Not in final article)

**Target Word Count:** 1500-2000 words

**Tone:** Authoritative yet accessible. Demystifying.

**Audience Level:** Intermediate. Assumes basic PowerShell knowledge (from Articles 1 & 2).

**Key Terms to Define:**
- **Idempotency:** The property that applying the same configuration multiple times produces the same result without side effects.
- **LCM (Local Configuration Manager):** The engine on the node that applies configurations.
- **MOF (Management Object Format):** The standard format for configuration data.

**Internal Linking Opportunities:**
- Link to Article 2 when discussing objects and the pipeline.
- Link to Article 8 (Best Practices) when discussing version control and security.

**Code Example Types Needed:**
- Basic Configuration skeleton.
- Practical IIS example (complete).
- LCM configuration example (snippet).

**Visual Elements to Consider:**
- Diagram of the DSC workflow (Author -> Compile -> Push/Pull -> Node).
- Screenshot of `Start-DscConfiguration -Verbose` output showing resources being applied.
```
