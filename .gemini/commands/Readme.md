# Usage Examples for Each Command

## Using research.toml
```powershell
# Basic research
gemini "/research PowerShell error handling patterns"

# Save research to file
gemini "/research Azure DevOps pipeline optimization" > research-notes.md

# Use in article creation script
gemini "/research $Topic" | Out-File $ResearchFile -Append -Encoding UTF8
```

## Using outline.toml
```powershell
# Generate outline with research context
gemini --add research-notes.md "/outline PowerShell Automation Best Practices"

# With date and series info
$OutlinePrompt = @"
Topic: SQL Server Performance Tuning
Date: 2025-11-23
Series: SQL Performance Series
Tags: sql, performance, database, optimization
"@
gemini --add research-notes.md "/outline $OutlinePrompt"
```
## Using expand.toml
```powershell
# Expand outline to full article
gemini --add content/posts/my-article.md "/expand"

# Or pass the content directly
$OutlineContent = Get-Content "content/posts/my-article.md" -Raw
gemini "/expand $OutlineContent"
```

## Using finalize.toml
```powershell
# Final polish before publishing
gemini --add content/posts/my-article.md "/finalize"

# Review both critique and improved version
gemini --add content/posts/my-article.md "/finalize" | Out-File review-results.md

# Then manually review and apply changes
code review-results.md
```

## Command Chaining Example

```powershell
$Topic = "PowerShell DSC Configuration Management"
$Slug = "powershell-dsc-basics"

# 1. Research
Write-Host "Researching..." -ForegroundColor Yellow
gemini "/research $Topic" > "temp-research.md"

# 2. Create outline
Write-Host "Creating outline..." -ForegroundColor Yellow
gemini --add "temp-research.md" "/outline $Topic" > "content/posts/$Slug.md"

# 3. Review outline
code "content/posts/$Slug.md"
Read-Host "Press Enter after reviewing outline..."

# 4. Expand to full article
Write-Host "Expanding to full article..." -ForegroundColor Yellow
$Expanded = gemini --add "content/posts/$Slug.md" "/expand"
$Expanded | Out-File "content/posts/$Slug.md" -Encoding UTF8

# 5. Review expanded article
code "content/posts/$Slug.md"
Read-Host "Press Enter after reviewing article..."

# 6. Final polish
Write-Host "Final polish and review..." -ForegroundColor Yellow
gemini --add "content/posts/$Slug.md" "/finalize" > "review-$Slug.md"

# 7. Review suggestions and apply manually
code "review-$Slug.md"

# Cleanup
Remove-Item "temp-research.md" -Force
```
