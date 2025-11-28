---
title: "Tooling Up for PowerShell DevOps: VS Code, PSScriptAnalyzer, and the Gallery"
date: 2025-11-26T13:00:00
draft: true
description: "Master the essential PowerShell DevOps toolset: VS Code for editing, PSScriptAnalyzer for code quality, and the Gallery for module management."
series: ["powershell-automation-for-devops"]
tags: ["PowerShell", "DevOps", "VS Code", "Tooling", "Scripting"]
categories: ["Automation"]
weight: 3
---

## Article Structure Outline

### Introduction
**Hook:** Are you still writing PowerShell in the ISE or Notepad? In the fast-paced world of DevOps, your tooling can be the difference between robust, maintainable automation and a fragile script spaghetti.

**Problem/Context:** As PowerShell has evolved into a cross-platform automation powerhouse, the ecosystem around it has matured. Efficient DevOps requires more than just knowing the syntax; it requires a professional development environment that ensures code quality, consistency, and reusability.

**What Reader Will Learn:**
- How to configure Visual Studio Code (VS Code) as the ultimate PowerShell editor.
- How to enforce code quality standards automatically using PSScriptAnalyzer.
- How to leverage the PowerShell Gallery to find and manage shared modules.

**Preview:** We'll walk through setting up VS Code, analyzing a script for best practices, and managing dependencies with the Gallery.

### The New Standard: Visual Studio Code (VS Code)

#### Setting Up the Environment
**Key Points:**
- VS Code is the official successor to PowerShell ISE.
- Cross-platform support (Windows, macOS, Linux).
- The importance of the PowerShell Extension.

**Content Notes:**
- [PLACEHOLDER: Brief installation steps for VS Code and the PowerShell Extension]
- [PLACEHOLDER: Screenshot of the VS Code interface with a PowerShell script open]

#### Essential Features for DevOps
**Key Points:**
- IntelliSense and code completion (cmdlets, parameters, paths).
- Integrated Terminal and Debugging (breakpoints, variable inspection).
- Code Snippets for rapid development.

**Content Notes:**
- [PLACEHOLDER: Example showing IntelliSense in action]
- [PLACEHOLDER: Explanation of `launch.json` for debugging configurations]

#### Recommended Workspace Settings
**Key Points:**
- Configuring `settings.json` for PowerShell.
- formatting rules (OneTBS, whitespace).
- "Format on Save" for consistency.

**Content Notes:**
- [PLACEHOLDER: Code block showing recommended `settings.json` snippet]

### Enforcing Quality with PSScriptAnalyzer

#### What is Static Code Analysis?
**Key Points:**
- Catching errors before runtime.
- Ensuring adherence to best practices and coding standards.
- PSScriptAnalyzer is the standard linter for PowerShell.

#### Running the Analyzer
**Key Points:**
- Using `Invoke-ScriptAnalyzer`.
- Interpreting the output (Errors, Warnings, Information).
- Common rules: `PSAvoidUsingWriteHost`, `PSUseDeclaredVarsMoreThanAssignments`.

**Content Notes:**
- [PLACEHOLDER: Code example running `Invoke-ScriptAnalyzer` against a sample script]
- [PLACEHOLDER: Sample output showing a violation and how to fix it]

#### Integration with VS Code
**Key Points:**
- Real-time linting (squiggles under code).
- Quick fixes (lightbulb icon).
- Customizing rules with `PSScriptAnalyzerSettings.psd1`.

**Content Notes:**
- [PLACEHOLDER: Screenshot showing a PSScriptAnalyzer warning in the VS Code editor]

### Mastering the PowerShell Gallery

#### The Power of Community and Modules
**Key Points:**
- Don't reinvent the wheel; use existing modules.
- The PowerShell Gallery as the central repository.
- Security and trust: `Get-PSRepository`, `Set-PSRepository`.

#### Finding and Installing Modules
**Key Points:**
- `Find-Module`: Searching by tag or name.
- `Install-Module` vs. `Save-Module`.
- Scope considerations (`-Scope CurrentUser` vs. `AllUsers`).

