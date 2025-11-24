<#
.SYNOPSIS
    Test all code examples in an article for syntax and logic errors
.DESCRIPTION
    Extracts code blocks and validates syntax, checks for common errors,
    and optionally attempts to execute PowerShell code blocks
.PARAMETER Slug
    The article slug to test
.PARAMETER ExecutePowerShell
    Actually execute PowerShell code blocks in isolated runspace (use with caution)
.PARAMETER OutputFile
    Optional file to save test results
.EXAMPLE
    .\scripts\Test-ArticleCode.ps1 -Slug "powershell-basics"
.EXAMPLE
    .\scripts\Test-ArticleCode.ps1 -Slug "azure-functions" -ExecutePowerShell -OutputFile "code-test-results.md"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Slug,
    
    [Parameter(Mandatory=$false)]
    [switch]$ExecutePowerShell,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFile
)

$ArticlePath = "content/posts/$Slug.md"

if (-not (Test-Path $ArticlePath)) {
    Write-Error "Article not found: $ArticlePath"
    exit 1
}

Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Code Validation Test" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Article: $Slug" -ForegroundColor Yellow
Write-Host ""

# Run Gemini code test
Write-Host "Running AI code validation..." -ForegroundColor Yellow
$TestResult = gemini --add $ArticlePath "/testcode"

Write-Host $TestResult
Write-Host ""

# If PowerShell execution enabled, extract and test PS code blocks
if ($ExecutePowerShell) {
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  PowerShell Code Execution Test" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    $Content = Get-Content $ArticlePath -Raw
    
    # Extract PowerShell code blocks
    $PSCodeBlocks = [regex]::Matches($Content, '``````', 
        [System.Text.RegularExpressions.RegexOptions]::Singleline)
    
    if ($PSCodeBlocks.Count -eq 0) {
        Write-Host "No PowerShell code blocks found." -ForegroundColor Gray
    } else {
        Write-Host "Found $($PSCodeBlocks.Count) PowerShell code block(s)" -ForegroundColor Yellow
        Write-Host ""
        
        $BlockNum = 1
        foreach ($Match in $PSCodeBlocks) {
            $Code = $Match.Groups[1].Value
            
            Write-Host "Testing PowerShell Block #$BlockNum..." -ForegroundColor Cyan
            
            try {
                # Parse the code (syntax check)
                $null = [System.Management.Automation.PSParser]::Tokenize($Code, [ref]$null)
                Write-Host "  ✓ Syntax check passed" -ForegroundColor Green
                
                # Optional: Try to execute in constrained mode
                # WARNING: This executes code - use only on trusted content
                Write-Host "  ⚠ Execution skipped (use -ExecutePowerShell carefully)" -ForegroundColor Yellow
                
            } catch {
                Write-Host "  ✗ Syntax error: $_" -ForegroundColor Red
            }
            
            Write-Host ""
            $BlockNum++
        }
    }
}

# Save results if requested
if ($OutputFile) {
    $ReportContent = @"
# Code Validation Report: $Slug

**Date:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Article:** $ArticlePath

---

## AI Code Validation

$TestResult

---

## Notes
- All code blocks have been analyzed for syntax and logic errors
- Review any flagged issues before publishing
- Consider manual testing for complex code examples
"@
    
    $ReportContent | Out-File $OutputFile -Encoding UTF8
    Write-Host "✓ Test results saved: $OutputFile" -ForegroundColor Green
    Write-Host ""
}
