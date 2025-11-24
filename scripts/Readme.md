# Complete Workflow Examples
## Example 1: Create Multi-Article Series on PowerShell Automation

```powershell
# Step 1: Create topic cluster plan
.\scripts\New-TopicCluster.ps1 -Topic "PowerShell Automation for DevOps"

# Output shows:
# - Plan created at: plans/powershell-automation-for-devops/_plan.md
# - Estimated 10 articles

# Step 2: Review and edit the plan if needed
code plans/powershell-automation-for-devops/_plan.md

# Step 3: Generate all article outlines from the plan
.\scripts\Generate-Outlines.ps1 -SeriesName "powershell-automation-for-devops"

# This creates:
# plans/powershell-automation-for-devops/outlines/01-article-1.md
# plans/powershell-automation-for-devops/outlines/02-article-2.md
# ... etc.

# Step 4: Review the generated outlines
code plans/powershell-automation-for-devops/outlines/

# Step 5: Promote first article to active development
.\scripts\Promote-Outline.ps1 -SeriesName "powershell-automation-for-devops" -Number 1

# Article now at: content/posts/getting-started-powershell-automation.md

# Step 6: Do additional focused research if needed
gemini --add content/posts/getting-started-powershell-automation.md "/research PowerShell error handling best practices"

# Step 7: Test draft locally
hugo server --buildDrafts

# Step 8: Expand to full article
.\scripts\Expand-Article.ps1 -Slug "getting-started-powershell-automation"

# Step 9: Review and polish
code content/posts/getting-started-powershell-automation.md

# Step 10: Publish when ready
.\scripts\Publish-Article.ps1 -Slug "getting-started-powershell-automation"

# Step 11: Repeat for next article in series
.\scripts\Promote-Outline.ps1 -SeriesName "powershell-automation-for-devops" -Number 2
```
## Example 2: Create Smaller Series
```
# Quick cluster on specific topic
.\scripts\New-TopicCluster.ps1 -Topic "SQL Server Performance Tuning" -SeriesName "sql-perf"

# Generate just first 3 articles
.\scripts\Generate-Outlines.ps1 -SeriesName "sql-perf" -Count 3

# Work through them one by one
.\scripts\Promote-Outline.ps1 -SeriesName "sql-perf" -Number 1
.\scripts\Expand-Article.ps1 -Slug "sql-server-performance-basics"
.\scripts\Publish-Article.ps1 -Slug "sql-server-performance-basics"
```

## Complete Workflow with Fact-Checking
```powershell
# 1. Create outline
.\scripts\New-Article.ps1 -Topic "PowerShell Error Handling"

# 2. Expand to full article
.\scripts\Expand-Article.ps1 -Slug "powershell-error-handling"

# 3. Fact-check the article
.\scripts\Test-ArticleAccuracy.ps1 -Slug "powershell-error-handling" -OutputFile "factcheck.md"

# 4. Test code examples
.\scripts\Test-ArticleCode.ps1 -Slug "powershell-error-handling"

# 5. Make corrections based on fact-check results
code content/posts/powershell-error-handling.md

# 6. Re-run fact-check to verify fixes
.\scripts\Test-ArticleAccuracy.ps1 -Slug "powershell-error-handling"

# 7. Final polish
gemini --add content/posts/powershell-error-handling.md "/finalize" > polish.md

# 8. Publish (includes optional fact-check)
.\scripts\Publish-Article.ps1 -Slug "powershell-error-handling"
```

## Hugo Front Matter Example with Series

```html
---
title: "Getting Started with PowerShell Automation"
date: 2025-11-22T03:00:00-05:00
draft: true
description: "Learn the fundamentals of PowerShell automation for DevOps workflows including scripts, modules, and best practices."
series: ["PowerShell Automation for DevOps"]
tags: ["powershell", "automation", "devops", "scripting", "beginner"]
categories: ["DevOps"]
weight: 1
---

<!-- Promoted from plan: powershell-automation-for-devops, outline #1 -->
<!-- Ready for deep research and expansion -->
```