**Content Notes:**
- [PLACEHOLDER: Code example searching for a module like `Az` or `Pester`]
- [PLACEHOLDER: Code example installing a specific version of a module]

#### Dependency Management
**Key Points:**
- Managing module versions.
- `Update-Module`.
- Introduction to `requirements.psd1` or script headers for declaring dependencies.

### Practical Example: Setting Up a Robust Dev Environment

**Scenario:** You are setting up a new workstation for a DevOps role. You need to configure VS Code, ensure your scripts are checked for quality, and install the Azure module.

**Requirements:**
- VS Code installed with PowerShell extension.
- PSScriptAnalyzer configured to warn on `Write-Host`.
- `Az` module installed.

**Implementation:**
- Step 1: Install VS Code and Extension (brief recap).
- Step 2: Create a `settings.json` enabling PSScriptAnalyzer.
- Step 3: Write a script with `Write-Host` to test the linter.
- Step 4: Install the `Az` module from the Gallery.

**Code Example:**
[PLACEHOLDER: PowerShell script that sets up VS Code settings or verifies the environment]

**Expected Results:**
VS Code underlines `Write-Host` in yellow. The `Az` module is available for import.

### Best Practices and Tips

**Do's:**
- Γ£ô Use VS Code Workspaces to manage project-specific settings.
- Γ£ô Treat warnings from PSScriptAnalyzer as errors until proven otherwise.
- Γ£ô Pin module versions in your scripts to avoid breaking changes.

**Don'ts:**
- Γ£ù Don't disable PSScriptAnalyzer rules globally; suppress them locally if absolutely necessary.
- Γ£ù Don't blindly install modules from the Gallery without checking the publisher/download count.

**Performance Tips:**
- Use `Save-Module` to inspect code before installing.
- Keep your VS Code extensions minimal to ensure editor performance.

### Troubleshooting Common Issues

**Issue 1: IntelliSense Stopped Working**
- **Cause:** The PowerShell Integrated Console process might have crashed or hung.
- **Solution:** Use the Command Palette (`Ctrl+Shift+P`) -> "PowerShell: Restart Current Session".

**Issue 2: "Script is not digitally signed" Error**
- **Cause:** Execution Policy restricts running scripts (`Restricted` or `AllSigned`).
- **Solution:** Set `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`.

### Conclusion

**Key Takeaways:**
1.  VS Code is the essential editor for modern PowerShell DevOps.
2.  PSScriptAnalyzer ensures your code is clean, consistent, and follows best practices.
3.  The PowerShell Gallery provides access to thousands of modules to accelerate your work.
4.  Proper tooling sets the stage for advanced topics like Infrastructure as Code.

**Next Steps:**
- Configure your local VS Code environment today.
- Run PSScriptAnalyzer on an old script and fix the warnings.
- Next, we will explore **Infrastructure as Code with PowerShell DSC**.

**Related Articles in This Series:**
- [Article 2: Mastering PowerShell Core Concepts]
- [Article 4: Infrastructure as Code with PowerShell DSC]

---

## Author Notes (Not in final article)

**Target Word Count:** 1500 words

**Tone:** Professional, encouraging, hands-on

**Audience Level:** Intermediate (Beginners moving to professional workflow)

**Key Terms to Define:**
- **Linter:** A tool that analyzes source code to flag programming errors, bugs, stylistic errors, and suspicious constructs.
- **Repository:** A storage location for software packages (modules).
- **IntelliSense:** A code-completion aid that includes a number of features: List Members, Parameter Info, Quick Info, and Complete Word.

**Internal Linking Opportunities:**
- Link to Article 2 when mentioning "cmdlets" or "objects".
- Link to Article 4 when discussing "Infrastructure as Code".

**Code Example Types Needed:**
- JSON configuration snippets (VS Code settings).
- PowerShell command examples (`Install-Module`, `Invoke-ScriptAnalyzer`).
- Bad vs. Good PowerShell code comparisons.

**Visual Elements to Consider:**
- Screenshot of VS Code with the PowerShell extension active.
- Screenshot of PSScriptAnalyzer squiggle and tooltip.
- Diagram showing the flow of fetching a module from the Gallery.
