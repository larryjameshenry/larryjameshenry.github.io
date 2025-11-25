<#
.SYNOPSIS
    Test all code examples in an article
.DESCRIPTION
    Uses Gemini CLI to validate code syntax and logic by embedding article content
.PARAMETER Slug
    The article slug to test
.PARAMETER OutputFile
    Optional file to save test results
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Slug,

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

# Read article
$ArticleContent = Get-Content $ArticlePath -Raw

# Build test prompt with article embedded
$TestPrompt = @"
Extract and validate all code examples from this article.

For each code block:

1. Identify language and context
2. Check syntax is correct for the language/version
3. Verify logic matches what article claims
4. Look for common issues:
   - Undefined variables or functions
   - Type mismatches
   - Missing error handling
   - Security issues (hardcoded credentials, injection vulnerabilities)
   - Resource leaks
5. Validate output examples match code logic

OUTPUT FORMAT:

# CODE VALIDATION SUMMARY
- Overall Code Quality Score: [0-100]
- Total code blocks: [N]
- Valid (no issues): [N]
- Warnings (minor issues): [N]
- Errors (critical issues): [N]
- Status: [✓ ALL PASS / ⚠ WARNINGS PRESENT / ✗ ERRORS FOUND]

# DETAILED CODE ANALYSIS

For each code block:

**Code Block #[N]: [Section Name or Line Number]**
- Language: [detected language and version]
- Status: [✓ Valid | ⚠ Warning | ✗ Error]
- Issues Found:
  - [List specific issues with line numbers]
- Recommendations:
  - [Specific fixes or improvements]

# CRITICAL ISSUES (Must Fix)
[List code blocks with critical errors that prevent execution]

# WARNINGS (Should Fix)
[List code blocks with warnings that could cause problems]

# SECURITY ANALYSIS
- Security Issues Found: [Number]
- [List any security concerns with severity]

# RECOMMENDATIONS
1. [Priority action]
2. [Next priority]

Be specific about line numbers and exact errors found.

--- ARTICLE START ---
$ArticleContent
--- ARTICLE END ---
"@

Write-Host "Running code validation (this may take 30-60 seconds)..." -ForegroundColor Yellow

try {
    # Call Gemini CLI with embedded prompt
    $TestResult = & gemini $TestPrompt 2>&1 | Out-String

    if ($LASTEXITCODE -ne 0) {
        throw "Gemini CLI returned exit code $LASTEXITCODE"
    }

    # Clean output - remove debug messages
    $Lines = $TestResult -split "`r?`n"
    $CleanLines = $Lines | Where-Object {
        $_ -notmatch '^Loaded cached credentials' -and
        $_ -notmatch '^Loading' -and
        $_ -notmatch '^Initializing' -and
        $_ -notmatch '^Using model' -and
        $_ -notmatch '^Gemini CLI' -and
        $_ -notmatch '^Generating content' -and
        $_ -notmatch '^Streaming'
    }

    # Remove leading empty lines
    while ($CleanLines.Count -gt 0 -and [string]::IsNullOrWhiteSpace($CleanLines[0])) {
        $CleanLines = $CleanLines[1..($CleanLines.Count - 1)]
    }

    $TestResult = ($CleanLines -join "`n").Trim()

    if ([string]::IsNullOrWhiteSpace($TestResult)) {
        throw "Gemini CLI returned empty result"
    }

    Write-Host ""
    Write-Host $TestResult
    Write-Host ""

    # Save results if requested
    if ($OutputFile) {
        $ReportContent = @"
# Code Validation Report: $Slug

**Date:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Article:** $ArticlePath

---

$TestResult

---

## Notes
- All code blocks have been analyzed for syntax and logic errors
- Review any flagged issues before publishing
- Consider manual testing for complex code examples
"@

        Set-Content -Path $OutputFile -Value $ReportContent -Encoding UTF8
        Write-Host "✓ Test results saved: $OutputFile" -ForegroundColor Green
        Write-Host ""
    }

    # Parse status
    $Status = "UNKNOWN"
    if ($TestResult -match 'Status:\s*(✓ ALL PASS|⚠ WARNINGS PRESENT|✗ ERRORS FOUND)') {
        $Status = $Matches[1]
    }

    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan

    switch -Wildcard ($Status) {
        "*ALL PASS*" {
            Write-Host "  ✓ CODE VALIDATION PASSED" -ForegroundColor Green
            Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "All code examples are valid!" -ForegroundColor Green
        }
        "*WARNINGS*" {
            Write-Host "  ⚠ WARNINGS FOUND" -ForegroundColor Yellow
            Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Code has minor issues that should be addressed." -ForegroundColor Yellow
        }
        "*ERRORS*" {
            Write-Host "  ✗ ERRORS FOUND" -ForegroundColor Red
            Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Code has critical errors that must be fixed." -ForegroundColor Red
        }
        default {
            Write-Host "  ? CODE VALIDATION COMPLETE" -ForegroundColor Yellow
            Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Review the validation results above." -ForegroundColor Yellow
        }
    }

    Write-Host ""

} catch {
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Red
    Write-Host "  Code Validation Failed" -ForegroundColor Red
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Red
    Write-Host ""
    Write-Error "Failed to run code validation: $($_.Exception.Message)"
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "  - Verify Gemini CLI is working: gemini 'test'" -ForegroundColor Gray
    Write-Host "  - Check article exists: Test-Path $ArticlePath" -ForegroundColor Gray
    Write-Host "  - Wait 5-10 minutes for rate limits" -ForegroundColor Gray
    Write-Host ""
    exit 1
}
